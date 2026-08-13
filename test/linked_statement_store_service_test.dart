import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:investigo/models/statement_entry.dart';
import 'package:investigo/services/linked_statement_store_service.dart';
import 'package:investigo/services/local_store_service.dart';

StatementEntry _linked(String body) => StatementEntry.create(
      caseId: 'case_1',
      witnessName: 'Witness One',
      witnessDetails: 'Address',
      statementType: 'Eye witness statement u/s 180 BNSS',
      body: body,
      linkedFromCd: true,
      sourceCdNumber: 2,
      sourceActionId: 'witness_examination',
      sourceKey: 'case_1|cd2|witness_examination|witness one',
      recordedDate: '2026-07-26',
      recordedTime: '12.20 hrs.',
      recordedPlace: 'Kalna PS',
      recordedBy: 'SI Test',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('linked statement sync replaces same-CD generated statement instead of duplicating', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final linkedStore = LinkedStatementStoreService();

    await linkedStore.replaceLinkedStatementsForCd(
      caseId: 'case_1',
      cdNumber: 2,
      entries: <StatementEntry>[_linked('First body')],
    );
    await linkedStore.replaceLinkedStatementsForCd(
      caseId: 'case_1',
      cdNumber: 2,
      entries: <StatementEntry>[_linked('Corrected body')],
    );

    final loaded = await LocalStoreService().loadStatements('case_1');
    expect(loaded.length, 1);
    expect(loaded.single.body, 'Corrected body');
    expect(loaded.single.linkedFromCd, isTrue);
  });
}
