import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/form_notice.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/models/structured_bnss_form.dart';
import 'package:investigo/services/structured_bnss_forms_service.dart';

void main() {
  final service = StructuredBnssFormsService();
  final officer = OfficerProfile.empty().copyWith(
    name: 'Partha Sarathi Chowdhury',
    rank: 'SI of Police',
    policeStation: 'Kalna PS',
    district: 'Purba Bardhaman',
    defaultHospital: 'Kalna SD & SS Hospital',
    defaultFslOffice: 'RFSL, Durgapur',
  );
  final caseFile = CaseFile.empty(ioName: officer.name).copyWith(
    psCaseNo: '605/2026',
    caseDate: '2026-07-25',
    sections: '281/125(b)/324(4) BNS',
    crimeHead: 'Road Traffic Accident',
    complainantName: 'Subhankar Biswas',
    accusedName: 'Driver of WB16BM/6158',
    firGist: 'Road traffic accident involving motorcycle WB44G/7311 and vehicle WB16BM/6158.',
  );

  test('35(3) schema contains date/time and service tracking', () {
    final schema = service.schemaFor('bnss_35_3_appearance__en');
    expect(schema.fields.any((e) => e.key == 'appearanceDate' && e.type == StructuredFormFieldType.date), isTrue);
    expect(schema.fields.any((e) => e.key == 'appearanceTime' && e.type == StructuredFormFieldType.time), isTrue);
    expect(schema.fields.any((e) => e.key == 'serviceStatus'), isTrue);
    expect(schema.fields.any((e) => e.key == 'acknowledgedBy'), isTrue);
  });

  test('arrest memo preserves unlabeled source row and checklist grounds', () {
    final schema = service.schemaFor('bnss_35_arrest_memo__en');
    expect(schema.fields.any((e) => e.key == 'sourceRow5'), isTrue);
    final grounds = schema.fields.firstWhere((e) => e.key == 'grounds');
    expect(grounds.type, StructuredFormFieldType.checklist);
    expect(grounds.options.length, greaterThanOrEqualTo(5));
  });

  test('94 notice has repeating document/thing rows', () {
    final schema = service.schemaFor('bnss_94_production__bn');
    final rows = schema.rowGroups.firstWhere((e) => e.key == 'productionItems');
    expect(rows.minRows, 3);
  });

  test('FSL has exhibit rows and receipt tracking', () {
    final schema = service.schemaFor('fsl_forwarding_reference__en');
    expect(schema.rowGroups.any((e) => e.key == 'fslExhibits'), isTrue);
    expect(schema.fields.any((e) => e.key == 'ackStatus'), isTrue);
    expect(schema.fields.any((e) => e.key == 'ackNo'), isTrue);
  });

  test('English and Bengali bodies render from same structured facts', () {
    var state = service.initialState(
      templateId: 'bnss_94_production__en',
      officer: officer,
      caseFile: caseFile,
    );
    final values = Map<String, String>.from(state.values)
      ..['recipientName'] = 'Medical Superintendent'
      ..['recipientAddress'] = 'Kalna SD & SS Hospital'
      ..['productionDate'] = '2026-07-26'
      ..['productionTime'] = '11:00'
      ..['productionPlace'] = 'Kalna PS';
    final rows = {for (final e in state.rows.entries) e.key: e.value.map((r) => Map<String, String>.from(r)).toList()};
    rows['productionItems']![0]['description'] = 'Injury Report';
    rows['productionItems']![1]['description'] = 'BHT';
    rows['productionItems']![2]['description'] = 'Treatment papers';
    state = state.copyWith(values: values, rows: rows);

    final en = service.renderBody(templateId: 'bnss_94_production__en', officer: officer, caseFile: caseFile, state: state);
    final bn = service.renderBody(templateId: 'bnss_94_production__bn', officer: officer, caseFile: caseFile, state: state);
    expect(en, contains('Injury Report'));
    expect(en, contains('NOTICE / WRITTEN ORDER'));
    expect(bn, contains('ধারা 94 BNSS'));
    expect(bn, contains('Injury Report'));
  });

  test('final validation blocks required row gaps', () {
    final state = service.initialState(
      templateId: 'bnss_94_production__en',
      officer: officer,
      caseFile: caseFile,
    );
    expect(service.validate('bnss_94_production__en', state), isNotEmpty);
  });

  test('structured form CD link carries tracked date/time/place', () {
    var state = service.initialState(
      templateId: 'bnss_35_3_appearance__en',
      officer: officer,
      caseFile: caseFile,
    );
    final values = Map<String, String>.from(state.values)
      ..['recipientName'] = 'Driver of WB16BM/6158'
      ..['recipientAddress'] = 'Known address'
      ..['appearanceDate'] = '2026-07-27'
      ..['appearanceTime'] = '10:30'
      ..['appearancePlace'] = 'Kalna PS'
      ..['serviceStatus'] = 'Served'
      ..['serviceDate'] = '2026-07-26'
      ..['serviceTime'] = '18:20'
      ..['servedAt'] = 'Kalna PS';
    state = state.copyWith(values: values);
    final form = FormNotice.create(
      caseId: caseFile.id,
      templateId: 'bnss_35_3_appearance__en',
      title: '35(3) Notice',
      body: '',
      workflowData: state.toJson(),
    );
    expect(service.cdActionDate(form), '2026-07-26');
    expect(service.cdActionTime(form), '18:20');
    expect(service.cdPlace(form, officer), 'Kalna PS');
    expect(service.cdParagraph(form), contains('Served notice'));
  });
}
