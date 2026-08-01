import '../models/case_file.dart';

class SopRule {
  final String title;
  final String detail;
  final String sectionRef;
  final bool mandatory;
  final String category;

  const SopRule({
    required this.title,
    required this.detail,
    required this.sectionRef,
    required this.mandatory,
    required this.category,
  });
}

class SopComplianceService {
  static const List<String> sexualOffenceSections = [
    '64', '65', '66', '67', '68', '69', '70', '71',
    '74', '75', '76', '77', '78', '79', '124',
  ];

  static const List<String> pocsoSections = ['4', '6', '8', '10'];

  bool _hasSection(CaseFile file, String section) {
    final normalized = file.sections.toLowerCase().replaceAll(RegExp(r'[^0-9a-z]+'), ' ');
    return RegExp('(^| )${RegExp.escape(section.toLowerCase())}( |\$)').hasMatch(normalized) ||
        file.sections.toLowerCase().contains('section $section') ||
        file.sections.toLowerCase().contains('/$section') ||
        file.sections.toLowerCase().contains('$section ');
  }

  bool hasSexualOrVulnerableOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    return lower.contains('pocso') || sexualOffenceSections.any((s) => _hasSection(file, s));
  }

  bool hasPocsoTimeBoundOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    if (!lower.contains('pocso')) return false;
    return pocsoSections.any((s) => _hasSection(file, s));
  }

  bool isElectronicEvidenceCase(CaseFile file) {
    final lower = '${file.sections} ${file.firGist} ${file.investigationStart.evidenceDetails}'.toLowerCase();
    return lower.contains('mobile') || lower.contains('cctv') || lower.contains('cdr') ||
        lower.contains('caf') || lower.contains('upi') || lower.contains('bank') ||
        lower.contains('electronic') || lower.contains('digital') || lower.contains('device');
  }

  bool likelySeriousOffence(CaseFile file) {
    final lower = file.sections.toLowerCase();
    return lower.contains('103') || lower.contains('109') || lower.contains('302') ||
        lower.contains('307') || lower.contains('376') || lower.contains('pocso') ||
        lower.contains('life') || lower.contains('death');
  }

  List<SopRule> buildRules(CaseFile file) {
    final sexual = hasSexualOrVulnerableOffence(file);
    final electronic = isElectronicEvidenceCase(file);
    final serious = likelySeriousOffence(file);
    final pocsoTimeBound = hasPocsoTimeBoundOffence(file);

    final rules = <SopRule>[
      const SopRule(
        category: 'FIR / Registration',
        title: 'Electronic information signature within 3 days',
        detail: 'If cognizable information is received by electronic communication, obtain signature of the informant within three days and mention compliance in CD.',
        sectionRef: 'SOP direction 1(a)-(b), BNSS 173',
        mandatory: true,
      ),
      const SopRule(
        category: 'PO Visit / Evidence',
        title: 'Photography / videography of PO',
        detail: 'Conduct photography/videography of the place of occurrence wherever applicable and link it as evidence/document.',
        sectionRef: 'SOP direction 2(a), BNSS 176(3)',
        mandatory: true,
      ),
      const SopRule(
        category: 'Statement',
        title: '180 BNSS statement without delay',
        detail: 'Record available witness/victim statements without delay; audio-video electronic means may be used where appropriate.',
        sectionRef: 'SOP direction 3, BNSS 180',
        mandatory: true,
      ),
      const SopRule(
        category: 'Final Stage',
        title: 'Inform victim/informant about progress/result',
        detail: 'Track whether progress/result of investigation is communicated to informant or victim within required timeline and mention mode/date.',
        sectionRef: 'SOP direction 5(c), BNSS 193(3)',
        mandatory: true,
      ),
      const SopRule(
        category: 'Final Stage',
        title: 'Electronic supply of charge sheet documents',
        detail: 'Track whether copy of charge sheet along with documents has been supplied electronically to accused and victim where applicable.',
        sectionRef: 'SOP direction 5(d), BNSS 193',
        mandatory: true,
      ),
      const SopRule(
        category: 'Further Investigation',
        title: 'Court permission for further investigation',
        detail: 'If further investigation is required after conclusion/filing, record court permission and complete within permitted period.',
        sectionRef: 'SOP direction 5(e), BNSS 193',
        mandatory: true,
      ),
      const SopRule(
        category: 'Further Investigation',
        title: 'Extension before 90 days if investigation not concluded',
        detail: 'If investigation is not concluded within 90 days, generate prayer before expiry of 90 days to extend time for further investigation.',
        sectionRef: 'SOP direction 5(f), BNSS 193',
        mandatory: true,
      ),
    ];

    if (sexual) {
      rules.addAll(const [
        SopRule(
          category: 'Women / Victim Sensitive Offence',
          title: 'FIR by woman police officer',
          detail: 'For BNS 64-71, 74-79 and 124 type offences, ensure FIR/statement is recorded by a woman police officer where required.',
          sectionRef: 'SOP direction 1(c)',
          mandatory: true,
        ),
        SopRule(
          category: 'Women / Victim Sensitive Offence',
          title: 'Interpreter/special educator support if required',
          detail: 'If the woman victim/informant is temporarily/permanently mentally or physically disabled, arrange interpreter/special educator and record at residence/place of convenience.',
          sectionRef: 'SOP direction 1(d), 4(c)-(d)',
          mandatory: true,
        ),
        SopRule(
          category: 'Women / Victim Sensitive Offence',
          title: 'Videography of vulnerable statement',
          detail: 'Where the SOP requires, record the statement through videography/audio-video electronic means preferably by mobile phone.',
          sectionRef: 'SOP direction 1(e), 4(d)',
          mandatory: true,
        ),
        SopRule(
          category: '183 BNSS',
          title: '183 BNSS statement before Magistrate without delay',
          detail: 'Move application before the Ld. Magistrate without delay for recording victim/witness statement as applicable.',
          sectionRef: 'SOP direction 1(f), 4(a)-(b)',
          mandatory: true,
        ),
        SopRule(
          category: '183 BNSS',
          title: 'Woman Magistrate preference',
          detail: 'For specified offences, victim statement should be recorded by a woman Magistrate, or in her absence by a male Magistrate in presence of a woman.',
          sectionRef: 'SOP direction 1(f), 4(a)',
          mandatory: true,
        ),
        SopRule(
          category: 'Statement',
          title: 'Victim statement at residence/place of choice',
          detail: 'For rape/sexual offence, record victim statement at her residence or place of choice where required.',
          sectionRef: 'SOP direction 2(c)',
          mandatory: true,
        ),
        SopRule(
          category: 'Statement',
          title: '180 BNSS by woman officer',
          detail: 'For BNS 64-71, 74-79 and 124 allegations, record victim statement u/s 180 BNSS by woman police officer/any woman officer.',
          sectionRef: 'SOP direction 3(b)',
          mandatory: true,
        ),
      ]);
    }

    if (pocsoTimeBound || sexual) {
      rules.add(const SopRule(
        category: 'Final Stage',
        title: 'Two-month completion check',
        detail: 'For specified BNS sexual offences and POCSO 4/6/8/10, track charge sheet/final report completion within two months from FIR date.',
        sectionRef: 'SOP direction 5(a)',
        mandatory: true,
      ));
    }

    if (serious) {
      rules.add(const SopRule(
        category: 'PO Visit / Evidence',
        title: 'Forensic expert at spot for serious offence',
        detail: 'If offence is punishable with more than seven years, call forensic expert at spot to collect forensic evidence and mention in CD.',
        sectionRef: 'SOP direction 2(b), BNSS 176(3)',
        mandatory: true,
      ));
    }

    if (electronic) {
      rules.add(const SopRule(
        category: 'Electronic Evidence',
        title: 'Sequence of custody for electronic device',
        detail: 'For electronic device/evidence, maintain and submit sequence/chain of custody details and link to evidence record.',
        sectionRef: 'SOP direction 5(b)',
        mandatory: true,
      ));
    }

    return rules;
  }
}
