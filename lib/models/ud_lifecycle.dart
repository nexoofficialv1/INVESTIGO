enum UdWorkflowStage {
  registered,
  inquestCompleted,
  challanPrepared,
  pmReportAwaited,
  pmReportReceived,
  readyForFinalReport,
  finalized,
}

enum UdFoulPlayAssessment {
  notSelected,
  detected,
  notDetected,
  inconclusive,
}

class UdLifecycleRecord {
  final String udCaseId;

  final bool inquestCompleted;
  final String spotVisitDate;
  final String spotVisitTime;
  final String inquestDate;
  final String inquestStartTime;
  final String inquestEndTime;
  final String inquestPlace;
  final String inquestObservation;

  final String pmPlannedDate;
  final bool challanFinalized;
  final String challanDate;
  final String challanTime;
  final String bodyDispatchDate;
  final String bodyDispatchTime;
  final String pmHospital;
  final String meansOfDispatch;
  final String escortDetails;
  final String documentsSent;
  final String articlesSent;

  final bool pmCompleted;
  final String pmDate;
  final String pmTime;
  final String pmNumber;
  final String doctorName;

  final bool pmReportReceived;
  final String pmReportNo;
  final String pmReportDate;
  final String pmReportReceivedDate;
  final String causeOfDeath;
  final String injuryFindings;
  final String medicalOpinion;
  final bool visceraPreserved;
  final bool otherReportPending;
  final String pendingReportDetails;
  final String otherMedicalOpinion;

