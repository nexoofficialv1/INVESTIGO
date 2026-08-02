import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/data/domain/case_investigation_store.dart';
import 'package:investigo/data/domain/domain_kind.dart';
import 'package:investigo/data/domain/ncr_store.dart';
import 'package:investigo/data/domain/ud_case_store.dart';

void main() {
  test('regular case, UD and NCR use distinct domain namespaces', () {
    expect(
      {
        CaseInvestigationStore().domain.storageNamespace,
        UdCaseStore().domain.storageNamespace,
        NcrStore().domain.storageNamespace,
      },
      hasLength(3),
    );
  });

  test('domain names remain stable for storage and migration records', () {
    expect(
      DomainKind.caseInvestigation.storageNamespace,
      'case_investigation',
    );
    expect(DomainKind.udCase.storageNamespace, 'ud_case');
    expect(DomainKind.ncr.storageNamespace, 'ncr');
  });
}
