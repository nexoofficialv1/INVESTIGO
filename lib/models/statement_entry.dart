class StatementEntry {
  final String id;
  final String caseId;
  final String witnessName;
  final String witnessDetails;
  final String statementType;
  final String body;
  final DateTime createdAt;

  // v202 linked-CD metadata. All fields are backward-compatible with old data.
  final bool linkedFromCd;
  final int sourceCdNumber;
  final String sourceActionId;
  final String sourceKey;
  final String recordedDate;
  final String recordedTime;
  final String recordedPlace;
  final String recordedBy;

  const StatementEntry({
    required this.id,
    required this.caseId,
    required this.witnessName,
    required this.witnessDetails,
    required this.statementType,
    required this.body,
    required this.createdAt,
    this.linkedFromCd = false,
    this.sourceCdNumber = 0,
    this.sourceActionId = '',
    this.sourceKey = '',
    this.recordedDate = '',
    this.recordedTime = '',
    this.recordedPlace = '',
    this.recordedBy = '',
  });

  factory StatementEntry.create({
    required String caseId,
    required String witnessName,
    required String witnessDetails,
    required String statementType,
    required String body,
    bool linkedFromCd = false,
    int sourceCdNumber = 0,
    String sourceActionId = '',
    String sourceKey = '',
    String recordedDate = '',
    String recordedTime = '',
    String recordedPlace = '',
    String recordedBy = '',
  }) {
    final now = DateTime.now();
    return StatementEntry(
      id: sourceKey.trim().isNotEmpty
          ? 'st_link_${_safeId(sourceKey)}'
          : 'st_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      witnessName: witnessName,
      witnessDetails: witnessDetails,
      statementType: statementType,
      body: body,
      createdAt: now,
      linkedFromCd: linkedFromCd,
      sourceCdNumber: sourceCdNumber,
      sourceActionId: sourceActionId,
      sourceKey: sourceKey,
      recordedDate: recordedDate,
      recordedTime: recordedTime,
      recordedPlace: recordedPlace,
      recordedBy: recordedBy,
    );
  }

  StatementEntry copyWith({
    String? witnessName,
    String? witnessDetails,
    String? statementType,
    String? body,
    bool? linkedFromCd,
    int? sourceCdNumber,
    String? sourceActionId,
    String? sourceKey,
    String? recordedDate,
    String? recordedTime,
    String? recordedPlace,
    String? recordedBy,
  }) {
    return StatementEntry(
      id: id,
      caseId: caseId,
      witnessName: witnessName ?? this.witnessName,
      witnessDetails: witnessDetails ?? this.witnessDetails,
      statementType: statementType ?? this.statementType,
      body: body ?? this.body,
      createdAt: createdAt,
      linkedFromCd: linkedFromCd ?? this.linkedFromCd,
      sourceCdNumber: sourceCdNumber ?? this.sourceCdNumber,
      sourceActionId: sourceActionId ?? this.sourceActionId,
      sourceKey: sourceKey ?? this.sourceKey,
      recordedDate: recordedDate ?? this.recordedDate,
      recordedTime: recordedTime ?? this.recordedTime,
      recordedPlace: recordedPlace ?? this.recordedPlace,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'witnessName': witnessName,
        'witnessDetails': witnessDetails,
        'statementType': statementType,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'linkedFromCd': linkedFromCd,
        'sourceCdNumber': sourceCdNumber,
        'sourceActionId': sourceActionId,
        'sourceKey': sourceKey,
        'recordedDate': recordedDate,
        'recordedTime': recordedTime,
        'recordedPlace': recordedPlace,
        'recordedBy': recordedBy,
      };

  factory StatementEntry.fromJson(Map<String, dynamic> json) {
    return StatementEntry(
      id: json['id'] ?? 'st_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      witnessName: json['witnessName'] ?? '',
      witnessDetails: json['witnessDetails'] ?? '',
      statementType: json['statementType'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      linkedFromCd: json['linkedFromCd'] ?? false,
      sourceCdNumber: (json['sourceCdNumber'] as num?)?.toInt() ?? 0,
      sourceActionId: json['sourceActionId'] ?? '',
      sourceKey: json['sourceKey'] ?? '',
      recordedDate: json['recordedDate'] ?? '',
      recordedTime: json['recordedTime'] ?? '',
      recordedPlace: json['recordedPlace'] ?? '',
      recordedBy: json['recordedBy'] ?? '',
    );
  }

  static String _safeId(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.length <= 80) return cleaned;
    return cleaned.substring(0, 80);
  }
}
