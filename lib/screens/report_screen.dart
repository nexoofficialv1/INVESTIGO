import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../screens/pdf_preview_screen.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../services/doc_export_service.dart';

class ReportScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? caseFile;

  const ReportScreen({super.key, required this.profile, this.caseFile});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _store = LocalStoreService();
  final _pdf = PdfService();
  late _ReportTemplate _selected;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  late TextEditingController _recipientController;
  late TextEditingController _memoController;
  late TextEditingController _referenceController;
  late bool _caseLinked;

  bool get _hasCase => widget.caseFile != null;

  @override
  void initState() {
    super.initState();
    _caseLinked = _hasCase;
    _selected = _hasCase ? _caseTemplates.first : _generalTemplates.first;
    _recipientController = TextEditingController(text: _selected.recipient);
    _subjectController = TextEditingController(text: _selected.subject(widget.caseFile));
    _bodyController = TextEditingController(text: _selected.body(widget.profile, widget.caseFile));
    _memoController = TextEditingController(text: '');
    _referenceController = TextEditingController(text: _hasCase ? widget.caseFile!.displayTitle : '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _recipientController.dispose();
    _memoController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  List<_ReportTemplate> get _availableTemplates => _caseLinked && _hasCase ? _caseTemplates : _generalTemplates;

  void _applyTemplate(_ReportTemplate template) {
    setState(() {
      _selected = template;
      _recipientController.text = template.recipient;
      _subjectController.text = template.subject(_caseLinked ? widget.caseFile : null);
      _bodyController.text = template.body(widget.profile, _caseLinked ? widget.caseFile : null);
    });
  }

  void _toggleCaseLink(bool value) {
    setState(() {
      _caseLinked = value && _hasCase;
      _selected = _availableTemplates.first;
      _recipientController.text = _selected.recipient;
      _subjectController.text = _selected.subject(_caseLinked ? widget.caseFile : null);
      _bodyController.text = _selected.body(widget.profile, _caseLinked ? widget.caseFile : null);
      _referenceController.text = _caseLinked && _hasCase ? widget.caseFile!.displayTitle : '';
    });
  }

  String _fullReportBody() {
    final memo = _memoController.text.trim().isEmpty ? '' : 'Memo No.: ${_memoController.text.trim()}\n\n';
    final reference = _referenceController.text.trim().isEmpty ? '' : 'Reference: ${_referenceController.text.trim()}\n\n';
    return '''To
${_recipientController.text.trim()}

Subject: ${_subjectController.text.trim()}

$memo$reference${_bodyController.text.trim()}

Submitted for favour of kind information and necessary action.''';
  }

  FormNotice _buildReport({bool finalSave = false}) {
    final title = 'Report to ${_recipientController.text.trim()}';
    return FormNotice.create(
      caseId: _caseLinked && _hasCase ? widget.caseFile!.id : 'general_report',
      templateId: _caseLinked ? 'case_report_${_selected.id}' : 'general_report_${_selected.id}',
      title: title,
      body: _fullReportBody(),
    ).copyWith(isFinal: finalSave);
  }

  Future<void> _saveDraft() async {
    await _store.saveForm(_buildReport());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report draft saved.')));
  }

  Future<void> _preview() async {
    final report = _buildReport();
    final fileSlug = _subjectController.text.trim().isEmpty
        ? 'General_Report'
        : _subjectController.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Report Preview',
          filename: '${fileSlug}_Report.pdf',
          docFilename: '${fileSlug}_Report.doc',
          buildPdf: () async {
            if (_caseLinked && _hasCase) {
              return _pdf.buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile!, form: report);
            }
            return _pdf.buildGeneralReportPdf(officer: widget.profile, form: report);
          },
          buildDoc: () async {
            if (_caseLinked && _hasCase) {
              return DocExportService().buildFormNoticeDoc(officer: widget.profile, caseFile: widget.caseFile!, form: report);
            }
            return DocExportService().buildGeneralReportDoc(officer: widget.profile, form: report);
          },
          onFinalSave: () async => _store.saveForm(report.copyWith(isFinal: true)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = _availableTemplates;
    if (!templates.contains(_selected)) _selected = templates.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Draft'),
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                  onPressed: _preview,
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
                  Text('Office Report Generator', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('কেস ছাড়াও যে কোনো office report এখান থেকে তৈরি করা যাবে। SP / SDPO / SDO / Court / Bank / BDO / Hospital / General report — সব edit করে Preview দেখে export করবেন।', style: TextStyle(fontWeight: FontWeight.w700)),
                  if (_hasCase) ...[
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _caseLinked,
                      onChanged: _toggleCaseLink,
                      title: const Text('Link this report with current case'),
                      subtitle: Text(widget.caseFile!.displayTitle),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Text('Mode: General / Non-case report', style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_ReportTemplate>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Report Type'),
            items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (value) {
              if (value != null) _applyTemplate(value);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(labelText: 'To / Recipient Office'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memoController,
            decoration: const InputDecoration(labelText: 'Memo No. / Reference, if any'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(labelText: 'Case / Petition / GDE / Memo Reference, if any'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Report Body'),
            minLines: 14,
            maxLines: 28,
            textAlignVertical: TextAlignVertical.top,
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _ReportTemplate {
  final String id;
  final String name;
  final String recipient;
  final String Function(CaseFile? file) subject;
  final String Function(OfficerProfile officer, CaseFile? file) body;

  const _ReportTemplate({required this.id, required this.name, required this.recipient, required this.subject, required this.body});
}

final List<_ReportTemplate> _caseTemplates = [
  _ReportTemplate(
    id: 'sp_progress',
    name: 'Case Report to Superintendent of Police',
    recipient: 'The Superintendent of Police, Purba Bardhaman',
    subject: (file) => 'Progress report in connection with ${file?.displayTitle ?? 'the matter'}',
    body: (officer, file) => '''Most respectfully I beg to submit that the above noted case was started on ${file?.caseDate ?? ''} u/s ${file?.sections ?? ''} on the basis of a written complaint/FIR.

During investigation, I took up investigation, perused the case record, visited/verified the relevant place and examined available witnesses as applicable. The present status of investigation is submitted below:

1. Brief fact: ${file?.firGist ?? ''}
2. PO: ${file?.placeOfOccurrence ?? ''}
3. Complainant: ${file?.complainantName ?? ''}
4. Victim: ${file?.victimName ?? ''}
5. Accused/Suspect: ${file?.accusedName ?? ''}
6. Present progress: 
7. Further action proposed: 

This is submitted for favour of kind information.''',
  ),
  _ReportTemplate(
    id: 'sdpo_progress',
    name: 'Case Report to SDPO',
    recipient: 'The Sub-Divisional Police Officer, Kalna',
    subject: (file) => 'Report regarding ${file?.displayTitle ?? 'the matter'}',
    body: (officer, file) => '''Most respectfully I submit that in connection with the above noted case, the undersigned has conducted investigation and the following facts have come to light.

Case reference: ${officer.policeStation} Case No. ${file?.psCaseNo ?? ''} dated ${file?.caseDate ?? ''} u/s ${file?.sections ?? ''}.

Brief fact: ${file?.firGist ?? ''}

Steps taken during investigation:
1. Case record perused.
2. Relevant witnesses examined.
3. Necessary requisition/document collection steps taken as applicable.
4. Present status: 

Further action: 

Submitted for kind perusal and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'sdo_report',
    name: 'Case / Enquiry Report to SDO',
    recipient: 'The Sub-Divisional Officer, Kalna',
    subject: (file) => 'Enquiry report regarding ${file?.displayTitle ?? 'the matter'}',
    body: (officer, file) => '''Most respectfully I beg to submit that as per direction/endorsement, an enquiry/investigation was conducted in connection with the above noted matter.

During enquiry/investigation, local enquiry was held and available persons were contacted. The relevant facts are as follows:

1. Case/Matter reference: ${file?.displayTitle ?? ''}
2. Sections/Subject: ${file?.sections ?? ''}
3. Place: ${file?.placeOfOccurrence ?? ''}
4. Brief fact: ${file?.firGist ?? ''}
5. Enquiry finding: 
6. Present situation: 
7. Police action taken/proposed: 

Submitted for favour of kind information and necessary order.''',
  ),
];

final List<_ReportTemplate> _generalTemplates = [
  _ReportTemplate(
    id: 'general_sp',
    name: 'General Report to Superintendent of Police',
    recipient: 'The Superintendent of Police, Purba Bardhaman',
    subject: (_) => 'Submission of report',
    body: (officer, _) => '''Most respectfully I beg to submit the following report for favour of kind information.

1. Reference / source of information: 
2. Date and time: 
3. Place / office / area concerned: 
4. Brief facts: 
5. Enquiry conducted / action taken: 
6. Present status: 
7. Further action proposed / prayer: 

This is submitted for favour of kind information and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'general_sdpo',
    name: 'General Report to SDPO',
    recipient: 'The Sub-Divisional Police Officer, Kalna',
    subject: (_) => 'Report for kind perusal',
    body: (officer, _) => '''Most respectfully I submit that the following facts are placed before your kind honour for perusal and necessary direction.

1. Reference: 
2. Subject matter: 
3. Facts learned during enquiry/local verification: 
4. Action taken so far: 
5. Present situation: 
6. Further action proposed: 

Submitted for kind perusal and necessary direction.''',
  ),
  _ReportTemplate(
    id: 'general_sdo',
    name: 'General Report to SDO / Executive Magistrate',
    recipient: 'The Sub-Divisional Officer, Kalna',
    subject: (_) => 'Enquiry report',
    body: (officer, _) => '''Most respectfully I beg to submit that as per endorsement/direction, enquiry was conducted locally regarding the subject matter.

During enquiry, the following facts came to notice:

1. Name and address of petitioner/informant, if any: 
2. Place of enquiry: 
3. Persons contacted: 
4. Fact revealed during enquiry: 
5. Police action taken/proposed: 
6. Opinion / finding: 

Submitted for favour of kind information and necessary order.''',
  ),
  _ReportTemplate(
    id: 'court_report',
    name: 'General Report to Ld. Court',
    recipient: 'The Learned Court Concerned',
    subject: (_) => 'Submission of report',
    body: (officer, _) => '''Most respectfully I beg to submit the following report before your kind honour.

1. Reference: 
2. Background of the matter: 
3. Steps taken by police: 
4. Present status: 
5. Prayer / submission: 

Submitted for favour of kind perusal and necessary order.''',
  ),
  _ReportTemplate(
    id: 'bank_report',
    name: 'Report / Letter to Bank',
    recipient: 'The Branch Manager, Concerned Bank',
    subject: (_) => 'Request for necessary information / compliance',
    body: (officer, _) => '''Sir/Madam,

With reference to the subject noted above, you are requested to kindly take necessary action / furnish the following information for the purpose of enquiry/investigation.

1. Account / transaction details: 
2. Required information / action: 
3. Reference number / acknowledgement, if any: 
4. Time period: 

You are requested to treat the matter as urgent and furnish the available information at the earliest.

This is for your kind information and necessary compliance.''',
  ),
  _ReportTemplate(
    id: 'hospital_report',
    name: 'Report / Requisition to Hospital',
    recipient: 'The Medical Officer / Superintendent, Concerned Hospital',
    subject: (_) => 'Request for medical papers / report',
    body: (officer, _) => '''Sir/Madam,

With reference to the subject noted above, you are requested to kindly provide the necessary medical papers/report as mentioned below.

1. Name of patient/person concerned: 
2. Date of treatment/admission: 
3. Required document/report: 
4. Purpose: 

This is for your kind information and necessary action.''',
  ),
  _ReportTemplate(
    id: 'blank_report',
    name: 'Blank Custom Report',
    recipient: 'The Officer Concerned',
    subject: (_) => 'Report',
    body: (officer, _) => '''Most respectfully I beg to submit that:



Submitted for favour of kind information and necessary action.''',
  ),
];
