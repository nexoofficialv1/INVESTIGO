import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RC1 settings hub and compact CD renderer are present', () {
    final settings = File('lib/screens/settings_screen.dart').readAsStringSync();
    final dashboard = File('lib/screens/dashboard_screen.dart').readAsStringSync();
    final pdf = File('lib/services/pdf_service.dart').readAsStringSync();

    expect(settings, contains('Backup & Restore'));
    expect(settings, contains('RC-1 Status'));
    expect(dashboard, contains('SettingsScreen'));
    expect(dashboard, contains("'INVESTIGO'"));
    expect(pdf, isNot(contains('final estimatedHeight')));
    expect(pdf, contains('horizontalInside: pw.BorderSide(width: 0.55)'));
  });

  test('production source contains no station-specific defaults', () {
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(source, isNot(contains('Kalna Police Station')));
    expect(source, isNot(contains('Purba Bardhaman')));
  });
}
