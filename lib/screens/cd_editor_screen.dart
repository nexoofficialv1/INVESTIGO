import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_screen.dart';
import '../widgets/form_helpers.dart';

class CdEditorScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final CdEntry cd;

  const CdEditorScreen({super.key, required this.profile, required this.caseFile, required this.cd});

  @override
  State<CdEditorScreen> createState() => _CdEditorScreenState();
}

class _CdEditorScreenState extends State<CdEditorScreen> {
  final LocalStoreService _store = LocalStoreService();
  late CdEntry _cd;
  late final TextEditingController cdDate;
  late final TextEditingController startTime;
  late final TextEditingController endTime;
  late final TextEditingController place;
  late final List<_CdLineControllers> _lineControllers;

  @override
  void initState() {
    super.initState();
    _cd = widget.cd;
    cdDate = TextEditingController(text: _cd.cdDate);
    startTime = TextEditingController(text: _cd.startTime);
    endTime = TextEditingController(text: _cd.endTime);
    place = TextEditingController(text: _cd.placeOfEntry);
    final initialLines = _cd.tableLines.isNotEmpty
        ? _cd.tableLines
        : [CdTableLine(noAndHour: 'I\n${_cd.startTime}', placeOfEntry: _cd.placeOfEntry, synopsis: _cd.cdNumber == 1 ? 'Received copy of FIR\n+\nGist' : 'Further investigation', proceedings: _cd.body)];
    _lineControllers = initialLines.map(_CdLineControllers.fromLine).toList();
  }

  @override
  void dispose() {
    cdDate.dispose();
    startTime.dispose();
    endTime.dispose();
    place.dispose();
    for (final c in _lineControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<CdTableLine> _currentLines() => _lineControllers
      .map((c) => CdTableLine(
            noAndHour: c.noAndHour.text.trim(),
            placeOfEntry: c.place.text.trim(),
            synopsis: c.synopsis.text.trim(),
            proceedings: c.proceedings.text.trim(),
          ))
      .where((line) => line.noAndHour.isNotEmpty || line.placeOfEntry.isNotEmpty || line.synopsis.isNotEmpty || line.proceedings.isNotEmpty)
      .toList();

  String _combinedBody(List<CdTableLine> lines) => lines.map((e) => e.proceedings).where((e) => e.trim().isNotEmpty).join('\n\n');

  Future<void> _save({bool finalSave = false}) async {
    final lines = _currentLines();
    final updated = _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: _combinedBody(lines),
      tableLines: lines,
      isFinal: finalSave ? true : _cd.isFinal,
    );
    await _store.saveCd(updated);
    if (!mounted) return;
    setState(() => _cd = updated);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalSave ? 'CD final saved' : 'CD draft saved')));
  }

  Future<void> _finalSave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Final Save CD?'),
        content: const Text('Final save করলে CD locked হিসেবে mark হবে। পরে edit করা যাবে, কিন্তু warning দেখাবে।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Final Save')),
        ],
      ),
    );
    if (ok == true) await _save(finalSave: true);
  }

  CdEntry _currentCd() {
    final lines = _currentLines();
    return _cd.copyWith(
      cdDate: cdDate.text.trim(),
      startTime: startTime.text.trim(),
      endTime: endTime.text.trim(),
      placeOfEntry: place.text.trim(),
      body: _combinedBody(lines),
      tableLines: lines,
    );
  }

  Future<void> _previewPdf() async {
    await _save(finalSave: false);
    if (!mounted) return;
    final cdForPreview = _currentCd();
    final baseName = 'CD_${widget.caseFile.psCaseNo.replaceAll('/', '_')}_${_cd.cdNumber}';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview CD-${_cd.cdNumber}',
          filename: '$baseName.pdf',
          docFilename: '$baseName.doc',
          buildPdf: () => PdfService().buildCaseDiaryPdf(officer: widget.profile, caseFile: widget.caseFile, cd: cdForPreview),
          buildDoc: () => DocExportService().buildCaseDiaryDoc(officer: widget.profile, caseFile: widget.caseFile, cd: cdForPreview),
          onFinalSave: () => _save(finalSave: true),
        ),
      ),
    );
  }

  void _addEntry() {
    setState(() {
      final next = _lineControllers.length + 1;
      _lineControllers.add(_CdLineControllers(
        noAndHour: TextEditingController(text: '$next\n${startTime.text.trim()}'),
        place: TextEditingController(text: place.text.trim()),
        synopsis: TextEditingController(text: 'New entry'),
        proceedings: TextEditingController(),
      ));
    });
  }

  void _deleteEntry(int index) {
    if (_lineControllers.length <= 1) return;
    setState(() {
      final removed = _lineControllers.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CD-${_cd.cdNumber} Editor')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Draft'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _finalSave, icon: const Icon(Icons.lock), label: const Text('Final'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _previewPdf, icon: const Icon(Icons.preview), label: const Text('Preview'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_cd.isFinal)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('This CD is final saved. Edit carefully if required.', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CD Header Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FormHelpers.textField(controller: cdDate, label: 'CD Date'),
                  Row(
                    children: [
                      Expanded(child: FormHelpers.textField(controller: startTime, label: 'Start Time')),
                      const SizedBox(width: 8),
                      Expanded(child: FormHelpers.textField(controller: endTime, label: 'End Time')),
                    ],
                  ),
                  FormHelpers.textField(controller: place, label: 'Default Place of Entry'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Entry-wise Official CD Columns', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('মোবাইলে স্ক্রল করে প্রতিটি entry edit করুন। Entry No/Time, Place of Entry, Synopsis of Entry এবং Proceedings আলাদা field হিসেবে থাকবে। PDF/DOC export-এ এগুলো official column-এ বসবে।'),
          const SizedBox(height: 10),
          ...List.generate(_lineControllers.length, (index) => _entryCard(index, _lineControllers[index])),
          OutlinedButton.icon(onPressed: _addEntry, icon: const Icon(Icons.add), label: const Text('Add Entry Line')),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _entryCard(int index, _CdLineControllers c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Entry ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => _deleteEntry(index), icon: const Icon(Icons.delete_outline)),
              ],
            ),
            FormHelpers.textField(controller: c.noAndHour, label: 'Entry No. and Hour / Time', maxLines: 2),
            FormHelpers.textField(controller: c.place, label: 'Place of Entry', maxLines: 2),
            FormHelpers.textField(controller: c.synopsis, label: 'Synopsis of Entry', maxLines: 3),
            FormHelpers.textField(controller: c.proceedings, label: 'Proceedings / Main Body', maxLines: 8),
          ],
        ),
      ),
    );
  }
}

class _CdLineControllers {
  final TextEditingController noAndHour;
  final TextEditingController place;
  final TextEditingController synopsis;
  final TextEditingController proceedings;

  _CdLineControllers({required this.noAndHour, required this.place, required this.synopsis, required this.proceedings});

  factory _CdLineControllers.fromLine(CdTableLine line) => _CdLineControllers(
        noAndHour: TextEditingController(text: line.noAndHour),
        place: TextEditingController(text: line.placeOfEntry),
        synopsis: TextEditingController(text: line.synopsis),
        proceedings: TextEditingController(text: line.proceedings),
      );

  void dispose() {
    noAndHour.dispose();
    place.dispose();
    synopsis.dispose();
    proceedings.dispose();
  }
}
