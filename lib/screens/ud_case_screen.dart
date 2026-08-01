import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/officer_profile.dart';
import '../models/ud_case.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';

class UdCaseScreen extends StatefulWidget {
  final OfficerProfile profile;
  const UdCaseScreen({super.key, required this.profile});

  @override
  State<UdCaseScreen> createState() => _UdCaseScreenState();
}

class _UdCaseScreenState extends State<UdCaseScreen> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  final _doc = DocExportService();
  final Map<String, TextEditingController> _c = {};
  List<UdCase> _saved = [];
  UdCase _ud = UdCase.empty();
  String _injuryPart = 'injuryHead';
  String _dischargePart = 'nostrils';

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
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) key: _c[key]!.text.trim(),
    };
    return _ud.copyWith(values);
  }

  Future<void> _save() async {
    _ud = _collect();
    await _store.saveUdCase(_ud);
    await _loadSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UD Inquest draft saved')));
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

  void _loadUd(UdCase ud) {
    setState(() {
      _ud = ud;
      final map = ud.toJson();
      for (final f in _fields) {
        _c[f.key]!.text = (map[f.key] ?? '').toString();
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
        _c[f.key]!.text = (map[f.key] ?? '').toString();
      }
      for (final key in [..._injuryOptions.keys, ..._dischargeOptions.keys]) {
        _c[key]!.text = (map[key] ?? '').toString();
      }
    });
  }

  @override
  void dispose() {
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Draft')),
              OutlinedButton.icon(onPressed: _previewPdf, icon: const Icon(Icons.visibility), label: const Text('Preview')),
              ElevatedButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
              ElevatedButton.icon(onPressed: _exportDoc, icon: const Icon(Icons.description), label: const Text('Export DOC')),
            ],
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
