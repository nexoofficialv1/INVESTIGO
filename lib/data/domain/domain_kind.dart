enum DomainKind {
  caseInvestigation,
  udCase,
  ncr,
}

extension DomainKindName on DomainKind {
  String get storageNamespace => switch (this) {
        DomainKind.caseInvestigation => 'case_investigation',
        DomainKind.udCase => 'ud_case',
        DomainKind.ncr => 'ncr',
      };
}
