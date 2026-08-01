import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/local_store_service.dart';
import '../widgets/form_helpers.dart';

class EvidenceScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const EvidenceScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final LocalStoreService _store = LocalStoreService();
  late CaseFile _caseFile;
  late TextEditingController _physical;
  late TextEditingController _digital;
  late TextEditingController _medical;
  late TextEditingController _seizure;
  late TextEditingController _remarks;

  @override
  void initState() {
    super.initState();
    _caseFile = widget.caseFile;
    final existing = _caseFile.investigationStart.evidenceDetails;
    _physical = TextEditingController(text: _extract(existing, 'Physical Evidence'));
    _digital = TextEditingController(text: _extract(existing, 'Digital Evidence'));
    _medical = TextEditingController(text: _extract(existing, 'Medical / Document Evidence'));
    _seizure = TextEditingController(text: _extract(existing, 'Seizure / Malkhana / FSL'));
    _remarks = TextEditingController(text: _extract(existing, 'Remarks'));
  }

  String _extract(String source, String title) {
    final marker = '$title:';
    final idx = source.indexOf(marker);
    if (idx < 0) return '';
    final start = idx + marker.length;
    final next = RegExp(r'\n[A-Za-z /]+:').firstMatch(source.substring(start));
    final end = next == null ? source.length : start + next.start;
    return source.substring(start, end).trim();
  }

  @override
  void dispose() {
    _physical.dispose();
    _digital.dispose();
    _medical.dispose();
    _seizure.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String _combinedEvidence() {
    return [
      'Physical Evidence: ${_physical.text.trim()}',
      'Digital Evidence: ${_digital.text.trim()}',
      'Medical / Document Evidence: ${_medical.text.trim()}',
      'Seizure / Malkhana / FSL: ${_seizure.text.trim()}',
      'Remarks: ${_remarks.text.trim()}',
    ].join('\n');
  }

  Future<void> _save({bool askCd = false}) async {
    final start = _caseFile.investigationStart;
    final updatedStart = InvestigationStart(
      ioName: start.ioName,
      tookUpDate: start.tookUpDate,
      visitedPo: start.visitedPo,
      poDetails: start.poDetails,
      sketchPrepared: start.sketchPrepared,
      sketchDetails: start.sketchDetails,
      witnessExamined: start.witnessExamined,
      witnessDetails: start.witnessDetails,
      medicalRequired: start.medicalRequired,
      medicalDetails: start.medicalDetails,
      seizureRequired: start.seizureRequired,
      seizureDetails: start.seizureDetails,
      evidenceRequired: true,
      evidenceDetails: _combinedEvidence(),
    );
    final updated = _caseFile.copyWith(investigationStart: updatedStart);
    await _store.saveCase(updated);
    if (!mounted) return;
    setState(() => _caseFile = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence details saved')));
    if (askCd) await _askMentionInCd();
  }

  Future<void> _askMentionInCd() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mention in Case Diary?'),
        content: const Text('Evidence/seizure/digital evidence details CD-তে pending entry হিসেবে রাখবেন?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true) return;
    final action = PendingCdAction.create(
      caseId: _caseFile.id,
      sourceType: 'Evidence',
      sourceId: _caseFile.id,
      title: 'Evidence details updated',
      actionDate: DateTime.now().toIso8601String().split('T').first,
      paragraph: 'Verified/collected evidence details in connection with this case. Details: ${_combinedEvidence()}',
    );
    await _store.savePendingCdAction(action);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pending CD entry created')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence Manager')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _save(), icon: const Icon(Icons.save), label: const Text('Save'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: () => _save(askCd: true), icon: const Icon(Icons.note_add), label: const Text('Save + CD'))),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Sections: ${_caseFile.sections}'),
                  const SizedBox(height: 8),
                  const Text('এখানে physical/digital/medical/seizure evidence details লিখুন। পরে CD/IF5-এ এগুলো ব্যবহার হবে।', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FormHelpers.textField(controller: _physical, label: 'Physical Evidence / Article / Document', maxLines: 4),
          FormHelpers.textField(controller: _digital, label: 'Digital Evidence / CCTV / CDR / CAF / Bank / UPI', maxLines: 4),
          FormHelpers.textField(controller: _medical, label: 'Medical / BHT / Injury / PM / Report Evidence', maxLines: 4),
          FormHelpers.textField(controller: _seizure, label: 'Seizure / Malkhana / FSL / Property Register', maxLines: 4),
          FormHelpers.textField(controller: _remarks, label: 'Remarks / Next Action', maxLines: 4),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
