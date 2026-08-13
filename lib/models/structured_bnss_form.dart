enum StructuredFormFieldType {
  text,
  multiline,
  date,
  time,
  choice,
  yesNo,
  checklist,
}

class StructuredFormOption {
  final String value;
  final String labelEn;
  final String labelBn;

  const StructuredFormOption(this.value, this.labelEn, this.labelBn);
}

class StructuredFormFieldSpec {
  final String key;
  final String labelEn;
  final String labelBn;
  final StructuredFormFieldType type;
  final bool required;
  final int maxLines;
  final List<StructuredFormOption> options;
  final String helperEn;
  final String helperBn;

  const StructuredFormFieldSpec({
    required this.key,
    required this.labelEn,
    required this.labelBn,
    this.type = StructuredFormFieldType.text,
    this.required = false,
    this.maxLines = 1,
    this.options = const [],
    this.helperEn = '',
    this.helperBn = '',
  });
}

class StructuredFormRowColumnSpec {
  final String key;
  final String labelEn;
  final String labelBn;
  final StructuredFormFieldType type;
  final bool required;
  final int maxLines;

  const StructuredFormRowColumnSpec({
    required this.key,
    required this.labelEn,
    required this.labelBn,
    this.type = StructuredFormFieldType.text,
    this.required = false,
    this.maxLines = 1,
  });
}

class StructuredFormRowGroupSpec {
  final String key;
  final String titleEn;
  final String titleBn;
  final int minRows;
  final int maxRows;
  final List<StructuredFormRowColumnSpec> columns;

  const StructuredFormRowGroupSpec({
    required this.key,
    required this.titleEn,
    required this.titleBn,
    required this.columns,
    this.minRows = 1,
    this.maxRows = 20,
  });
}

class StructuredFormSchema {
  final String templateId;
  final List<StructuredFormFieldSpec> fields;
  final List<StructuredFormRowGroupSpec> rowGroups;

  const StructuredFormSchema({
    required this.templateId,
    required this.fields,
    this.rowGroups = const [],
  });
}

class StructuredBnssFormState {
  final Map<String, String> values;
  final Map<String, List<String>> checks;
  final Map<String, List<Map<String, String>>> rows;

  const StructuredBnssFormState({
    this.values = const {},
    this.checks = const {},
    this.rows = const {},
  });

  factory StructuredBnssFormState.fromJson(Map<String, dynamic> json) {
    final values = <String, String>{};
    final checks = <String, List<String>>{};
    final rows = <String, List<Map<String, String>>>{};

    final rawValues = Map<String, dynamic>.from(json['values'] ?? const {});
    for (final entry in rawValues.entries) {
      values[entry.key] = '${entry.value ?? ''}';
    }

    final rawChecks = Map<String, dynamic>.from(json['checks'] ?? const {});
    for (final entry in rawChecks.entries) {
      checks[entry.key] = (entry.value as List? ?? const [])
          .map((e) => '$e')
          .toList();
    }

    final rawRows = Map<String, dynamic>.from(json['rows'] ?? const {});
    for (final entry in rawRows.entries) {
      final list = <Map<String, String>>[];
      for (final item in (entry.value as List? ?? const [])) {
        final row = <String, String>{};
        for (final cell in Map<String, dynamic>.from(item as Map).entries) {
          row[cell.key] = '${cell.value ?? ''}';
        }
        list.add(row);
      }
      rows[entry.key] = list;
    }

    return StructuredBnssFormState(values: values, checks: checks, rows: rows);
  }

  Map<String, dynamic> toJson() => {
        'version': 'structured-bnss-form-v1',
        'values': values,
        'checks': checks,
        'rows': rows,
      };

  StructuredBnssFormState copyWith({
    Map<String, String>? values,
    Map<String, List<String>>? checks,
    Map<String, List<Map<String, String>>>? rows,
  }) =>
      StructuredBnssFormState(
        values: values ?? this.values,
        checks: checks ?? this.checks,
        rows: rows ?? this.rows,
      );
}
