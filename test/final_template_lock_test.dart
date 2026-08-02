import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/final_case_documents.dart';
import 'package:investigo/services/official_template_spec.dart';

void main() {
  test('final CD and IF5 template measurements stay locked', () {
    expect(
      OfficialTemplateSpec.finalCdColumnRatios,
      equals(OfficialTemplateSpec.cdColumnRatios),
    );
    expect(
      OfficialTemplateSpec.finalCdColumnRatios,
      equals(const <double>[0.09, 0.09, 0.11, 0.71]),
    );
    expect(OfficialTemplateSpec.if5FormNo, '39');
  });

  test('legacy IF5 JSON receives safe defaults', () {
    final draft = If5Draft.fromJson({'caseId': 'c1'});
    expect(draft.originalOrSupplementary, 'Original');
    expect(draft.chargeSheetNo, isEmpty);
  });
}
