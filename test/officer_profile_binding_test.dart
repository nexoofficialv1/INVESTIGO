import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/officer_profile.dart';

void main() {
  test('empty profile has no hard-coded station or district', () {
    final profile = OfficerProfile.empty();
    expect(profile.policeStation, isEmpty);
    expect(profile.district, isEmpty);
    expect(profile.isComplete, isFalse);
  });

  test('old JSON remains backward compatible', () {
    final profile = OfficerProfile.fromJson({
      'name': 'Officer',
      'rank': 'SI',
      'policeStation': 'Jamalpur PS',
      'district': 'Purba Bardhaman',
    });
    expect(profile.policeStation, 'Jamalpur PS');
    expect(profile.defaultFslOffice, isEmpty);
    expect(profile.isComplete, isTrue);
  });
}
