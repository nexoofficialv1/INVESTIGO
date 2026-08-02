import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/final_case_documents.dart';

void main() {
  test('final case drafts preserve separate approval states', () {
    final finalCd = FinalCdDraft.empty('case-1').copyWith(approved: true);
    final chargeSheet = ChargeSheetDraft.empty('case-1');
    final if5 = If5Draft.empty('case-1');

    expect(finalCd.approved, isTrue);
    expect(chargeSheet.approved, isFalse);
    expect(if5.approved, isFalse);
  });

  test('draft JSON remains case scoped', () {
    final draft = ChargeSheetDraft.empty('case-44').copyWith(
      courtName: 'Ld. ACJM',
      chargeSheetNo: '12/26',
      approved: true,
    );
    final restored = ChargeSheetDraft.fromJson(draft.toJson());

    expect(restored.caseId, 'case-44');
    expect(restored.courtName, 'Ld. ACJM');
    expect(restored.approved, isTrue);
  });
}
