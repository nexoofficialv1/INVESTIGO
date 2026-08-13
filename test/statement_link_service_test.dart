import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/services/cd_workflow_service.dart';
import 'package:investigo/services/statement_link_service.dart';

CaseFile _case() => CaseFile.empty(ioName: 'SI Test').copyWith(
      psCaseNo: '605/2026',
      caseDate: '2026-07-25',
      sections: '281/125(b)/324(4) BNS',
      crimeHead: 'Road Traffic Accident',
      placeOfOccurrence: 'STKK Road, Sahapur Kalitala',
      complainantName: 'Subhankar Biswas',
      victimName: 'Victim A',
    );

OfficerProfile _profile() => OfficerProfile.empty().copyWith(
      name: 'Partha Sarathi Chowdhury',
      rank: 'SI',
      policeStation: 'Kalna PS',
      district: 'Purba Bardhaman',
    );

void main() {
  group('StatementLinkService v202', () {
    test('CD-I complainant input creates one linked u/s 180 statement', () {
      final caseFile = _case();
      final plan = CdWorkflowService().buildPlan(caseFile: caseFile, cdNumber: 1);
      final entries = StatementLinkService().buildLinkedStatements(
        caseFile: caseFile,
        profile: _profile(),
        plan: plan,
        cdNumber: 1,
        cdDate: '2026-07-25',
        answers: const <String, String>{
          'cd1_complainant_examined': 'yes',
          'cd1_complainant_statement_recorded': 'yes',
          'cd1_complainant_exam_time': '21.35 hrs.',
          'cd1_complainant_exam_place': 'Kalna PS',
          'cd1_complainant_identity_details': 'S/o Dhiren Biswas, Purba Sahapur',
          'cd1_complainant_statement': 'I stated the occurrence in my own words.',
        },
      );

      expect(entries.length, 1);
      expect(entries.single.witnessName, 'Subhankar Biswas');
      expect(entries.single.statementType, contains('u/s 180 BNSS'));
      expect(entries.single.recordedTime, '21.35 hrs.');
      expect(entries.single.recordedPlace, 'Kalna PS');
      expect(entries.single.recordedBy, 'SI Partha Sarathi Chowdhury');
      expect(entries.single.sourceKey, contains('|cd1|cd1_complainant|'));
    });

    test('does not fabricate a statement when recorded is No', () {
      final caseFile = _case();
      final plan = CdWorkflowService().buildPlan(caseFile: caseFile, cdNumber: 1);
      final entries = StatementLinkService().buildLinkedStatements(
        caseFile: caseFile,
        profile: _profile(),
        plan: plan,
        cdNumber: 1,
        cdDate: '2026-07-25',
        answers: const <String, String>{
          'cd1_complainant_examined': 'yes',
          'cd1_complainant_statement_recorded': 'no',
        },
      );
      expect(entries, isEmpty);
    });

    test('continuation witness creates linked statement from structured witness data', () {
      final caseFile = _case();
      final plan = CdWorkflowService().buildPlan(caseFile: caseFile, cdNumber: 2);
      final entries = StatementLinkService().buildLinkedStatements(
        caseFile: caseFile,
        profile: _profile(),
        plan: plan,
        cdNumber: 2,
        cdDate: '2026-07-26',
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionWitnessExamination,
          'witness_name': 'Witness One',
          'witness_identity_details': 'S/o Test, Vill-Test, PS Kalna',
          'witness_role': 'Eye witness',
          'witness_statement_recorded': 'yes',
          'witness_statement_material': 'I saw the occurrence and state the facts in my own words.',
          'witness_time': '12.20 hrs.',
          'witness_place': 'Kalna PS',
        },
      );

      expect(entries.length, 1);
      expect(entries.single.witnessName, 'Witness One');
      expect(entries.single.statementType, startsWith('Eye witness'));
      expect(entries.single.sourceCdNumber, 2);
      expect(entries.single.sourceActionId, CdWorkflowService.actionWitnessExamination);
    });
  });
}
