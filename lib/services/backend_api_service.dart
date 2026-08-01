import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_config.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';

class BackendApiService {
  Future<String> testConnection(BackendConfig config) async {
    if (!config.isCustomServer) {
      return config.mode == 'offline' ? 'Offline mode selected' : 'Supabase mode will be configured later';
    }
    final base = config.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return 'API Base URL is empty';
    try {
      final res = await http
          .get(Uri.parse('$base/health'), headers: _headers(config))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return 'Connected: ${res.body}';
      }
      return 'Server responded ${res.statusCode}: ${res.body}';
    } catch (e) {
      return 'Connection failed: $e';
    }
  }

  Future<String> syncCases({
    required BackendConfig config,
    required OfficerProfile profile,
    required List<CaseFile> cases,
  }) async {
    if (!config.isCustomServer || !config.syncEnabled) return 'Sync disabled';
    final base = config.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return 'API Base URL is empty';
    try {
      final payload = {
        'officer': profile.toJson(),
        'cases': cases.map((e) => e.toJson()).toList(),
      };
      final res = await http
          .post(Uri.parse('$base/api/sync/cases'), headers: _headers(config), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode >= 200 && res.statusCode < 300) return 'Synced ${cases.length} cases';
      return 'Sync failed ${res.statusCode}: ${res.body}';
    } catch (e) {
      return 'Sync failed: $e';
    }
  }

  Map<String, String> _headers(BackendConfig config) => {
        'Content-Type': 'application/json',
        if (config.apiToken.trim().isNotEmpty) 'Authorization': 'Bearer ${config.apiToken.trim()}',
      };
}
