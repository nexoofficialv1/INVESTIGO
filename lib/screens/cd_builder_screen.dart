import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/cd_generator_service.dart';
import '../services/local_store_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';
import 'cd_editor_screen.dart';

class CdBuilderScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CdBuilderScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<CdBuilderScreen> createState() => _CdBuilderScreenState();
}

class _CdBuilderScreenState extends State<CdBuilderScreen> {
  final LocalStoreService _store = LocalStoreService();
  final CdQuestionAnswer _answers = CdQuestionAnswer();

  int? cdNumber;
  List<PendingCdAction> pendingActions = [];
  final Set<String> selectedPendingActionIds = <String>{};
  final witness = TextEditingController();
  final po = TextEditingController();
  final sketch = TextEditingController();
  final medical = TextEditingController();
  final requisition = TextEditingController();
  final seizure = TextEditingController();
  final arrest = TextEditingController();
  final notice = TextEditingController();
  final courtPrayer = TextEditingController();
  final receivedDocument = TextEditingController();
  final localEnquiry = TextEditingController();
  final verification = TextEditingController();
  final digitalEvidence = TextEditingController();
  final importantDevelopment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNextCd();
    _loadPendingActions();
  }

  Future<void> _loadNextCd() async {
    final next = await _store.nextCdNumber(widget.caseFile.id);
    if (!mounted) return;
    setState(() => cdNumber = next);
  }


  Future<void> _loadPendingActions() async {
    final actions = await _store.loadPendingCdActions(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      pendingActions = actions;
      selectedPendingActionIds.addAll(actions.map((e) => e.id));
    });
  }

  @override
  void dispose() {
    for (final c in [witness, po, sketch, medical, requisition, seizure, arrest, notice, courtPrayer, receivedDocument, localEnquiry, verification, digitalEvidence, importantDevelopment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final number = cdNumber;
    if (number == null) return;

    _answers.witnessDetails = witness.text.trim();
    _answers.poDetails = po.text.trim();
    _answers.sketchDetails = sketch.text.trim();
    _answers.medicalDetails = medical.text.trim();
    _answers.requisitionDetails = requisition.text.trim();
    _answers.seizureDetails = seizure.text.trim();
    _answers.arrestDetails = arrest.text.trim();
    _answers.noticeDetails = notice.text.trim();
    _answers.courtPrayerDetails = courtPrayer.text.trim();
    _answers.receivedDocumentDetails = receivedDocument.text.trim();
    _answers.localEnquiryDetails = localEnquiry.text.trim();
    _answers.verificationDetails = verification.text.trim();
    _answers.digitalEvidenceDetails = digitalEvidence.text.trim();
    _answers.importantDevelopmentDetails = importantDevelopment.text.trim();
    final selectedPending = pendingActions.where((e) => selectedPendingActionIds.contains(e.id)).toList();
    _answers.pendingActionParagraphs = selectedPending.map((e) => e.paragraph).toList();

    final service = CdGeneratorService();
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} hrs.';
    final tableLines = service.generateOfficialCdTableLines(
      caseFile: widget.caseFile,
      cdNumber: number,
      time: time,
      defaultPlace: widget.profile.policeStation,
      answers: _answers,
    );
    final body = tableLines.map((e) => e.proceedings).join('\n\n');
    final cd = CdEntry.newDraft(
      caseId: widget.caseFile.id,
      cdNumber: number,
      body: body,
      placeOfEntry: widget.profile.policeStation,
      tableLines: tableLines,
    );
    await _store.saveCd(cd);
    await _store.markPendingCdActionsConsumed(selectedPending.map((e) => e.id).toList());
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CdEditorScreen(profile: widget.profile, caseFile: widget.caseFile, cd: cd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final number = cdNumber;
    return Scaffold(
      appBar: AppBar(title: Text(number == null ? 'New CD' : 'Create CD-$number')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_awesome), label: const Text('Generate CD')),
        ),
      ),
      body: number == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('CD-$number তৈরি হবে। Yes/No select করে details দিন। Generate CD চাপলে draft তৈরি হবে।', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (pendingActions.isNotEmpty)
                  AppSectionCard(
                    title: 'Pending CD Entries from Forms/Requisitions',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('আগে save/export করা requisition/form থেকে CD mention pending আছে। যেগুলো আজকের CD-তে রাখতে চান tick রাখুন।'),
                        const SizedBox(height: 8),
                        ...pendingActions.map((action) => CheckboxListTile(
                              value: selectedPendingActionIds.contains(action.id),
                              title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${action.actionDate} • ${action.paragraph}'),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedPendingActionIds.add(action.id);
                                  } else {
                                    selectedPendingActionIds.remove(action.id);
                                  }
                                });
                              },
                            )),
                      ],
                    ),
                  ),
                _questionCard('1. Did you examine any witness today?', _answers.examinedWitness, (v) => setState(() => _answers.examinedWitness = v), witness, 'Witness examination details'),
                _questionCard('2. Did you visit the PO today?', _answers.visitedPo, (v) => setState(() => _answers.visitedPo = v), po, 'PO visit details'),
                _questionCard('3. Did you prepare/modify rough sketch map?', _answers.sketchMap, (v) => setState(() => _answers.sketchMap = v), sketch, 'Sketch map details'),
                _questionCard('4. Did you collect any medical paper?', _answers.medicalPaper, (v) => setState(() => _answers.medicalPaper = v), medical, 'Medical / BHT / injury details'),
                _questionCard('5. Did you send any requisition?', _answers.requisition, (v) => setState(() => _answers.requisition = v), requisition, 'Requisition details'),
                _questionCard('6. Did you seize any article/document?', _answers.seizure, (v) => setState(() => _answers.seizure = v), seizure, 'Seizure details'),
                _questionCard('7. Did you arrest any accused?', _answers.arrest, (v) => setState(() => _answers.arrest = v), arrest, 'Arrest details'),
                _questionCard('8. Did you serve any notice?', _answers.notice, (v) => setState(() => _answers.notice = v), notice, 'Notice details'),
                _questionCard('9. Did you submit any court prayer?', _answers.courtPrayer, (v) => setState(() => _answers.courtPrayer = v), courtPrayer, 'Court prayer details'),
                _questionCard('10. Did you receive any order/report/document?', _answers.receivedDocument, (v) => setState(() => _answers.receivedDocument = v), receivedDocument, 'Received document details'),
                _questionCard('11. Did you conduct local enquiry?', _answers.localEnquiry, (v) => setState(() => _answers.localEnquiry = v), localEnquiry, 'Local enquiry details'),
                _questionCard('12. Did you verify any person/detail?', _answers.verification, (v) => setState(() => _answers.verification = v), verification, 'Verification details'),
                _questionCard('13. Did you collect/take steps for evidence?', _answers.digitalEvidence, (v) => setState(() => _answers.digitalEvidence = v), digitalEvidence, 'Digital evidence details'),
                _questionCard('14. Any important development today?', _answers.importantDevelopment, (v) => setState(() => _answers.importantDevelopment = v), importantDevelopment, 'Important development details'),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _questionCard(String title, bool value, ValueChanged<bool> onChanged, TextEditingController controller, String label) {
    return AppSectionCard(
      title: title,
      child: Column(
        children: [
          FormHelpers.yesNoTile(title: 'Answer', value: value, onChanged: onChanged),
          if (value) FormHelpers.textField(controller: controller, label: label, maxLines: 4),
        ],
      ),
    );
  }
}
