import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/pending_cd_action.dart';

void main() {
  test('pending CD action preserves official row metadata', () {
    final action = PendingCdAction.create(
      caseId: 'case-1',
      sourceType: 'Investigation Assistant',
      sourceId: 'action-1',
      title: 'PO Visit',
      actionDate: '2026-08-02',
      entryTime: '10:30 hrs.',
      placeOfEntry: 'Village Khaspur',
      synopsis: 'PO Visit + Local enquiry',
      paragraph: 'Visited the place of occurrence and held local enquiry.',
    );

    final restored = PendingCdAction.fromJson(action.toJson());
    expect(restored.entryTime, '10:30 hrs.');
    expect(restored.placeOfEntry, 'Village Khaspur');
    expect(restored.synopsis, 'PO Visit + Local enquiry');
    expect(restored.paragraph, contains('place of occurrence'));
  });

  test('old pending action JSON remains backward compatible', () {
    final restored = PendingCdAction.fromJson({
      'id': 'old-1',
      'caseId': 'case-1',
      'sourceType': 'Old Form',
      'sourceId': 'source-1',
      'title': 'Witness statement recorded',
      'actionDate': '2026-08-01',
      'paragraph': 'Examined one witness.',
      'consumed': false,
    });

    expect(restored.entryTime, isEmpty);
    expect(restored.placeOfEntry, isEmpty);
    expect(restored.synopsis, 'Witness statement recorded');
  });
}
