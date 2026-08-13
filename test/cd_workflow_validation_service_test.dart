import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/services/cd_workflow_service.dart';
import 'package:investigo/services/cd_workflow_validation_service.dart';

CaseFile _case() => CaseFile.empty(ioName: 'SI Test').copyWith(
      psCaseNo: '326/2026',
      sections: '25/27 Arms Act',
      crimeHead: 'Arms',
      placeOfOccurrence: 'Kharinan, Kalna',
      complainantName: 'Complainant',
    );

void main() {
  group('CD workflow validation v199', () {
    test('blocks raid arrival before departure', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionRaidSearch,
          'raid_departure': '18.00 hrs.',
          'raid_arrival_time': '17.30 hrs.',
          'raid_place': 'Kharinan',
          'raid_place_force_result': 'Raid held.',
          'continuation_return_time': '19.00 hrs.',
        },
      );

      expect(issues.any((e) => e.isError), isTrue);
    });

    test('blocks an event after closing time', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionRecoverySeizure,
          'recovery_time': '20.15 hrs.',
          'recovery_place': 'Kharinan',
          'recovery_basis': 'showing of accused',
          'recovery_article': 'One cartridge',
          'continuation_return_time': '19.45 hrs.',
        },
      );

      expect(issues.any((e) => e.isError), isTrue);
    });

    test('warns when PC disclosure leads to recovery but recovery action is absent', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionPcInterrogation,
          'pc_time': '10.00 hrs.',
          'pc_accused_name': 'Accused A',
          'pc_interrogation_material': 'Disclosure made.',
          'pc_leading_to_recovery': 'yes',
          'continuation_return_time': '11.00 hrs.',
        },
      );

      expect(issues.any((e) => !e.isError), isTrue);
    });

    test('clean chronological recovery can pass without errors', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionRecoverySeizure,
          'recovery_time': '18.15 hrs.',
          'recovery_place': 'Kharinan',
          'recovery_basis': 'showing of PC accused',
          'recovery_article': 'One cartridge',
          'recovery_witness_custody': 'Witness A/B; kept in malkhana',
          'continuation_return_time': '19.15 hrs.',
        },
      );

      expect(issues.any((e) => e.isError), isFalse);
    });


    test('auto sketch requires exact PO and all four boundaries', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionPoVisit,
          'po_departure_time': '10.00 hrs.',
          'po_visit_time': '10.30 hrs.',
          'po_exact': 'Kharinan field',
          'po_sketch_index': 'yes',
          'po_north': 'House',
          'po_south': 'Pond',
          'po_east': 'Road',
          'po_west': '',
          'continuation_return_time': '11.30 hrs.',
        },
      );
      expect(issues.any((e) => e.isError && e.questionIds.contains('po_west')), isTrue);
    });
  });
}
