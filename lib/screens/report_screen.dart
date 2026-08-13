import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../services/doc_export_service.dart';
import '../services/local_store_service.dart';
import '../services/pdf_service.dart';
import '../widgets/investigo_ui.dart';
import 'pdf_preview_screen.dart';

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
  late final TextEditingController _recipient;
  late final TextEditingController _subject;
  late final TextEditingController _memo;
  late final TextEditingController _reference;
  late final TextEditingController _body;

  List<FormNotice> _saved = [];
  late String _draftId;
  late DateTime _draftCreatedAt;

  bool get _caseLinked => widget.caseFile != null;
  String get _storageCaseId => _caseLinked ? widget.caseFile!.id : 'general_report';

  @override
  void initState() {
    super.initState();
    _selected = _templates.first;
    _recipient = TextEditingController(text: _resolvedRecipient(_selected));
    _subject = TextEditingController(text: _selected.subject(widget.caseFile));
    _memo = TextEditingController();
    _reference = TextEditingController(text: _caseLinked ? widget.caseFile!.displayTitle : '');
    _body = TextEditingController(text: _selected.body(widget.profile, widget.caseFile));
    _startNewIdentity();
    _loadSaved();
  }

  void _startNewIdentity() {
    final now = DateTime.now();
    _draftId = 'report_${now.microsecondsSinceEpoch}';
    _draftCreatedAt = now;
  }

  @override
  void dispose() {
    _recipient.dispose();
    _subject.dispose();
    _memo.dispose();
    _reference.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final forms = await _store.loadForms(_storageCaseId);
    final saved = forms.where((f) => f.workflowData['reportV208'] == true).toList();
    if (!mounted) return;
    setState(() => _saved = saved);
  }

  String _resolvedRecipient(_ReportTemplate template) {
    final supervisoryOffice = widget.profile.defaultSdpoOffice.trim().isEmpty
        ? widget.profile.district
        : widget.profile.defaultSdpoOffice.trim();
    return template.recipient
        .replaceAll('{district}', widget.profile.district)
        .replaceAll('{sdpoOffice}', supervisoryOffice)
        .replaceAll('{policeStation}', widget.profile.policeStation)
        .replaceAll('{court}', widget.profile.courtName.trim().isEmpty ? 'Learned Court Concerned' : widget.profile.courtName);
  }

  void _applyTemplate(_ReportTemplate template) {
    setState(() {
      _selected = template;
      _recipient.text = _resolvedRecipient(template);
      _subject.text = template.subject(widget.caseFile);
      _body.text = template.body(widget.profile, widget.caseFile);
      _startNewIdentity();
    });
  }

  void _newReport() {
    setState(() {
      _startNewIdentity();
      _memo.clear();
      _reference.text = _caseLinked ? widget.caseFile!.displayTitle : '';
      _recipient.text = _resolvedRecipient(_selected);
      _subject.text = _selected.subject(widget.caseFile);
      _body.text = _selected.body(widget.profile, widget.caseFile);
    });
  }

  void _openSaved(FormNotice form) {
    final data = form.workflowData;
    final templateId = (data['templateId'] ?? '').toString();
    final match = _templates.where((e) => e.id == templateId).toList();
    setState(() {
      if (match.isNotEmpty) _selected = match.first;
      _draftId = form.id;
      _draftCreatedAt = form.createdAt;
      _recipient.text = (data['recipient'] ?? '').toString();
      _subject.text = (data['subject'] ?? '').toString();
      _memo.text = (data['memo'] ?? '').toString();
      _reference.text = (data['reference'] ?? '').toString();
      _body.text = (data['body'] ?? '').toString();
    });
  }

  String _fullBody() {
    final memoText = _memo.text.trim().isEmpty ? '' : 'Memo No.: ${_memo.text.trim()}\n\n';
    final refText = _reference.text.trim().isEmpty ? '' : 'Reference: ${_reference.text.trim()}\n\n';
    return '''To
${_recipient.text.trim()}

Subject: ${_subject.text.trim()}

$memoText$refText${_body.text.trim()}

Submitted for favour of kind information and necessary action.''';
  }

  FormNotice _build({bool finalSave = false}) {
    return FormNotice(
      id: _draftId,
      caseId: _storageCaseId,
      templateId: _caseLinked ? 'case_report_${_selected.id}' : 'general_report_${_selected.id}',
      title: 'Report — ${_subject.text.trim()}',
      body: _fullBody(),
      workflowData: {
        'reportV208': true,
        'templateId': _selected.id,
        'recipient': _recipient.text.trim(),
        'subject': _subject.text.trim(),
        'memo': _memo.text.trim(),
        'reference': _reference.text.trim(),
        'body': _body.text.trim(),
        'caseLinked': _caseLinked,
      },
      isFinal: finalSave,
      createdAt: _draftCreatedAt,
      updatedAt: DateTime.now(),
    );
  }

  List<String> _errors() {
    final out = <String>[];
    if (_recipient.text.trim().isEmpty) out.add('Recipient/To দিন।');
    if (_subject.text.trim().isEmpty) out.add('Subject দিন।');
    if (_body.text.trim().isEmpty) out.add('Report body লিখুন।');
    return out;
  }

  Future<FormNotice?> _save({bool finalSave = false}) async {
    final errors = _errors();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.first)));
      return null;
    }
    final report = _build(finalSave: finalSave);
    await _store.saveForm(report);
    await _loadSaved();
    if (!mounted) return report;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(finalSave ? 'Report final saved' : 'Report draft saved')));
    return report;
  }

  Future<void> _preview() async {
    final report = _build();
    final slug = _subject.text.trim().isEmpty
        ? 'Report'
        : _subject.text.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Report Preview',
          filename: '${slug}_Report.pdf',
          docFilename: '${slug}_Report.doc',
          buildPdf: () async => _caseLinked
              ? _pdf.buildFormNoticePdf(officer: widget.profile, caseFile: widget.caseFile!, form: report)
              : _pdf.buildGeneralReportPdf(officer: widget.profile, form: report),
          buildDoc: () async => _caseLinked
              ? DocExportService().buildFormNoticeDoc(officer: widget.profile, caseFile: widget.caseFile!, form: report)
              : DocExportService().buildGeneralReportDoc(officer: widget.profile, form: report),
          onFinalSave: () async {
            final saved = _build(finalSave: true);
            await _store.saveForm(saved);
            await _loadSaved();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: Text(_caseLinked ? 'Case Report' : 'Office Reports'),
        actions: [IconButton(onPressed: _newReport, tooltip: 'New report', icon: const Icon(Icons.add_rounded))],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save_outlined), label: const Text('Draft'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: _preview, icon: const Icon(Icons.preview_outlined), label: const Text('Preview'))),
          ]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          InvestigoPageTitle(
            title: _caseLinked ? 'Case-linked Report' : 'General / Office Report',
            subtitle: _caseLinked
                ? '${widget.caseFile!.displayTitle} — app কোনো investigation step নিজে থেকে লিখবে না'
                : 'কোনো case auto-link করা হয়নি; প্রয়োজন হলে case workspace থেকে Report খুলুন',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<_ReportTemplate>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Report Type', border: OutlineInputBorder()),
            items: _templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: (v) { if (v != null) _applyTemplate(v); },
          ),
          const SizedBox(height: 10),
          _field(_recipient, 'To / Recipient Office', lines: 2),
          _field(_subject, 'Subject', lines: 2),
          _field(_memo, 'Memo No., if any'),
          _field(_reference, 'Case / Petition / GDE / Memo Reference, if any', lines: 2),
          _field(_body, 'Report Body — শুধু verified facts লিখুন', lines: 16),
          if (_saved.isNotEmpty) ...[
            const SizedBox(height: 18),
            const InvestigoPageTitle(title: 'Saved Reports', subtitle: 'আগের draft আবার খুলে edit করা যাবে'),
            const SizedBox(height: 8),
            ..._saved.take(20).map((form) => Card(
              child: ListTile(
                leading: Icon(form.isFinal ? Icons.lock_outline : Icons.description_outlined),
                title: Text(form.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(form.isFinal ? 'Final saved' : 'Draft'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openSaved(form),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          minLines: lines,
          maxLines: lines,
          decoration: InputDecoration(labelText: label, alignLabelWithHint: lines > 1, border: const OutlineInputBorder()),
        ),
      );
}

class _ReportTemplate {
  final String id;
  final String name;
  final String recipient;
  final String Function(CaseFile? file) subject;
  final String Function(OfficerProfile officer, CaseFile? file) body;

  const _ReportTemplate({required this.id, required this.name, required this.recipient, required this.subject, required this.body});
}

final List<_ReportTemplate> _templates = [
  _ReportTemplate(
    id: 'sp',
    name: 'Report to Superintendent of Police',
    recipient: 'The Superintendent of Police, {district}',
    subject: (file) => file == null ? 'Submission of report' : 'Report in connection with ${file.displayTitle}',
    body: (officer, file) => file == null
        ? '''Most respectfully I beg to submit the following report for favour of kind information.

Reference / source:

Brief facts:

Enquiry / action actually taken:
1.
2.
3.

Present finding / status:

Further action proposed / prayer:
'''
        : '''Case Reference: ${officer.policeStation} Case No. ${file.psCaseNo} dated ${file.caseDate} u/s ${file.sections}.

Brief fact as per case record:
${file.firGist}

Investigation / enquiry steps actually taken by the officer:
1.
2.
3.

Materials / reports received:

Present finding / status:

Further action proposed / prayer:
''',
  ),
  _ReportTemplate(
    id: 'sdpo',
    name: 'Report to SDPO',
    recipient: 'The Sub-Divisional Police Officer, {sdpoOffice}',
    subject: (file) => file == null ? 'Report for kind perusal' : 'Report regarding ${file.displayTitle}',
    body: (officer, file) => file == null
        ? '''Most respectfully I submit the following facts for kind perusal.

Reference:

Facts verified during enquiry:

Action actually taken:

Present status:

Further action proposed:
'''
        : '''Case Reference: ${officer.policeStation} Case No. ${file.psCaseNo} dated ${file.caseDate} u/s ${file.sections}.

Brief fact as per case record:
${file.firGist}

Verified investigation steps actually taken:
1.
2.
3.

Present status / finding:

Further action proposed:
''',
  ),
  _ReportTemplate(
    id: 'court',
    name: 'Report to Learned Court',
    recipient: '{court}',
    subject: (file) => file == null ? 'Submission of report' : 'Submission of report regarding ${file.displayTitle}',
    body: (officer, file) => '''Most respectfully I beg to submit the following report before the Learned Court.

Reference:
${file == null ? '' : '${officer.policeStation} Case No. ${file.psCaseNo} dated ${file.caseDate} u/s ${file.sections}'}

Verified facts:

Police action actually taken:

Present status:

Prayer / submission:
''',
  ),
  _ReportTemplate(
    id: 'general',
    name: 'General Report / Letter',
    recipient: '',
    subject: (_) => 'Submission of report',
    body: (officer, file) => '''Reference:

Subject matter / brief facts:

Verified enquiry / action:

Present status / finding:

Further action / prayer:
''',
  ),
];
