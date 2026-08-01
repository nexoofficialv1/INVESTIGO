import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../models/sketch_map.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/doc_export_service.dart';
import 'pdf_preview_screen.dart';

class SketchMapScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const SketchMapScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<SketchMapScreen> createState() => _SketchMapScreenState();
}


class _SketchMapScreenState extends State<SketchMapScreen> {
  final LocalStoreService _store = LocalStoreService();
  final PdfService _pdf = PdfService();

  late SketchMapEntry _map;
  final _poCtrl = TextEditingController();
  final _northCtrl = TextEditingController();
  final _southCtrl = TextEditingController();
  final _eastCtrl = TextEditingController();
  final _westCtrl = TextEditingController();

  String? _selectedObjectId;
  final _markerEditCtrl = TextEditingController();
  final _labelEditCtrl = TextEditingController();
  final _indexEditCtrl = TextEditingController();
  String _directionEdit = '';
  double _widthEdit = .20;
  double _heightEdit = .14;
  double _rotationEdit = 0;

  SketchMapObject? get _selectedObject {
    if (_selectedObjectId == null) return null;
    for (final obj in _map.objects) {
      if (obj.id == _selectedObjectId) return obj;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _map = SketchMapEntry.empty(caseId: widget.caseFile.id);
    _load();
  }

  Future<void> _load() async {
    final saved = await _store.loadSketchMap(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _map = saved ?? SketchMapEntry.empty(caseId: widget.caseFile.id);
      _poCtrl.text = _map.poDescription;
      _northCtrl.text = _map.north;
      _southCtrl.text = _map.south;
      _eastCtrl.text = _map.east;
      _westCtrl.text = _map.west;
    });
  }

  @override
  void dispose() {
    _poCtrl.dispose();
    _northCtrl.dispose();
    _southCtrl.dispose();
    _eastCtrl.dispose();
    _westCtrl.dispose();
    _markerEditCtrl.dispose();
    _labelEditCtrl.dispose();
    _indexEditCtrl.dispose();
    super.dispose();
  }

  String _nextMarker() {
    final used = _map.objects.map((e) => e.marker).toSet();
    for (var i = 0; i < 26; i++) {
      final mark = String.fromCharCode(65 + i);
      if (!used.contains(mark)) return mark;
    }
    return '${_map.objects.length + 1}';
  }

  void _addObject(SketchObjectType type) {
    final offset = (_map.objects.length % 6) * 0.055;
    final obj = SketchMapObject.create(
      type: type,
      marker: _nextMarker(),
      x: (0.18 + offset).clamp(0.02, 0.82).toDouble(),
      y: (0.20 + offset).clamp(0.02, 0.82).toDouble(),
    );
    setState(() => _map = _map.copyWith(objects: [..._map.objects, obj]));
    _selectObject(obj);
  }

  void _updateObject(SketchMapObject obj) {
    setState(() {
      _map = _map.copyWith(objects: _map.objects.map((e) => e.id == obj.id ? obj : e).toList());
    });
  }

  void _deleteSelectedObject() {
    final obj = _selectedObject;
    if (obj == null) return;
    setState(() {
      _map = _map.copyWith(objects: _map.objects.where((e) => e.id != obj.id).toList());
      _selectedObjectId = null;
    });
    _markerEditCtrl.clear();
    _labelEditCtrl.clear();
    _indexEditCtrl.clear();
  }

  void _selectObject(SketchMapObject obj) {
    setState(() {
      _selectedObjectId = obj.id;
      _markerEditCtrl.text = obj.marker;
      _labelEditCtrl.text = obj.label;
      _indexEditCtrl.text = obj.indexDescription;
      _directionEdit = obj.direction;
      _widthEdit = obj.width;
      _heightEdit = obj.height;
      _rotationEdit = obj.rotationDeg;
    });
  }

