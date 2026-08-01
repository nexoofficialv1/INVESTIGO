class InvestigationStart {
  final String ioName;
  final String tookUpDate;
  final bool visitedPo;
  final String poDetails;
  final bool sketchPrepared;
  final String sketchDetails;
  final bool witnessExamined;
  final String witnessDetails;
  final bool medicalRequired;
  final String medicalDetails;
  final bool seizureRequired;
  final String seizureDetails;
  final bool evidenceRequired;
  final String evidenceDetails;

  const InvestigationStart({
    required this.ioName,
    required this.tookUpDate,
    required this.visitedPo,
    required this.poDetails,
    required this.sketchPrepared,
    required this.sketchDetails,
    required this.witnessExamined,
    required this.witnessDetails,
    required this.medicalRequired,
    required this.medicalDetails,
    required this.seizureRequired,
    required this.seizureDetails,
    required this.evidenceRequired,
    required this.evidenceDetails,
  });

  factory InvestigationStart.empty({String ioName = ''}) => InvestigationStart(
        ioName: ioName,
        tookUpDate: DateTime.now().toIso8601String().split('T').first,
        visitedPo: false,
        poDetails: '',
        sketchPrepared: false,
        sketchDetails: '',
        witnessExamined: false,
        witnessDetails: '',
        medicalRequired: false,
        medicalDetails: '',
        seizureRequired: false,
        seizureDetails: '',
        evidenceRequired: false,
        evidenceDetails: '',
      );

  Map<String, dynamic> toJson() => {
        'ioName': ioName,
        'tookUpDate': tookUpDate,
        'visitedPo': visitedPo,
        'poDetails': poDetails,
        'sketchPrepared': sketchPrepared,
        'sketchDetails': sketchDetails,
        'witnessExamined': witnessExamined,
        'witnessDetails': witnessDetails,
        'medicalRequired': medicalRequired,
        'medicalDetails': medicalDetails,
        'seizureRequired': seizureRequired,
        'seizureDetails': seizureDetails,
        'evidenceRequired': evidenceRequired,
        'evidenceDetails': evidenceDetails,
      };

  factory InvestigationStart.fromJson(Map<String, dynamic> json) {
    return InvestigationStart(
      ioName: json['ioName'] ?? '',
      tookUpDate: json['tookUpDate'] ?? '',
      visitedPo: json['visitedPo'] ?? false,
      poDetails: json['poDetails'] ?? '',
      sketchPrepared: json['sketchPrepared'] ?? false,
      sketchDetails: json['sketchDetails'] ?? '',
      witnessExamined: json['witnessExamined'] ?? false,
      witnessDetails: json['witnessDetails'] ?? '',
      medicalRequired: json['medicalRequired'] ?? false,
      medicalDetails: json['medicalDetails'] ?? '',
      seizureRequired: json['seizureRequired'] ?? false,
      seizureDetails: json['seizureDetails'] ?? '',
      evidenceRequired: json['evidenceRequired'] ?? false,
      evidenceDetails: json['evidenceDetails'] ?? '',
    );
  }
}

class CaseFile {
  final String id;
  final String psCaseNo;
  final String caseDate;
  final String sections;
  final String crimeHead;
  final String placeOfOccurrence;
  final String dateTimeOccurrence;
  final String dateTimeReporting;
  final String complainantName;
  final String victimName;
  final String accusedName;
  final String firGist;
  final InvestigationStart investigationStart;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseFile({
    required this.id,
    required this.psCaseNo,
    required this.caseDate,
    required this.sections,
    required this.crimeHead,
    required this.placeOfOccurrence,
    required this.dateTimeOccurrence,
    required this.dateTimeReporting,
    required this.complainantName,
    required this.victimName,
    required this.accusedName,
    required this.firGist,
    required this.investigationStart,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseFile.empty({String ioName = ''}) {
    final now = DateTime.now();
    return CaseFile(
      id: 'case_${now.microsecondsSinceEpoch}',
      psCaseNo: '',
      caseDate: now.toIso8601String().split('T').first,
      sections: '',
      crimeHead: '',
      placeOfOccurrence: '',
      dateTimeOccurrence: '',
      dateTimeReporting: '',
      complainantName: '',
      victimName: '',
      accusedName: '',
      firGist: '',
      investigationStart: InvestigationStart.empty(ioName: ioName),
      createdAt: now,
      updatedAt: now,
    );
  }

  String get displayTitle => psCaseNo.trim().isEmpty ? 'New Case' : 'PS Case No. $psCaseNo';

  CaseFile copyWith({
    String? psCaseNo,
    String? caseDate,
    String? sections,
    String? crimeHead,
    String? placeOfOccurrence,
    String? dateTimeOccurrence,
    String? dateTimeReporting,
    String? complainantName,
    String? victimName,
    String? accusedName,
    String? firGist,
    InvestigationStart? investigationStart,
  }) {
    return CaseFile(
      id: id,
      psCaseNo: psCaseNo ?? this.psCaseNo,
      caseDate: caseDate ?? this.caseDate,
      sections: sections ?? this.sections,
      crimeHead: crimeHead ?? this.crimeHead,
      placeOfOccurrence: placeOfOccurrence ?? this.placeOfOccurrence,
      dateTimeOccurrence: dateTimeOccurrence ?? this.dateTimeOccurrence,
      dateTimeReporting: dateTimeReporting ?? this.dateTimeReporting,
      complainantName: complainantName ?? this.complainantName,
      victimName: victimName ?? this.victimName,
      accusedName: accusedName ?? this.accusedName,
      firGist: firGist ?? this.firGist,
      investigationStart: investigationStart ?? this.investigationStart,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'psCaseNo': psCaseNo,
        'caseDate': caseDate,
        'sections': sections,
        'crimeHead': crimeHead,
        'placeOfOccurrence': placeOfOccurrence,
        'dateTimeOccurrence': dateTimeOccurrence,
        'dateTimeReporting': dateTimeReporting,
        'complainantName': complainantName,
        'victimName': victimName,
        'accusedName': accusedName,
        'firGist': firGist,
        'investigationStart': investigationStart.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CaseFile.fromJson(Map<String, dynamic> json) {
    return CaseFile(
      id: json['id'] ?? 'case_${DateTime.now().microsecondsSinceEpoch}',
      psCaseNo: json['psCaseNo'] ?? '',
      caseDate: json['caseDate'] ?? '',
      sections: json['sections'] ?? '',
      crimeHead: json['crimeHead'] ?? '',
      placeOfOccurrence: json['placeOfOccurrence'] ?? '',
      dateTimeOccurrence: json['dateTimeOccurrence'] ?? '',
      dateTimeReporting: json['dateTimeReporting'] ?? '',
      complainantName: json['complainantName'] ?? '',
      victimName: json['victimName'] ?? '',
      accusedName: json['accusedName'] ?? '',
      firGist: json['firGist'] ?? '',
      investigationStart: InvestigationStart.fromJson(
        Map<String, dynamic>.from(json['investigationStart'] ?? {}),
      ),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
