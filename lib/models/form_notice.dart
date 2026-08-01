class FormNotice {
  final String id;
  final String caseId;
  final String templateId;
  final String title;
  final String body;
  final bool isFinal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormNotice({
    required this.id,
    required this.caseId,
    required this.templateId,
    required this.title,
    required this.body,
    required this.isFinal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FormNotice.create({
    required String caseId,
    required String templateId,
    required String title,
    required String body,
  }) {
    final now = DateTime.now();
    return FormNotice(
      id: 'form_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      templateId: templateId,
      title: title,
      body: body,
      isFinal: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  FormNotice copyWith({
    String? title,
    String? body,
    bool? isFinal,
  }) {
    return FormNotice(
      id: id,
      caseId: caseId,
      templateId: templateId,
      title: title ?? this.title,
      body: body ?? this.body,
      isFinal: isFinal ?? this.isFinal,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'templateId': templateId,
        'title': title,
        'body': body,
        'isFinal': isFinal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FormNotice.fromJson(Map<String, dynamic> json) {
    return FormNotice(
      id: json['id'] ?? 'form_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      templateId: json['templateId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isFinal: json['isFinal'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
