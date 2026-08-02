import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/sketch_map.dart';

void main() {
  test('professional sketch map object library includes field landmarks', () {
    expect(SketchObjectType.values, containsAll(<SketchObjectType>[
      SketchObjectType.tower,
      SketchObjectType.lampPost,
      SketchObjectType.gumti,
      SketchObjectType.vacantLand,
      SketchObjectType.gate,
      SketchObjectType.electricPole,
      SketchObjectType.canal,
      SketchObjectType.river,
      SketchObjectType.railway,
      SketchObjectType.school,
      SketchObjectType.hospital,
      SketchObjectType.office,
    ]));
  });

  test('all sketch objects preserve rotation through json', () {
    final object = SketchMapObject.create(
      type: SketchObjectType.house,
      marker: 'A',
    ).copyWith(rotationDeg: 135, width: .31, height: .27);
    final restored = SketchMapObject.fromJson(object.toJson());
    expect(restored.rotationDeg, 135);
    expect(restored.width, .31);
    expect(restored.height, .27);
  });
}
