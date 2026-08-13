import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/offline_license_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v209.1 starts a 14-day offline trial', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = OfflineLicenseService();
    final start = DateTime.utc(2026, 8, 13, 0, 0);
    final first = await service.evaluate(nowUtc: start);
    expect(first.state, OfflineLicenseState.trial);
    expect(first.daysRemaining, 14);

    final expired =
        await service.evaluate(nowUtc: start.add(const Duration(days: 15)));
    expect(expired.state, OfflineLicenseState.expired);
  });

  test('v209.1 detects material clock rollback', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = OfflineLicenseService();
    final day10 = DateTime.utc(2026, 8, 23, 12);
    await service.evaluate(nowUtc: day10);
    final rolledBack =
        await service.evaluate(nowUtc: day10.subtract(const Duration(days: 1)));
    expect(rolledBack.state, OfflineLicenseState.clockError);
  });

  test('v209.1 verifies an Ed25519 yearly license offline', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'offline_license_device_code_v209': 'INV-TEST-DEVICE-0001',
    });
    final service = OfflineLicenseService();
    const token = 'INV1.eyJjdXN0b21lciI6IkNJIFRFU1QiLCJkZXZpY2VDb2RlIjoiSU5WLVRFU1QtREVWSUNFLTAwMDEiLCJleHBpcmVzQXQiOiIyMDI3LTA4LTEzVDIzOjU5OjU5WiIsImlzc3VlZEF0IjoiMjAyNi0wOC0xM1QwMDowMDowMFoiLCJsaWNlbnNlSWQiOiJURVNULUxJQy0wMDEiLCJwbGFuIjoiWUVBUkxZIiwicHJvZHVjdCI6IklOVkVTVElHTyJ9.i6RG78GYWwGDu_Ynm5uCrBYf-0Tt5FjaL_y5cywvo2BDsTJIXtxY1Tavg1INaBlT8V1mW-NldLNg-Z7VqF5FAw';
    final result = await service.activate(
      token,
      nowUtc: DateTime.utc(2026, 8, 13, 12),
    );
    expect(result.success, isTrue);
    expect(result.snapshot?.state, OfflineLicenseState.licensed);
  });

  test('v209.1 product gate enforces locked expiry and install-bound trial backup', () {
    final dashboard =
        File('lib/screens/dashboard_screen.dart').readAsStringSync();
    final parser =
        File('lib/screens/case_parser_screen.dart').readAsStringSync();
    final license =
        File('lib/screens/license_screen.dart').readAsStringSync();
    final intro = File('lib/screens/intro_screen.dart').readAsStringSync();
    final workflow =
        File('.github/workflows/android-apk.yml').readAsStringSync();

    expect(dashboard, contains('Manual Case Entry'));
    expect(dashboard, contains('Case Parser / FIR'));
    expect(dashboard, contains("title: L10n.t('কেস পার্সার', 'Case Parser')"));
    expect(parser, contains('PS Case No. missing'));
    expect(parser, contains('Date & Time of Reporting missing'));
    expect(license, contains('OfflineLicenseService'));
    expect(license, isNot(contains('code.length < 6')));
    expect(intro, contains('100% Offline • Secure Local Workflow'));
    final backup =
        File('lib/screens/backup_screen.dart').readAsStringSync();

    expect(workflow, contains('Configure INVESTIGO native splash'));
    expect(workflow, contains('Disable Android automatic data restore'));
    expect(
      workflow,
      contains("text = set_attr(text, 'allowBackup', 'false')"),
    );
    expect(
      workflow,
      contains("text = set_attr(text, 'fullBackupContent', 'false')"),
    );

    expect(backup, contains("'backupVersion': 2"));
    expect(backup, contains("key.startsWith('offline_license_')"));
    expect(backup, contains("mode == 'trial'"));
    expect(backup, contains('backupDeviceCode != current.deviceCode'));
    expect(backup, contains('Trial backup belongs to another installation'));
    expect(backup, contains('Trial expired. Activate a license before backup/restore.'));
    expect(license, contains('Trial শেষ হলে activation ছাড়া app-এর কোনো data, backup, export বা restore access থাকবে না'));
  });
}
