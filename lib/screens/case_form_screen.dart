import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/investigo_ui.dart';

class CaseFormScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? existing;

  const CaseFormScreen({super.key, required this.profile, this.existing});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _store = LocalStoreService();
  late CaseFile _base;
  late final TextEditingController psCaseNo;
  late final TextEditingController caseDate;
  late final TextEditingController sections;
  late final TextEditingController crimeHead;
  late final TextEditingController po;
  late final TextEditingController dto;
  late final TextEditingController dtr;
  late final TextEditingController complainant;
  late final TextEditingController victim;
  late final TextEditingController accused;
  late final TextEditingController gist;

  @override
  void initState() {
    super.initState();
    _base = widget.existing ?? CaseFile.empty(ioName: '${widget.profile.rank} ${widget.profile.name}');
    psCaseNo = TextEditingController(text: _base.psCaseNo);
    caseDate = TextEditingController(text: _base.caseDate);
    sections = TextEditingController(text: _base.sections);
    crimeHead = TextEditingController(text: _base.crimeHead);
    po = TextEditingController(text: _base.placeOfOccurrence);
    dto = TextEditingController(text: _base.dateTimeOccurrence);
    dtr = TextEditingController(text: _base.dateTimeReporting);
    complainant = TextEditingController(text: _base.complainantName);
    victim = TextEditingController(text: _base.victimName);
    accused = TextEditingController(text: _base.accusedName);
    gist = TextEditingController(text: _base.firGist);
  }

  @override
  void dispose() {
    for (final c in [psCaseNo, caseDate, sections, crimeHead, po, dto, dtr, complainant, victim, accused, gist]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _pickDate(String current) async {
    final parsed = DateTime.tryParse(current.split(' ').first);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return null;
    return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _pickTime(String current) async {
    final raw = current.contains(' ') ? current.split(' ').last : current;
    final parts = raw.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour, minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDateOnly(TextEditingController controller) async {
    final value = await _pickDate(controller.text);
    if (value != null) setState(() => controller.text = value);
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final date = await _pickDate(controller.text);
    if (date == null || !mounted) return;
    final time = await _pickTime(controller.text);
    if (time == null) return;
    setState(() => controller.text = '$date $time');
  }

  Widget _text(TextEditingController controller, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _picker(TextEditingController controller, String label, {bool dateOnly = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: () => dateOnly ? _pickDateOnly(controller) : _pickDateTime(controller),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Icon(dateOnly ? Icons.calendar_month_outlined : Icons.event_available_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
      );

  List<String> _errors() {
    final errors = <String>[];
    if (psCaseNo.text.trim().isEmpty) errors.add('PS Case No. দিন');
    if (caseDate.text.trim().isEmpty) errors.add('Case Date দিন');
    if (sections.text.trim().isEmpty) errors.add('Sections of Law দিন');
    if (po.text.trim().isEmpty) errors.add('Place of Occurrence দিন');
    if (dtr.text.trim().isEmpty) errors.add('Date & Time of Reporting দিন');
    if (gist.text.trim().isEmpty) errors.add('FIR-এর Brief Gist দিন');
    return errors;
  }

  Future<void> _save() async {
    final errors = _errors();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errors.first)));
      return;
    }

    final all = await _store.loadCases();
    final normalized = psCaseNo.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final duplicate = all.any((item) =>
        item.id != _base.id &&
        item.psCaseNo.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '') == normalized);
    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('এই PS Case No. আগে থেকেই আছে। Existing case খুলে Edit করুন।')));
      return;
    }

    final updated = _base.copyWith(
      psCaseNo: psCaseNo.text.trim(),
      caseDate: caseDate.text.trim(),
      sections: sections.text.trim(),
      crimeHead: crimeHead.text.trim(),
      placeOfOccurrence: po.text.trim(),
      dateTimeOccurrence: dto.text.trim(),
      dateTimeReporting: dtr.text.trim(),
      complainantName: complainant.text.trim(),
      victimName: victim.text.trim(),
      accusedName: accused.text.trim(),
      firGist: gist.text.trim(),
      // Investigation facts are deliberately not collected here in v208.
      // They remain preserved for older cases and are entered through the CD workflow.
      investigationStart: _base.investigationStart,
    );
    await _store.saveCase(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.existing == null ? 'নতুন মামলা / New Case' : 'মামলা Edit করুন'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            style: InvestigoUi.primaryButtonStyle(),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Case'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          const InvestigoPageTitle(
            title: 'মামলার মূল তথ্য',
            subtitle: 'তদন্তের কাজ এখানে নয় — CD Wizard-এ এক ধাপ করে হবে',
          ),
          const SizedBox(height: 14),
          _card('1', 'Case Details', [
            _text(psCaseNo, 'PS Case No. / Year'),
            _picker(caseDate, 'Case Date', dateOnly: true),
            _text(sections, 'Sections of Law'),
            _text(crimeHead, 'Crime Head / Case Type'),
          ]),
          const SizedBox(height: 12),
          _card('2', 'Incident', [
            _text(po, 'Place of Occurrence', lines: 2),
            _picker(dto, 'Date & Time of Occurrence'),
            _picker(dtr, 'Date & Time of Reporting'),
            _text(gist, 'Brief Gist of FIR', lines: 6),
          ]),
          const SizedBox(height: 12),
          _card('3', 'People', [
            _text(complainant, 'Complainant / Informant Details', lines: 2),
            _text(victim, 'Victim Details, if any', lines: 2),
            _text(accused, 'Accused / Suspect Details', lines: 3),
          ]),
        ],
      ),
    );
  }

  Widget _card(String no, String title, List<Widget> children) => Container(
        decoration: InvestigoUi.cardDecoration(),
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: InvestigoUi.primary.withOpacity(.09), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(no, style: const TextStyle(color: InvestigoUi.primary, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );
}
