import '../models/case_file.dart';
import '../models/officer_profile.dart';

class ParsedCaseData {
  final String psCaseNo;
  final String caseDate;
  final String sections;
  final String placeOfOccurrence;
  final String dateTimeOccurrence;
  final String dateTimeReporting;
  final String complainant;
  final String victim;
  final String accused;
  final String ioName;
  final String ioMobile;
  final String gist;
  final String arrest;
  final String rawText;

  const ParsedCaseData({
    required this.psCaseNo,
    required this.caseDate,
    required this.sections,
    required this.placeOfOccurrence,
    required this.dateTimeOccurrence,
    required this.dateTimeReporting,
    required this.complainant,
    required this.victim,
    required this.accused,
    required this.ioName,
    required this.ioMobile,
    required this.gist,
    required this.arrest,
    required this.rawText,
  });

  factory ParsedCaseData.empty({String rawText = ''}) => ParsedCaseData(
        psCaseNo: '',
        caseDate: '',
        sections: '',
        placeOfOccurrence: '',
        dateTimeOccurrence: '',
        dateTimeReporting: '',
        complainant: '',
        victim: '',
        accused: '',
        ioName: '',
        ioMobile: '',
        gist: '',
        arrest: '',
        rawText: rawText,
      );

  CaseFile toCaseFile(OfficerProfile profile, {CaseFile? existing}) {
    final base = existing ?? CaseFile.empty(ioName: '${profile.rank} ${profile.name}');
    final io = ioName.trim().isEmpty ? '${profile.rank} ${profile.name}' : ioName.trim();
    return base.copyWith(
      psCaseNo: psCaseNo.trim().isEmpty ? base.psCaseNo : psCaseNo.trim(),
      caseDate: caseDate.trim().isEmpty ? base.caseDate : caseDate.trim(),
      sections: sections.trim().isEmpty ? base.sections : sections.trim(),
      placeOfOccurrence: placeOfOccurrence.trim().isEmpty ? base.placeOfOccurrence : placeOfOccurrence.trim(),
      dateTimeOccurrence: dateTimeOccurrence.trim().isEmpty ? base.dateTimeOccurrence : dateTimeOccurrence.trim(),
      dateTimeReporting: dateTimeReporting.trim().isEmpty ? base.dateTimeReporting : dateTimeReporting.trim(),
      complainantName: complainant.trim().isEmpty ? base.complainantName : complainant.trim(),
      victimName: victim.trim().isEmpty ? base.victimName : victim.trim(),
      accusedName: accused.trim().isEmpty ? base.accusedName : accused.trim(),
      firGist: gist.trim().isEmpty ? base.firGist : gist.trim(),
      investigationStart: InvestigationStart(
        ioName: io,
        tookUpDate: base.investigationStart.tookUpDate,
        visitedPo: base.investigationStart.visitedPo,
        poDetails: base.investigationStart.poDetails,
        sketchPrepared: base.investigationStart.sketchPrepared,
        sketchDetails: base.investigationStart.sketchDetails,
        witnessExamined: base.investigationStart.witnessExamined,
        witnessDetails: base.investigationStart.witnessDetails,
        medicalRequired: base.investigationStart.medicalRequired,
        medicalDetails: base.investigationStart.medicalDetails,
        seizureRequired: base.investigationStart.seizureRequired,
        seizureDetails: base.investigationStart.seizureDetails,
        evidenceRequired: base.investigationStart.evidenceRequired,
        evidenceDetails: _joinNonEmpty([
          base.investigationStart.evidenceDetails,
          arrest.trim().isEmpty ? '' : 'Arrest: ${arrest.trim()}',
        ]),
      ),
    );
  }

  static String _joinNonEmpty(List<String> items) {
    return items.map((e) => e.trim()).where((e) => e.isNotEmpty).join('\n');
  }
}

class CaseParserService {
  ParsedCaseData parse(String input) {
    final text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) return ParsedCaseData.empty(rawText: input);

