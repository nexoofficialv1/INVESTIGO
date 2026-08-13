import 'dart:convert';

enum WitnessCdEntryMode {
  separate,
  groupedSameSession,
}

class WitnessExaminationEntry {
  final String id;
  final String witnessName;
  final String witnessDetails;
  final String role;
  final String recordedTime;
  final String recordedPlace;
  final bool statementRecorded;
  final String statementBody;
  final String examinationNote;

  const WitnessExaminationEntry({
    required this.id,
    required this.witnessName,
    required this.witnessDetails,
    required this.role,
    required this.recordedTime,
    required this.recordedPlace,
    required this.statementRecorded,
    required this.statementBody,
    this.examinationNote = '',
  });

  WitnessExaminationEntry copyWith({
    String? witnessName,
    String? witnessDetails,
    String? role,
    String? recordedTime,
    String? recordedPlace,
    bool? statementRecorded,
    String? statementBody,
    String? examinationNote,
  }) {
    return WitnessExaminationEntry(
      id: id,
      witnessName: witnessName ?? this.witnessName,
      witnessDetails: witnessDetails ?? this.witnessDetails,
      role: role ?? this.role,
      recordedTime: recordedTime ?? this.recordedTime,
      recordedPlace: recordedPlace ?? this.recordedPlace,
      statementRecorded: statementRecorded ?? this.statementRecorded,
      statementBody: statementBody ?? this.statementBody,
      examinationNote: examinationNote ?? this.examinationNote,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'witnessName': witnessName,
        'witnessDetails': witnessDetails,
        'role': role,
        'recordedTime': recordedTime,
        'recordedPlace': recordedPlace,
        'statementRecorded': statementRecorded,
        'statementBody': statementBody,
        'examinationNote': examinationNote,
      };

  factory WitnessExaminationEntry.fromJson(Map<String, dynamic> json) {
    return WitnessExaminationEntry(
      id: (json['id'] ?? '').toString(),
      witnessName: (json['witnessName'] ?? '').toString(),
      witnessDetails: (json['witnessDetails'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      recordedTime: (json['recordedTime'] ?? '').toString(),
      recordedPlace: (json['recordedPlace'] ?? '').toString(),
      statementRecorded: json['statementRecorded'] == true,
      statementBody: (json['statementBody'] ?? '').toString(),
      examinationNote: (json['examinationNote'] ?? '').toString(),
    );
  }
}

class MultiWitnessBatch {
  final WitnessCdEntryMode mode;
  final List<WitnessExaminationEntry> entries;

  const MultiWitnessBatch({
    this.mode = WitnessCdEntryMode.separate,
    this.entries = const <WitnessExaminationEntry>[],
  });

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  MultiWitnessBatch copyWith({
    WitnessCdEntryMode? mode,
    List<WitnessExaminationEntry>? entries,
  }) {
    return MultiWitnessBatch(
      mode: mode ?? this.mode,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        'mode': mode.name,
        'entries': entries.map((e) => e.toJson()).toList(growable: false),
      };

  String encode() => jsonEncode(toJson());

  factory MultiWitnessBatch.fromJson(Map<String, dynamic> json) {
    final modeName = (json['mode'] ?? '').toString();
    final mode = WitnessCdEntryMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => WitnessCdEntryMode.separate,
    );
    final rawEntries = json['entries'];
    final entries = rawEntries is List
        ? rawEntries
            .whereType<Map>()
            .map(
              (e) => WitnessExaminationEntry.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .where((e) => e.id.trim().isNotEmpty || e.witnessName.trim().isNotEmpty)
            .toList(growable: false)
        : const <WitnessExaminationEntry>[];
    return MultiWitnessBatch(mode: mode, entries: entries);
  }

  factory MultiWitnessBatch.decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const MultiWitnessBatch();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return MultiWitnessBatch.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Invalid/legacy data is handled by service-level compatibility logic.
    }
    return const MultiWitnessBatch();
  }

  MultiWitnessBatch upsert(WitnessExaminationEntry entry) {
    final list = <WitnessExaminationEntry>[];
    var replaced = false;
    for (final current in entries) {
      if (current.id == entry.id) {
        list.add(entry);
        replaced = true;
      } else {
        list.add(current);
      }
    }
    if (!replaced) list.add(entry);
    return copyWith(entries: list);
  }

  MultiWitnessBatch remove(String id) => copyWith(
        entries: entries.where((e) => e.id != id).toList(growable: false),
      );

  MultiWitnessBatch copyFirstSessionToAll() {
    if (entries.length < 2) return this;
    final first = entries.first;
    return copyWith(
      entries: entries
          .map(
            (e) => e.copyWith(
              recordedTime: first.recordedTime,
              recordedPlace: first.recordedPlace,
            ),
          )
          .toList(growable: false),
    );
  }
}
