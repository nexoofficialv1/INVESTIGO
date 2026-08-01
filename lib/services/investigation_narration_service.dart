class NarrationActionSuggestion {
  final String actionType;
  final String synopsis;
  final String paragraph;
  final String detectedTime;
  final String detectedPlace;
  final List<String> detectedPersons;
  final bool outsidePs;
  final bool arrestInvolved;
  final bool seizureInvolved;
  final bool suggestsSketchMap;
  final bool suggestsIndex;

  const NarrationActionSuggestion({
    required this.actionType,
    required this.synopsis,
    required this.paragraph,
    this.detectedTime = '',
    this.detectedPlace = '',
    this.detectedPersons = const [],
    this.outsidePs = false,
    this.arrestInvolved = false,
    this.seizureInvolved = false,
    this.suggestsSketchMap = false,
    this.suggestsIndex = false,
  });
}

class NarrationDetectedContext {
  final List<String> times;
  final List<String> places;
  final int? witnessCount;
  final List<String> witnessNames;

  const NarrationDetectedContext({
    this.times = const [],
    this.places = const [],
    this.witnessCount,
    this.witnessNames = const [],
  });

  bool get isEmpty =>
      times.isEmpty &&
      places.isEmpty &&
      witnessCount == null &&
      witnessNames.isEmpty;
}

class NarrationAnalysisResult {
  final List<NarrationActionSuggestion> suggestions;
  final List<String> warnings;
  final NarrationDetectedContext context;
  final bool processedOffline;

  const NarrationAnalysisResult({
    required this.suggestions,
    required this.warnings,
    this.context = const NarrationDetectedContext(),
    this.processedOffline = true,
  });
}

