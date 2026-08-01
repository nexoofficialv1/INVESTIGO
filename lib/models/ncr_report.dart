class NcrReport {
  final String id;
  final String formNo;
  final String reportYear;
  final String reference;
  final String district;
  final String policeStation;
  final String ncrNo;
  final String caseSections;
  final String complainantInformation;
  final String accusedDetails;
  final String arrestDate;
  final String hearingDate;
  final String offenceBrief;
  final String witnessDetails;
  final String trialResult;
  final String remarks;
  final String submittedBy;
  final DateTime updatedAt;

  const NcrReport({
    required this.id,
    required this.formNo,
    required this.reportYear,
    required this.reference,
    required this.district,
    required this.policeStation,
    required this.ncrNo,
    required this.caseSections,
    required this.complainantInformation,
    required this.accusedDetails,
    required this.arrestDate,
    required this.hearingDate,
    required this.offenceBrief,
    required this.witnessDetails,
    required this.trialResult,
    required this.remarks,
    required this.submittedBy,
    required this.updatedAt,
  });

  factory NcrReport.empty({String ps = '', String district = '', String submittedBy = ''}) {
    final now = DateTime.now();
    return NcrReport(
      id: now.microsecondsSinceEpoch.toString(),
      formNo: '5358',
      reportYear: now.year.toString(),
      reference: '',
      district: district,
      policeStation: ps,
      ncrNo: '',
      caseSections: '126/135 BNSS',
      complainantInformation: '',
      accusedDetails: '',
      arrestDate: 'Not Arrested',
      hearingDate: '',
      offenceBrief: '',
      witnessDetails: '',
      trialResult: '',
      remarks: '',
      submittedBy: submittedBy,
      updatedAt: now,
    );
  }

  NcrReport copyWith(Map<String, String> values) => NcrReport(
        id: id,
        formNo: values['formNo'] ?? formNo,
        reportYear: values['reportYear'] ?? reportYear,
        reference: values['reference'] ?? reference,
        district: values['district'] ?? district,
        policeStation: values['policeStation'] ?? policeStation,
        ncrNo: values['ncrNo'] ?? ncrNo,
        caseSections: values['caseSections'] ?? caseSections,
        complainantInformation: values['complainantInformation'] ?? complainantInformation,
        accusedDetails: values['accusedDetails'] ?? accusedDetails,
        arrestDate: values['arrestDate'] ?? arrestDate,
        hearingDate: values['hearingDate'] ?? hearingDate,
        offenceBrief: values['offenceBrief'] ?? offenceBrief,
        witnessDetails: values['witnessDetails'] ?? witnessDetails,
        trialResult: values['trialResult'] ?? trialResult,
        remarks: values['remarks'] ?? remarks,
        submittedBy: values['submittedBy'] ?? submittedBy,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'formNo': formNo,
        'reportYear': reportYear,
        'reference': reference,
        'district': district,
        'policeStation': policeStation,
        'ncrNo': ncrNo,
        'caseSections': caseSections,
        'complainantInformation': complainantInformation,
        'accusedDetails': accusedDetails,
        'arrestDate': arrestDate,
        'hearingDate': hearingDate,
        'offenceBrief': offenceBrief,
        'witnessDetails': witnessDetails,
        'trialResult': trialResult,
        'remarks': remarks,
        'submittedBy': submittedBy,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NcrReport.fromJson(Map<String, dynamic> json) => NcrReport(
        id: (json['id'] ?? '').toString(),
        formNo: (json['formNo'] ?? '5358').toString(),
        reportYear: (json['reportYear'] ?? '').toString(),
        reference: (json['reference'] ?? '').toString(),
        district: (json['district'] ?? '').toString(),
        policeStation: (json['policeStation'] ?? '').toString(),
        ncrNo: (json['ncrNo'] ?? '').toString(),
        caseSections: (json['caseSections'] ?? '').toString(),
        complainantInformation: (json['complainantInformation'] ?? '').toString(),
        accusedDetails: (json['accusedDetails'] ?? '').toString(),
        arrestDate: (json['arrestDate'] ?? '').toString(),
        hearingDate: (json['hearingDate'] ?? '').toString(),
        offenceBrief: (json['offenceBrief'] ?? '').toString(),
        witnessDetails: (json['witnessDetails'] ?? '').toString(),
        trialResult: (json['trialResult'] ?? '').toString(),
        remarks: (json['remarks'] ?? '').toString(),
        submittedBy: (json['submittedBy'] ?? '').toString(),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ?? DateTime.now(),
      );
}
