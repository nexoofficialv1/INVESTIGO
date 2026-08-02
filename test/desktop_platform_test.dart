import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/core/platform_info.dart';

void main() {
  test('desktop platforms are detected', () {
    expect(isDesktopTarget(TargetPlatform.windows), isTrue);
    expect(isDesktopTarget(TargetPlatform.macOS), isTrue);
    expect(isDesktopTarget(TargetPlatform.linux), isTrue);
  });

  test('mobile platforms are not detected as desktop', () {
    expect(isDesktopTarget(TargetPlatform.android), isFalse);
    expect(isDesktopTarget(TargetPlatform.iOS), isFalse);
    expect(isDesktopTarget(TargetPlatform.fuchsia), isFalse);
  });
}