/// Deterministic and fully offline narration parser.
///
/// No network request is made. It creates editable suggestions only and never
/// finalises a diary entry without the investigating officer's approval.
class InvestigationNarrationService {
  NarrationAnalysisResult analyse(String narration) {
    final source = narration.trim();
    if (source.isEmpty) {
      return const NarrationAnalysisResult(
        suggestions: [],
        warnings: ['নিজের ভাষায় তদন্তের বিবরণ লিখুন বা বলুন।'],
      );
    }

    final text = _normalise(source);
    final sentences = _sentences(source);
    final suggestions = <NarrationActionSuggestion>[];
    final warnings = <String>[];

    void add({
      required String actionType,
      required String synopsis,
      required List<String> keywords,
      bool outsidePs = false,
      bool arrestInvolved = false,
      bool seizureInvolved = false,
      bool suggestsSketchMap = false,
      bool suggestsIndex = false,
    }) {
      if (suggestions.any((e) => e.actionType == actionType)) return;
      final matched = _matchingSentences(sentences, keywords);
      final paragraph = matched.isEmpty ? source : matched.join(' ');
      final localTimes = _extractTimes(paragraph);
      final localPlaces = _extractPlaces(paragraph);
      suggestions.add(
        NarrationActionSuggestion(
          actionType: actionType,
          synopsis: synopsis,
          paragraph: paragraph,
          detectedTime: localTimes.isEmpty ? '' : localTimes.first,
          detectedPlace: localPlaces.isEmpty ? '' : localPlaces.first,
          detectedPersons: actionType.contains('Witness')
              ? _extractWitnessNames(paragraph)
              : const [],
          outsidePs: outsidePs,
          arrestInvolved: arrestInvolved,
          seizureInvolved: seizureInvolved,
          suggestsSketchMap: suggestsSketchMap,
          suggestsIndex: suggestsIndex,
        ),
      );
    }

    const poKeywords = [
      'ঘটনাস্থল',
      'po visit',
      'place of occurrence',
      'spot visit',
      'স্থান পরিদর্শন',
    ];
    if (_hasAny(text, poKeywords)) {
      add(
        actionType: 'PO Visit / Local Enquiry',
        synopsis: 'PO Visit',
        keywords: poKeywords,
        outsidePs: true,
      );
    }

    const complainantKeywords = [
      'অভিযোগকারীকে পরীক্ষা',
      'অভিযোগকারীর বিবৃতি',
      'complainant examined',
      'complainant statement',
      'victim examined',
      'ভিকটিমকে পরীক্ষা',
      'বাদীকে পরীক্ষা',
    ];
    if (_hasAny(text, complainantKeywords)) {
      add(
        actionType: 'Complainant Examination / Statement Record',
        synopsis: 'Complainant examined and statement recorded',
        keywords: complainantKeywords,
      );
    }

    const witnessKeywords = [
      'সাক্ষীকে পরীক্ষা',
      'সাক্ষীদের পরীক্ষা',
      'সাক্ষীর বিবৃতি',
      'সাক্ষীদের বিবৃতি',
      'witness examined',
      'witness statement',
      'statement recorded',
    ];
    if (_hasAny(text, witnessKeywords)) {
      add(
        actionType: 'Witness Examination / Statement Record',
        synopsis: 'Witness statement recorded',
        keywords: witnessKeywords,
      );
    }

    const sketchKeywords = [
      'স্কেচ ম্যাপ',
      'স্কেচম্যাপ',
      'rough sketch map',
      'sketch map',
    ];
    const indexKeywords = [
      'ইনডেক্স',
      'index prepared',
      'with index',
      'সূচিপত্র',
    ];
    final sketch = _hasAny(text, sketchKeywords);
    final index = _hasAny(text, indexKeywords);
    if (sketch) {
      add(
        actionType: 'Rough Sketch Map Prepared',
        synopsis: 'Rough sketch map prepared',
        keywords: sketchKeywords,
        outsidePs: true,
        suggestsSketchMap: true,
        suggestsIndex: index,
      );
    }
    if (index) {
      add(
        actionType: 'Index Prepared',
        synopsis: 'Index of sketch map prepared',
        keywords: indexKeywords,
        suggestsIndex: true,
      );
    }

    const raidKeywords = [
      'তল্লাশি',
      'রেড',
      'raid',
      'search conducted',
      'search held',
    ];
    if (_hasAny(text, raidKeywords)) {
      add(
        actionType: 'Raid / Search',
        synopsis: 'Raid and search conducted',
        keywords: raidKeywords,
        outsidePs: true,
      );
    }

    const arrestKeywords = ['গ্রেফতার', 'arrested', 'apprehended', 'আটক'];
    if (_hasAny(text, arrestKeywords)) {
      add(
        actionType: 'Arrest',
        synopsis: 'Accused arrested',
        keywords: arrestKeywords,
        outsidePs: true,
        arrestInvolved: true,
      );
    }

    const seizureKeywords = ['জব্দ', 'seized', 'seizure', 'উদ্ধার করে জব্দ'];
    if (_hasAny(text, seizureKeywords)) {
      add(
        actionType: 'Seizure / Recovery',
        synopsis: 'Article/property seized',
        keywords: seizureKeywords,
        outsidePs: true,
        seizureInvolved: true,
      );
    }

    const requisitionKeywords = [
      'রিকুইজিশন',
      'requisition',
      'প্রার্থনা পাঠালাম',
      'report চাইলাম',
      'রিপোর্ট চাইলাম',
    ];
    if (_hasAny(text, requisitionKeywords)) {
      add(
        actionType: 'Requisition / Prayer Sent',
        synopsis: 'Requisition/prayer sent',
        keywords: requisitionKeywords,
      );
    }

    const reportKeywords = [
      'রিপোর্ট পেলাম',
      'রিপোর্ট সংগ্রহ',
      'report received',
      'report collected',
      'pm report',
      'fsl report',
    ];
    if (_hasAny(text, reportKeywords)) {
      add(
        actionType: 'Report Collection',
        synopsis: 'Report received/collected',
        keywords: reportKeywords,
      );
    }

    const courtKeywords = [
      'কোর্টে পাঠালাম',
      'forwarded to court',
      'court forwarding',
      'আদালতে প্রেরণ',
    ];
    if (_hasAny(text, courtKeywords)) {
      add(
        actionType: 'Court Forwarding',
        synopsis: 'Forwarded to the Ld. Court',
        keywords: courtKeywords,
      );
    }

    const closingKeywords = [
      'তদন্ত বন্ধ',
      'ডায়েরি বন্ধ',
      'ডায়েরি বন্ধ',
      'closed the diary',
      'pending further investigation',
    ];
    if (_hasAny(text, closingKeywords)) {
      add(
        actionType: 'Diary Closing',
        synopsis: 'Closed the diary for the day',
        keywords: closingKeywords,
      );
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        NarrationActionSuggestion(
          actionType: 'Other Investigation Work',
          synopsis: 'Investigation work recorded',
          paragraph: source,
          detectedTime: _extractTimes(source).firstOrNull ?? '',
          detectedPlace: _extractPlaces(source).firstOrNull ?? '',
        ),
      );
      warnings.add(
        'নির্দিষ্ট investigation action শনাক্ত হয়নি। “Other Investigation Work” হিসেবে draft করা হয়েছে—সংরক্ষণের আগে যাচাই করুন।',
      );
    }

