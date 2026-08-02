class UdNarrationAnalysisResult {
  final Map<String, String> values;
  final List<String> warnings;

  const UdNarrationAnalysisResult({
    required this.values,
    required this.warnings,
  });

  int get populatedFieldCount =>
      values.values.where((value) => value.trim().isNotEmpty).length;
}

/// Deterministic offline parser for a single UD/inquest narration.
///
/// The narration remains the source of truth in `briefFacts`; recognised facts
/// are copied into the shared UD model used by the inquest report, dead-body
/// challan and final report.
class UdNarrationService {
  UdNarrationAnalysisResult analyse(String narration) {
    final source = narration.trim();
    if (source.isEmpty) {
      return const UdNarrationAnalysisResult(
        values: <String, String>{},
        warnings: <String>['UD/Inquest narration লিখুন।'],
      );
    }

    final values = <String, String>{'briefFacts': source};
    final warnings = <String>[];

    void capture(String key, List<RegExp> patterns) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(source);
        final value = match?.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          values[key] = _clean(value);
          return;
        }
      }
    }

    capture('udNo', <RegExp>[
      RegExp(
        r'(?:UD|U\.D\.|ইউডি)\s*(?:Case\s*)?(?:No\.?|নং|নম্বর)?\s*[:\-]?\s*([^,;।\n]{1,35})',
        caseSensitive: false,
      ),
    ]);
    capture('gdeNo', <RegExp>[
      RegExp(
        r'(?:GDE|G\.D\.E\.|জিডিই|জিডি)\s*(?:No\.?|নং|নম্বর)?\s*[:\-]?\s*([^,;।\n]{1,45})',
        caseSensitive: false,
      ),
    ]);
    capture('dateTime', <RegExp>[
      RegExp(
        r'(?:Date\s*(?:&|and)?\s*Time|তারিখ\s*(?:ও|এবং)?\s*সময়|তারিখ\s*(?:ও|এবং)?\s*সময়)\s*[:\-]?\s*([^;।\n]{3,50})',
        caseSensitive: false,
      ),
    ]);
    capture('placeFound', <RegExp>[
      RegExp(
        r'(?:Place where (?:the )?dead body (?:was )?found|মৃতদেহ (?:যেখানে|যে স্থানে) পাওয়া যায়|মৃতদেহ পাওয়ার স্থান|মৃতদেহ পাওয়ার স্থান|ঘটনাস্থল)\s*[:\-]?\s*([^;।\n]{3,140})',
        caseSensitive: false,
      ),
    ]);
    capture('distanceFromPs', <RegExp>[
      RegExp(
        r'(?:Distance from (?:the )?P\.?S\.?|থানা থেকে দূরত্ব)\s*[:\-]?\s*([^,;।\n]{1,60})',
        caseSensitive: false,
      ),
    ]);
    capture('directionFromPs', <RegExp>[
      RegExp(
        r'(?:Direction from (?:the )?P\.?S\.?|থানা থেকে দিক)\s*[:\-]?\s*([^,;।\n]{1,60})',
        caseSensitive: false,
      ),
    ]);
    capture('informantName', <RegExp>[
      RegExp(
        r'(?:Informant(?: Name)?|সংবাদদাতার নাম|খবরদাতার নাম)\s*[:\-]?\s*([^,;।\n]{2,100})',
        caseSensitive: false,
      ),
    ]);
    capture('informantAddress', <RegExp>[
      RegExp(
        r'(?:Informant Address|সংবাদদাতার ঠিকানা|খবরদাতার ঠিকানা)\s*[:\-]?\s*([^;।\n]{3,160})',
        caseSensitive: false,
      ),
    ]);
    capture('identifiedByName', <RegExp>[
      RegExp(
        r'(?:Identified by|Identifier(?: Name)?|মৃতদেহ সনাক্তকারী(?:র নাম)?|সনাক্তকারীর নাম)\s*[:\-]?\s*([^,;।\n]{2,100})',
        caseSensitive: false,
      ),
    ]);
    capture('identifiedByAddress', <RegExp>[
      RegExp(
        r'(?:Identifier Address|সনাক্তকারীর ঠিকানা)\s*[:\-]?\s*([^;।\n]{3,160})',
        caseSensitive: false,
      ),
    ]);
    capture('identifiedByRelation', <RegExp>[
      RegExp(
        r'(?:Relation with deceased|Relation|মৃতের সঙ্গে সম্পর্ক|সম্পর্ক)\s*[:\-]?\s*([^,;।\n]{2,60})',
        caseSensitive: false,
      ),
    ]);
    capture('deceasedName', <RegExp>[
      RegExp(
        r'(?:Name of (?:the )?deceased|Deceased(?: Name)?|মৃত ব্যক্তির নাম|মৃতের নাম)\s*[:\-]?\s*([^,;।\n]{2,120})',
        caseSensitive: false,
      ),
    ]);
    capture('deceasedAge', <RegExp>[
      RegExp(
        r'(?:Age of (?:the )?deceased|Deceased Age|মৃতের বয়স|মৃতের বয়স|আনুমানিক বয়স|আনুমানিক বয়স)\s*[:\-]?\s*([^,;।\n]{1,30})',
        caseSensitive: false,
      ),
    ]);
    capture('deceasedSex', <RegExp>[
      RegExp(
        r'(?:Sex of (?:the )?deceased|Deceased Sex|মৃতের লিঙ্গ|লিঙ্গ)\s*[:\-]?\s*(Male|Female|Other|পুরুষ|মহিলা|নারী|অন্যান্য)',
        caseSensitive: false,
      ),
    ]);
    capture('deceasedAddress', <RegExp>[
      RegExp(
        r'(?:Address of (?:the )?deceased|Deceased Address|মৃতের ঠিকানা)\s*[:\-]?\s*([^;।\n]{3,180})',
        caseSensitive: false,
      ),
    ]);
    capture('bodyPosition', <RegExp>[
      RegExp(
        r'(?:Position of (?:the )?dead body|Body position|মৃতদেহের অবস্থান|দেহের অবস্থান)\s*[:\-]?\s*([^;।\n]{3,220})',
        caseSensitive: false,
      ),
    ]);
    capture('rigorMortis', <RegExp>[
      RegExp(
        r'(?:Rigor Mortis|রিগর মর্টিস|শবকাঠিন্য)\s*[:\-]?\s*([^,;।\n]{2,100})',
        caseSensitive: false,
      ),
    ]);
    capture('dress', <RegExp>[
      RegExp(
        r'(?:Dress|Wearing apparel|পরনের পোশাক|পোশাক)\s*[:\-]?\s*([^;।\n]{2,180})',
        caseSensitive: false,
      ),
    ]);
    capture('otherFeatures', <RegExp>[
      RegExp(
        r'(?:Other features|Other identification marks|অন্যান্য বৈশিষ্ট্য|সনাক্তকরণ চিহ্ন)\s*[:\-]?\s*([^;।\n]{2,200})',
        caseSensitive: false,
      ),
    ]);
    capture('poDescription', <RegExp>[
      RegExp(
        r'(?:Description of (?:the )?(?:place of occurrence|place found)|ঘটনাস্থলের বিবরণ|স্থানটির বিবরণ)\s*[:\-]?\s*([^;।\n]{3,240})',
        caseSensitive: false,
      ),
    ]);
    capture('articlesAtPo', <RegExp>[
      RegExp(
        r'(?:Articles at P\.?O\.?|Articles found at the spot|ঘটনাস্থলে পাওয়া সামগ্রী|ঘটনাস্থলে পাওয়া সামগ্রী|ঘটনাস্থলের আলামত)\s*[:\-]?\s*([^;।\n]{2,220})',
        caseSensitive: false,
      ),
    ]);
    capture('probableCauseOfDeath', <RegExp>[
      RegExp(
        r'(?:Probable cause of death|Cause of death|সম্ভাব্য মৃত্যুর কারণ|মৃত্যুর কারণ)\s*[:\-]?\s*([^;।\n]{2,180})',
        caseSensitive: false,
      ),
    ]);
    capture('witness1NameAddress', <RegExp>[
      RegExp(
        r'(?:Witness\s*(?:1|I)|সাক্ষী\s*(?:১|1|এক))\s*[:\-]?\s*([^;।\n]{2,180})',
        caseSensitive: false,
      ),
    ]);
    capture('witness2NameAddress', <RegExp>[
      RegExp(
        r'(?:Witness\s*(?:2|II)|সাক্ষী\s*(?:২|2|দুই))\s*[:\-]?\s*([^;।\n]{2,180})',
        caseSensitive: false,
      ),
    ]);

    final injurySentence = _firstSentenceContaining(source, <String>[
      'injury',
      'আঘাত',
      'ক্ষত',
      'রক্ত',
    ]);
    if (injurySentence.isNotEmpty) {
      values['injuryOther'] = injurySentence;
    }

    final dischargeSentence = _firstSentenceContaining(source, <String>[
      'discharge',
      'নাক',
      'মুখ',
      'কান',
      'anus',
      'vagina',
      'penis',
    ]);
    if (dischargeSentence.isNotEmpty) {
      values['foreignMaterial'] = dischargeSentence;
    }

    if (!values.containsKey('deceasedName')) {
      warnings.add('মৃত ব্যক্তির নাম শনাক্ত হয়নি।');
    }
    if (!values.containsKey('placeFound')) {
      warnings.add('মৃতদেহ পাওয়ার স্থান শনাক্ত হয়নি।');
    }
    if (!values.containsKey('probableCauseOfDeath')) {
      warnings.add('সম্ভাব্য মৃত্যুর কারণ শনাক্ত হয়নি; প্রয়োজন হলে হাতে পূরণ করুন।');
    }

    return UdNarrationAnalysisResult(values: values, warnings: warnings);
  }

  String _firstSentenceContaining(String source, List<String> keywords) {
    for (final sentence in source.split(RegExp(r'(?<=[।.!?])\s+|\n+'))) {
      final lower = sentence.toLowerCase();
      if (keywords.any(lower.contains)) return _clean(sentence);
    }
    return '';
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'^[\s:;,-]+|[\s:;,-]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