    final ref = _field(text, ['Ref', 'Reference']);
    final po = _field(text, ['P.O', 'PO', 'Place of Occurrence']);
    final dio = _field(text, ['D.O', 'DO', 'Date of Occurrence']);
    final dr = _field(text, ['D.R', 'DR', 'Date of Reporting']);
    final complt = _field(text, ['Complt', 'Complainant', 'Informant']);
    final victim = _field(text, ['Victim']);
    final accused = _field(text, ['FIR Named Accd', 'FIR Named Accused', 'Accused', 'Accd']);
    final io = _field(text, ['I.O', 'IO', 'Investigating Officer']);
    final gist = _field(text, ['Gist', 'Brief fact', 'Brief facts']);
    final arrest = _field(text, ['Arrest', 'Arrested']);

    final refParsed = _parseReference(ref);
    final ioParsed = _parseNameMobile(io);

    return ParsedCaseData(
      psCaseNo: refParsed.caseNo,
      caseDate: refParsed.date,
      sections: refParsed.sections,
      placeOfOccurrence: po,
      dateTimeOccurrence: dio,
      dateTimeReporting: dr,
      complainant: complt,
      victim: victim,
      accused: accused,
      ioName: ioParsed.name,
      ioMobile: ioParsed.mobile,
      gist: gist,
      arrest: arrest,
      rawText: input,
    );
  }

  String _field(String text, List<String> labels) {
    final allLabels = <String>[
      'Ref', 'Reference', 'P.O', 'PO', 'Place of Occurrence', 'D.O', 'DO', 'Date of Occurrence',
      'D.R', 'DR', 'Date of Reporting', 'Complt', 'Complainant', 'Informant', 'Victim',
      'FIR Named Accd', 'FIR Named Accused', 'Accused', 'Accd', 'I.O', 'IO', 'Investigating Officer',
      'Gist', 'Brief fact', 'Brief facts', 'Arrest', 'Arrested'
    ];
    for (final label in labels) {
      final escaped = RegExp.escape(label);
      final stop = allLabels.where((e) => e.toLowerCase() != label.toLowerCase()).map(RegExp.escape).join('|');
      final pattern = RegExp('(?:^|\\n)\\s*$escaped\\s*[:\u2013-]\\s*([\\s\\S]*?)(?=\\n\\s*(?:$stop)\\s*[:\u2013-]|\$)', caseSensitive: false);
      final match = pattern.firstMatch(text);
      if (match != null) return _clean(match.group(1) ?? '');
    }
    return '';
  }

  _ReferenceParts _parseReference(String ref) {
    if (ref.trim().isEmpty) return const _ReferenceParts('', '', '');
    final caseMatch = RegExp(r'Case\s*No\s*[-: ]+\s*([^\s]+)', caseSensitive: false).firstMatch(ref);
    final dateMatch = RegExp(r'Dated\s+([^\s]+)', caseSensitive: false).firstMatch(ref);
    final sectionMatch = RegExp(r'U/S\s*[-: ]*\s*([\s\S]+)', caseSensitive: false).firstMatch(ref);
    return _ReferenceParts(
      _clean(caseMatch?.group(1) ?? ''),
      _clean(dateMatch?.group(1) ?? ''),
      _clean(sectionMatch?.group(1) ?? ''),
    );
  }

  _NameMobile _parseNameMobile(String value) {
    final mobile = RegExp(r'(?:Mob|Mobile)?\s*[-:]?\s*(\b\d{10}\b)', caseSensitive: false).firstMatch(value)?.group(1) ?? '';
    var name = value.replaceAll(RegExp(r'\(?\s*(?:Mob|Mobile)?\s*[-:]?\s*\d{10}\s*\)?', caseSensitive: false), '').trim();
    return _NameMobile(_clean(name), mobile);
  }

  String _clean(String value) {
    return value
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*\.\s*$'), '')
        .trim();
  }
}

class _ReferenceParts {
  final String caseNo;
  final String date;
  final String sections;
  const _ReferenceParts(this.caseNo, this.date, this.sections);
}

class _NameMobile {
  final String name;
  final String mobile;
  const _NameMobile(this.name, this.mobile);
}
