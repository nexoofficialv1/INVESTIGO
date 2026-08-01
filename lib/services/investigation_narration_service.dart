class NarrationActionSuggestion {
  final String actionType;
  final String synopsis;
  final String paragraph;
  final bool outsidePs;
  final bool arrestInvolved;
  final bool seizureInvolved;
  final bool suggestsSketchMap;
  final bool suggestsIndex;

  const NarrationActionSuggestion({
    required this.actionType,
    required this.synopsis,
    required this.paragraph,
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

  const NarrationDetectedContext({
    this.times = const [],
    this.places = const [],
    this.witnessCount,
  });

  bool get isEmpty => times.isEmpty && places.isEmpty && witnessCount == null;
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
/// No network request is made and no case data leaves the device. The service
/// creates editable suggestions only; the investigating officer must review
/// and approve every draft before it is saved.
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
      suggestions.add(
        NarrationActionSuggestion(
          actionType: actionType,
          synopsis: synopsis,
          paragraph: paragraph,
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

    const seizureKeywords = [
      'জব্দ',
      'seized',
      'seizure',
      'উদ্ধার করে জব্দ',
    ];
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
    );
    if (context.times.isEmpty) {
      warnings.add('সময় শনাক্ত হয়নি—CD entry save করার আগে সময় যাচাই করুন।');
    }
    if (_hasAny(text, poKeywords) && context.places.isEmpty) {
      warnings.add('PO Visit শনাক্ত হয়েছে, কিন্তু নির্দিষ্ট স্থান শনাক্ত হয়নি।');
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
    final patterns = <RegExp>[
      RegExp(r'\b(?:[01]?\d|2[0-3])[:.]\d{2}\s*(?:hrs?|ঘটিকা|টা)?\b', caseSensitive: false),
      RegExp(r'\b\d{1,2}\s*(?:টা|ঘটিকায়|ঘটিকায়)\b'),
      RegExp(r'\b(?:সকাল|দুপুর|বিকাল|সন্ধ্যা|রাত)\s*\d{1,2}(?::\d{2})?\s*(?:টা|ঘটিকা)?\b'),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(source)) {
        final value = match.group(0)?.trim();
        if (value != null && value.isNotEmpty && !results.contains(value)) {
          results.add(value);
        }
      }
    }
    return results;
  }

  List<String> _extractPlaces(String source) {
    final results = <String>[];
    final patterns = <RegExp>[
      RegExp(r'(?:ঘটনাস্থল|স্থান|গ্রাম|village|at)\s*[:\-]?\s*([^।,.\n]{3,60})', caseSensitive: false),
      RegExp(r'(?:গেলাম|পৌঁছালাম)\s+([^।,.\n]{3,60})', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(source)) {
        final value = match.group(1)?.trim();
        if (value != null && value.isNotEmpty && !results.contains(value)) {
          results.add(value);
        }
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
    };
    for (final entry in bengaliNumbers.entries) {
      if (text.contains(entry.key) && text.contains('সাক্ষী')) return entry.value;
    }
    final match = RegExp(r'\b(\d{1,2})\s*(?:জন\s*)?(?:সাক্ষী|witness)').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String _normalise(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _hasAny(String source, List<String> values) =>
      values.any((value) => source.contains(value));
}
