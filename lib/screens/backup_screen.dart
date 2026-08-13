import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../models/backend_config.dart';
import '../services/local_store_service.dart';
import '../services/offline_license_service.dart';
import 'backend_settings_screen.dart';
import '../models/officer_profile.dart';

class BackupScreen extends StatefulWidget {
  final OfficerProfile profile;
  const BackupScreen({super.key, required this.profile});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final LocalStoreService _store = LocalStoreService();
  final OfflineLicenseService _licenseService = OfflineLicenseService();
  final TextEditingController _restoreController = TextEditingController();
  BackendConfig _config = BackendConfig.empty();
  String _status = 'Ready';
  String? _lastBackupPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _store.loadBackendConfig();
    if (!mounted) return;
    setState(() => _config = config);
  }

  bool _isLicensePreferenceKey(String key) {
    return key.startsWith('offline_license_') ||
        key == 'license_plan_v1' ||
        key == 'license_status_v1' ||
        key == 'license_fee_v1' ||
        key == 'license_upi_v1' ||
        key == 'license_txn_v1' ||
        key == 'license_code_v1';
  }

  Future<OfflineLicenseSnapshot> _requireActiveLicense() async {
    final snapshot = await _licenseService.evaluate();
    if (!snapshot.canUseApp) {
      throw StateError(
        'Trial expired. Activate a license before backup/restore.',
      );
    }
    return snapshot;
  }

  Future<Map<String, dynamic>> _collectBackup() async {
    final license = await _requireActiveLicense();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final data = <String, dynamic>{};
    for (final key in keys) {
      if (_isLicensePreferenceKey(key)) continue;
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
      'app': 'INVESTIGO',
      'backupVersion': 2,
      'createdAt': DateTime.now().toIso8601String(),
      'officer': widget.profile.toJson(),
      'binding': {
        'mode': license.isLicensed ? 'licensed' : 'trial',
        'deviceCode': license.deviceCode,
        'licenseId': license.licenseId ?? '',
      },
      'data': data,
    };
  }

  String? _restoreBindingError(
    Map<String, dynamic> decoded,
    OfflineLicenseSnapshot current,
  ) {
    final version = decoded['backupVersion'];
    final bindingRaw = decoded['binding'];

    // Legacy v1 backups are never restorable into a fresh trial. A licensed
    // installation may still import them for migration.
    if (version != 2 || bindingRaw is! Map) {
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

  Future<void> _createBackup({bool share = false}) async {
    setState(() {
      _busy = true;
      _status = 'Creating backup...';
    });
    try {
      final backup = await _collectBackup();
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/investigation_process_backup_$stamp.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup));
      if (!mounted) return;
      setState(() {
        _lastBackupPath = file.path;
        _status = 'Backup created: ${file.path}';
      });
      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: 'Investigation & Process local backup');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromText() async {
    final textValue = _restoreController.text.trim();
    if (textValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste backup JSON first')),
      );
      return;
    }

    Map<String, dynamic> decoded;
    OfflineLicenseSnapshot current;
    try {
      current = await _requireActiveLicense();
      decoded = Map<String, dynamic>.from(
        jsonDecode(textValue) as Map,
      );
      final bindingError = _restoreBindingError(decoded, current);
      if (bindingError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(bindingError)),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore blocked: $e')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
          'এতে app-এর local saved data overwrite হতে পারে। '
          'License/trial state কখনও backup থেকে restore হবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _busy = true;
      _status = 'Restoring backup...';
    });
    try {
      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        if (_isLicensePreferenceKey(entry.key)) continue;
        final value = entry.value;
        if (value is String) await prefs.setString(entry.key, value);
        if (value is bool) await prefs.setBool(entry.key, value);
        if (value is int) await prefs.setInt(entry.key, value);
        if (value is double) await prefs.setDouble(entry.key, value);
        if (value is List) {
          await prefs.setStringList(
            entry.key,
            value.map((e) => e.toString()).toList(),
          );
        }
      }
      if (!mounted) return;
      setState(
        () => _status = 'Restore complete. Restart app for best result.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBackend() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BackendSettingsScreen(profile: widget.profile)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Backup & Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Local Backup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Active trial/license থাকলেই backup নেওয়া যাবে। Trial শেষ হলে backup/export বন্ধ থাকবে। Trial backup শুধু একই installation-এ restore হবে। License/trial security keys backup-এ রাখা হবে না।'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _busy ? null : () => _createBackup(), icon: const Icon(Icons.save_alt), label: const Text('Create'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _createBackup(share: true), icon: const Icon(Icons.share), label: const Text('Share'))),
                ]),
                if (_lastBackupPath != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_lastBackupPath!, style: const TextStyle(fontSize: 12))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Backend Server Sync', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Mode: ${_config.mode}'),
                Text('Sync: ${_config.syncEnabled ? 'Enabled' : 'Disabled'}'),
                Text('Last status: ${_config.lastStatus}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _openBackend, icon: const Icon(Icons.dns_rounded), label: const Text('Add / Change Server')),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Restore from Backup JSON', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Backup restore license policy অনুযায়ী যাচাই হবে। Reinstall-এর নতুন trial-এ আগের trial installation-এর backup restore হবে না।'),
                const SizedBox(height: 10),
                TextField(controller: _restoreController, minLines: 5, maxLines: 10, decoration: const InputDecoration(labelText: 'Paste backup JSON here')),
                const SizedBox(height: 10),
                ElevatedButton.icon(onPressed: _busy ? null : _restoreFromText, icon: const Icon(Icons.restore), label: const Text('Restore')),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(_status, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
