enum BnssFormLanguage { english, bengali }

extension BnssFormLanguageX on BnssFormLanguage {
  String get code => this == BnssFormLanguage.bengali ? 'bn' : 'en';
  String get label => this == BnssFormLanguage.bengali ? 'বাংলা' : 'English';
}

class BilingualBnssFormTemplate {
  final String id;
  final String titleEn;
  final String titleBn;
  final String categoryEn;
  final String categoryBn;
  final String sectionRef;
  final String oldLawRef;
  final String sourcePage;
  final String sourceNote;

  const BilingualBnssFormTemplate({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.categoryEn,
    required this.categoryBn,
    required this.sectionRef,
    this.oldLawRef = '',
    this.sourcePage = '',
    this.sourceNote = '',
  });

  String title(BnssFormLanguage language) =>
      language == BnssFormLanguage.bengali ? titleBn : titleEn;

  String category(BnssFormLanguage language) =>
      language == BnssFormLanguage.bengali ? categoryBn : categoryEn;

  String storageId(BnssFormLanguage language) => '${id}__${language.code}';
}
