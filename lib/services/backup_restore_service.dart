import 'package:shared_preferences/shared_preferences.dart';

import '../models/officer_profile.dart';
import 'offline_license_service.dart';

class BackupRestoreService {
  static const String appName = 'INVESTIGO';
  static const int backupVersion = 2;

  bool isLicensePreferenceKey(String key) {
    return key.startsWith('offline_license_') ||
        key == 'license_plan_v1' ||
        key == 'license_status_v1' ||
        key == 'license_fee_v1' ||
        key == 'license_upi_v1' ||
        key == 'license_txn_v1' ||
        key == 'license_code_v1';
  }

  Future<Map<String, dynamic>> collect({
    required OfficerProfile officer,
    required OfflineLicenseSnapshot license,
    DateTime? createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final data = <String, dynamic>{};

    for (final key in keys) {
      if (isLicensePreferenceKey(key)) continue;
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        data[key] = value;
      }
    }

    return {
      'app': appName,
      'backupVersion': backupVersion,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'officer': officer.toJson(),
      'binding': {
        'mode': license.isLicensed ? 'licensed' : 'trial',
        'deviceCode': license.deviceCode,
        'licenseId': license.licenseId ?? '',
      },
      'data': data,
    };
  }

  String? validateForRestore(
    Map<String, dynamic> decoded,
    OfflineLicenseSnapshot current,
  ) {
    final version = decoded['backupVersion'];
    final app = decoded['app']?.toString().trim() ?? '';
    final dataRaw = decoded['data'];

    if (version == backupVersion && app != appName) {
      return 'This backup was not created by INVESTIGO.';
    }
    if (app.isNotEmpty && app != appName) {
      return 'This backup belongs to a different application.';
    }
    if (dataRaw is! Map) {
      return 'Backup data section is missing or invalid.';
    }

    for (final entry in dataRaw.entries) {
      final key = entry.key.toString();
      if (isLicensePreferenceKey(key)) continue;
      if (!_isSupportedJsonValue(entry.value)) {
        return 'Backup contains an unsupported value for "$key".';
      }
    }

    final bindingRaw = decoded['binding'];

    // Legacy v1 backups are never restorable into a fresh trial. A licensed
    // installation may still import them for migration.
    if (version != backupVersion || bindingRaw is! Map) {
      return current.isLicensed
          ? null
          : 'Legacy backup restore requires an active yearly license.';
    }

    final binding = Map<String, dynamic>.from(bindingRaw);
    final mode = binding['mode']?.toString() ?? '';
    final backupDeviceCode = binding['deviceCode']?.toString() ?? '';
    final backupLicenseId = binding['licenseId']?.toString() ?? '';

    if (mode == 'trial') {
      if (current.state != OfflineLicenseState.trial) {
        return 'Trial backup can only be restored during the same active trial.';
      }
      if (backupDeviceCode != current.deviceCode) {
        return 'Trial backup belongs to another installation and cannot be restored here.';
      }
      return null;
    }

    if (mode == 'licensed') {
      if (!current.isLicensed) {
        return 'Licensed backup restore requires an active yearly license.';
      }
      if (backupLicenseId.isEmpty || backupLicenseId != current.licenseId) {
        return 'This licensed backup belongs to a different license.';
      }
      return null;
    }

    return 'Backup license binding is invalid.';
  }

  Future<void> restore(Map<String, dynamic> decoded) async {
    final dataRaw = decoded['data'];
    if (dataRaw is! Map) {
      throw const FormatException('Backup data section is missing or invalid.');
    }

    final data = Map<String, dynamic>.from(dataRaw);
    final staged = <String, Object>{};

    // Validate and stage everything before mutating local preferences.
    for (final entry in data.entries) {
      if (isLicensePreferenceKey(entry.key)) continue;
      final value = entry.value;
      if (value is String || value is bool || value is int || value is double) {
        staged[entry.key] = value;
      } else if (value is List && value.every((item) => item is String)) {
        staged[entry.key] = value.cast<String>().toList(growable: false);
      } else {
        throw FormatException(
          'Unsupported backup value for preference "${entry.key}".',
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();

    // Exact-state restore: remove stale application preferences that are not
    // present in the backup. License/trial keys are explicitly preserved.
    final removableKeys = prefs
        .getKeys()
        .where((key) => !isLicensePreferenceKey(key))
        .toList(growable: false);
    for (final key in removableKeys) {
      await prefs.remove(key);
    }

    for (final entry in staged.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
    }
  }

  bool _isSupportedJsonValue(Object? value) {
    return value is String ||
        value is bool ||
        value is int ||
        value is double ||
        (value is List && value.every((item) => item is String));
  }
}
