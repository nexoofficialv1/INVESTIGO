import '../data/legal_reference_core_text.dart';
import '../data/legal_reference_index.dart';
import '../models/legal_reference.dart';

class LegalReferenceService {
  static final Map<String, VerifiedLegalText> _verifiedByKey = {
    for (final item in verifiedLegalTexts) item.key: item,
  };

  static String _norm(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\bu\s*/\s*s\b'), ' ')
      .replaceAll(RegExp(r'\bsections?\b|\bsec\.?\b'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9()]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> extractSectionTokens(String raw) {
    final matches = RegExp(r'\d{1,3}(?:\([a-zA-Z0-9]+\))*')
        .allMatches(raw)
        .map((m) => m.group(0)!)
        .toList();
    return {...matches}.toList();
  }

  static LegalCode? inferCode(String raw) {
    final q = raw.toLowerCase();
    if (q.contains('bnss') || q.contains('crpc')) return LegalCode.bnss;
    if (q.contains('bns') || q.contains('ipc')) return LegalCode.bns;
    return null;
  }

  List<LegalSearchResult> search(
    String raw, {
    LegalCode? code,
    int limit = 80,
  }) {
    final inferred = code ?? inferCode(raw);
    final q = _norm(raw);
    final tokens = extractSectionTokens(raw).map(_norm).toSet();
    final oldHint = raw.toLowerCase().contains('ipc') ||
        raw.toLowerCase().contains('crpc');
    final scored = <LegalSearchResult>[];

    for (final item in legalReferenceIndex) {
      if (inferred != null && item.code != inferred) continue;
      final sec = _norm(item.section);
      final baseSec =
          RegExp(r'^\d+').firstMatch(item.section)?.group(0) ?? sec;
      final title = _norm(item.titleEn);
      final old = _norm(item.oldSection);
      final oldSectionTokens =
          extractSectionTokens(item.oldSection).map(_norm).toSet();
      final note = _norm(item.comparisonNote);
      final oldSectionMatch =
          oldHint && oldSectionTokens.any(tokens.contains);
      var score = 0;

      if (q.isEmpty) {
        if (_verifiedByKey.containsKey(item.key)) {
          score = 50;
        } else if (RegExp(r'^\d+$').hasMatch(item.section)) {
          score = 5;
        }
      } else {
        // When the user explicitly searches an IPC/CrPC section, the
        // corresponding BNS/BNSS row must outrank an unrelated current-law row
        // that happens to have the same section number. Example:
        //   CrPC 161 -> BNSS 180 (oldSection 161), not BNSS 161.
        if (oldSectionMatch) score += 420;

        if (tokens.contains(sec)) score += oldHint ? 70 : 160;
        if (sec != baseSec && tokens.contains(baseSec)) score += 60;
        if (q == sec) score += oldHint ? 60 : 180;
        if (q.contains(sec) && sec.isNotEmpty) score += oldHint ? 25 : 55;
        if (title == q) score += 140;
        if (title.contains(q) && q.length >= 3) score += 90;
        for (final part in q.split(' ')) {
          if (part.length >= 3 && title.contains(part)) score += 14;
        }
        if (!oldHint && old.isNotEmpty && q.length >= 2 && old.contains(q)) {
          score += 22;
        }
        if (q.length >= 4 && note.contains(q)) score += 16;
      }

      final verified = _verifiedByKey[item.key];
      if (verified != null) score += 18;
      if (score > 0) {
        scored.add(
          LegalSearchResult(index: item, verified: verified, score: score),
        );
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final an = int.tryParse(
            RegExp(r'^\d+').firstMatch(a.index.section)?.group(0) ?? '',
          ) ??
          9999;
      final bn = int.tryParse(
            RegExp(r'^\d+').firstMatch(b.index.section)?.group(0) ?? '',
          ) ??
          9999;
      final byNo = an.compareTo(bn);
      if (byNo != 0) return byNo;
      return a.index.section.compareTo(b.index.section);
    });
    return scored.take(limit).toList();
  }

  VerifiedLegalText? verifiedFor(LegalIndexRecord entry) =>
      _verifiedByKey[entry.key];
}