    if (sketch && !index) {
      warnings.add(
        'Sketch Map উল্লেখ আছে, কিন্তু Index উল্লেখ নেই। Index এখন তৈরি করা প্রয়োজন কি না যাচাই করুন।',
      );
    }
    if (index && !sketch) {
      warnings.add(
        'Index উল্লেখ আছে, কিন্তু Sketch Map উল্লেখ নেই। সংশ্লিষ্ট Sketch Map link করুন।',
      );
    }

    final context = NarrationDetectedContext(
      times: _extractTimes(source),
      places: _extractPlaces(source),
      witnessCount: _extractWitnessCount(text),
      witnessNames: _extractWitnessNames(source),
    );
    if (context.times.isEmpty) {
      warnings.add('সময় শনাক্ত হয়নি—CD entry save করার আগে সময় যাচাই করুন।');
    }
    if (_hasAny(text, poKeywords) && context.places.isEmpty) {
      warnings.add('PO Visit শনাক্ত হয়েছে, কিন্তু নির্দিষ্ট স্থান শনাক্ত হয়নি।');
    }
    if (_hasAny(text, witnessKeywords) &&
        context.witnessCount == null &&
        context.witnessNames.isEmpty) {
      warnings.add('সাক্ষীর সংখ্যা/নাম শনাক্ত হয়নি—save করার আগে যাচাই করুন।');
    }

