import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/services/backup_restore_service.dart';
import 'package:investigo/services/offline_license_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  OfflineLicenseSnapshot trialSnapshot({
    String deviceCode = 'INV-TEST-DEVICE-0001',
  }) {
    final start = DateTime.utc(2026, 8, 14);
    return OfflineLicenseSnapshot(
      state: OfflineLicenseState.trial,
      deviceCode: deviceCode,
      trialStartedAt: start,
      trialEndsAt: start.add(const Duration(days: 14)),
      licenseExpiresAt: null,
      licenseId: null,
      customer: null,
      daysRemaining: 14,
      detail: 'trial',
    );
  }

  OfflineLicenseSnapshot licensedSnapshot({
    String licenseId = 'LIC-001',
  }) {
    final start = DateTime.utc(2026, 8, 14);
    return OfflineLicenseSnapshot(
      state: OfflineLicenseState.licensed,
      deviceCode: 'INV-LICENSED-DEVICE',
      trialStartedAt: start,
      trialEndsAt: start.add(const Duration(days: 14)),
      licenseExpiresAt: DateTime.utc(2027, 8, 14),
      licenseId: licenseId,
      customer: 'Test Customer',
      daysRemaining: 365,
      detail: 'licensed',
    );
  }

  test('backup excludes license keys and includes restore binding', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'cases_v1': '[{"id":"case-1"}]',
      'app_language_v1': 'en',
      'offline_license_token_v209': 'DO-NOT-BACK-UP',
      'license_status_v1': 'DO-NOT-BACK-UP-EITHER',
    });

    final service = BackupRestoreService();
    final backup = await service.collect(
      officer: OfficerProfile.empty().copyWith(
        name: 'Test Officer',
        rank: 'SI',
        policeStation: 'Test PS',
        district: 'Test District',
      ),
      license: trialSnapshot(),
      createdAt: DateTime.utc(2026, 8, 14, 18),
    );

    expect(backup['app'], BackupRestoreService.appName);
    expect(backup['backupVersion'], BackupRestoreService.backupVersion);

    final data = Map<String, dynamic>.from(backup['data'] as Map);
    expect(data['cases_v1'], isNotNull);
    expect(data['app_language_v1'], 'en');
    expect(data.containsKey('offline_license_token_v209'), isFalse);
    expect(data.containsKey('license_status_v1'), isFalse);

    final binding = Map<String, dynamic>.from(backup['binding'] as Map);
    expect(binding['mode'], 'trial');
    expect(binding['deviceCode'], 'INV-TEST-DEVICE-0001');
  });

  test('trial restore is bound to the same installation', () {
    final service = BackupRestoreService();
    final backup = <String, dynamic>{
      'app': 'INVESTIGO',
      'backupVersion': 2,
      'binding': <String, dynamic>{
        'mode': 'trial',
        'deviceCode': 'INV-ORIGINAL',
        'licenseId': '',
      },
      'data': <String, dynamic>{'cases_v1': '[]'},
    };

    expect(
      service.validateForRestore(
        backup,
        trialSnapshot(deviceCode: 'INV-ORIGINAL'),
      ),
      isNull,
    );
    expect(
      service.validateForRestore(
        backup,
        trialSnapshot(deviceCode: 'INV-OTHER'),
      ),
      contains('another installation'),
    );
  });

  test('licensed restore is bound to the same license id', () {
    final service = BackupRestoreService();
    final backup = <String, dynamic>{
      'app': 'INVESTIGO',
      'backupVersion': 2,
      'binding': <String, dynamic>{
        'mode': 'licensed',
        'deviceCode': 'INV-OLD-DEVICE',
        'licenseId': 'LIC-001',
      },
      'data': <String, dynamic>{'cases_v1': '[]'},
    };

    expect(
      service.validateForRestore(
        backup,
        licensedSnapshot(licenseId: 'LIC-001'),
      ),
      isNull,
    );
    expect(
      service.validateForRestore(
        backup,
        licensedSnapshot(licenseId: 'LIC-OTHER'),
      ),
      contains('different license'),
    );
  });

  test('restore rejects a current-format backup from another app', () {
    final service = BackupRestoreService();
    final backup = <String, dynamic>{
      'app': 'OTHER_APP',
      'backupVersion': 2,
      'binding': <String, dynamic>{
        'mode': 'trial',
        'deviceCode': 'INV-TEST-DEVICE-0001',
        'licenseId': '',
      },
      'data': <String, dynamic>{'cases_v1': '[]'},
    };

    expect(
      service.validateForRestore(backup, trialSnapshot()),
      contains('not created by INVESTIGO'),
    );
  });

  test('restore replaces stale app data but preserves license preferences',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'cases_v1': 'OLD',
      'stale_key_v1': 'REMOVE-ME',
      'offline_license_token_v209': 'KEEP-LICENSE',
      'offline_license_device_code_v209': 'KEEP-DEVICE',
    });

    final service = BackupRestoreService();
    final backup = <String, dynamic>{
      'app': 'INVESTIGO',
      'backupVersion': 2,
      'binding': <String, dynamic>{
        'mode': 'trial',
        'deviceCode': 'INV-TEST-DEVICE-0001',
        'licenseId': '',
      },
      'data': <String, dynamic>{
        'cases_v1': 'NEW',
        'app_language_v1': 'bn',
        'list_key': <String>['one', 'two'],
      },
    };

    expect(service.validateForRestore(backup, trialSnapshot()), isNull);
    await service.restore(backup);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cases_v1'), 'NEW');
    expect(prefs.getString('app_language_v1'), 'bn');
    expect(prefs.getStringList('list_key'), <String>['one', 'two']);
    expect(prefs.containsKey('stale_key_v1'), isFalse);
    expect(prefs.getString('offline_license_token_v209'), 'KEEP-LICENSE');
    expect(
      prefs.getString('offline_license_device_code_v209'),
      'KEEP-DEVICE',
    );
  });
}
