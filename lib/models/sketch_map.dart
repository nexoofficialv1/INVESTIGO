enum SketchObjectType { house, pond, tree, shop, road, field, po, arrow }

extension SketchObjectTypeLabel on SketchObjectType {
  String get label {
    switch (this) {
      case SketchObjectType.house:
        return 'House';
      case SketchObjectType.pond:
        return 'Pond';
      case SketchObjectType.tree:
        return 'Tree';
      case SketchObjectType.shop:
        return 'Shop';
      case SketchObjectType.road:
        return 'Road';
      case SketchObjectType.field:
        return 'Field';
      case SketchObjectType.po:
        return 'PO';
      case SketchObjectType.arrow:
        return 'Arrow';
    }
  }

  String get symbol {
    switch (this) {
      case SketchObjectType.house:
        return 'HOUSE';
      case SketchObjectType.pond:
        return 'POND';
      case SketchObjectType.tree:
        return 'TREE';
      case SketchObjectType.shop:
        return 'SHOP';
      case SketchObjectType.road:
        return 'ROAD';
      case SketchObjectType.field:
        return 'FIELD';
      case SketchObjectType.po:
        return 'PO';
      case SketchObjectType.arrow:
        return 'N';
    }
  }
}

SketchObjectType sketchObjectTypeFromString(String value) {
  return SketchObjectType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SketchObjectType.house,
  );
}

class SketchMapObject {
  final String id;
  final SketchObjectType type;
  final String marker;
  final String label;
  final String direction;
  final String indexDescription;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotationDeg;

  const SketchMapObject({
    required this.id,
    required this.type,
    required this.marker,
    required this.label,
    required this.direction,
    required this.indexDescription,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotationDeg,
  });

  factory SketchMapObject.create({
    required SketchObjectType type,
    required String marker,
    double x = 0.40,
    double y = 0.40,
  }) {
    final now = DateTime.now();
    final bool isRoad = type == SketchObjectType.road;
    final bool isArrow = type == SketchObjectType.arrow;
    final bool isTree = type == SketchObjectType.tree;
    return SketchMapObject(
      id: 'sketch_obj_${now.microsecondsSinceEpoch}',
      type: type,
      marker: marker,
      label: type == SketchObjectType.po ? 'PO' : '$marker (${type.label})',
      direction: '',
      indexDescription: '',
      x: x,
      y: y,
      width: isRoad ? 0.46 : (isTree || isArrow ? 0.15 : 0.20),
      height: isRoad ? 0.08 : (isTree || isArrow ? 0.18 : 0.14),
      rotationDeg: 0,
    );
  }

  SketchMapObject copyWith({
    String? marker,
    String? label,
    String? direction,
    String? indexDescription,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotationDeg,
  }) {
    return SketchMapObject(
      id: id,
      type: type,
      marker: marker ?? this.marker,
      label: label ?? this.label,
      direction: direction ?? this.direction,
      indexDescription: indexDescription ?? this.indexDescription,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDeg: rotationDeg ?? this.rotationDeg,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'marker': marker,
        'label': label,
        'direction': direction,
        'indexDescription': indexDescription,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotationDeg': rotationDeg,
      };

  factory SketchMapObject.fromJson(Map<String, dynamic> json) {
    return SketchMapObject(
      id: json['id'] ?? 'sketch_obj_${DateTime.now().microsecondsSinceEpoch}',
      type: sketchObjectTypeFromString(json['type'] ?? 'house'),
      marker: json['marker'] ?? 'A',
      label: json['label'] ?? '',
      direction: json['direction'] ?? '',
      indexDescription: json['indexDescription'] ?? '',
      x: (json['x'] ?? 0.40).toDouble(),
      y: (json['y'] ?? 0.40).toDouble(),
      width: (json['width'] ?? 0.18).toDouble(),
      height: (json['height'] ?? 0.12).toDouble(),
      rotationDeg: (json['rotationDeg'] ?? 0).toDouble(),
    );
  }
}

class SketchMapEntry {
  final String id;
  final String caseId;
  final String title;
  final String date;
  final String poDescription;
  final String north;
  final String south;
  final String east;
  final String west;
  final List<SketchMapObject> objects;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SketchMapEntry({
    required this.id,
    required this.caseId,
    required this.title,
    required this.date,
    required this.poDescription,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.objects,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SketchMapEntry.empty({required String caseId}) {
    final now = DateTime.now();
    return SketchMapEntry(
      id: 'sketch_${now.microsecondsSinceEpoch}',
      caseId: caseId,
      title: 'Rough Sketch Map with Index',
      date: now.toIso8601String().split('T').first,
      poDescription: '',
      north: '',
      south: '',
      east: '',
      west: '',
      objects: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  SketchMapEntry copyWith({
    String? title,
    String? date,
    String? poDescription,
    String? north,
    String? south,
    String? east,
    String? west,
    List<SketchMapObject>? objects,
  }) {
    return SketchMapEntry(
      id: id,
      caseId: caseId,
      title: title ?? this.title,
      date: date ?? this.date,
      poDescription: poDescription ?? this.poDescription,
      north: north ?? this.north,
      south: south ?? this.south,
      east: east ?? this.east,
      west: west ?? this.west,
      objects: objects ?? this.objects,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'title': title,
        'date': date,
        'poDescription': poDescription,
        'north': north,
        'south': south,
        'east': east,
        'west': west,
        'objects': objects.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SketchMapEntry.fromJson(Map<String, dynamic> json) {
    return SketchMapEntry(
      id: json['id'] ?? 'sketch_${DateTime.now().microsecondsSinceEpoch}',
      caseId: json['caseId'] ?? '',
      title: json['title'] ?? 'Rough Sketch Map with Index',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T').first,
      poDescription: json['poDescription'] ?? '',
      north: json['north'] ?? '',
      south: json['south'] ?? '',
      east: json['east'] ?? '',
      west: json['west'] ?? '',
      objects: ((json['objects'] as List?) ?? const []).map((e) => SketchMapObject.fromJson(Map<String, dynamic>.from(e))).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
