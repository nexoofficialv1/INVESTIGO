import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/case_parser_service.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class CaseParserScreen extends StatefulWidget {
  final OfficerProfile profile;
  const CaseParserScreen({super.key, required this.profile});

  @override
  State<CaseParserScreen> createState() => _CaseParserScreenState();
}

class _CaseParserScreenState extends State<CaseParserScreen> {
  final _store = LocalStoreService();
  final _parser = CaseParserService();
  final rawText = TextEditingController();

  final psCaseNo = TextEditingController();
  final caseDate = TextEditingController();
  final sections = TextEditingController();
  final po = TextEditingController();
  final dO = TextEditingController();
  final dR = TextEditingController();
  final complainant = TextEditingController();
  final victim = TextEditingController();
  final accused = TextEditingController();
  final io = TextEditingController();
  final ioMobile = TextEditingController();
  final gist = TextEditingController();
  final arrest = TextEditingController();

  List<CaseFile> _cases = [];
  CaseFile? _selectedCase;
  bool _parsed = false;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final cases = await _store.loadCases();
    if (!mounted) return;
    setState(() => _cases = cases);
  }

  @override
  void dispose() {
    for (final c in [rawText, psCaseNo, caseDate, sections, po, dO, dR, complainant, victim, accused, io, ioMobile, gist, arrest]) {
      c.dispose();
    }
    super.dispose();
  }

  void _parse() {
    final result = _parser.parse(rawText.text);
    setState(() {
      psCaseNo.text = result.psCaseNo;
      caseDate.text = result.caseDate;
      sections.text = result.sections;
      po.text = result.placeOfOccurrence;
      dO.text = result.dateTimeOccurrence;
      dR.text = result.dateTimeReporting;
      complainant.text = result.complainant;
      victim.text = result.victim;
      accused.text = result.accused;
      io.text = result.ioName;
      ioMobile.text = result.ioMobile;
      gist.text = result.gist;
      arrest.text = result.arrest;
      _parsed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data extracted. Review/edit before saving.')));
  }

  ParsedCaseData _currentParsed() => ParsedCaseData(
        psCaseNo: psCaseNo.text.trim(),
        caseDate: caseDate.text.trim(),
        sections: sections.text.trim(),
        placeOfOccurrence: po.text.trim(),
        dateTimeOccurrence: dO.text.trim(),
        dateTimeReporting: dR.text.trim(),
        complainant: complainant.text.trim(),
        victim: victim.text.trim(),
        accused: accused.text.trim(),
        ioName: io.text.trim(),
        ioMobile: ioMobile.text.trim(),
        gist: gist.text.trim(),
        arrest: arrest.text.trim(),
        rawText: rawText.text,
      );

  String? _coreValidationError(CaseFile file) {
    if (file.psCaseNo.trim().isEmpty) return 'PS Case No. missing';
    if (file.caseDate.trim().isEmpty) return 'Case Date missing';
    if (file.sections.trim().isEmpty) return 'Sections of Law missing';
    if (file.placeOfOccurrence.trim().isEmpty) {
      return 'Place of Occurrence missing';
    }
    if (file.dateTimeReporting.trim().isEmpty) {
      return 'Date & Time of Reporting missing';
    }
    if (file.firGist.trim().isEmpty) return 'Brief Gist of FIR missing';
    return null;
  }

  String _normalCaseNo(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  Future<void> _saveNewCase() async {
    if (!_parsed) _parse();
    final file = _currentParsed().toCaseFile(widget.profile);
    final error = _coreValidationError(file);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final all = await _store.loadCases();
    final normalized = _normalCaseNo(file.psCaseNo);
    final duplicate = all.any(
      (item) => _normalCaseNo(item.psCaseNo) == normalized,
    );
    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'এই PS Case No. আগে থেকেই আছে। Existing case select করে Update করুন।',
          ),
        ),
      );
      return;
    }

    await _store.saveCase(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parsed data saved as new case')),
    );
    Navigator.pop(context);
  }

  Future<void> _updateSelectedCase() async {
    final selected = _selectedCase;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update করার জন্য আগে existing case select করুন।'),
        ),
      );
      return;
    }
    if (!_parsed) _parse();
    final file = _currentParsed().toCaseFile(
      widget.profile,
      existing: selected,
    );
    final error = _coreValidationError(file);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final all = await _store.loadCases();
    final normalized = _normalCaseNo(file.psCaseNo);
    final duplicate = all.any(
      (item) =>
          item.id != selected.id &&
          _normalCaseNo(item.psCaseNo) == normalized,
    );
    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই PS Case No. অন্য case-এ আছে।')),
      );
      return;
    }

    await _store.saveCase(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected case updated from parsed data')),
    );
    Navigator.pop(context);
  }

  void _showCameraNote() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan Document / Camera OCR'),
        content: const Text('এই version-এ offline Text Parser ready। Camera OCR এখনো চালু নয়। পরের offline on-device OCR patch-এ scan extraction add হবে। এখন document text copy/paste করে Parse করুন।'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showUseOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Parsed data দিয়ে কী করবেন?', style: TextStyle(fontWeight: FontWeight.w900))),
            ListTile(leading: const Icon(Icons.add_box), title: const Text('Create New Case'), onTap: () { Navigator.pop(context); _saveNewCase(); }),
            ListTile(leading: const Icon(Icons.folder_open), title: const Text('Update Selected Case'), onTap: () { Navigator.pop(context); _updateSelectedCase(); }),
            const ListTile(leading: Icon(Icons.menu_book), title: Text('Create CD Entry'), subtitle: Text('Next patch: parsed text থেকে CD entry বানাবে')),
            const ListTile(leading: Icon(Icons.description), title: Text('Create Form / Notice'), subtitle: Text('Next patch: selected case/form auto-fill')),
            const ListTile(leading: Icon(Icons.inventory_2), title: Text('Save as Evidence / Document'), subtitle: Text('Next patch: case document manager')),
          ],
        ),
      ),
    );
  }

  void _fillDemo() {
    final ps = widget.profile.policeStation.trim().isEmpty ? 'Sample Police Station' : widget.profile.policeStation;
    final district = widget.profile.district.trim().isEmpty ? 'Sample District' : widget.profile.district;
    rawText.text = '''Ref: $ps Case No- 001/26 Dated 01.01.26 U/S- 115(2)/3(5) BNS.

P.O: Sample locality, P.S. $ps, Dist. $district.

D.O: On 01.01.2026 at about 13:30 Hrs.

D.R: 01.01.2026 at 14.25 hrs.

Complt: Sample Complainant of Sample locality, P.S. $ps, Dist. $district.

FIR Named Accd-01 & others: Sample Accused of Sample locality.

I.O: ${widget.profile.rank} ${widget.profile.name}

Gist: On the basis of a written complaint, the above noted case was started and investigation is proceeding.

Arrest: NIL.''';
    _parse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Parser')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _showUseOptions, icon: const Icon(Icons.rule), label: const Text('Use Data'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _parse, icon: const Icon(Icons.auto_fix_high), label: const Text('Parse'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            title: 'Paste / Scan Case Text',
            subtitle: 'Ref, P.O, D.O, D.R, Complt, Accused, I.O, Gist, Arrest format চিনে নেবে।',
            icon: Icons.document_scanner,
            child: Column(
              children: [
                FormHelpers.textField(controller: rawText, label: 'Paste complaint/FIR/order/report text here', maxLines: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _fillDemo, icon: const Icon(Icons.text_snippet), label: const Text('Demo'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: _showCameraNote, icon: const Icon(Icons.camera_alt), label: const Text('Scan Document'))),
                  ],
                ),
              ],
            ),
          ),
          AppSectionCard(
            title: 'Review Extracted Data',
            subtitle: 'Direct save হবে না। আগে IO verify/edit করবে, তারপর save/update।',
            icon: Icons.fact_check,
            child: Column(
              children: [
                if (_cases.isNotEmpty)
                  DropdownButtonFormField<CaseFile>(
                    value: _selectedCase,
                    items: _cases.map((c) => DropdownMenuItem(value: c, child: Text(c.displayTitle, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedCase = v),
                    decoration: const InputDecoration(labelText: 'Update existing case (optional)', border: OutlineInputBorder()),
                  ),
                if (_cases.isNotEmpty) const SizedBox(height: 12),
                FormHelpers.textField(controller: psCaseNo, label: 'PS Case No.'),
                FormHelpers.textField(controller: caseDate, label: 'Case Date'),
                FormHelpers.textField(controller: sections, label: 'Sections'),
                FormHelpers.textField(controller: po, label: 'P.O / Place of Occurrence', maxLines: 2),
                FormHelpers.textField(controller: dO, label: 'D.O / Date & Time of Occurrence'),
                FormHelpers.textField(controller: dR, label: 'D.R / Date & Time of Reporting'),
                FormHelpers.textField(controller: complainant, label: 'Complainant / Informant', maxLines: 3),
                FormHelpers.textField(controller: victim, label: 'Victim', maxLines: 2),
                FormHelpers.textField(controller: accused, label: 'FIR Named Accused', maxLines: 4),
                Row(
                  children: [
                    Expanded(child: FormHelpers.textField(controller: io, label: 'I.O Name')),
                    const SizedBox(width: 10),
                    Expanded(child: FormHelpers.textField(controller: ioMobile, label: 'I.O Mobile')),
                  ],
                ),
                FormHelpers.textField(controller: gist, label: 'Gist / Brief Facts', maxLines: 6),
                FormHelpers.textField(controller: arrest, label: 'Arrest Status'),
                const SizedBox(height: 8),
                const Text('After save, this data will auto-fill Case Entry, CD-I, Forms, Statement, Final CD and IF5.', style: TextStyle(color: AppTheme.deepGreen, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
