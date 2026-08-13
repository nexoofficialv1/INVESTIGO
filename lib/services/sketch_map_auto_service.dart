import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sketch_map.dart';

class SketchMapApprovalRecord {
  final String caseId;
  final String sketchId;
  final bool approved;
  final String approvedBy;
  final String approvedAt;
  final int sourceCdNumber;
  final String fingerprint;

  const SketchMapApprovalRecord({
    required this.caseId,
    required this.sketchId,
    required this.approved,
    required this.approvedBy,
    required this.approvedAt,
    required this.sourceCdNumber,
    required this.fingerprint,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'sketchId': sketchId,
        'approved': approved,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt,
        'sourceCdNumber': sourceCdNumber,
        'fingerprint': fingerprint,
      };

  factory SketchMapApprovalRecord.fromJson(Map<String, dynamic> json) {
    return SketchMapApprovalRecord(
      caseId: json['caseId'] ?? '',
      sketchId: json['sketchId'] ?? '',
      approved: json['approved'] ?? false,
      approvedBy: json['approvedBy'] ?? '',
      approvedAt: json['approvedAt'] ?? '',
      sourceCdNumber: json['sourceCdNumber'] ?? 0,
      fingerprint: json['fingerprint'] ?? '',
    );
  }
}

class SketchMapAutoService {
  static const _approvalKey = 'sketch_map_approval_v200';

  SketchMapEntry generateDraft({
    required String caseId,
    required int sourceCdNumber,
    required String exactPo,
    required String north,
    required String south,
    required String east,
    required String west,
    String? date,
  }) {
    final base = SketchMapEntry.empty(caseId: caseId);
    final objects = <SketchMapObject>[
      _object(
        id: 'auto_${caseId}_${sourceCdNumber}_po',
        type: SketchObjectType.po,
        marker: 'X',
        label: 'X (PO)',
        direction: 'Inside PO',
        indexDescription: 'X = The PO of the case is ${exactPo.trim()}.',
        x: .42,
        y: .40,
        width: .17,
        height: .13,
      ),
      if (north.trim().isNotEmpty)
        _boundaryObject(
          id: 'auto_${caseId}_${sourceCdNumber}_north',
          marker: 'A',
          direction: 'North',
          description: north,
          x: .34,
          y: .09,
        ),
      if (south.trim().isNotEmpty)
        _boundaryObject(
          id: 'auto_${caseId}_${sourceCdNumber}_south',
          marker: 'B',
          direction: 'South',
          description: south,
          x: .34,
          y: .76,
        ),
      if (east.trim().isNotEmpty)
        _boundaryObject(
          id: 'auto_${caseId}_${sourceCdNumber}_east',
          marker: 'C',
          direction: 'East',
          description: east,
          x: .72,
          y: .40,
          rotation: 90,
        ),
      if (west.trim().isNotEmpty)
        _boundaryObject(
          id: 'auto_${caseId}_${sourceCdNumber}_west',
          marker: 'D',
          direction: 'West',
          description: west,
          x: .07,
          y: .40,
          rotation: 90,
        ),
      _object(
        id: 'auto_${caseId}_${sourceCdNumber}_north_arrow',
        type: SketchObjectType.arrow,
        marker: 'N',
        label: 'N',
        direction: 'North',
        indexDescription: '',
        x: .84,
        y: .04,
        width: .10,
        height: .16,
      ),
    ];

    return base.copyWith(
      title: 'Rough Sketch Map of PO with Index',
      date: date ?? DateTime.now().toIso8601String().split('T').first,
      poDescription: exactPo.trim(),
      north: north.trim(),
      south: south.trim(),
      east: east.trim(),
      west: west.trim(),
      objects: objects,
    );
  }

  SketchMapObject _boundaryObject({
    required String id,
    required String marker,
    required String direction,
    required String description,
    required double x,
    required double y,
    double rotation = 0,
  }) {
    final type = _inferType(description);
    final linear = <SketchObjectType>{
      SketchObjectType.road,
      SketchObjectType.canal,
      SketchObjectType.river,
      SketchObjectType.railway,
    }.contains(type);
    return _object(
      id: id,
      type: type,
      marker: marker,
      label: '$marker (${description.trim()})',
      direction: direction,
      indexDescription: '$marker = $direction: ${description.trim()}.',
      x: x,
      y: y,
      width: linear ? .30 : .20,
      height: linear ? .07 : .13,
      rotation: rotation,
    );
  }

  SketchMapObject _object({
    required String id,
    required SketchObjectType type,
    required String marker,
    required String label,
    required String direction,
    required String indexDescription,
    required double x,
    required double y,
    required double width,
    required double height,
    double rotation = 0,
  }) {
    return SketchMapObject(
      id: id,
      type: type,
      marker: marker,
      label: label,
      direction: direction,
      indexDescription: indexDescription,
      x: x,
      y: y,
      width: width,
      height: height,
      rotationDeg: rotation,
    );
  }

