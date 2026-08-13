import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ud_lifecycle.dart';

class UdLifecycleStore {
  static const _key = 'ud_lifecycle_v208';

  Future<UdLifecycleRecord> load(String udCaseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return UdLifecycleRecord.empty(udCaseId);
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final item = map[udCaseId];
    if (item == null) return UdLifecycleRecord.empty(udCaseId);
    return UdLifecycleRecord.fromJson(Map<String, dynamic>.from(item));
  }

  Future<Map<String, UdLifecycleRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return {
      for (final entry in map.entries)
        entry.key: UdLifecycleRecord.fromJson(Map<String, dynamic>.from(entry.value)),
    };
  }

  Future<void> save(UdLifecycleRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    map[record.udCaseId] = record.toJson();
    await prefs.setString(_key, jsonEncode(map));
  }
}
