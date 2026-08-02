import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/officer_profile.dart';
import '../models/ud_case.dart';
import '../services/doc_export_service.dart';
import '../data/domain/ud_case_store.dart';
import '../services/pdf_service.dart';
import '../services/ud_narration_service.dart';
import 'pdf_preview_screen.dart';

class UdCaseScreen extends StatefulWidget {
  final OfficerProfile profile;
  const UdCaseScreen({super.key, required this.profile});

  @override
  State<UdCaseScreen> createState() => _UdCaseScreenState();
}

class _UdCaseScreenState extends State<UdCaseScreen> {
  final _store = UdCaseStore();
  final _pdf = PdfService();
  final _doc = DocExportService();
  final _narrationParser = UdNarrationService();
  final _smartNarration = TextEditingController();
  final Map<String, TextEditingController> _c = {};
  List<UdCase> _saved = [];
  UdCase _ud = UdCase.empty();
  String _injuryPart = 'injuryHead';
  String _dischargePart = 'nostrils';
  bool _applyingNarration = false;

  static const Map<String, String> _injuryOptions = {
    'injuryHead': 'Head',
    'injuryFace': 'Face',
    'injuryNeck': 'Neck',
    'injuryChest': 'Chest',
    'injuryStomach': 'Stomach',
    'injuryShoulder': 'Shoulder',
    'injuryRightHand': 'Right Hand',
    'injuryLeftHand': 'Left Hand',
    'injuryRightLeg': 'Right Leg',
    'injuryLeftLeg': 'Left Leg',
    'injuryPrivateParts': 'Private parts',
    'injuryBack': 'Back',
    'injuryOther': 'Any other injury',
  };

  static const Map<String, String> _dischargeOptions = {
    'nostrils': 'Nostrils',
    'earsEyes': 'Ears / Eyes',
    'mouth': 'Mouth',
    'penisVagina': 'Penis/Vagina',
    'anus': 'Anus',
  };

  final List<_F> _fields = const [
    _F('district', 'District'),
    _F('policeStation', 'PS'),
    _F('udNo', 'FIR/UD No.'),
    _F('gdeNo', 'GDE No. & Date'),
    _F('dateTime', 'Date & Time'),
    _F('distanceFromPs', 'Distance from PS'),
    _F('directionFromPs', 'Direction from PS'),
    _F('placeFound', 'Place where dead body found'),
    _F('longitude', 'Longitude'),
    _F('latitude', 'Latitude'),
    _F('deadBodyFoundDate', 'Dead body found/traced Date'),
    _F('deadBodyFoundTime', 'Dead body found/traced Time'),
    _F('informantName', 'Informant Name'),
    _F('informantAge', 'Informant Age'),
    _F('informantSex', 'Informant Sex'),
    _F('informantAddress', 'Informant Address', lines: 2),
    _F('identifiedByName', 'Dead Body identified by Name'),
    _F('identifiedByAge', 'Identifier Age'),
    _F('identifiedBySex', 'Identifier Sex'),
    _F('identifiedByRelation', 'Relation, if any'),
    _F('identifiedByAddress', 'Identifier Address', lines: 2),
    _F('deceasedName', 'Name of deceased'),
    _F('deceasedSex', 'Sex: Male/Female'),
    _F('deceasedAge', 'Approx. Age'),
    _F('deceasedAddress', 'Deceased Address', lines: 2),
    _F('bodyPosition', 'Position of dead body including PM staining', lines: 3),
    _F('build', 'Build'),
    _F('height', 'Height'),
    _F('rigorMortis', 'Rigor Mortis'),
    _F('complexion', 'Complexion'),
    _F('deformities', 'Deformities, if any'),
    _F('religionRaceCommunity', 'Religion/Race/Community'),
    _F('teeth', 'Identification mark: Teeth'),
    _F('eyes', 'Eyes'),
    _F('laceDerma', 'Lace derma'),
    _F('mole', 'Mole'),
    _F('tattoo', 'Tattoo'),
    _F('dress', 'Dress/wearing apparel', lines: 2),
    _F('otherFeatures', 'Other features, if any', lines: 2),
    _F('weaponOpinion', 'Opinion on nature of weapon/injury manner', lines: 3),
    _F('ligatureDescription', 'Ligature mark / rope / knot description', lines: 3),
    _F('foreignMaterial', 'Foreign material found on body', lines: 3),
    _F('poDescription', 'Description of place of occurrence', lines: 3),
    _F('articlesAtPo', 'Articles at PO including weapon/ornaments', lines: 3),
    _F('probableCauseOfDeath', 'Probable cause of death', lines: 2),
    _F('remarks', 'Remarks', lines: 3),
    _F('witness1NameAddress', 'Witness (i) Name/Address', lines: 2),
    _F('witness2NameAddress', 'Witness (ii) Name/Address', lines: 2),
    _F('briefFacts', 'Brief facts', lines: 5),
  ];

