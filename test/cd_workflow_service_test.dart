import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/cd_workflow.dart';
import 'package:investigo/services/cd_workflow_service.dart';

CaseFile _case({
  String sections = '25/27 Arms Act',
  String crimeHead = 'Arms',
  String victimName = '',
}) {
  final base = CaseFile.empty(ioName: 'SI Test Officer');
  return base.copyWith(
    psCaseNo: '326/2026',
    sections: sections,
    crimeHead: crimeHead,
    complainantName: 'Complainant',
    victimName: victimName,
  );
}

void main() {
  group('CD Workflow v2', () {
    test('CD-I uses the initial investigation question tree', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(
        caseFile: _case(),
        cdNumber: 1,
      );

      expect(plan.phase, CdWorkflowPhase.initial);
      expect(
        plan.questions.any((q) => q.id == 'cd1_fir_received'),
        isTrue,
      );
      expect(
        plan.questions.any((q) => q.id == 'cd1_left_for_po'),
        isTrue,
      );
      expect(
        plan.questions.any((q) => q.id == 'today_actions'),
        isFalse,
      );
    });

    test('subsequent CD starts with an action selector', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(
        caseFile: _case(),
        cdNumber: 3,
        hasPcAccused: true,
      );

      expect(plan.phase, CdWorkflowPhase.continuation);
      expect(plan.questions.first.id, 'today_actions');
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionPcInterrogation),
      );
    });

    test('continuation exposes required chronological time questions', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(caseFile: _case(), cdNumber: 3);

      final raidDeparture = plan.questions.firstWhere((q) => q.id == 'raid_departure');
      final raidArrival = plan.questions.firstWhere((q) => q.id == 'raid_arrival_time');
      final recoveryTime = plan.questions.firstWhere((q) => q.id == 'recovery_time');
      final courtArrival = plan.questions.firstWhere((q) => q.id == 'court_arrival_time');

      expect(raidDeparture.required, isTrue);
      expect(raidArrival.required, isTrue);
      expect(recoveryTime.required, isTrue);
      expect(courtArrival.required, isTrue);
    });

    test('POCSO continuation recommends victim/judicial/age-proof steps', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(
        caseFile: _case(
          sections: '06 of POCSO Act',
          crimeHead: 'POCSO',
          victimName: 'VG',
        ),
        cdNumber: 2,
      );

      expect(plan.caseCategory, CdCaseCategory.pocso);
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionVictimExamination),
      );
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionJudicialStatement),
      );
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionAgeProof),
      );
    });

    test('Arms continuation recommends expert report and sanction', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(
        caseFile: _case(),
        cdNumber: 4,
        completedActions: const {
          CdWorkflowService.actionRecoverySeizure,
        },
      );

      expect(plan.caseCategory, CdCaseCategory.arms);
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionExpertReport),
      );
      expect(
        plan.recommendedActionIds,
        contains(CdWorkflowService.actionSanction),
      );
    });

    test('last CD switches to finalisation question tree', () {
      final service = CdWorkflowService();
      final plan = service.buildPlan(
        caseFile: _case(),
        cdNumber: 9,
        finalisationRequested: true,
      );

      expect(plan.phase, CdWorkflowPhase.finalisation);
      expect(plan.questions.first.id, 'final_superior_order');
      expect(
        plan.questions.any((q) => q.id == 'final_cs_number_date'),
        isTrue,
      );
    });
  });
}
