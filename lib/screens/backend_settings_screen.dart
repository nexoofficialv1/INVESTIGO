import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/backend_config.dart';
import '../models/officer_profile.dart';
import '../services/backend_api_service.dart';
import '../services/local_store_service.dart';

class BackendSettingsScreen extends StatefulWidget {
  final OfficerProfile profile;
  const BackendSettingsScreen({super.key, required this.profile});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final LocalStoreService _store = LocalStoreService();
  final BackendApiService _api = BackendApiService();
  final _apiBaseController = TextEditingController();
  final _tokenController = TextEditingController();
  final _uploadController = TextEditingController();

  BackendConfig _config = BackendConfig.empty();
  bool _busy = true;
  bool _testing = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await _store.loadBackendConfig();
    _apiBaseController.text = config.apiBaseUrl;
    _tokenController.text = config.apiToken;
    _uploadController.text = config.fileUploadUrl;
    if (!mounted) return;
    setState(() {
      _config = config;
      _busy = false;
    });
  }

  Future<void> _save({String? status, DateTime? testedAt}) async {
    final updated = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
      lastStatus: status,
      lastTestedAt: testedAt,
    );
    await _store.saveBackendConfig(updated);
    if (!mounted) return;
    setState(() => _config = updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backend settings saved')));
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    final draft = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
    );
    final result = await _api.testConnection(draft);
    await _store.saveBackendConfig(draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now()));
    if (!mounted) return;
    setState(() {
      _config = draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now());
      _testing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final cases = await _store.loadCases();
    final draft = _config.copyWith(
      apiBaseUrl: _apiBaseController.text.trim(),
      apiToken: _tokenController.text.trim(),
      fileUploadUrl: _uploadController.text.trim(),
    );
    final result = await _api.syncCases(config: draft, profile: widget.profile, cases: cases);
    await _store.saveBackendConfig(draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now()));
    if (!mounted) return;
    setState(() {
      _config = draft.copyWith(lastStatus: result, lastTestedAt: DateTime.now());
      _syncing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Backend Server Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(),
          const SizedBox(height: 12),
          _modeCard(),
          const SizedBox(height: 12),
          _serverCard(),
          const SizedBox(height: 12),
          _migrationCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            Text('Mode: ${_config.mode}'),
            Text('Sync: ${_config.syncEnabled ? 'Enabled' : 'Disabled'}'),
            Text('Last status: ${_config.lastStatus}'),
            if (_config.lastTestedAt != null) Text('Last test/sync: ${_config.lastTestedAt}'),
          ]),
        ),
      );

  Widget _modeCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Backend Mode', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            RadioListTile<String>(
              value: 'offline',
              groupValue: _config.mode,
              title: const Text('Offline Only'),
              subtitle: const Text('সব data mobile-এর local storage-এ থাকবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, syncEnabled: false, lastStatus: 'Offline only')),
            ),
            RadioListTile<String>(
              value: 'custom_server',
              groupValue: _config.mode,
              title: const Text('Custom Server + PostgreSQL'),
              subtitle: const Text('নিজস্ব API server দিয়ে data PostgreSQL-এ save/sync হবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, lastStatus: 'Custom server mode selected')),
            ),
            RadioListTile<String>(
              value: 'supabase',
              groupValue: _config.mode,
              title: const Text('Supabase / PostgreSQL later'),
              subtitle: const Text('পরবর্তী সময়ে Supabase URL/Key বসিয়ে enable করা যাবে।'),
              onChanged: (v) => setState(() => _config = _config.copyWith(mode: v, syncEnabled: false, lastStatus: 'Supabase setup pending')),
            ),
            SwitchListTile(
              value: _config.syncEnabled,
              title: const Text('Enable Sync'),
              subtitle: const Text('Server connection test successful হলে enable করুন।'),
              onChanged: _config.mode == 'custom_server' ? (v) => setState(() => _config = _config.copyWith(syncEnabled: v)) : null,
            ),
          ]),
        ),
      );

  Widget _serverCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Custom Server Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            TextField(controller: _apiBaseController, decoration: const InputDecoration(labelText: 'API Base URL', hintText: 'https://api.yourdomain.com')),
            const SizedBox(height: 8),
            TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'API Token / Bearer Token')),
            const SizedBox(height: 8),
            TextField(controller: _uploadController, decoration: const InputDecoration(labelText: 'File Upload URL (optional)')),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: _testing ? null : _test, icon: const Icon(Icons.wifi_tethering), label: Text(_testing ? 'Testing...' : 'Test'))),
            ]),
          ]),
        ),
      );

  Widget _migrationCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Local Data Upload / Migration', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            const Text('Backend চালু করার পরে existing local cases server-এ upload করা যাবে। প্রথম version-এ cases sync হবে; পরে CD, statement, forms, evidence, files sync add হবে।'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncing || !_config.isOnlineEnabled ? null : _syncNow,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_syncing ? 'Syncing...' : 'Upload Local Cases Now'),
            ),
          ]),
        ),
      );
}
