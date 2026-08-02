import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/rc_feature_manifest.dart';

void main() {
  test('RC-1 manifest keeps deferred modules out of included scope', () {
    expect(RcFeatureManifest.included.any((e) => e.id == 'sync'), isFalse);
    expect(RcFeatureManifest.included.any((e) => e.id == 'court'), isFalse);
    expect(RcFeatureManifest.included.any((e) => e.id == 'case-cd'), isTrue);
    expect(RcFeatureManifest.included.any((e) => e.id == 'ud-final'), isTrue);
    expect(RcFeatureManifest.included.any((e) => e.id == 'ncr'), isTrue);
  });
}
