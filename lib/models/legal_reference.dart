enum LegalCode { bns, bnss }

enum LegalSourceTier { officialVerified, comparisonIndex }

extension LegalCodeX on LegalCode {
  String get shortName => this == LegalCode.bns ? 'BNS' : 'BNSS';
  String get fullName => this == LegalCode.bns
      ? 'Bharatiya Nyaya Sanhita, 2023'
      : 'Bharatiya Nagarik Suraksha Sanhita, 2023';
  String get oldCodeName => this == LegalCode.bns ? 'IPC' : 'CrPC';
  String get actNumber => this == LegalCode.bns ? '45 of 2023' : '46 of 2023';
}

class LegalIndexRecord {
  final LegalCode code;
  final String section;
  final String titleEn;
  final String oldSection;
  final String comparisonNote;

  const LegalIndexRecord({
    required this.code,
    required this.section,
    required this.titleEn,
    required this.oldSection,
    required this.comparisonNote,
  });

  String get key => '${code.shortName}:$section';
}

class VerifiedLegalText {
  final LegalCode code;
  final String section;
  final String titleEn;
  final String officialTextEn;
  final String bengaliGuide;
  final String sourceLabel;
  final String sourceUrl;
  final bool isFullSectionText;

  const VerifiedLegalText({
    required this.code,
    required this.section,
    required this.titleEn,
    required this.officialTextEn,
    required this.bengaliGuide,
    required this.sourceLabel,
    required this.sourceUrl,
    this.isFullSectionText = false,
  });

  String get key => '${code.shortName}:$section';
}

class LegalSearchResult {
  final LegalIndexRecord index;
  final VerifiedLegalText? verified;
  final int score;

  const LegalSearchResult({
    required this.index,
    required this.verified,
    required this.score,
  });

  bool get hasVerifiedOfficialText => verified != null;
}