  void _applyEditorToSelected() {
    final obj = _selectedObject;
    if (obj == null) return;
    final marker = _markerEditCtrl.text.trim().isEmpty ? obj.marker : _markerEditCtrl.text.trim().toUpperCase();
    final label = _labelEditCtrl.text.trim().isEmpty ? '$marker (${obj.type.label})' : _labelEditCtrl.text.trim();
    _updateObject(obj.copyWith(
      marker: marker,
      label: label,
      direction: _directionEdit,
      indexDescription: _indexEditCtrl.text.trim(),
      width: _widthEdit,
      height: _heightEdit,
      rotationDeg: _rotationEdit,
    ));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Object updated')));
  }

  SketchMapEntry _currentMap() => _map.copyWith(
        poDescription: _poCtrl.text.trim(),
        north: _northCtrl.text.trim(),
        south: _southCtrl.text.trim(),
        east: _eastCtrl.text.trim(),
        west: _westCtrl.text.trim(),
      );

  Future<void> _save({bool askCd = false}) async {
    try {
      final updated = _currentMap();
      await _store.saveSketchMap(updated);
      if (!mounted) return;
      setState(() => _map = updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sketch map saved • v2.4 no popup editor')));
      if (askCd) await _askMentionInCd();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sketch map save failed: $e')));
    }
  }

  Future<void> _askMentionInCd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mention in Case Diary?'),
        content: const Text('Prepared rough sketch map with index — এই action-টা CD-তে mention করা হবে?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true) return;
    final action = PendingCdAction.create(
      caseId: widget.caseFile.id,
      sourceType: 'Sketch Map',
      sourceId: _map.id,
      title: 'Rough Sketch Map prepared',
      actionDate: DateTime.now().toIso8601String().split('T').first,
      paragraph: 'Prepared rough sketch map of the PO with index.',
    );
    await _store.savePendingCdAction(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CD pending entry created')));
  }

  Future<void> _preview() async {
    await _save();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview Sketch Map',
          filename: 'Sketch_Map_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
          docFilename: 'Sketch_Map_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.doc',
          buildPdf: () => _pdf.buildSketchMapPdf(officer: widget.profile, caseFile: widget.caseFile, sketch: _currentMap()),
          buildDoc: () => DocExportService().buildSketchMapDoc(officer: widget.profile, caseFile: widget.caseFile, sketch: _currentMap()),
          onFinalSave: () async => _save(askCd: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Sketch Map Builder v2.4')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Save'))),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Clear map objects',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Clear sketch map?'),
                      content: const Text('This will remove all map objects from this case sketch. Continue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    setState(() {
                      _map = _map.copyWith(objects: const []);
                      _selectedObjectId = null;
                    });
                  }
                },
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _preview, icon: const Icon(Icons.picture_as_pdf), label: const Text('Preview'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _caseCard(),
          const SizedBox(height: 10),
          _toolbar(),
          const SizedBox(height: 10),
          _canvas(),
          const SizedBox(height: 12),
          _objectEditorCard(),
          const SizedBox(height: 12),
          _poAndDirections(),
          const SizedBox(height: 12),
          _indexList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _caseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.caseFile.displayTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('PO: ${widget.caseFile.placeOfOccurrence.isEmpty ? 'Not mentioned' : widget.caseFile.placeOfOccurrence}'),
            const SizedBox(height: 4),
            const Text('v2.4 SAFE MODE: object edit এখন popup/bottom sheet নয়। Object tap করলে নিচের editor card-এ edit করুন। Crash বন্ধ করার জন্য এই mode করা হয়েছে.', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF004D40))),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    final items = [
      _SketchTool(SketchObjectType.house, 'House'),
      _SketchTool(SketchObjectType.pond, 'Pond'),
      _SketchTool(SketchObjectType.tree, 'Tree'),
      _SketchTool(SketchObjectType.shop, 'Shop'),
      _SketchTool(SketchObjectType.road, 'Road ↔/↕'),
      _SketchTool(SketchObjectType.field, 'Field'),
      _SketchTool(SketchObjectType.po, 'PO'),
      _SketchTool(SketchObjectType.arrow, 'North'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((e) => ActionChip(
                    avatar: SizedBox(width: 26, height: 22, child: CustomPaint(painter: _MapSymbolPainter(type: e.type))),
                    label: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => _addObject(e.type),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _canvas() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF004D40),
            child: const Text('Rough Sketch Canvas • v2.4 safe inline editor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          AspectRatio(
            aspectRatio: 1.12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Positioned(top: 8, right: 12, child: _northMark()),
                      ..._map.objects.map((obj) => _sketchObjectWidget(obj, w, h)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _northMark() => const Column(
        children: [
          Icon(Icons.navigation, color: Colors.black87),
          Text('N', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      );

  Widget _sketchObjectWidget(SketchMapObject obj, double w, double h) {
    final left = obj.x * w;
    final top = obj.y * h;
    final width = obj.width * w;
    final height = obj.height * h;
    final selected = obj.id == _selectedObjectId;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectObject(obj),
        onPanUpdate: (details) {
          final nx = (obj.x + details.delta.dx / w).clamp(0.0, 0.94).toDouble();
          final ny = (obj.y + details.delta.dy / h).clamp(0.0, 0.94).toDouble();
          final moved = obj.copyWith(x: nx, y: ny);
          _updateObject(moved);
          if (selected) _selectedObjectId = moved.id;
        },
        child: Container(
          decoration: selected ? BoxDecoration(border: Border.all(color: Colors.red, width: 2)) : null,
          child: Transform.rotate(
            angle: obj.rotationDeg * math.pi / 180,
            child: SizedBox(width: width, height: height, child: _realisticSketchObject(obj)),
          ),
        ),
      ),
    );
  }

  Widget _realisticSketchObject(SketchMapObject obj) {
    final text = obj.label.trim().isEmpty ? obj.marker : obj.label.trim();
    return CustomPaint(
      painter: _MapSymbolPainter(type: obj.type),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(3),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: obj.type == SketchObjectType.road ? 9 : 8,
            fontWeight: FontWeight.w900,
            color: obj.type == SketchObjectType.po ? Colors.red.shade900 : Colors.black,
            backgroundColor: Colors.white.withOpacity(0.55),
          ),
        ),
      ),
    );
  }

  Widget _objectEditorCard() {
    final obj = _selectedObject;
    if (obj == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Object edit: map object tap করলে এখানে Marker / Label / Index / Size / Rotation edit করার option আসবে.', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 44, height: 34, child: CustomPaint(painter: _MapSymbolPainter(type: obj.type))),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit ${obj.marker} - ${obj.type.label}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _markerEditCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Marker / Index letter', helperText: 'Example: A, B, C or PO'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelEditCtrl,
              decoration: const InputDecoration(labelText: 'Map label', helperText: 'Example: A (House), B (Pond), C (Road)'),
            ),
            const SizedBox(height: 8),
            const Text('Direction for index', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['', 'North', 'South', 'East', 'West', 'Inside PO', 'Near PO']
                  .map((d) => ChoiceChip(
                        label: Text(d.isEmpty ? 'None' : d),
                        selected: _directionEdit == d,
                        onSelected: (_) => setState(() => _directionEdit = d),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _indexEditCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Index description', helperText: 'Example: East - A - House of ...'),
            ),
            const SizedBox(height: 12),
            const Text('Size / Rotation', style: TextStyle(fontWeight: FontWeight.w900)),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _widthEdit = (_widthEdit - .03).clamp(.08, .80).toDouble()), child: const Text('Width -'))),
                const SizedBox(width: 6),
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _widthEdit = (_widthEdit + .03).clamp(.08, .80).toDouble()), child: const Text('Width +'))),
              ],
            ),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _heightEdit = (_heightEdit - .03).clamp(.05, .65).toDouble()), child: const Text('Height -'))),
                const SizedBox(width: 6),
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _heightEdit = (_heightEdit + .03).clamp(.05, .65).toDouble()), child: const Text('Height +'))),
              ],
            ),
            if (obj.type == SketchObjectType.road || obj.type == SketchObjectType.arrow) ...[
              const SizedBox(height: 8),
              Text('Rotation: ${_rotationEdit.round()}°', style: const TextStyle(fontWeight: FontWeight.w800)),
              Slider(
                min: 0,
                max: 360,
                divisions: 24,
                value: _rotationEdit.clamp(0, 360).toDouble(),
                label: '${_rotationEdit.round()}°',
                onChanged: (v) => setState(() => _rotationEdit = v),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(label: const Text('East-West'), onPressed: () => setState(() => _rotationEdit = 0)),
                  ActionChip(label: const Text('North-South'), onPressed: () => setState(() => _rotationEdit = 90)),
                  ActionChip(label: const Text('Diagonal'), onPressed: () => setState(() => _rotationEdit = 45)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: _deleteSelectedObject, icon: const Icon(Icons.delete_outline), label: const Text('Delete'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton.icon(onPressed: _applyEditorToSelected, icon: const Icon(Icons.check), label: const Text('Apply'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _poAndDirections() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PO & Surroundings / Direction Index', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(controller: _poCtrl, decoration: const InputDecoration(labelText: 'PO description')),
            const SizedBox(height: 8),
            TextField(controller: _northCtrl, decoration: const InputDecoration(labelText: 'North')),
            TextField(controller: _southCtrl, decoration: const InputDecoration(labelText: 'South')),
            TextField(controller: _eastCtrl, decoration: const InputDecoration(labelText: 'East')),
            TextField(controller: _westCtrl, decoration: const InputDecoration(labelText: 'West')),
          ],
        ),
      ),
    );
  }

  Widget _indexList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Object Index', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            if (_map.objects.isEmpty)
              const Text('No object added yet. Add House/Pond/Road/PO etc.')
            else
              ..._map.objects.map((o) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(o.marker)),
                    title: Text(o.label),
                    subtitle: Text('${o.direction.isEmpty ? 'Direction not set' : o.direction} • ${o.indexDescription.isEmpty ? 'Index description not set' : o.indexDescription}'),
                    trailing: const Icon(Icons.edit),
                    selected: o.id == _selectedObjectId,
                    onTap: () => _selectObject(o),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SketchTool {
  final SketchObjectType type;
  final String label;
  const _SketchTool(this.type, this.label);
}

class _MapSymbolPainter extends CustomPainter {
  final SketchObjectType type;
  const _MapSymbolPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final fill = Paint()..style = PaintingStyle.fill;

    switch (type) {
      case SketchObjectType.house:
        fill.color = const Color(0xFFFFE0B2);
        final body = Rect.fromLTWH(size.width * .18, size.height * .38, size.width * .64, size.height * .48);
        final roof = Path()
          ..moveTo(size.width * .10, size.height * .40)
          ..lineTo(size.width * .50, size.height * .08)
          ..lineTo(size.width * .90, size.height * .40)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF8D4B20));
        canvas.drawPath(roof, border);
        canvas.drawRect(body, fill);
        canvas.drawRect(body, border);
        canvas.drawRect(Rect.fromLTWH(size.width * .44, size.height * .62, size.width * .12, size.height * .24), border);
        break;
      case SketchObjectType.shop:
        final base = Rect.fromLTWH(size.width * .10, size.height * .24, size.width * .80, size.height * .62);
        canvas.drawRect(base, Paint()..color = const Color(0xFFF3E5F5));
        canvas.drawRect(base, border);
        canvas.drawRect(Rect.fromLTWH(size.width * .06, size.height * .10, size.width * .88, size.height * .22), Paint()..color = const Color(0xFFCE93D8));
        canvas.drawRect(Rect.fromLTWH(size.width * .06, size.height * .10, size.width * .88, size.height * .22), border);
        for (var i = 0; i < 4; i++) {
          final x = size.width * (.08 + i * .21);
          canvas.drawRect(Rect.fromLTWH(x, size.height * .10, size.width * .11, size.height * .22), Paint()..color = i.isEven ? Colors.white : const Color(0xFFE1BEE7));
          canvas.drawRect(Rect.fromLTWH(x, size.height * .10, size.width * .11, size.height * .22), border);
        }
        break;
      case SketchObjectType.pond:
        fill.color = const Color(0xFFB3E5FC);
        final path = Path()
          ..moveTo(size.width * .10, size.height * .45)
          ..cubicTo(size.width * .10, size.height * .14, size.width * .45, size.height * .06, size.width * .68, size.height * .18)
          ..cubicTo(size.width * .96, size.height * .30, size.width * .92, size.height * .72, size.width * .62, size.height * .82)
          ..cubicTo(size.width * .34, size.height * .92, size.width * .08, size.height * .76, size.width * .10, size.height * .45)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
        final wave = Paint()..color = const Color(0xFF0277BD)..strokeWidth = 1..style = PaintingStyle.stroke;
        for (var i = 0; i < 3; i++) {
          final y = size.height * (.36 + i * .15);
          canvas.drawLine(Offset(size.width * .28, y), Offset(size.width * .72, y), wave);
        }
        break;
      case SketchObjectType.tree:
        canvas.drawRect(Rect.fromLTWH(size.width * .45, size.height * .52, size.width * .10, size.height * .32), Paint()..color = const Color(0xFF795548));
        canvas.drawCircle(Offset(size.width * .50, size.height * .34), size.shortestSide * .25, Paint()..color = const Color(0xFFA5D6A7));
        canvas.drawCircle(Offset(size.width * .38, size.height * .43), size.shortestSide * .20, Paint()..color = const Color(0xFF81C784));
        canvas.drawCircle(Offset(size.width * .62, size.height * .43), size.shortestSide * .20, Paint()..color = const Color(0xFF66BB6A));
        break;
      case SketchObjectType.road:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * .16, size.width, size.height * .68), const Radius.circular(2)), Paint()..color = const Color(0xFFBDBDBD));
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * .16, size.width, size.height * .68), const Radius.circular(2)), border);
        final mid = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke;
        var x = size.width * .08;
        while (x < size.width * .95) {
          canvas.drawLine(Offset(x, size.height * .50), Offset(x + size.width * .08, size.height * .50), mid);
          x += size.width * .16;
        }
        break;
      case SketchObjectType.field:
        canvas.drawRect(Rect.fromLTWH(size.width * .06, size.height * .12, size.width * .88, size.height * .76), Paint()..color = const Color(0xFFDCECC5));
        canvas.drawRect(Rect.fromLTWH(size.width * .06, size.height * .12, size.width * .88, size.height * .76), border);
        final line = Paint()..color = const Color(0xFF7CB342)..strokeWidth = 1;
        for (var i = 1; i < 5; i++) {
          final x = size.width * (.06 + i * .17);
          canvas.drawLine(Offset(x, size.height * .12), Offset(x, size.height * .88), line);
        }
        break;
      case SketchObjectType.po:
        canvas.drawRect(Rect.fromLTWH(size.width * .12, size.height * .18, size.width * .76, size.height * .64), Paint()..color = const Color(0xFFFFEBEE));
        final poBorder = Paint()..color = const Color(0xFFB71C1C)..style = PaintingStyle.stroke..strokeWidth = 2.2;
        canvas.drawRect(Rect.fromLTWH(size.width * .12, size.height * .18, size.width * .76, size.height * .64), poBorder);
        break;
      case SketchObjectType.arrow:
        final p = Paint()..color = Colors.black87..strokeWidth = 3..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(size.width * .50, size.height * .86), Offset(size.width * .50, size.height * .18), p);
        final head = Path()
          ..moveTo(size.width * .50, size.height * .08)
          ..lineTo(size.width * .32, size.height * .28)
          ..lineTo(size.width * .68, size.height * .28)
          ..close();
        canvas.drawPath(head, Paint()..color = Colors.black87);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MapSymbolPainter oldDelegate) => oldDelegate.type != type;
}
