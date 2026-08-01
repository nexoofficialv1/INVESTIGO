import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class CaseFormScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile? existing;

  const CaseFormScreen({super.key, required this.profile, this.existing});

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final LocalStoreService _store = LocalStoreService();

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
  late final TextEditingController tookUpDate;
  late final TextEditingController poDetails;
  late final TextEditingController sketchDetails;
  late final TextEditingController witnessDetails;
  late final TextEditingController medicalDetails;
  late final TextEditingController seizureDetails;
  late final TextEditingController evidenceDetails;

  bool visitedPo = false;
  bool sketchPrepared = false;
  bool witnessExamined = false;
  bool medicalRequired = false;
  bool seizureRequired = false;
  bool evidenceRequired = false;

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

    final start = _base.investigationStart;
    tookUpDate = TextEditingController(text: start.tookUpDate);
    poDetails = TextEditingController(text: start.poDetails);
    sketchDetails = TextEditingController(text: start.sketchDetails);
    witnessDetails = TextEditingController(text: start.witnessDetails);
    medicalDetails = TextEditingController(text: start.medicalDetails);
    seizureDetails = TextEditingController(text: start.seizureDetails);
    evidenceDetails = TextEditingController(text: start.evidenceDetails);
    visitedPo = start.visitedPo;
    sketchPrepared = start.sketchPrepared;
    witnessExamined = start.witnessExamined;
    medicalRequired = start.medicalRequired;
    seizureRequired = start.seizureRequired;
    evidenceRequired = start.evidenceRequired;
  }

  @override
  void dispose() {
    for (final c in [psCaseNo, caseDate, sections, crimeHead, po, dto, dtr, complainant, victim, accused, gist, tookUpDate, poDetails, sketchDetails, witnessDetails, medicalDetails, seizureDetails, evidenceDetails]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (psCaseNo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PS Case No. required')));
      return;
    }

    final start = InvestigationStart(
      ioName: '${widget.profile.rank} ${widget.profile.name}',
      tookUpDate: tookUpDate.text.trim(),
      visitedPo: visitedPo,
      poDetails: poDetails.text.trim(),
      sketchPrepared: sketchPrepared,
      sketchDetails: sketchDetails.text.trim(),
      witnessExamined: witnessExamined,
      witnessDetails: witnessDetails.text.trim(),
      medicalRequired: medicalRequired,
      medicalDetails: medicalDetails.text.trim(),
      seizureRequired: seizureRequired,
      seizureDetails: seizureDetails.text.trim(),
      evidenceRequired: evidenceRequired,
      evidenceDetails: evidenceDetails.text.trim(),
    );

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
      investigationStart: start,
    );
    await _store.saveCase(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Create Case' : 'Edit Case')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Case')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            title: 'Step 1: Basic Details',
            icon: Icons.assignment,
            child: Column(
              children: [
                FormHelpers.textField(controller: psCaseNo, label: 'PS Case No. / Year'),
                FormHelpers.textField(controller: caseDate, label: 'Case Date'),
                FormHelpers.textField(controller: sections, label: 'Sections of Law'),
                FormHelpers.textField(controller: crimeHead, label: 'Crime Head / Case Type'),
              ],
            ),
          ),
          AppSectionCard(
            title: 'Step 2: Incident Details',
            icon: Icons.place,
            child: Column(
              children: [
                FormHelpers.textField(controller: po, label: 'Place of Occurrence', maxLines: 2),
                FormHelpers.textField(controller: dto, label: 'Date & Time of Occurrence'),
                FormHelpers.textField(controller: dtr, label: 'Date & Time of Reporting'),
                FormHelpers.textField(controller: gist, label: 'Brief Gist of FIR', maxLines: 5),
              ],
            ),
          ),
          AppSectionCard(
            title: 'Step 3: Parties',
            icon: Icons.people,
            child: Column(
              children: [
                FormHelpers.textField(controller: complainant, label: 'Complainant Details', maxLines: 2),
                FormHelpers.textField(controller: victim, label: 'Victim Details', maxLines: 2),
                FormHelpers.textField(controller: accused, label: 'Accused / Suspect Details', maxLines: 3),
              ],
            ),
          ),
          AppSectionCard(
            title: 'Step 4: Investigation Start',
            subtitle: 'Yes হলে details field open হবে। এই data থেকে CD-I auto draft তৈরি হবে।',
            icon: Icons.manage_search,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IO Name: ${widget.profile.rank} ${widget.profile.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FormHelpers.textField(controller: tookUpDate, label: 'Took up investigation date'),
                FormHelpers.yesNoTile(title: 'Visited PO?', value: visitedPo, onChanged: (v) => setState(() => visitedPo = v)),
                if (visitedPo) FormHelpers.textField(controller: poDetails, label: 'Details of PO visit', maxLines: 4),
                FormHelpers.yesNoTile(title: 'Rough sketch map prepared?', value: sketchPrepared, onChanged: (v) => setState(() => sketchPrepared = v)),
                if (sketchPrepared) FormHelpers.textField(controller: sketchDetails, label: 'Rough sketch map details', maxLines: 3),
                FormHelpers.yesNoTile(title: 'Witness examined?', value: witnessExamined, onChanged: (v) => setState(() => witnessExamined = v)),
                if (witnessExamined) FormHelpers.textField(controller: witnessDetails, label: 'Witness examination details', maxLines: 4),
                FormHelpers.yesNoTile(title: 'Medical required?', value: medicalRequired, onChanged: (v) => setState(() => medicalRequired = v)),
                if (medicalRequired) FormHelpers.textField(controller: medicalDetails, label: 'Medical / BHT / Injury details', maxLines: 4),
                FormHelpers.yesNoTile(title: 'Seizure required?', value: seizureRequired, onChanged: (v) => setState(() => seizureRequired = v)),
                if (seizureRequired) FormHelpers.textField(controller: seizureDetails, label: 'Seizure details', maxLines: 4),
                FormHelpers.yesNoTile(title: 'Evidence available/required?', value: evidenceRequired, onChanged: (v) => setState(() => evidenceRequired = v)),
                if (evidenceRequired) FormHelpers.textField(controller: evidenceDetails, label: 'Evidence details (physical/digital/CCTV/document etc.)', maxLines: 4),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
