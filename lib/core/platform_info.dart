import 'package:flutter/foundation.dart';

bool isDesktopTarget(TargetPlatform platform) {
  return platform == TargetPlatform.windows ||
      platform == TargetPlatform.macOS ||
      platform == TargetPlatform.linux;
}

bool get isDesktopRuntime => !kIsWeb && isDesktopTarget(defaultTargetPlatform);
