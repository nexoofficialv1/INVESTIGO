import 'package:flutter/material.dart';

import '../data/domain/case_investigation_store.dart';
import '../models/case_file.dart';
import '../models/final_case_documents.dart';
import '../models/officer_profile.dart';
import '../services/doc_export_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_screen.dart';

enum FinalCaseDocumentKind { finalCd, chargeSheet, if5 }

class FinalCaseDocumentEditorScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;
  final FinalCaseDocumentKind kind;
  final FinalCdDraft? finalCd;
  final ChargeSheetDraft? chargeSheet;
  final If5Draft? if5;

  const FinalCaseDocumentEditorScreen({
    super.key,
    required this.profile,
    required this.caseFile,
    required this.kind,
    this.finalCd,
    this.chargeSheet,
    this.if5,
  });

  @override
  State<FinalCaseDocumentEditorScreen> createState() => _FinalCaseDocumentEditorScreenState();
}

class _FinalCaseDocumentEditorScreenState extends State<FinalCaseDocumentEditorScreen> {
  final _store = CaseInvestigationStore();
  final _pdf = PdfService();
  final _doc = DocExportService();
  final Map<String, TextEditingController> _c = {};
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  TextEditingController _controller(String key, String value) =>
      _c.putIfAbsent(key, () => TextEditingController(text: value));

  void _seed() {
    if (widget.kind == FinalCaseDocumentKind.finalCd) {
      final d = widget.finalCd ?? FinalCdDraft.empty(widget.caseFile.id);
      _controller('narrative', d.narrative);
      _controller('witnessList', d.witnessList);
      _controller('accusedStatus', d.accusedStatus);
      _controller('entryTime', d.entryTime);
      _controller('entryPlace', d.entryPlace);
      _controller('synopsis', d.synopsis);
      _approved = d.approved;
    } else if (widget.kind == FinalCaseDocumentKind.chargeSheet) {
      final d = widget.chargeSheet ?? ChargeSheetDraft.empty(widget.caseFile.id);
      _controller('courtName', d.courtName);
      _controller('chargeSheetNo', d.chargeSheetNo);
      _controller('chargeSheetDate', d.chargeSheetDate);
      _controller('sections', d.sections);
      _controller('accusedParticulars', d.accusedParticulars);
      _controller('witnessList', d.witnessList);
      _controller('briefFacts', d.briefFacts);
      _controller('reliedDocuments', d.reliedDocuments);
      _approved = d.approved;
    } else {
      final d = widget.if5 ?? If5Draft.empty(widget.caseFile.id);
      _controller('courtName', d.courtName);
      _controller('finalReportType', d.finalReportType);
      _controller('complainant', d.complainant);
      _controller('accusedParticulars', d.accusedParticulars);
      _controller('witnessList', d.witnessList);
      _controller('propertyDocuments', d.propertyDocuments);
      _controller('briefFacts', d.briefFacts);
      _controller('resultCommunication', d.resultCommunication);
      _controller('chargeSheetNo', d.chargeSheetNo);
      _controller('chargeSheetDate', d.chargeSheetDate);
      _controller('originalOrSupplementary', d.originalOrSupplementary);
      _controller('investigatingOfficer', d.investigatingOfficer);
      _controller('unchargedAccused', d.unchargedAccused);
      _controller('laboratoryResult', d.laboratoryResult);
      _controller('falseCaseAction', d.falseCaseAction);
      _controller('dispatchDetails', d.dispatchDetails);
      _approved = d.approved;
    }
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.kind) {
        FinalCaseDocumentKind.finalCd => 'Final CD',
        FinalCaseDocumentKind.chargeSheet => 'Charge Sheet',
        FinalCaseDocumentKind.if5 => 'IF-5 / Final Form',
      };

  FinalCdDraft _finalCdDraft() => FinalCdDraft(
        caseId: widget.caseFile.id,
        narrative: _c['narrative']!.text.trim(),
        witnessList: _c['witnessList']!.text.trim(),
        accusedStatus: _c['accusedStatus']!.text.trim(),
        entryTime: _c['entryTime']!.text.trim(),
        entryPlace: _c['entryPlace']!.text.trim(),
        synopsis: _c['synopsis']!.text.trim(),
        approved: _approved,
        updatedAt: DateTime.now(),
      );

