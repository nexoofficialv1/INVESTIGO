class PendingCdAction {
  final String id;
  final String caseId;
  final String sourceType;
  final String sourceId;
  final String title;
  final String actionDate;
  final String entryTime;
  final String placeOfEntry;
  final String synopsis;
  final String paragraph;
  final bool consumed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingCdAction({
    required this.id,
    required this.caseId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.actionDate,
    required this.entryTime,
    required this.placeOfEntry,
    required this.synopsis,
    required this.paragraph,
    required this.consumed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingCdAction.create({
    required String caseId,
    required String sourceType,
    required String sourceId,
    required String title,
    required String actionDate,
    String entryTime = '',
    String placeOfEntry = '',
    String synopsis = '',
    required String paragraph,
  }) {
    final now = DateTime.now();
    return PendingCdAction(
      id: 'cd_action_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      actionDate: actionDate,
      entryTime: entryTime,
      placeOfEntry: placeOfEntry,
      synopsis: synopsis.isEmpty ? title : synopsis,
      paragraph: paragraph,
      consumed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  PendingCdAction copyWith({
    String? entryTime,
    String? placeOfEntry,
    String? synopsis,
    String? paragraph,
    bool? consumed,
  }) {
    return PendingCdAction(
      id: id,
      caseId: caseId,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      actionDate: actionDate,
      entryTime: entryTime ?? this.entryTime,
      placeOfEntry: placeOfEntry ?? this.placeOfEntry,
      synopsis: synopsis ?? this.synopsis,
      paragraph: paragraph ?? this.paragraph,
      consumed: consumed ?? this.consumed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'title': title,
        'actionDate': actionDate,
        'entryTime': entryTime,
        'placeOfEntry': placeOfEntry,
        'synopsis': synopsis,
        'paragraph': paragraph,
        'consumed': consumed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PendingCdAction.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? '';
    return PendingCdAction(
      id: json['id'] ?? 'cd_action_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      sourceType: json['sourceType'] ?? '',
      sourceId: json['sourceId'] ?? '',
      title: title,
      actionDate: json['actionDate'] ?? '',
      entryTime: json['entryTime'] ?? '',
      placeOfEntry: json['placeOfEntry'] ?? '',
      synopsis: json['synopsis'] ?? title,
      paragraph: json['paragraph'] ?? '',
      consumed: json['consumed'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