  SketchObjectType _inferType(String raw) {
    final text = raw.toLowerCase();
    bool any(List<String> values) => values.any(text.contains);

    if (any(<String>['road', 'stkk', 'street', 'lane', 'রাস্তা', 'সড়ক', 'সড়ক'])) {
      return SketchObjectType.road;
    }
    if (any(<String>['pond', 'pukur', 'পুকুর'])) return SketchObjectType.pond;
    if (any(<String>['hospital', 'health centre', 'হাসপাতাল'])) return SketchObjectType.hospital;
    if (any(<String>['school', 'বিদ্যালয়', 'বিদ্যালয়'])) return SketchObjectType.school;
    if (any(<String>['house', 'home', 'residence', 'বাড়ি', 'বাড়ি'])) return SketchObjectType.house;
    if (any(<String>['shop', 'store', 'দোকান'])) return SketchObjectType.shop;
    if (any(<String>['field', 'agricultural', 'cultivation', 'মাঠ', 'জমি'])) return SketchObjectType.field;
    if (any(<String>['vacant', 'ফাঁকা', 'খালি'])) return SketchObjectType.vacantLand;
    if (any(<String>['river', 'নদী'])) return SketchObjectType.river;
    if (any(<String>['canal', 'khal', 'খাল'])) return SketchObjectType.canal;
    if (any(<String>['rail', 'railway', 'রেল'])) return SketchObjectType.railway;
    if (any(<String>['tower', 'টাওয়ার', 'টাওয়ার'])) return SketchObjectType.tower;
    if (any(<String>['lamp post', 'lamp-post'])) return SketchObjectType.lampPost;
    if (any(<String>['electric pole', 'electric post', 'বিদ্যুৎ'])) return SketchObjectType.electricPole;
    if (any(<String>['gate', 'গেট'])) return SketchObjectType.gate;
    if (any(<String>['gumti', 'গুমটি'])) return SketchObjectType.gumti;
    return SketchObjectType.office;
  }

  List<String> validateDraft(SketchMapEntry map) {
    final issues = <String>[];
    if (map.poDescription.trim().isEmpty) issues.add('Exact PO is missing.');
    if (map.north.trim().isEmpty) issues.add('North boundary is missing.');
    if (map.south.trim().isEmpty) issues.add('South boundary is missing.');
    if (map.east.trim().isEmpty) issues.add('East boundary is missing.');
    if (map.west.trim().isEmpty) issues.add('West boundary is missing.');
    if (!map.objects.any((e) => e.type == SketchObjectType.po)) {
      issues.add('PO marker is missing from sketch map.');
    }
    if (!map.objects.any((e) => e.type == SketchObjectType.arrow)) {
      issues.add('North arrow is missing from sketch map.');
    }
    final markers = <String>{};
    for (final object in map.objects) {
      final marker = object.marker.trim().toUpperCase();
      if (marker.isEmpty) continue;
      if (!markers.add(marker)) issues.add('Duplicate index marker: $marker');
    }
    return issues;
  }

  String fingerprint(SketchMapEntry map) {
    final canonical = jsonEncode(<String, dynamic>{
      'po': map.poDescription.trim(),
      'north': map.north.trim(),
      'south': map.south.trim(),
      'east': map.east.trim(),
      'west': map.west.trim(),
      'objects': map.objects
          .map((e) => <String, dynamic>{
                'id': e.id,
                'type': e.type.name,
                'marker': e.marker,
                'label': e.label,
                'direction': e.direction,
                'index': e.indexDescription,
                'x': e.x,
                'y': e.y,
                'w': e.width,
                'h': e.height,
                'r': e.rotationDeg,
              })
          .toList(growable: false),
    });
    var hash = 0x811C9DC5;
    for (final unit in canonical.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  bool isApprovedFor(
    SketchMapEntry? map,
    SketchMapApprovalRecord? approval,
  ) {
    if (map == null || approval == null || !approval.approved) return false;
    if (approval.sketchId != map.id || approval.caseId != map.caseId) return false;
    return approval.fingerprint == fingerprint(map);
  }

  Future<SketchMapApprovalRecord?> loadApproval(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_approvalKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    final value = decoded[caseId];
    if (value == null) return null;
    return SketchMapApprovalRecord.fromJson(Map<String, dynamic>.from(value));
  }

  Future<SketchMapApprovalRecord> approve({
    required SketchMapEntry map,
    required String officerName,
    required int sourceCdNumber,
  }) async {
    final issues = validateDraft(map);
    if (issues.isNotEmpty) {
      throw StateError(issues.join(' '));
    }
    final record = SketchMapApprovalRecord(
      caseId: map.caseId,
      sketchId: map.id,
      approved: true,
      approvedBy: officerName.trim(),
      approvedAt: DateTime.now().toIso8601String(),
      sourceCdNumber: sourceCdNumber,
      fingerprint: fingerprint(map),
    );
    await _saveApproval(record);
    return record;
  }

  Future<void> invalidate(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_approvalKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = Map<String, dynamic>.from(jsonDecode(raw));
    decoded.remove(caseId);
    await prefs.setString(_approvalKey, jsonEncode(decoded));
  }

  Future<void> _saveApproval(SketchMapApprovalRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_approvalKey);
    final decoded = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    decoded[record.caseId] = record.toJson();
    await prefs.setString(_approvalKey, jsonEncode(decoded));
  }
}
