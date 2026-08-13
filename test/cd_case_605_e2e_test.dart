import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/cd_entry.dart';
import 'package:investigo/models/cd_workflow.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/services/cd_workflow_draft_service.dart';
import 'package:investigo/services/cd_workflow_service.dart';
import 'package:investigo/services/cd_workflow_validation_service.dart';
import 'package:investigo/services/sketch_map_auto_service.dart';
import 'package:investigo/services/statement_link_service.dart';

CaseFile _case605() {
  final now = DateTime(2026, 7, 25, 21, 5);
  return CaseFile(
    id: 'case_605_2026',
    psCaseNo: '605/2026',
    caseDate: '2026-07-25',
    sections: '281/125(b)/324(4) BNS',
    crimeHead: 'Road Traffic Accident',
    placeOfOccurrence: 'On STKK Road, Sahapur Kalitala, PS Kalna, Dist Purba Bardhaman',
    dateTimeOccurrence: '25.07.2026 at about 16.45 hrs.',
    dateTimeReporting: '25.07.2026 at 21.05 hrs.',
    complainantName: 'Subhankar Biswas',
    victimName: '',
    accusedName: 'Driver of offending vehicle Reg No. WB16BM/6158',
    firGist: 'One M/C WB44G/7311 was dashed by four wheeler WB16BM/6158; rider sustained bleeding injuries and was shifted to Kalna SD & SS Hospital.',
    investigationStart: InvestigationStart.empty(ioName: 'SI Partha Sarathi Chowdhury'),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kalna PS Case 605/2026 end-to-end CD workflow', () {
    test('CD-I validates, auto-sketch approves and produces chronological diary', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final workflow = CdWorkflowService();
      final draft = CdWorkflowDraftService();
      final validator = CdWorkflowValidationService();
      final sketchService = SketchMapAutoService();
      final caseFile = _case605();

      final plan = workflow.buildPlan(caseFile: caseFile, cdNumber: 1);
      expect(plan.caseCategory, CdCaseCategory.roadTrafficAccident);
      expect(plan.phase, CdWorkflowPhase.initial);

      const answers = <String, String>{
        'cd1_fir_receive_time': '21.15 hrs.',
        'cd1_departure_time': '22.00 hrs.',
        'cd1_first_arrival_time': '22.25 hrs.',
        'cd1_first_arrival_place': 'On STKK Road, Sahapur Kalitala, PS Kalna, Dist Purba Bardhaman',
        'cd1_ro': 'Duty Officer, Kalna PS',
        'cd1_fir_received': 'yes',
        'cd1_complainant_examined': 'yes',
        'cd1_complainant_exam_time': '21.35 hrs.',
        'cd1_complainant_exam_place': 'Kalna PS',
        'cd1_complainant_identity_details': 'S/o Shri Dhiren Biswas of Purba Sahapur, PS Kalna, Dist Purba Bardhaman, Mob-7001326875',
        'cd1_complainant_statement_recorded': 'yes',
        'cd1_complainant_statement': 'I stated the facts and circumstances of the road traffic incident as recorded by the IO for this workflow test.',
        'cd1_existing_seizure': 'no',
        'cd1_accused_available': 'no',
        'cd1_left_for_po': 'yes',
        'cd1_po_first_destination': 'yes',
        'cd1_po_exact': 'On STKK Road, Sahapur Kalitala, PS Kalna, Dist Purba Bardhaman',
        'cd1_po_shown_by': 'Complainant Subhankar Biswas',
        'cd1_sketch_index': 'yes',
        // Demo-only boundaries for workflow verification, not asserted as real case facts.
        'cd1_po_north': 'Demo house',
        'cd1_po_south': 'Demo pond',
        'cd1_po_east': 'STKK Road',
        'cd1_po_west': 'Demo vacant land',
        'cd1_clue_search': 'yes',
        'cd1_clue_search_time': '22.50 hrs.',
        'cd1_clue_search_result': 'Demo-only search result for workflow verification.',
        'cd1_local_witness_search': 'yes',
        'cd1_local_witness_search_time': '22.55 hrs.',
        'cd1_local_witness_result': 'Demo-only local enquiry result for workflow verification.',
        'cd1_po_departure_from_spot_time': '23.15 hrs.',
        'cd1_return_time': '23.40 hrs.',
      };

      final issues = validator.validate(plan: plan, answers: answers);
      expect(issues.where((e) => e.isError), isEmpty);

      final sketch = sketchService.generateDraft(
        caseId: caseFile.id,
        sourceCdNumber: 1,
        exactPo: answers['cd1_po_exact']!,
        north: answers['cd1_po_north']!,
        south: answers['cd1_po_south']!,
        east: answers['cd1_po_east']!,
        west: answers['cd1_po_west']!,
        date: '2026-07-25',
      );
      expect(sketchService.validateDraft(sketch), isEmpty);
      final approval = await sketchService.approve(
        map: sketch,
        officerName: 'SI Partha Sarathi Chowdhury',
        sourceCdNumber: 1,
      );
      expect(sketchService.isApprovedFor(sketch, approval), isTrue);

      final lines = draft.buildTableLines(
        caseFile: caseFile,
        plan: plan,
        answers: answers,
        defaultPlace: 'Kalna PS',
      );
      final body = lines.map((e) => e.proceedings).join('\n');
      expect(body, contains('Subhankar Biswas'));
      expect(body, contains('rough sketch map'));
      expect(body, contains('North: Demo house'));
      expect(lines.any((e) => e.placeOfEntry == 'Kalna PS' && e.synopsis.contains('Examine complainant')), isTrue);
      expect(lines.where((e) => e.synopsis.contains('Dept\nfor PO')).length, 1);
      expect(lines.any((e) => e.noAndHour.contains('22.50 hrs.') && e.synopsis.contains('clue')), isTrue);
      expect(lines.any((e) => e.noAndHour.contains('22.55 hrs.') && e.synopsis.contains('Local enquiry')), isTrue);
      expect(lines.any((e) => e.noAndHour.contains('23.15 hrs.') && e.synopsis.contains('from PO')), isTrue);
      expect(body, isNot(contains(answers['cd1_complainant_statement']!)));

      final linked = StatementLinkService().buildLinkedStatements(
        caseFile: caseFile,
        profile: OfficerProfile.empty().copyWith(
          name: 'Partha Sarathi Chowdhury',
          rank: 'SI',
          policeStation: 'Kalna PS',
          district: 'Purba Bardhaman',
        ),
        plan: plan,
        cdNumber: 1,
        cdDate: '2026-07-25',
        answers: answers,
      );
      expect(linked.length, 1);
      expect(linked.single.witnessName, 'Subhankar Biswas');
      expect(linked.single.linkedFromCd, isTrue);
      expect(linked.single.sourceCdNumber, 1);
      expect(linked.single.body, answers['cd1_complainant_statement']);
    });

    test('CD-II recommends road-accident pending actions and drafts medical + vehicle verification', () {
      final workflow = CdWorkflowService();
      final draft = CdWorkflowDraftService();
      final validator = CdWorkflowValidationService();
      final caseFile = _case605();

      final plan = workflow.buildPlan(
        caseFile: caseFile,
        cdNumber: 2,
        completedActions: const <String>{CdWorkflowService.actionPoVisit},
      );
      expect(plan.recommendedActionIds, contains(CdWorkflowService.actionInjuryMedicalPapers));
      expect(plan.recommendedActionIds, contains(CdWorkflowService.actionVehicleDriverVerification));
      expect(plan.recommendedActionIds, contains(CdWorkflowService.actionWitnessExamination));

      const answers = <String, String>{
        'today_actions': 'injury_medical_papers,vehicle_driver_verification',
        'injury_doc_departure_time': '10.30 hrs.',
        'injury_doc_arrival_time': '10.50 hrs.',
        'injury_doc_action_time': '11.10 hrs.',
        'injury_doc_departure_hospital_time': '11.40 hrs.',
        'injury_doc_return_ps_time': '12.05 hrs.',
        'injury_doc_hospital': 'Kalna SD & SS Hospital',
        'injury_doc_step': 'Submitted requisition for Injury Report/BHT/medical papers.',
        'injury_doc_collected': 'no',
        'vehicle_verify_time': '12.25 hrs.',
        'vehicle_number': 'WB16BM/6158',
        'vehicle_owner_driver_status': 'Registered owner/actual driver particulars are under verification.',
        'vehicle_found': 'no',
        'vehicle_step_taken': 'Necessary verification/search steps taken.',
        'continuation_return_time': '13.10 hrs.',
      };

      final issues = validator.validate(plan: plan, answers: answers);
      expect(issues.where((e) => e.isError), isEmpty);

      final previous = CdEntry.newDraft(
        caseId: caseFile.id,
        cdNumber: 1,
        body: 'Previous CD-I',
        placeOfEntry: 'Kalna PS',
      ).copyWith(cdDate: '2026-07-25');
      final lines = draft.buildTableLines(
        caseFile: caseFile,
        plan: plan,
        answers: answers,
        defaultPlace: 'Kalna PS',
        previousCd: previous,
      );
      final text = lines.map((e) => e.proceedings).join('\n');
      expect(text, contains('Kalna SD & SS Hospital'));
      expect(text, contains('medical papers are awaited'));
      expect(text, contains('returned to PS'));
      expect(text, contains('WB16BM/6158'));
      expect(text, contains('actual driver'));
    });
  });
}
