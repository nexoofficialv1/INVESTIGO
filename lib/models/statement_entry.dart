class StatementEntry {
  final String id;
  final String caseId;
  final String witnessName;
  final String witnessDetails;
  final String statementType;
  final String body;
  final DateTime createdAt;

  const StatementEntry({
    required this.id,
    required this.caseId,
    required this.witnessName,
    required this.witnessDetails,
    required this.statementType,
    required this.body,
    required this.createdAt,
  });

  factory StatementEntry.create({
    required String caseId,
    required String witnessName,
    required String witnessDetails,
    required String statementType,
    required String body,
  }) {
    final now = DateTime.now();
    return StatementEntry(
      id: 'st_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      witnessName: witnessName,
      witnessDetails: witnessDetails,
      statementType: statementType,
      body: body,
      createdAt: now,
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
    );
  }
}
