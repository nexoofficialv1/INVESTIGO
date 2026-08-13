import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/sketch_map.dart';
import '../services/local_store_service.dart';
import '../services/sketch_map_auto_service.dart';
import 'sketch_map_screen.dart';

class AutoSketchMapValidationScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final int sourceCdNumber;
  final String exactPo;
  final String north;
  final String south;
  final String east;
  final String west;

  const AutoSketchMapValidationScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.sourceCdNumber,
    required this.exactPo,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  @override
  State<AutoSketchMapValidationScreen> createState() =>
      _AutoSketchMapValidationScreenState();
}

class _AutoSketchMapValidationScreenState
    extends State<AutoSketchMapValidationScreen> {
  final LocalStoreService _store = LocalStoreService();
  final SketchMapAutoService _auto = SketchMapAutoService();

  SketchMapEntry? _map;
  SketchMapApprovalRecord? _approval;
  String? _selectedId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var map = await _store.loadSketchMap(widget.caseFile.id);
    if (map == null || map.objects.isEmpty) {
      map = _newDraft();
      await _store.saveSketchMap(map);
    }
    final approval = await _auto.loadApproval(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _map = map;
      _approval = approval;
      _loading = false;
    });
  }

  SketchMapEntry _newDraft() => _auto.generateDraft(
        caseId: widget.caseFile.id,
        sourceCdNumber: widget.sourceCdNumber,
        exactPo: widget.exactPo,
        north: widget.north,
        south: widget.south,
        east: widget.east,
        west: widget.west,
        date: DateTime.now().toIso8601String().split('T').first,
      );

  bool get _approved => _auto.isApprovedFor(_map, _approval);

  Future<void> _regenerate() async {
    final map = _newDraft();
    await _store.saveSketchMap(map);
    await _auto.invalidate(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _map = map;
      _approval = null;
      _selectedId = null;
    });
  }

  Future<void> _openAdvancedEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SketchMapScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
        ),
      ),
    );
    final map = await _store.loadSketchMap(widget.caseFile.id);
    final approval = await _auto.loadApproval(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _map = map;
      _approval = approval;
    });
  }

  Future<void> _approve() async {
    final map = _map;
    if (map == null) return;
    final issues = _auto.validateDraft(map);
    if (issues.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sketch Map validation incomplete'),
          content: Text(issues.map((e) => '• $e').join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক করি'),
            ),
          ],
        ),
      );
      return;
    }
    final approval = await _auto.approve(
      map: map,
      officerName: widget.profile.name,
      sourceCdNumber: widget.sourceCdNumber,
    );
    if (!mounted) return;
    setState(() => _approval = approval);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sketch Map validated and approved.')),
    );
  }

  void _moveObject(SketchMapObject object, Offset delta, double w, double h) {
    final nx = (object.x + delta.dx / w).clamp(0.0, .93).toDouble();
    final ny = (object.y + delta.dy / h).clamp(0.0, .93).toDouble();
    final moved = object.copyWith(x: nx, y: ny);
    final map = _map;
    if (map == null) return;
    setState(() {
      _map = map.copyWith(
        objects: map.objects.map((e) => e.id == moved.id ? moved : e).toList(),
      );
      _approval = null;
    });
  }

  Future<void> _persistLayout() async {
    final map = _map;
    if (map == null) return;
    await _store.saveSketchMap(map);
    await _auto.invalidate(widget.caseFile.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _map == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final map = _map!;
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Sketch Map • Validate')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openAdvancedEditor,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Full Edit / Export'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _approved
                      ? () => Navigator.pop(context, true)
                      : _approve,
                  icon: Icon(_approved ? Icons.check_circle : Icons.verified_outlined),
                  label: Text(_approved ? 'Use in CD' : 'Approve Final'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_approved ? Icons.verified : Icons.auto_awesome),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _approved
                              ? 'Officer validated • Final sketch map'
                              : 'Auto-generated draft • Officer validation required',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Exact PO: ${map.poDescription}'),
                  Text('North: ${map.north}'),
                  Text('South: ${map.south}'),
                  Text('East: ${map.east}'),
                  Text('West: ${map.west}'),
                  if (_approved && _approval != null) ...[
                    const SizedBox(height: 8),
                    Text('Approved by: ${_approval!.approvedBy}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Drag objects to correct the auto layout. For label, size, rotation or extra objects use Full Edit.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1.12,
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      return Container(
                        color: Colors.white,
                        child: Stack(
                          children: map.objects
                              .map((o) => _objectWidget(o, w, h))
                              .toList(growable: false),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Auto Index', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  ...map.objects
                      .where((e) => e.indexDescription.trim().isNotEmpty)
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(e.indexDescription),
                          )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _regenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate from Exact PO + N/S/E/W'),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _objectWidget(SketchMapObject object, double w, double h) {
    final selected = object.id == _selectedId;
    return Positioned(
      left: object.x * w,
      top: object.y * h,
      child: GestureDetector(
        onTap: () => setState(() => _selectedId = object.id),
        onPanUpdate: (d) => _moveObject(object, d.delta, w, h),
        onPanEnd: (_) => _persistLayout(),
        child: Transform.rotate(
          angle: object.rotationDeg * 3.141592653589793 / 180,
          child: Container(
            width: object.width * w,
            height: object.height * h,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: object.type == SketchObjectType.po
                  ? const Color(0xFFFFEBEE)
                  : object.type == SketchObjectType.road
                      ? const Color(0xFFE0E0E0)
                      : Colors.white,
              border: Border.all(
                width: selected ? 2.2 : 1.2,
                color: object.type == SketchObjectType.po
                    ? const Color(0xFFB71C1C)
                    : selected
                        ? Colors.blueGrey
                        : Colors.black87,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              object.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: object.type == SketchObjectType.po
                    ? const Color(0xFFB71C1C)
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
