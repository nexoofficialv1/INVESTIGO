class InvestigationActionEntry {
  final String id;
  final String caseId;
  final String actionDate;
  final String actionType;
  final bool outsidePs;
  final String departureTime;
  final String actionArrivalTime;
  final String returnTime;
  final String place;
  final String accompaniedBy;
  final String sopResponse;
  final String details;
  final bool arrestInvolved;
  final bool seizureInvolved;
  final bool courtForwardingSuggested;
  final bool pcPrayerSuggested;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestigationActionEntry({
    required this.id,
    required this.caseId,
    required this.actionDate,
    required this.actionType,
    required this.outsidePs,
    required this.departureTime,
    required this.actionArrivalTime,
    required this.returnTime,
    required this.place,
    required this.accompaniedBy,
    required this.sopResponse,
    required this.details,
    required this.arrestInvolved,
    required this.seizureInvolved,
    required this.courtForwardingSuggested,
    required this.pcPrayerSuggested,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestigationActionEntry.create({
    required String caseId,
    required String actionDate,
    required String actionType,
    required bool outsidePs,
    required String departureTime,
    required String actionArrivalTime,
    required String returnTime,
    required String place,
    required String accompaniedBy,
    required String sopResponse,
    required String details,
    required bool arrestInvolved,
    required bool seizureInvolved,
    required bool courtForwardingSuggested,
    required bool pcPrayerSuggested,
  }) {
    final now = DateTime.now();
    return InvestigationActionEntry(
      id: 'inv_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      actionDate: actionDate,
      actionType: actionType,
      outsidePs: outsidePs,
      departureTime: departureTime,
      actionArrivalTime: actionArrivalTime,
      returnTime: returnTime,
      place: place,
      accompaniedBy: accompaniedBy,
      sopResponse: sopResponse,
      details: details,
      arrestInvolved: arrestInvolved,
      seizureInvolved: seizureInvolved,
      courtForwardingSuggested: courtForwardingSuggested,
      pcPrayerSuggested: pcPrayerSuggested,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'actionDate': actionDate,
        'actionType': actionType,
        'outsidePs': outsidePs,
        'departureTime': departureTime,
        'actionArrivalTime': actionArrivalTime,
        'returnTime': returnTime,
        'place': place,
        'accompaniedBy': accompaniedBy,
        'sopResponse': sopResponse,
        'details': details,
        'arrestInvolved': arrestInvolved,
        'seizureInvolved': seizureInvolved,
        'courtForwardingSuggested': courtForwardingSuggested,
        'pcPrayerSuggested': pcPrayerSuggested,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InvestigationActionEntry.fromJson(Map<String, dynamic> json) {
    return InvestigationActionEntry(
      id: json['id'] ?? 'inv_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      actionDate: json['actionDate'] ?? '',
      actionType: json['actionType'] ?? '',
      outsidePs: json['outsidePs'] ?? false,
      departureTime: json['departureTime'] ?? '',
      actionArrivalTime: json['actionArrivalTime'] ?? '',
      returnTime: json['returnTime'] ?? '',
      place: json['place'] ?? '',
      accompaniedBy: json['accompaniedBy'] ?? '',
      sopResponse: json['sopResponse'] ?? '',
      details: json['details'] ?? '',
      arrestInvolved: json['arrestInvolved'] ?? false,
      seizureInvolved: json['seizureInvolved'] ?? false,
      courtForwardingSuggested: json['courtForwardingSuggested'] ?? false,
      pcPrayerSuggested: json['pcPrayerSuggested'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
