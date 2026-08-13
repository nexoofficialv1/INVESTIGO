import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/statement_entry.dart';

class LinkedStatementStoreService {
  static const _statementsKey = 'statement_entries_v1';

  Future<int> replaceLinkedStatementsForCd({
    required String caseId,
    required int cdNumber,
    required List<StatementEntry> entries,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statementsKey);
    final all = raw == null || raw.isEmpty
        ? <StatementEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => StatementEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    all.removeWhere(
      (e) => e.caseId == caseId &&
          e.linkedFromCd &&
          e.sourceCdNumber == cdNumber,
    );
    all.addAll(entries);

    await prefs.setString(
      _statementsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
    return entries.length;
  }
}
