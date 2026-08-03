import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/services/local_store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('two different cases are stored without overwriting', () async {
    final store = LocalStoreService();
    final first = CaseFile.empty(ioName: 'SI Test Officer').copyWith(
      psCaseNo: '101/2026',
      sections: 'Section A',
      complainantName: 'First complainant',
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));

    final second = CaseFile.empty(ioName: 'SI Test Officer').copyWith(
      psCaseNo: '102/2026',
      sections: 'Section B',
      complainantName: 'Second complainant',
    );

    expect(first.id, isNot(second.id));

    await store.saveCase(first);
    await store.saveCase(second);

    final cases = await store.loadCases();
    expect(cases, hasLength(2));
    expect(cases.map((file) => file.id).toSet(), hasLength(2));
    expect(
      cases.map((file) => file.psCaseNo),
      containsAll(<String>['101/2026', '102/2026']),
    );
  });

  test('editing one case keeps the other case intact', () async {
    final store = LocalStoreService();
    final first = CaseFile.empty(ioName: 'SI Test Officer').copyWith(
      psCaseNo: '201/2026',
    );

    await Future<void>.delayed(const Duration(milliseconds: 1));

    final second = CaseFile.empty(ioName: 'SI Test Officer').copyWith(
      psCaseNo: '202/2026',
    );

    await store.saveCase(first);
    await store.saveCase(second);
    await store.saveCase(first.copyWith(sections: 'Updated section'));

    final cases = await store.loadCases();
    expect(cases, hasLength(2));
    expect(
      cases.singleWhere((file) => file.id == first.id).sections,
      'Updated section',
    );
    expect(
      cases.singleWhere((file) => file.id == second.id).psCaseNo,
      '202/2026',
    );
  });
}
