import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/cd_entry.dart';
import 'package:investigo/models/cd_workflow.dart';
import 'package:investigo/services/cd_workflow_draft_service.dart';
import 'package:investigo/services/cd_workflow_service.dart';

CaseFile _case({String sections = '25/27 Arms Act'}) {
  return CaseFile.empty(ioName: 'SI Test Officer').copyWith(
    psCaseNo: '326/2026',
    sections: sections,
    crimeHead: 'Arms',
    placeOfOccurrence: 'Kharinan, Kalna',
    dateTimeOccurrence: '13.05.2026 at 00.45 hrs',
    dateTimeReporting: '13.05.2026 at 02.45 hrs',
    complainantName: 'SI Test Complainant',
    firGist: 'illegal firearm was recovered from the accused.',
  );
}

void main() {
  group('CD workflow draft service', () {
    test('CD-I builds FIR, complainant, PO and closing lines', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 1);
      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        answers: const <String, String>{
          'cd1_fir_receive_time': '07.00 hrs.',
          'cd1_departure_time': '07.15 hrs.',
          'cd1_first_arrival_time': '07.45 hrs.',
          'cd1_first_arrival_place': 'Kalna PS campus',
          'cd1_ro': 'SI Test RO',
          'cd1_fir_received': 'yes',
          'cd1_complainant_examined': 'yes',
          'cd1_complainant_exam_time': '07.50 hrs.',
          'cd1_complainant_statement_recorded': 'yes',
          'cd1_complainant_statement': 'Material facts stated by complainant.',
          'cd1_left_for_po': 'yes',
          'cd1_po_departure_time': '08.00 hrs.',
          'cd1_po_arrival_time': '08.30 hrs.',
          'cd1_po_exact': 'Kharinan field beside village road',
          'cd1_po_shown_by': 'the complainant',
          'cd1_sketch_index': 'yes',
          'cd1_po_north': 'House of A',
          'cd1_po_south': 'Pond',
          'cd1_po_east': 'Village road',
          'cd1_po_west': 'Vacant land',
          'cd1_clue_search': 'yes',
          'cd1_local_witness_search': 'yes',
          'cd1_return_time': '09.30 hrs.',
        },
      );

      final body = lines.map((e) => e.proceedings).join('\n');
      expect(body, contains('received copy of FIR'));
      expect(body, contains('recorded the statement u/s-180 BNSS'));
      expect(body, contains('rough sketch map'));
      expect(body, contains('Closed the diary pending'));
      expect(lines.first.noAndHour, startsWith('I\n'));
    });

    test('continuation CD uses selected action only', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 3);
      final previous = CdEntry.newDraft(
        caseId: _case().id,
        cdNumber: 2,
        body: 'previous',
      ).copyWith(cdDate: '14.05.2026');
      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        previousCd: previous,
        answers: const <String, String>{
          'today_actions': CdWorkflowService.actionRecoverySeizure,
          'recovery_time': '18.20 hrs.',
          'recovery_place': 'Kharinan field',
          'recovery_basis': 'leading statement of PC accused',
          'recovery_article': 'One round .303 live ammunition',
          'recovery_witness_custody': 'Witness A and Witness B; kept in malkhana',
          'continuation_return_time': '20.25 hrs.',
        },
      );

      final body = lines.map((e) => e.proceedings).join('\n');
      expect(body, contains('CD No-II'));
      expect(body, contains('One round .303 live ammunition'));
      expect(body, isNot(contains('medical/medico-legal')));
    });

    test('complex continuation action is split and chronologically sorted', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(caseFile: _case(), cdNumber: 4);
      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        answers: const <String, String>{
          'today_actions':
              '${CdWorkflowService.actionRaidSearch},${CdWorkflowService.actionRecoverySeizure}',
          'raid_departure': '17.10 hrs.',
          'raid_arrival_time': '17.40 hrs.',
          'raid_place': 'Kharinan field',
          'raid_place_force_result': 'Raid held with force and PC accused.',
          'recovery_time': '18.05 hrs.',
          'recovery_place': 'Kharinan field',
          'recovery_basis': 'showing of PC accused',
          'recovery_article': 'One live cartridge',
          'recovery_witness_custody': 'Witness A and B; kept in malkhana',
          'continuation_return_time': '19.10 hrs.',
        },
      );

      expect(lines.first.synopsis, contains('R/I'));
      expect(lines.first.synopsis, contains('Dept'));
      expect(lines[1].noAndHour, contains('17.40 hrs.'));
      expect(lines[2].noAndHour, contains('18.05 hrs.'));
      expect(lines[2].synopsis, contains('Recovery'));
      expect(lines.last.noAndHour, contains('19.10 hrs.'));
      expect(lines.last.synopsis, contains('Closing'));
    });

    test('finalisation builds charge and closing sequence', () {
      final workflow = CdWorkflowService();
      final plan = workflow.buildPlan(
        caseFile: _case(),
        cdNumber: 9,
        finalisationRequested: true,
      );
      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        answers: const <String, String>{
          'final_superior_order': 'MOE approved by superior officer.',
          'final_sections': '25/27 Arms Act',
          'final_accused_status': 'Accused A - forwarded and in judicial custody',
          'final_investigation_summary': 'PO visited; witnesses examined; expert report collected.',
          'final_supplementary_provision': 'yes',
          'final_witnesses': '1. Complainant 2. Seizure witness 3. IO',
          'final_complainant_informed': 'yes',
          'final_cs_number_date': 'No. 100/2026 dated 20.05.2026',
        },
      );

      final body = lines.map((e) => e.proceedings).join('\n');
      expect(body, contains('prima facie charge'));
      expect(body, contains('supplementary charge sheet/report'));
      expect(body, contains('Closed the diary as well as investigation'));
    });
  });
}