  ChargeSheetDraft _chargeSheetDraft() => ChargeSheetDraft(
        caseId: widget.caseFile.id,
        chargeSheetNo: _c['chargeSheetNo']!.text.trim(),
        chargeSheetDate: _c['chargeSheetDate']!.text.trim(),
        courtName: _c['courtName']!.text.trim(),
        sections: _c['sections']!.text.trim(),
        accusedParticulars: _c['accusedParticulars']!.text.trim(),
        witnessList: _c['witnessList']!.text.trim(),
        briefFacts: _c['briefFacts']!.text.trim(),
        reliedDocuments: _c['reliedDocuments']!.text.trim(),
        approved: _approved,
        updatedAt: DateTime.now(),
      );

  If5Draft _if5Draft() => If5Draft(
        caseId: widget.caseFile.id,
        courtName: _c['courtName']!.text.trim(),
        finalReportType: _c['finalReportType']!.text.trim(),
        complainant: _c['complainant']!.text.trim(),
        accusedParticulars: _c['accusedParticulars']!.text.trim(),
        witnessList: _c['witnessList']!.text.trim(),
        propertyDocuments: _c['propertyDocuments']!.text.trim(),
        briefFacts: _c['briefFacts']!.text.trim(),
        resultCommunication: _c['resultCommunication']!.text.trim(),
        chargeSheetNo: _c['chargeSheetNo']!.text.trim(),
        chargeSheetDate: _c['chargeSheetDate']!.text.trim(),
        originalOrSupplementary: _c['originalOrSupplementary']!.text.trim(),
        investigatingOfficer: _c['investigatingOfficer']!.text.trim(),
        unchargedAccused: _c['unchargedAccused']!.text.trim(),
        laboratoryResult: _c['laboratoryResult']!.text.trim(),
        falseCaseAction: _c['falseCaseAction']!.text.trim(),
        dispatchDetails: _c['dispatchDetails']!.text.trim(),
        approved: _approved,
        updatedAt: DateTime.now(),
      );

  List<String> _validate() {
    if (widget.kind == FinalCaseDocumentKind.finalCd) {
      final d = _finalCdDraft();
      return [
        if (d.narrative.isEmpty) 'Final investigation narrative is required.',
        if (d.accusedStatus.isEmpty) 'Accused status is required.',
      ];
    }
    if (widget.kind == FinalCaseDocumentKind.chargeSheet) {
      final d = _chargeSheetDraft();
      return [
        if (d.courtName.isEmpty) 'Court name is required.',
        if (d.sections.isEmpty) 'Sections are required.',
        if (d.accusedParticulars.isEmpty) 'Accused particulars are required.',
        if (d.briefFacts.isEmpty) 'Brief facts are required.',
      ];
    }
    final d = _if5Draft();
    return [
      if (d.courtName.isEmpty) 'Court name is required.',
      if (d.complainant.isEmpty) 'Complainant is required.',
      if (d.accusedParticulars.isEmpty) 'Accused particulars are required.',
      if (d.briefFacts.isEmpty) 'Brief facts are required.',
    ];
  }