    return NarrationAnalysisResult(
      suggestions: suggestions,
      warnings: warnings,
      context: context,
      processedOffline: true,
    );
  }

  List<String> _sentences(String source) => source
      .split(RegExp(r'(?<=[।.!?])\s+|\n+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> _matchingSentences(
    List<String> sentences,
    List<String> keywords,
  ) {
    final matched = <String>[];
    for (final sentence in sentences) {
      final normalised = _normalise(sentence);
      if (_hasAny(normalised, keywords) && !matched.contains(sentence)) {
        matched.add(sentence);
      }
    }
    return matched;
  }

  List<String> _extractTimes(String source) {
    final results = <String>[];
    final searchable = _toAsciiDigits(source);
    final patterns = <RegExp>[
      RegExp(
        r'(?:^|\s)((?:[01]?\d|2[0-3])[:.]\d{2}\s*(?:hrs?|ঘটিকা|টা)?)',
        caseSensitive: false,
      ),
      RegExp(r'(?:^|\s)(\d{1,2}\s*(?:টা|ঘটিকায়|ঘটিকায়))'),
      RegExp(
        r'(?:সকাল|দুপুর|বিকাল|সন্ধ্যা|রাত)\s*\d{1,2}(?::\d{2})?\s*(?:টা|ঘটিকা|টায়|টায়)?',
      ),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(searchable)) {
        final value = (match.groupCount >= 1 ? match.group(1) : match.group(0))?.trim();
        if (value != null && value.isNotEmpty && !results.contains(value)) {
          results.add(value);
        }
      }
    }
    return results;
  }

  String _toAsciiDigits(String value) {
    const bn = '০১২৩৪৫৬৭৮৯';
    var converted = value;
    for (var i = 0; i < bn.length; i++) {
      converted = converted.replaceAll(bn[i], '$i');
    }
    return converted;
  }

  List<String> _extractPlaces(String source) {
    final results = <String>[];
    final patterns = <RegExp>[
      RegExp(r'(?:ঘটনাস্থল|স্থান|গ্রাম|village|at)\s*[:\-]?\s*([^।,.\n]{3,60})', caseSensitive: false),
      RegExp(r'(?:গেলাম|পৌঁছালাম|পরিদর্শন করলাম)\s+(?:গ্রাম\s+)?([^।,.\n]{3,60})', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(source)) {
        var value = match.group(1)?.trim() ?? '';
        value = value.replaceFirst(RegExp(r'\s+(?:ঘটনাস্থল|পরিদর্শন|গিয়ে|গিয়ে).*$'), '').trim();
        if (value.isNotEmpty && !results.contains(value)) results.add(value);
      }
    }
    return results.take(3).toList();
  }

  int? _extractWitnessCount(String text) {
    const bengaliNumbers = {
      'একজন': 1,
      'দুইজন': 2,
      'দুজন': 2,
      'তিনজন': 3,
      'চারজন': 4,
      'পাঁচজন': 5,
      'ছয়জন': 6,
      'ছয়জন': 6,
      'সাতজন': 7,
      'আটজন': 8,
      'নয়জন': 9,
      'নয়জন': 9,
      'দশজন': 10,
    };
    for (final entry in bengaliNumbers.entries) {
      if (text.contains(entry.key) && text.contains('সাক্ষী')) return entry.value;
    }
    final match = RegExp(r'\b(\d{1,2})\s*(?:জন\s*)?(?:সাক্ষী|witness)', caseSensitive: false).firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  List<String> _extractWitnessNames(String source) {
    final results = <String>[];

    void addChunk(String chunk) {
      var cleaned = chunk.trim();
      cleaned = cleaned
          .replaceFirst(
            RegExp(
              r'(?:কে|দেরকে)?\s*(?:পরীক্ষা|জিজ্ঞাসাবাদ|examin|statement|বিবৃতি|রেকর্ড).*',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      for (final raw in cleaned.split(
        RegExp(r'\s*(?:,|;|\sও\s|\sand\s|&)\s*', caseSensitive: false),
      )) {
        final value = raw
            .replaceFirst(RegExp(r'^(?:নামে|namely)\s*', caseSensitive: false), '')
            .replaceFirst(RegExp(r'(?:কে|দেরকে)$'), '')
            .trim();
        if (value.length >= 2 &&
            value.length <= 45 &&
            !results.contains(value)) {
          results.add(value);
        }
      }
    }

    final directPatterns = <RegExp>[
      RegExp(
        r'(?:সাক্ষী|witness(?:es)?)\s*(?:নাম(?:ে)?|namely|:|-)\s*([^।.\n]{3,120})',
        caseSensitive: false,
      ),
      RegExp(
        r'([^।,\n]{2,80})\s*(?:নামে সাক্ষী|কে সাক্ষী হিসেবে)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in directPatterns) {
      for (final match in pattern.allMatches(source)) {
        final chunk = match.group(1)?.trim();
        if (chunk != null && chunk.isNotEmpty) addChunk(chunk);
      }
    }

    return results.take(12).toList();
  }

  String _normalise(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _hasAny(String source, List<String> values) =>
      values.any((value) => source.contains(value));
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
