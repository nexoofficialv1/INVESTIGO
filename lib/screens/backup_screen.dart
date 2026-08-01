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

  Future<Map<String, dynamic>> _collectBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    final data = <String, dynamic>{};
    for (final key in keys) {
      final value = prefs.get(key);
      if (value is String || value is bool || value is int || value is double || value is List<String>) {
        data[key] = value;
      }
    }
    return {
      'app': 'Investigation & Process',
      'backupVersion': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'officer': widget.profile.toJson(),
      'data': data,
    };
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
    final text = _restoreController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste backup JSON first')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text('এতে app-এর local saved data overwrite হতে পারে। আগে current backup নিয়ে নিন।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _status = 'Restoring backup...';
    });
    try {
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String) await prefs.setString(entry.key, value);
        if (value is bool) await prefs.setBool(entry.key, value);
        if (value is int) await prefs.setInt(entry.key, value);
        if (value is double) await prefs.setDouble(entry.key, value);
        if (value is List) await prefs.setStringList(entry.key, value.map((e) => e.toString()).toList());
      }
      if (!mounted) return;
      setState(() => _status = 'Restore complete. Restart app for best result.');
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
                const Text('এই backup app-এর local case, CD, forms, evidence, sketch map, UD case, backend settings ইত্যাদি JSON file হিসেবে save/share করবে।'),
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
                const Text('Backup file খুলে JSON text paste করলে restore করা যাবে।'),
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
