import '../models/case_file.dart';
import '../models/cd_workflow.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/witness_examination_entry.dart';
import 'cd_workflow_service.dart';

class StatementLinkService {
  List<StatementEntry> buildLinkedStatements({
    required CaseFile caseFile,
    required OfficerProfile profile,
    required CdWorkflowPlan plan,
    required int cdNumber,
    required String cdDate,
    required Map<String, String> answers,
  }) {
    final result = <StatementEntry>[];
    final recordedBy = [profile.rank.trim(), profile.name.trim()]
        .where((e) => e.isNotEmpty)
        .join(' ');

    if (plan.phase == CdWorkflowPhase.initial) {
      if (_yes(answers, 'cd1_complainant_examined') &&
          _yes(answers, 'cd1_complainant_statement_recorded')) {
        _add(
          result,
          caseFile: caseFile,
          cdNumber: cdNumber,
          cdDate: cdDate,
          actionId: 'cd1_complainant',
          witnessName: caseFile.complainantName.trim(),
          witnessDetails: _answer(answers, 'cd1_complainant_identity_details'),
          statementType: 'Complainant statement u/s 180 BNSS',
          body: _answer(answers, 'cd1_complainant_statement'),
          recordedTime: _answer(answers, 'cd1_complainant_exam_time'),
          recordedPlace: _answer(answers, 'cd1_complainant_exam_place'),
          recordedBy: recordedBy,
        );
      }

      if (_yes(answers, 'cd1_victim_contacted') &&
          _yes(answers, 'cd1_victim_statement_recorded')) {
        _add(
          result,
          caseFile: caseFile,
          cdNumber: cdNumber,
          cdDate: cdDate,
          actionId: 'cd1_victim',
          witnessName: _answer(
            answers,
            'cd1_victim_name',
            fallback: caseFile.victimName.trim(),
          ),
          witnessDetails: _answer(answers, 'cd1_victim_identity_details'),
          statementType: 'Victim/VG statement u/s 180 BNSS',
          body: _answer(answers, 'cd1_victim_statement_body'),
          recordedTime: _answer(answers, 'cd1_victim_time'),
          recordedPlace: _answer(answers, 'cd1_victim_place'),
          recordedBy: recordedBy,
        );
      }
    }

    if (plan.phase == CdWorkflowPhase.initial) {
      _addWitnessBatch(
        result,
        raw: _answer(answers, 'cd1_witness_entries_json'),
        caseFile: caseFile,
        cdNumber: cdNumber,
        cdDate: cdDate,
        actionPrefix: 'cd1_witness_examination',
        recordedBy: recordedBy,
      );
    }

    if (plan.phase == CdWorkflowPhase.continuation) {
      final actions = _actions(answers);
      if (actions.contains(CdWorkflowService.actionWitnessExamination)) {
        final before = result.length;
        _addWitnessBatch(
          result,
          raw: _answer(answers, 'witness_entries_json'),
          caseFile: caseFile,
          cdNumber: cdNumber,
          cdDate: cdDate,
          actionPrefix: CdWorkflowService.actionWitnessExamination,
          recordedBy: recordedBy,
        );

        // Backward compatibility for a pre-v203 single-witness saved draft.
        if (result.length == before &&
            _yes(answers, 'witness_statement_recorded')) {
          final role = _answer(answers, 'witness_role');
          final identity = _answer(answers, 'witness_identity_details');
          _add(
            result,
            caseFile: caseFile,
            cdNumber: cdNumber,
            cdDate: cdDate,
            actionId: CdWorkflowService.actionWitnessExamination,
            witnessName: _answer(answers, 'witness_name'),
            witnessDetails: [
              if (identity.isNotEmpty) identity,
              if (role.isNotEmpty) 'Role: $role',
            ].join(' | '),
            statementType: role.isEmpty
                ? 'Witness statement u/s 180 BNSS'
                : '$role statement u/s 180 BNSS',
            body: _answer(answers, 'witness_statement_material'),
            recordedTime: _answer(answers, 'witness_time'),
            recordedPlace: _answer(answers, 'witness_place'),
            recordedBy: recordedBy,
          );
        }
      }

      if (actions.contains(CdWorkflowService.actionVictimExamination) &&
          _yes(answers, 'victim_statement_recorded')) {
        _add(
          result,
          caseFile: caseFile,
          cdNumber: cdNumber,
          cdDate: cdDate,
          actionId: CdWorkflowService.actionVictimExamination,
          witnessName: _answer(
            answers,
            'victim_name',
            fallback: caseFile.victimName.trim(),
          ),
          witnessDetails: _answer(answers, 'victim_identity_details'),
          statementType: 'Victim/VG statement u/s 180 BNSS',
          body: _answer(answers, 'victim_statement_body'),
          recordedTime: _answer(answers, 'victim_time'),
          recordedPlace: _answer(answers, 'victim_place'),
          recordedBy: recordedBy,
        );
      }
    }

    return result;
  }

  void _addWitnessBatch(
    List<StatementEntry> output, {
    required String raw,
    required CaseFile caseFile,
    required int cdNumber,
    required String cdDate,
    required String actionPrefix,
    required String recordedBy,
  }) {
    final batch = MultiWitnessBatch.decode(raw);
    for (final entry in batch.entries) {
      if (!entry.statementRecorded) continue;
      final role = entry.role.trim();
      final identity = entry.witnessDetails.trim();
      _add(
        output,
        caseFile: caseFile,
        cdNumber: cdNumber,
        cdDate: cdDate,
        actionId: '$actionPrefix:${entry.id}',
        witnessName: entry.witnessName,
        witnessDetails: [
          if (identity.isNotEmpty) identity,
          if (role.isNotEmpty) 'Role: $role',
        ].join(' | '),
        statementType: role.isEmpty
            ? 'Witness statement u/s 180 BNSS'
            : '$role statement u/s 180 BNSS',
        body: entry.statementBody,
        recordedTime: entry.recordedTime,
        recordedPlace: entry.recordedPlace,
        recordedBy: recordedBy,
      );
    }
  }

  void _add(
    List<StatementEntry> output, {
    required CaseFile caseFile,
    required int cdNumber,
    required String cdDate,
    required String actionId,
    required String witnessName,
    required String witnessDetails,
    required String statementType,
    required String body,
    required String recordedTime,
    required String recordedPlace,
    required String recordedBy,
  }) {
    final name = witnessName.trim();
    final text = body.trim();
    if (name.isEmpty || text.isEmpty) return;

    final sourceKey = [
      caseFile.id,
      'cd$cdNumber',
      actionId,
      name.toLowerCase(),
    ].join('|');

    output.add(
      StatementEntry.create(
        caseId: caseFile.id,
        witnessName: name,
        witnessDetails: witnessDetails.trim(),
        statementType: statementType.trim(),
        body: text,
        linkedFromCd: true,
        sourceCdNumber: cdNumber,
        sourceActionId: actionId,
        sourceKey: sourceKey,
        recordedDate: cdDate,
        recordedTime: recordedTime.trim(),
        recordedPlace: recordedPlace.trim(),
        recordedBy: recordedBy.trim(),
      ),
    );
  }

  Set<String> _actions(Map<String, String> answers) =>
      _answer(answers, 'today_actions')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

  bool _yes(Map<String, String> answers, String key) =>
      _answer(answers, key).toLowerCase() == 'yes';

  String _answer(
    Map<String, String> answers,
    String key, {
    String fallback = '',
  }) {
    final value = (answers[key] ?? '').trim();
    return value.isEmpty ? fallback : value;
  }
}
