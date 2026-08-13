import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:investigo/services/sketch_map_auto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auto Sketch Map v200', () {
    test('builds PO + N/S/E/W + north arrow and index automatically', () {
      final service = SketchMapAutoService();
      final map = service.generateDraft(
        caseId: 'case_605',
        sourceCdNumber: 1,
        exactPo: 'On STKK Road, Sahapur Kalitala',
        north: 'Pond',
        south: 'Village road',
        east: 'House of A',
        west: 'Vacant land',
      );

      expect(map.poDescription, contains('STKK Road'));
      expect(map.objects.map((e) => e.marker), containsAll(<String>['X', 'A', 'B', 'C', 'D', 'N']));
      expect(map.objects.firstWhere((e) => e.marker == 'X').indexDescription, contains('PO of the case'));
      expect(service.validateDraft(map), isEmpty);
    });

    test('approval becomes invalid automatically after map edit', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final service = SketchMapAutoService();
      final map = service.generateDraft(
        caseId: 'case_605',
        sourceCdNumber: 1,
        exactPo: 'STKK Road',
        north: 'A',
        south: 'B',
        east: 'C',
        west: 'D',
      );
      final approval = await service.approve(
        map: map,
        officerName: 'SI Test Officer',
        sourceCdNumber: 1,
      );
      expect(service.isApprovedFor(map, approval), isTrue);

      final edited = map.copyWith(
        objects: map.objects
            .map((e) => e.marker == 'A' ? e.copyWith(x: e.x + .05) : e)
            .toList(),
      );
      expect(service.isApprovedFor(edited, approval), isFalse);
    });
  });
}