  Future<void> _save({bool showMessage = true}) async {
    if (widget.kind == FinalCaseDocumentKind.finalCd) {
      await _store.saveFinalCdDraft(_finalCdDraft());
    } else if (widget.kind == FinalCaseDocumentKind.chargeSheet) {
      await _store.saveChargeSheetDraft(_chargeSheetDraft());
    } else {
      await _store.saveIf5Draft(_if5Draft());
    }
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved')));
    }
  }

  Future<void> _toggleApproval(bool value) async {
    if (value) {
      final issues = _validate();
      if (issues.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cannot approve'),
            content: Text(issues.map((e) => '• $e').join('\n')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        return;
      }
    }
    setState(() => _approved = value);
    await _save(showMessage: false);
  }

  Future<void> _preview() async {
    await _save(showMessage: false);
    if (!mounted) return;
    if (widget.kind == FinalCaseDocumentKind.finalCd) {
      final d = _finalCdDraft();
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
        title: 'Final CD Preview',
        filename: 'Final_CD_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
        docFilename: 'Final_CD_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.doc',
        buildPdf: () => _pdf.buildFinalCdPdf(officer: widget.profile, caseFile: widget.caseFile, draft: d),
        buildDoc: () => _doc.buildFinalCdDoc(officer: widget.profile, caseFile: widget.caseFile, draft: d),
      )));
    } else if (widget.kind == FinalCaseDocumentKind.chargeSheet) {
      final d = _chargeSheetDraft();
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
        title: 'Charge Sheet Preview',
        filename: 'Charge_Sheet_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
        docFilename: 'Charge_Sheet_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.doc',
        buildPdf: () => _pdf.buildChargeSheetPdf(officer: widget.profile, caseFile: widget.caseFile, draft: d),
        buildDoc: () => _doc.buildChargeSheetDoc(officer: widget.profile, caseFile: widget.caseFile, draft: d),
      )));
    } else {
      final d = _if5Draft();
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
        title: 'IF-5 Preview',
        filename: 'IF5_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.pdf',
        docFilename: 'IF5_${widget.caseFile.psCaseNo.replaceAll('/', '_')}.doc',
        buildPdf: () => _pdf.buildIf5Pdf(officer: widget.profile, caseFile: widget.caseFile, draft: d),
        buildDoc: () => _doc.buildIf5Doc(officer: widget.profile, caseFile: widget.caseFile, draft: d),
      )));
    }
  }

  Widget _field(String key, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _c[key],
          minLines: lines,
          maxLines: lines == 1 ? 1 : null,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Save Draft'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: _preview, icon: const Icon(Icons.preview), label: const Text('Preview'))),
          ]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _approved,
            onChanged: _toggleApproval,
            title: const Text('IO Approval'),
            subtitle: const Text('Required fields complete না হলে approval হবে না।'),
          ),
          const SizedBox(height: 8),
          if (widget.kind == FinalCaseDocumentKind.finalCd) ...[
            _field('entryTime', 'No. and hour of entry'),
            _field('entryPlace', 'Place of entry'),
            _field('synopsis', 'Synopsis of entry'),
            _field('narrative', 'Final investigation narrative', lines: 12),
            _field('accusedStatus', 'Status of accused', lines: 4),
            _field('witnessList', 'Witness list', lines: 6),
          ] else if (widget.kind == FinalCaseDocumentKind.chargeSheet) ...[
            _field('courtName', 'Court name'),
            _field('chargeSheetNo', 'Charge Sheet No.'),
            _field('chargeSheetDate', 'Charge Sheet Date'),
            _field('sections', 'Acts and Sections'),
            _field('accusedParticulars', 'Accused particulars and status', lines: 6),
            _field('witnessList', 'Witness list', lines: 6),
            _field('reliedDocuments', 'Relied documents / property', lines: 5),
            _field('briefFacts', 'Brief facts of the case', lines: 12),
          ] else ...[
            _field('courtName', 'Court name'),
            _field('chargeSheetNo', 'Charge Sheet No.'),
            _field('chargeSheetDate', 'Charge Sheet Date'),
            _field('originalOrSupplementary', 'Original / Supplementary'),
            _field('investigatingOfficer', 'Name, rank and number of I.O.'),
            _field('finalReportType', 'Type of Final Report'),
            _field('complainant', 'Complainant / Informant'),
            _field('accusedParticulars', 'Particulars of accused persons', lines: 6),
            _field('propertyDocuments', 'Properties / articles / documents', lines: 5),
            _field('unchargedAccused', 'Accused persons not charge-sheeted', lines: 4),
            _field('witnessList', 'Particulars of witnesses', lines: 6),
            _field('resultCommunication', 'Communication of result'),
            _field('laboratoryResult', 'Result of laboratory analysis', lines: 3),
            _field('falseCaseAction', 'Action in false case, if applicable', lines: 3),
            _field('dispatchDetails', 'Dispatch details'),
            _field('briefFacts', 'Brief facts of the case', lines: 12),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