  @override
  void initState() {
    super.initState();
    _ud = UdCase.empty(ps: widget.profile.policeStation, district: widget.profile.district);
    _initControllers();
    _loadSaved();
  }

  void _initControllers() {
    final map = _ud.toJson();
    for (final f in _fields) {
      _c[f.key] = TextEditingController(text: (map[f.key] ?? '').toString());
    }
    for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
      _c[key] = TextEditingController(text: (map[key] ?? '').toString());
    }
  }

  Future<void> _loadSaved() async {
    final list = await _store.loadUdCases();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  UdCase _collect() {
    final values = {
      for (final f in _fields) f.key: _c[f.key]!.text.trim(),
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys])
        key: _c[key]!.text.trim(),
      'policeStation': widget.profile.policeStation,
      'district': widget.profile.district,
    };
    return _ud.copyWith(values);
  }

  Future<void> _applyNarrationToUd() async {
    if (_smartNarration.text.trim().isEmpty || _applyingNarration) return;
    setState(() => _applyingNarration = true);
    try {
      final result = _narrationParser.analyse(_smartNarration.text);
      for (final entry in result.values.entries) {
        final controller = _c[entry.key];
        if (controller != null && entry.value.trim().isNotEmpty) {
          controller.text = entry.value.trim();
        }
      }
      _ud = _collect();
      await _store.saveUdCase(_ud);
      await _loadSaved();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('UD নথি Auto-fill সম্পন্ন'),
          content: Text(
            '${result.populatedFieldCount}টি field শনাক্ত করে shared UD record-এ বসানো হয়েছে. এই একই data থেকে সুরতহাল/Inquest, Dead Body Challan এবং Final Report তৈরি হবে.'
            '${result.warnings.isEmpty ? '' : '\n\nযাচাই করুন:\n• ${result.warnings.join('\n• ')}'}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _applyingNarration = false);
    }
  }

  Future<void> _save() async {
    _ud = _collect();
    await _store.saveUdCase(_ud);
    await _loadSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UD Inquest draft saved')));
  }

  Future<void> _runDocumentAction(String label, Future<void> Function() action) async {
    if (!widget.profile.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer Profile-এ Police Station এবং District পূরণ করুন।')),
      );
      return;
    }
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label failed: $error')),
      );
    }
  }

  Future<void> _previewPdf() async {
    _ud = _collect();
    final bytes = await _pdf.buildUdInquestPdf(officer: widget.profile, ud: _ud);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf() async {
    _ud = _collect();
    final bytes = await _pdf.buildUdInquestPdf(officer: widget.profile, ud: _ud);
    await Printing.sharePdf(bytes: bytes, filename: 'UD_Inquest_${_ud.udNo.replaceAll('/', '_')}.pdf');
  }

  Future<void> _exportDoc() async {
    _ud = _collect();
    final bytes = await _doc.buildUdInquestDoc(officer: widget.profile, ud: _ud);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/UD_Inquest_${_ud.udNo.replaceAll('/', '_')}.doc';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)], text: 'UD Inquest DOC');
  }

  Future<void> _previewDeadBodyChallan() async {
    await _runDocumentAction('Dead Body Challan Preview', () async {
      _ud = _collect();
      await _store.saveUdCase(_ud);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            title: 'Dead Body Challan — Form 5371',
            filename:
                'UD_Dead_Body_Challan_${_ud.udNo.replaceAll('/', '_')}.pdf',
            docFilename:
                'UD_Dead_Body_Challan_${_ud.udNo.replaceAll('/', '_')}.doc',
            buildPdf: () => _pdf.buildUdDeadBodyChallanPdf(
              officer: widget.profile,
              ud: _ud,
            ),
            buildDoc: () => _doc.buildUdDeadBodyChallanDoc(
              officer: widget.profile,
              ud: _ud,
            ),
          ),
        ),
      );
    });
  }

  Future<void> _exportDeadBodyChallan() async {
    await _runDocumentAction('Dead Body Challan PDF', () async {
      _ud = _collect();
      final bytes = await _pdf.buildUdDeadBodyChallanPdf(officer: widget.profile, ud: _ud);
      await Printing.sharePdf(bytes: bytes, filename: 'UD_Dead_Body_Challan_${_ud.udNo.replaceAll('/', '_')}.pdf');
    });
  }

  Future<void> _exportDeadBodyChallanDoc() async {
    await _runDocumentAction('Dead Body Challan DOC', () async {
      _ud = _collect();
      final bytes = await _doc.buildUdDeadBodyChallanDoc(officer: widget.profile, ud: _ud);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/UD_Dead_Body_Challan_${_ud.udNo.replaceAll('/', '_')}.doc';
      await File(path).writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(path)], text: 'UD Dead Body Challan DOC');
    });
  }

  Future<void> _previewFinalReport() async {
    _ud = _collect();
    final bytes = await _pdf.buildUdFinalReportPdf(
      officer: widget.profile,
      ud: _ud,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportFinalReport() async {
    _ud = _collect();
    final bytes = await _pdf.buildUdFinalReportPdf(
      officer: widget.profile,
      ud: _ud,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'UD_Final_Report_${_ud.udNo.replaceAll('/', '_')}.pdf',
    );
  }

  Future<void> _exportFinalReportDoc() async {
    _ud = _collect();
    final bytes = await _doc.buildUdFinalReportDoc(officer: widget.profile, ud: _ud);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/UD_Final_Report_${_ud.udNo.replaceAll('/', '_')}.doc';
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)], text: 'UD Final Report DOC');
  }

  void _loadUd(UdCase ud) {
    setState(() {
      _ud = ud;
      final map = ud.toJson();
      for (final f in _fields) {
        if (f.key == 'policeStation') {
          _c[f.key]!.text = widget.profile.policeStation;
        } else if (f.key == 'district') {
          _c[f.key]!.text = widget.profile.district;
        } else {
          _c[f.key]!.text = (map[f.key] ?? '').toString();
        }
      }
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
        _c[key]!.text = (map[key] ?? '').toString();
      }
    });
  }

  void _newUd() {
    setState(() {
      _ud = UdCase.empty(ps: widget.profile.policeStation, district: widget.profile.district);
      final map = _ud.toJson();
      for (final f in _fields) {
        if (f.key == 'policeStation') {
          _c[f.key]!.text = widget.profile.policeStation;
        } else if (f.key == 'district') {
          _c[f.key]!.text = widget.profile.district;
        } else {
          _c[f.key]!.text = (map[f.key] ?? '').toString();
        }
      }
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
        _c[key]!.text = (map[key] ?? '').toString();
      }
    });
  }

  @override
  void dispose() {
    _smartNarration.dispose();
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('UD Case / Inquest'),
        actions: [IconButton(onPressed: _newUd, icon: const Icon(Icons.add))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_saved.isNotEmpty) _savedList(),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'এক জায়গায় UD/Inquest-এর পুরো বিবরণ লিখুন',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'বাংলা বা English-এ UD no., GDE, মৃতের পরিচয়, কোথায়/কী অবস্থায় দেহ পাওয়া গেছে, পোশাক, আঘাত, সাক্ষী ও সম্ভাব্য মৃত্যুর কারণ লিখুন। App একই shared record থেকে Inquest/সুরতহাল, Dead Body Challan ও Final Report পূরণ করবে।',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _smartNarration,
                    minLines: 7,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      labelText: 'UD / Inquest narration',
                      hintText: 'উদাহরণ: UD No: 10/2026; মৃতের নাম: ...; মৃতদেহ পাওয়ার স্থান: ...; দেহের অবস্থান: ...; পোশাক: ...; সম্ভাব্য মৃত্যুর কারণ: ...; সাক্ষী ১: ...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _applyingNarration ? null : _applyNarrationToUd,
                    icon: _applyingNarration
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Auto-fill Inquest + Challan + Final Report',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Inquest Form — Section 194 / 196 OF BNSS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('আপনার দেওয়া scanned format অনুযায়ী field-wise data fill করুন। Export-এর আগে Preview দেখে নিন।', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  ..._fields.map((f) {
                    final field = Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _c[f.key],
                        readOnly: f.key == 'policeStation' || f.key == 'district',
                        minLines: f.lines,
                        maxLines: f.lines > 1 ? f.lines + 2 : 1,
                        decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
                      ),
                    );
                    if (f.key == 'otherFeatures') {
                      return Column(children: [field, _injuryDropdownCard(), _dischargeDropdownCard()]);
                    }
                    return field;
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Profile source: ${widget.profile.policeStation}, ${widget.profile.district}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UD Documents / ইউডি নথিপত্র',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Draft'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewPdf,
                        icon: const Icon(Icons.visibility),
                        label: const Text('সুরতহাল Preview'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('সুরতহাল PDF'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportDoc,
                        icon: const Icon(Icons.description),
                        label: const Text('সুরতহাল DOC'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewDeadBodyChallan,
                        icon: const Icon(Icons.visibility),
                        label: const Text('ডেডবডি চালান Preview'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportDeadBodyChallan,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('ডেডবডি চালান PDF'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportDeadBodyChallanDoc,
                        icon: const Icon(Icons.description),
                        label: const Text('ডেডবডি চালান DOC'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _previewFinalReport,
                        icon: const Icon(Icons.visibility),
                        label: const Text('Final Report Preview'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportFinalReport,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Final Report PDF'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _exportFinalReportDoc,
                        icon: const Icon(Icons.description),
                        label: const Text('Final Report DOC'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }


  Widget _injuryDropdownCard() {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('10. Description of external injuries found on Dead Body', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _injuryPart,
              decoration: const InputDecoration(labelText: 'Select body part', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _injuryOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _injuryPart = v ?? _injuryPart),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _c[_injuryPart],
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Entry for ${_injuryOptions[_injuryPart]}',
                helperText: 'Select body part from dropdown, then enter injury details. It will export in official Sl. No. 10 format.',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _summaryList(_injuryOptions),
          ],
        ),
      ),
    );
  }

  Widget _dischargeDropdownCard() {
    return Card(
      color: Colors.blueGrey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('11. Discharge form', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _dischargePart,
              decoration: const InputDecoration(labelText: 'Select discharge part', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
              items: _dischargeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _dischargePart = v ?? _dischargePart),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _c[_dischargePart],
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Entry for ${_dischargeOptions[_dischargePart]}',
                helperText: 'Select item from dropdown, then enter discharge details. It will export in official Sl. No. 11 format.',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _summaryList(_dischargeOptions),
          ],
        ),
      ),
    );
  }

  Widget _summaryList(Map<String, String> options) {
    final filled = options.entries.where((e) => (_c[e.key]?.text.trim().isNotEmpty ?? false)).toList();
    if (filled.isEmpty) {
      return const Text('No entry added yet.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filled.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text('• ${e.value}: ${_c[e.key]!.text.trim()}', maxLines: 2, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }

  Widget _savedList() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history),
        title: const Text('Saved UD Drafts', style: TextStyle(fontWeight: FontWeight.w900)),
        children: _saved.map((ud) => ListTile(
              title: Text(ud.displayTitle),
              subtitle: Text('Deceased: ${ud.deceasedName}\nPlace: ${ud.placeFound}', maxLines: 2),
              isThreeLine: true,
              onTap: () => _loadUd(ud),
            )).toList(),
      ),
    );
  }
}

class _F {
  final String key;
  final String label;
  final int lines;
  const _F(this.key, this.label, {this.lines = 1});
}