  final UdFoulPlayAssessment foulPlayAssessment;
  final String finalInvestigationSummary;
  final String finalDispatchDate;
  final String finalDispatchTime;
  final bool finalized;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UdLifecycleRecord({
    required this.udCaseId,
    required this.inquestCompleted,
    required this.spotVisitDate,
    required this.spotVisitTime,
    required this.inquestDate,
    required this.inquestStartTime,
    required this.inquestEndTime,
    required this.inquestPlace,
    required this.inquestObservation,
    required this.pmPlannedDate,
    required this.challanFinalized,
    required this.challanDate,
    required this.challanTime,
    required this.bodyDispatchDate,
    required this.bodyDispatchTime,
    required this.pmHospital,
    required this.meansOfDispatch,
    required this.escortDetails,
    required this.documentsSent,
    required this.articlesSent,
    required this.pmCompleted,
    required this.pmDate,
    required this.pmTime,
    required this.pmNumber,
    required this.doctorName,
    required this.pmReportReceived,
    required this.pmReportNo,
    required this.pmReportDate,
    required this.pmReportReceivedDate,
    required this.causeOfDeath,
    required this.injuryFindings,
    required this.medicalOpinion,
    required this.visceraPreserved,
    required this.otherReportPending,
    required this.pendingReportDetails,
    required this.otherMedicalOpinion,
    required this.foulPlayAssessment,
    required this.finalInvestigationSummary,
    required this.finalDispatchDate,
    required this.finalDispatchTime,
    required this.finalized,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UdLifecycleRecord.empty(String udCaseId) {
    final now = DateTime.now();
    return UdLifecycleRecord(
      udCaseId: udCaseId,
      inquestCompleted: false,
      spotVisitDate: '',
      spotVisitTime: '',
      inquestDate: '',
      inquestStartTime: '',
      inquestEndTime: '',
      inquestPlace: '',
      inquestObservation: '',
      pmPlannedDate: '',
      challanFinalized: false,
      challanDate: '',
      challanTime: '',
      bodyDispatchDate: '',
      bodyDispatchTime: '',
      pmHospital: '',
      meansOfDispatch: '',
      escortDetails: '',
      documentsSent: '',
      articlesSent: '',
      pmCompleted: false,
      pmDate: '',
      pmTime: '',
      pmNumber: '',
      doctorName: '',
      pmReportReceived: false,
      pmReportNo: '',
      pmReportDate: '',
      pmReportReceivedDate: '',
      causeOfDeath: '',
      injuryFindings: '',
      medicalOpinion: '',
      visceraPreserved: false,
      otherReportPending: false,
      pendingReportDetails: '',
      otherMedicalOpinion: '',
      foulPlayAssessment: UdFoulPlayAssessment.notSelected,
      finalInvestigationSummary: '',
      finalDispatchDate: '',
      finalDispatchTime: '',
      finalized: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  UdWorkflowStage get stage {
    if (finalized) return UdWorkflowStage.finalized;
    if (pmReportReceived &&
        foulPlayAssessment != UdFoulPlayAssessment.notSelected &&
        !otherReportPending &&
        finalInvestigationSummary.trim().isNotEmpty) {
      return UdWorkflowStage.readyForFinalReport;
    }
    if (pmReportReceived) return UdWorkflowStage.pmReportReceived;
    if (pmCompleted) return UdWorkflowStage.pmReportAwaited;
    if (challanFinalized) return UdWorkflowStage.challanPrepared;
    if (inquestCompleted) return UdWorkflowStage.inquestCompleted;
    return UdWorkflowStage.registered;
  }

  String get stageLabelBn {
    switch (stage) {
      case UdWorkflowStage.registered:
        return 'UD রেজিস্টার্ড / সুরতহাল বাকি';
      case UdWorkflowStage.inquestCompleted:
        return 'সুরতহাল সম্পন্ন';
      case UdWorkflowStage.challanPrepared:
        return 'Dead Body Challan প্রস্তুত / PM বাকি';
      case UdWorkflowStage.pmReportAwaited:
        return 'PM রিপোর্টের অপেক্ষায়';
      case UdWorkflowStage.pmReportReceived:
        return 'PM রিপোর্ট পাওয়া গেছে';
      case UdWorkflowStage.readyForFinalReport:
        return 'Final Form তৈরির জন্য প্রস্তুত';
      case UdWorkflowStage.finalized:
        return 'UD Finalized';
    }
  }

  UdLifecycleRecord copyWith({
    bool? inquestCompleted,
    String? spotVisitDate,
    String? spotVisitTime,
    String? inquestDate,
    String? inquestStartTime,
    String? inquestEndTime,
    String? inquestPlace,
    String? inquestObservation,
    String? pmPlannedDate,
    bool? challanFinalized,
    String? challanDate,
    String? challanTime,
    String? bodyDispatchDate,
    String? bodyDispatchTime,
    String? pmHospital,
    String? meansOfDispatch,
    String? escortDetails,
    String? documentsSent,
    String? articlesSent,
    bool? pmCompleted,
    String? pmDate,
    String? pmTime,
    String? pmNumber,
    String? doctorName,
    bool? pmReportReceived,
    String? pmReportNo,
    String? pmReportDate,
    String? pmReportReceivedDate,
    String? causeOfDeath,
    String? injuryFindings,
    String? medicalOpinion,
    bool? visceraPreserved,
    bool? otherReportPending,
    String? pendingReportDetails,
    String? otherMedicalOpinion,
    UdFoulPlayAssessment? foulPlayAssessment,
    String? finalInvestigationSummary,
    String? finalDispatchDate,
    String? finalDispatchTime,
    bool? finalized,
  }) {
    return UdLifecycleRecord(
      udCaseId: udCaseId,
      inquestCompleted: inquestCompleted ?? this.inquestCompleted,
      spotVisitDate: spotVisitDate ?? this.spotVisitDate,
      spotVisitTime: spotVisitTime ?? this.spotVisitTime,
      inquestDate: inquestDate ?? this.inquestDate,
      inquestStartTime: inquestStartTime ?? this.inquestStartTime,
      inquestEndTime: inquestEndTime ?? this.inquestEndTime,
      inquestPlace: inquestPlace ?? this.inquestPlace,
      inquestObservation: inquestObservation ?? this.inquestObservation,
      pmPlannedDate: pmPlannedDate ?? this.pmPlannedDate,
      challanFinalized: challanFinalized ?? this.challanFinalized,
      challanDate: challanDate ?? this.challanDate,
      challanTime: challanTime ?? this.challanTime,
      bodyDispatchDate: bodyDispatchDate ?? this.bodyDispatchDate,
      bodyDispatchTime: bodyDispatchTime ?? this.bodyDispatchTime,
      pmHospital: pmHospital ?? this.pmHospital,
      meansOfDispatch: meansOfDispatch ?? this.meansOfDispatch,
      escortDetails: escortDetails ?? this.escortDetails,
      documentsSent: documentsSent ?? this.documentsSent,
      articlesSent: articlesSent ?? this.articlesSent,
      pmCompleted: pmCompleted ?? this.pmCompleted,
      pmDate: pmDate ?? this.pmDate,
      pmTime: pmTime ?? this.pmTime,
      pmNumber: pmNumber ?? this.pmNumber,
      doctorName: doctorName ?? this.doctorName,
      pmReportReceived: pmReportReceived ?? this.pmReportReceived,
      pmReportNo: pmReportNo ?? this.pmReportNo,
      pmReportDate: pmReportDate ?? this.pmReportDate,
      pmReportReceivedDate: pmReportReceivedDate ?? this.pmReportReceivedDate,
      causeOfDeath: causeOfDeath ?? this.causeOfDeath,
      injuryFindings: injuryFindings ?? this.injuryFindings,
      medicalOpinion: medicalOpinion ?? this.medicalOpinion,
      visceraPreserved: visceraPreserved ?? this.visceraPreserved,
      otherReportPending: otherReportPending ?? this.otherReportPending,
      pendingReportDetails: pendingReportDetails ?? this.pendingReportDetails,
      otherMedicalOpinion: otherMedicalOpinion ?? this.otherMedicalOpinion,
      foulPlayAssessment: foulPlayAssessment ?? this.foulPlayAssessment,
      finalInvestigationSummary: finalInvestigationSummary ?? this.finalInvestigationSummary,
      finalDispatchDate: finalDispatchDate ?? this.finalDispatchDate,
      finalDispatchTime: finalDispatchTime ?? this.finalDispatchTime,
      finalized: finalized ?? this.finalized,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'udCaseId': udCaseId,
        'inquestCompleted': inquestCompleted,
        'spotVisitDate': spotVisitDate,
        'spotVisitTime': spotVisitTime,
        'inquestDate': inquestDate,
        'inquestStartTime': inquestStartTime,
        'inquestEndTime': inquestEndTime,
        'inquestPlace': inquestPlace,
        'inquestObservation': inquestObservation,
        'pmPlannedDate': pmPlannedDate,
        'challanFinalized': challanFinalized,
        'challanDate': challanDate,
        'challanTime': challanTime,
        'bodyDispatchDate': bodyDispatchDate,
        'bodyDispatchTime': bodyDispatchTime,
        'pmHospital': pmHospital,
        'meansOfDispatch': meansOfDispatch,
        'escortDetails': escortDetails,
        'documentsSent': documentsSent,
        'articlesSent': articlesSent,
        'pmCompleted': pmCompleted,
        'pmDate': pmDate,
        'pmTime': pmTime,
        'pmNumber': pmNumber,
        'doctorName': doctorName,
        'pmReportReceived': pmReportReceived,
        'pmReportNo': pmReportNo,
        'pmReportDate': pmReportDate,
        'pmReportReceivedDate': pmReportReceivedDate,
        'causeOfDeath': causeOfDeath,
        'injuryFindings': injuryFindings,
        'medicalOpinion': medicalOpinion,
        'visceraPreserved': visceraPreserved,
        'otherReportPending': otherReportPending,
        'pendingReportDetails': pendingReportDetails,
        'otherMedicalOpinion': otherMedicalOpinion,
        'foulPlayAssessment': foulPlayAssessment.name,
        'finalInvestigationSummary': finalInvestigationSummary,
        'finalDispatchDate': finalDispatchDate,
        'finalDispatchTime': finalDispatchTime,
        'finalized': finalized,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UdLifecycleRecord.fromJson(Map<String, dynamic> json) {
    UdFoulPlayAssessment parseAssessment(String raw) {
      for (final value in UdFoulPlayAssessment.values) {
        if (value.name == raw) return value;
      }
      return UdFoulPlayAssessment.notSelected;
    }

    return UdLifecycleRecord(
      udCaseId: json['udCaseId'] ?? '',
      inquestCompleted: json['inquestCompleted'] ?? false,
      spotVisitDate: json['spotVisitDate'] ?? '',
      spotVisitTime: json['spotVisitTime'] ?? '',
      inquestDate: json['inquestDate'] ?? '',
      inquestStartTime: json['inquestStartTime'] ?? '',
      inquestEndTime: json['inquestEndTime'] ?? '',
      inquestPlace: json['inquestPlace'] ?? '',
      inquestObservation: json['inquestObservation'] ?? '',
      pmPlannedDate: json['pmPlannedDate'] ?? '',
      challanFinalized: json['challanFinalized'] ?? false,
      challanDate: json['challanDate'] ?? '',
      challanTime: json['challanTime'] ?? '',
      bodyDispatchDate: json['bodyDispatchDate'] ?? '',
      bodyDispatchTime: json['bodyDispatchTime'] ?? '',
      pmHospital: json['pmHospital'] ?? '',
      meansOfDispatch: json['meansOfDispatch'] ?? '',
      escortDetails: json['escortDetails'] ?? '',
      documentsSent: json['documentsSent'] ?? '',
      articlesSent: json['articlesSent'] ?? '',
      pmCompleted: json['pmCompleted'] ?? false,
      pmDate: json['pmDate'] ?? '',
      pmTime: json['pmTime'] ?? '',
      pmNumber: json['pmNumber'] ?? '',
      doctorName: json['doctorName'] ?? '',
      pmReportReceived: json['pmReportReceived'] ?? false,
      pmReportNo: json['pmReportNo'] ?? '',
      pmReportDate: json['pmReportDate'] ?? '',
      pmReportReceivedDate: json['pmReportReceivedDate'] ?? '',
      causeOfDeath: json['causeOfDeath'] ?? '',
      injuryFindings: json['injuryFindings'] ?? '',
      medicalOpinion: json['medicalOpinion'] ?? '',
      visceraPreserved: json['visceraPreserved'] ?? false,
      otherReportPending: json['otherReportPending'] ?? false,
      pendingReportDetails: json['pendingReportDetails'] ?? '',
      otherMedicalOpinion: json['otherMedicalOpinion'] ?? '',
      foulPlayAssessment: parseAssessment(json['foulPlayAssessment'] ?? ''),
      finalInvestigationSummary: json['finalInvestigationSummary'] ?? '',
      finalDispatchDate: json['finalDispatchDate'] ?? '',
      finalDispatchTime: json['finalDispatchTime'] ?? '',
      finalized: json['finalized'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
