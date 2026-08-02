import 'regular_case_document_data.dart';

class FinalCdDraft {
  final String caseId;
  final String narrative;
  final String witnessList;
  final String accusedStatus;
  final String entryTime;
  final String entryPlace;
  final String synopsis;
  final bool approved;
  final DateTime updatedAt;

  const FinalCdDraft({
    required this.caseId,
    required this.narrative,
    required this.witnessList,
    required this.accusedStatus,
    this.entryTime = '23:59 hrs',
    this.entryPlace = 'PS',
    this.synopsis = 'Closing / Final Investigation',
    this.approved = false,
    required this.updatedAt,
  });

  factory FinalCdDraft.empty(String caseId) => FinalCdDraft(
        caseId: caseId,
        narrative: '',
        witnessList: '',
        accusedStatus: '',
        entryTime: '23:59 hrs',
        entryPlace: 'PS',
        synopsis: 'Closing / Final Investigation',
        updatedAt: DateTime.now(),
      );

  FinalCdDraft copyWith({
    String? narrative,
    String? witnessList,
    String? accusedStatus,
    String? entryTime,
    String? entryPlace,
    String? synopsis,
    bool? approved,
  }) =>
      FinalCdDraft(
        caseId: caseId,
        narrative: narrative ?? this.narrative,
        witnessList: witnessList ?? this.witnessList,
        accusedStatus: accusedStatus ?? this.accusedStatus,
        entryTime: entryTime ?? this.entryTime,
        entryPlace: entryPlace ?? this.entryPlace,
        synopsis: synopsis ?? this.synopsis,
        approved: approved ?? this.approved,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'narrative': narrative,
        'witnessList': witnessList,
        'accusedStatus': accusedStatus,
        'entryTime': entryTime,
        'entryPlace': entryPlace,
        'synopsis': synopsis,
        'approved': approved,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FinalCdDraft.fromJson(Map<String, dynamic> json) => FinalCdDraft(
        caseId: json['caseId'] ?? '',
        narrative: json['narrative'] ?? '',
        witnessList: json['witnessList'] ?? '',
        accusedStatus: json['accusedStatus'] ?? '',
        entryTime: json['entryTime'] ?? '23:59 hrs',
        entryPlace: json['entryPlace'] ?? 'PS',
        synopsis: json['synopsis'] ?? 'Closing / Final Investigation',
        approved: json['approved'] ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}

class ChargeSheetDraft {
  final String caseId;
  final String chargeSheetNo;
  final String chargeSheetDate;
  final String courtName;
  final String sections;
  final String accusedParticulars;
  final String witnessList;
  final String briefFacts;
  final String reliedDocuments;
  final bool approved;
  final DateTime updatedAt;

  const ChargeSheetDraft({
    required this.caseId,
    required this.chargeSheetNo,
    required this.chargeSheetDate,
    required this.courtName,
    required this.sections,
    required this.accusedParticulars,
    required this.witnessList,
    required this.briefFacts,
    required this.reliedDocuments,
    this.approved = false,
    required this.updatedAt,
  });

  factory ChargeSheetDraft.empty(String caseId) => ChargeSheetDraft(
        caseId: caseId,
        chargeSheetNo: '',
        chargeSheetDate: '',
        courtName: '',
        sections: '',
        accusedParticulars: '',
        witnessList: '',
        briefFacts: '',
        reliedDocuments: '',
        updatedAt: DateTime.now(),
      );

  ChargeSheetDraft copyWith({
    String? chargeSheetNo,
    String? chargeSheetDate,
    String? courtName,
    String? sections,
    String? accusedParticulars,
    String? witnessList,
    String? briefFacts,
    String? reliedDocuments,
    bool? approved,
  }) =>
      ChargeSheetDraft(
        caseId: caseId,
        chargeSheetNo: chargeSheetNo ?? this.chargeSheetNo,
        chargeSheetDate: chargeSheetDate ?? this.chargeSheetDate,
        courtName: courtName ?? this.courtName,
        sections: sections ?? this.sections,
        accusedParticulars: accusedParticulars ?? this.accusedParticulars,
        witnessList: witnessList ?? this.witnessList,
        briefFacts: briefFacts ?? this.briefFacts,
        reliedDocuments: reliedDocuments ?? this.reliedDocuments,
        approved: approved ?? this.approved,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'chargeSheetNo': chargeSheetNo,
        'chargeSheetDate': chargeSheetDate,
        'courtName': courtName,
        'sections': sections,
        'accusedParticulars': accusedParticulars,
        'witnessList': witnessList,
        'briefFacts': briefFacts,
        'reliedDocuments': reliedDocuments,
        'approved': approved,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChargeSheetDraft.fromJson(Map<String, dynamic> json) => ChargeSheetDraft(
        caseId: json['caseId'] ?? '',
        chargeSheetNo: json['chargeSheetNo'] ?? '',
        chargeSheetDate: json['chargeSheetDate'] ?? '',
        courtName: json['courtName'] ?? '',
        sections: json['sections'] ?? '',
        accusedParticulars: json['accusedParticulars'] ?? '',
        witnessList: json['witnessList'] ?? '',
        briefFacts: json['briefFacts'] ?? '',
        reliedDocuments: json['reliedDocuments'] ?? '',
        approved: json['approved'] ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}

class If5Draft {
  final String caseId;
  final String courtName;
  final String finalReportType;
  final String complainant;
  final String accusedParticulars;
  final String witnessList;
  final String propertyDocuments;
  final String briefFacts;
  final String resultCommunication;
  final String chargeSheetNo;
  final String chargeSheetDate;
  final String originalOrSupplementary;
  final String investigatingOfficer;
  final String unchargedAccused;
  final String laboratoryResult;
  final String falseCaseAction;
  final String dispatchDetails;
  final bool approved;
  final DateTime updatedAt;

  const If5Draft({
    required this.caseId,
    required this.courtName,
    required this.finalReportType,
    required this.complainant,
    required this.accusedParticulars,
    required this.witnessList,
    required this.propertyDocuments,
    required this.briefFacts,
    required this.resultCommunication,
    this.chargeSheetNo = '',
    this.chargeSheetDate = '',
    this.originalOrSupplementary = 'Original',
    this.investigatingOfficer = '',
    this.unchargedAccused = '',
    this.laboratoryResult = '',
    this.falseCaseAction = '',
    this.dispatchDetails = '',
    this.approved = false,
    required this.updatedAt,
  });

  factory If5Draft.empty(String caseId) => If5Draft(
        caseId: caseId,
        courtName: '',
        finalReportType: 'Charge-Sheet',
        complainant: '',
        accusedParticulars: '',
        witnessList: '',
        propertyDocuments: '',
        briefFacts: '',
        resultCommunication: '',
        chargeSheetNo: '',
        chargeSheetDate: '',
        originalOrSupplementary: 'Original',
        investigatingOfficer: '',
        unchargedAccused: '',
        laboratoryResult: '',
        falseCaseAction: '',
        dispatchDetails: '',
        updatedAt: DateTime.now(),
      );

  If5Draft copyWith({
    String? courtName,
    String? finalReportType,
    String? complainant,
    String? accusedParticulars,
    String? witnessList,
    String? propertyDocuments,
    String? briefFacts,
    String? resultCommunication,
    String? chargeSheetNo,
    String? chargeSheetDate,
    String? originalOrSupplementary,
    String? investigatingOfficer,
    String? unchargedAccused,
    String? laboratoryResult,
    String? falseCaseAction,
    String? dispatchDetails,
    bool? approved,
  }) =>
      If5Draft(
        caseId: caseId,
        courtName: courtName ?? this.courtName,
        finalReportType: finalReportType ?? this.finalReportType,
        complainant: complainant ?? this.complainant,
        accusedParticulars: accusedParticulars ?? this.accusedParticulars,
        witnessList: witnessList ?? this.witnessList,
        propertyDocuments: propertyDocuments ?? this.propertyDocuments,
        briefFacts: briefFacts ?? this.briefFacts,
        resultCommunication: resultCommunication ?? this.resultCommunication,
        chargeSheetNo: chargeSheetNo ?? this.chargeSheetNo,
        chargeSheetDate: chargeSheetDate ?? this.chargeSheetDate,
        originalOrSupplementary: originalOrSupplementary ?? this.originalOrSupplementary,
        investigatingOfficer: investigatingOfficer ?? this.investigatingOfficer,
        unchargedAccused: unchargedAccused ?? this.unchargedAccused,
        laboratoryResult: laboratoryResult ?? this.laboratoryResult,
        falseCaseAction: falseCaseAction ?? this.falseCaseAction,
        dispatchDetails: dispatchDetails ?? this.dispatchDetails,
        approved: approved ?? this.approved,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'courtName': courtName,
        'finalReportType': finalReportType,
        'complainant': complainant,
        'accusedParticulars': accusedParticulars,
        'witnessList': witnessList,
        'propertyDocuments': propertyDocuments,
        'briefFacts': briefFacts,
        'resultCommunication': resultCommunication,
        'chargeSheetNo': chargeSheetNo,
        'chargeSheetDate': chargeSheetDate,
        'originalOrSupplementary': originalOrSupplementary,
        'investigatingOfficer': investigatingOfficer,
        'unchargedAccused': unchargedAccused,
        'laboratoryResult': laboratoryResult,
        'falseCaseAction': falseCaseAction,
        'dispatchDetails': dispatchDetails,
        'approved': approved,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory If5Draft.fromJson(Map<String, dynamic> json) => If5Draft(
        caseId: json['caseId'] ?? '',
        courtName: json['courtName'] ?? '',
        finalReportType: json['finalReportType'] ?? 'Charge-Sheet',
        complainant: json['complainant'] ?? '',
        accusedParticulars: json['accusedParticulars'] ?? '',
        witnessList: json['witnessList'] ?? '',
        propertyDocuments: json['propertyDocuments'] ?? '',
        briefFacts: json['briefFacts'] ?? '',
        resultCommunication: json['resultCommunication'] ?? '',
        chargeSheetNo: json['chargeSheetNo'] ?? '',
        chargeSheetDate: json['chargeSheetDate'] ?? '',
        originalOrSupplementary: json['originalOrSupplementary'] ?? 'Original',
        investigatingOfficer: json['investigatingOfficer'] ?? '',
        unchargedAccused: json['unchargedAccused'] ?? '',
        laboratoryResult: json['laboratoryResult'] ?? '',
        falseCaseAction: json['falseCaseAction'] ?? '',
        dispatchDetails: json['dispatchDetails'] ?? '',
        approved: json['approved'] ?? false,
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}

class FinalCaseDocumentSet {
  final RegularCaseDocumentData source;
  final FinalCdDraft finalCd;
  final ChargeSheetDraft chargeSheet;
  final If5Draft if5;

  const FinalCaseDocumentSet({
    required this.source,
    required this.finalCd,
    required this.chargeSheet,
    required this.if5,
  });
}
