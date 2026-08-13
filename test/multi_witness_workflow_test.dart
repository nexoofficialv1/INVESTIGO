import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/models/witness_examination_entry.dart';
import 'package:investigo/services/cd_workflow_draft_service.dart';
import 'package:investigo/services/cd_workflow_service.dart';
import 'package:investigo/services/cd_workflow_validation_service.dart';
import 'package:investigo/services/statement_link_service.dart';

CaseFile _case() => CaseFile.empty(ioName: 'SI Test').copyWith(
      psCaseNo: '326/2026',
      caseDate: '2026-05-13',
      sections: '25/27 Arms Act',
      crimeHead: 'Arms',
      placeOfOccurrence: 'Open field near Nandai petrol pump',
      complainantName: 'SI Test Complainant',
    );

OfficerProfile _profile() => OfficerProfile.empty().copyWith(
      name: 'Test Officer',
      rank: 'SI',
      policeStation: 'Kalna PS',
      district: 'Purba Bardhaman',
    );

WitnessExaminationEntry _witness({
  required String id,
  required String name,
  required String time,
  String place = 'Kalna PS',
  String role = 'Police Witness',
  bool recorded = true,
  String body = 'I state the material facts in my own words.',
}) {
  return WitnessExaminationEntry(
    id: id,
    witnessName: name,
    witnessDetails: 'S/o Test, Vill-Test, PS Kalna',
    role: role,
    recordedTime: time,
    recordedPlace: place,
    statementRecorded: recorded,
    statementBody: recorded ? body : '',
  );
}

void main() {
  group('v203 Multi-Witness workflow', () {
    test('workflow uses a witness repeater instead of one fixed witness form', () {
      final plan = CdWorkflowService().buildPlan(caseFile: _case(), cdNumber: 3);
      final repeater = plan.questions.where((q) => q.id == 'witness_entries_json');
      expect(repeater.length, 1);
      expect(repeater.single.type.name, 'witnessRepeater');
      expect(plan.questions.any((q) => q.id == 'witness_name'), isFalse);
    });

    test('batch JSON round-trip preserves multiple witnesses', () {
      final batch = MultiWitnessBatch(
        mode: WitnessCdEntryMode.separate,
        entries: <WitnessExaminationEntry>[
          _witness(id: 'w1', name: 'Witness One', time: '18.45 hrs.'),
          _witness(id: 'w2', name: 'Witness Two', time: '18.55 hrs.'),
        ],
      );
      final decoded = MultiWitnessBatch.decode(batch.encode());
      expect(decoded.mode, WitnessCdEntryMode.separate);
      expect(decoded.entries.length, 2);
      expect(decoded.entries.last.witnessName, 'Witness Two');
    });

    test('separate mode creates one chronological CD line per witness', () {
      final plan = CdWorkflowService().buildPlan(caseFile: _case(), cdNumber: 3);
      final batch = MultiWitnessBatch(
        entries: <WitnessExaminationEntry>[
          _witness(id: 'w2', name: 'Witness Two', time: '18.55 hrs.'),
          _witness(id: 'w1', name: 'Witness One', time: '18.45 hrs.'),
        ],
      );
      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        answers: <String, String>{
          'today_actions': CdWorkflowService.actionWitnessExamination,
          'witness_entries_json': batch.encode(),
          'continuation_return_time': '19.30 hrs.',
        },
      );

      final witnessLines = lines
          .where((line) => line.synopsis.contains('u/s-180 BNSS'))
          .toList(growable: false);
      expect(witnessLines.length, 2);
      expect(witnessLines.first.noAndHour, contains('18.45 hrs.'));
      expect(witnessLines.first.proceedings, contains('Witness One'));
      expect(witnessLines.last.proceedings, contains('Witness Two'));
    });

    test('grouped same-session mode creates one CD entry but separate statements', () {
      final plan = CdWorkflowService().buildPlan(caseFile: _case(), cdNumber: 3);
      final batch = MultiWitnessBatch(
        mode: WitnessCdEntryMode.groupedSameSession,
        entries: <WitnessExaminationEntry>[
          _witness(id: 'w1', name: 'ASI Witness One', time: '20.25 hrs.'),
          _witness(id: 'w2', name: 'C/100 Witness Two', time: '20.25 hrs.'),
        ],
      );
      final answers = <String, String>{
        'today_actions': CdWorkflowService.actionWitnessExamination,
        'witness_entries_json': batch.encode(),
        'continuation_return_time': '21.00 hrs.',
      };

      final lines = CdWorkflowDraftService().buildTableLines(
        caseFile: _case(),
        plan: plan,
        defaultPlace: 'Kalna PS',
        answers: answers,
      );
      final groupLines = lines
          .where((line) => line.proceedings.contains('below noted witnesses'))
          .toList(growable: false);
      expect(groupLines.length, 1);
      expect(groupLines.single.proceedings, contains('(1) ASI Witness One'));
      expect(groupLines.single.proceedings, contains('(2) C/100 Witness Two'));

      final statements = StatementLinkService().buildLinkedStatements(
        caseFile: _case(),
        profile: _profile(),
        plan: plan,
        cdNumber: 3,
        cdDate: '2026-05-15',
        answers: answers,
      );
      expect(statements.length, 2);
      expect(statements.map((e) => e.sourceKey).toSet().length, 2);
      expect(statements.every((e) => e.sourceActionId.contains(e.witnessName == 'ASI Witness One' ? 'w1' : 'w2')), isTrue);
    });

    test('statement not recorded is not fabricated as a separate statement sheet', () {
      final plan = CdWorkflowService().buildPlan(caseFile: _case(), cdNumber: 3);
      final batch = MultiWitnessBatch(
        entries: <WitnessExaminationEntry>[
          _witness(id: 'w1', name: 'Witness One', time: '10.00 hrs.'),
          _witness(
            id: 'w2',
            name: 'Witness Two',
            time: '10.10 hrs.',
            recorded: false,
          ),
        ],
      );
      final statements = StatementLinkService().buildLinkedStatements(
        caseFile: _case(),
        profile: _profile(),
        plan: plan,
        cdNumber: 3,
        cdDate: '2026-05-15',
        answers: <String, String>{
          'today_actions': CdWorkflowService.actionWitnessExamination,
          'witness_entries_json': batch.encode(),
        },
      );
      expect(statements.length, 1);
      expect(statements.single.witnessName, 'Witness One');
    });

    test('grouped mode blocks different time/place and closing overflow', () {
      final plan = CdWorkflowService().buildPlan(caseFile: _case(), cdNumber: 3);
      final batch = MultiWitnessBatch(
        mode: WitnessCdEntryMode.groupedSameSession,
        entries: <WitnessExaminationEntry>[
          _witness(id: 'w1', name: 'Witness One', time: '18.20 hrs.'),
          _witness(
            id: 'w2',
            name: 'Witness Two',
            time: '19.40 hrs.',
            place: 'PO',
          ),
        ],
      );
      final issues = CdWorkflowValidationService().validate(
        plan: plan,
        answers: <String, String>{
          'today_actions': CdWorkflowService.actionWitnessExamination,
          'witness_entries_json': batch.encode(),
          'continuation_return_time': '19.00 hrs.',
        },
      );
      expect(issues.any((e) => e.isError && e.messageEn.contains('Grouped Same-Session')), isTrue);
      expect(issues.any((e) => e.isError && e.messageEn.contains('after the CD closing time')), isTrue);
    });
  });
}
