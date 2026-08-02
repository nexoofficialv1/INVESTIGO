import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/form_notice.dart';
import '../models/pending_cd_action.dart';
import '../models/sketch_map.dart';
import '../models/backend_config.dart';
import '../models/ud_case.dart';
import '../models/investigation_action.dart';
import '../models/ncr_report.dart';
import '../models/final_case_documents.dart';

class LocalStoreService {
  static const _profileKey = 'officer_profile_v1';
  static const _casesKey = 'cases_v1';
  static const _cdsKey = 'cd_entries_v1';
  static const _statementsKey = 'statement_entries_v1';
  static const _formsKey = 'form_notice_entries_v1';
  static const _pendingCdActionsKey = 'pending_cd_actions_v1';
  static const _sketchMapsKey = 'sketch_maps_v1';
  static const _backendConfigKey = 'backend_config_v1';
  static const _udCasesKey = 'ud_cases_v1';
  static const _investigationActionsKey = 'investigation_actions_v1';
  static const _ncrReportsKey = 'ncr_reports_v1';
  static const _finalCdDraftsKey = 'final_cd_drafts_v1';
  static const _chargeSheetDraftsKey = 'charge_sheet_drafts_v1';
  static const _if5DraftsKey = 'if5_drafts_v1';



  Future<FinalCdDraft?> loadFinalCdDraft(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_finalCdDraftsKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final item = map[caseId];
    if (item == null) return null;
    return FinalCdDraft.fromJson(Map<String, dynamic>.from(item));
  }

  Future<void> saveFinalCdDraft(FinalCdDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_finalCdDraftsKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    map[draft.caseId] = draft.toJson();
    await prefs.setString(_finalCdDraftsKey, jsonEncode(map));
  }

  Future<ChargeSheetDraft?> loadChargeSheetDraft(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chargeSheetDraftsKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final item = map[caseId];
    if (item == null) return null;
    return ChargeSheetDraft.fromJson(Map<String, dynamic>.from(item));
  }

  Future<void> saveChargeSheetDraft(ChargeSheetDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chargeSheetDraftsKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    map[draft.caseId] = draft.toJson();
    await prefs.setString(_chargeSheetDraftsKey, jsonEncode(map));
  }

  Future<If5Draft?> loadIf5Draft(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_if5DraftsKey);
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final item = map[caseId];
    if (item == null) return null;
    return If5Draft.fromJson(Map<String, dynamic>.from(item));
  }

  Future<void> saveIf5Draft(If5Draft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_if5DraftsKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw));
    map[draft.caseId] = draft.toJson();
    await prefs.setString(_if5DraftsKey, jsonEncode(map));
  }

  Future<List<NcrReport>> loadNcrReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ncrReportsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => NcrReport.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveNcrReport(NcrReport report) async {
    final reports = await loadNcrReports();
    final index = reports.indexWhere((e) => e.id == report.id);
    if (index >= 0) {
      reports[index] = report;
    } else {
      reports.add(report);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ncrReportsKey, jsonEncode(reports.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteNcrReport(String id) async {
    final reports = await loadNcrReports();
    reports.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ncrReportsKey, jsonEncode(reports.map((e) => e.toJson()).toList()));
  }



  Future<List<InvestigationActionEntry>> loadInvestigationActions(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_investigationActionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => InvestigationActionEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
  }

  Future<void> saveInvestigationAction(InvestigationActionEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_investigationActionsKey);
    final all = raw == null || raw.isEmpty
        ? <InvestigationActionEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => InvestigationActionEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.add(entry);
    }
    await prefs.setString(_investigationActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<List<UdCase>> loadUdCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_udCasesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UdCase.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveUdCase(UdCase udCase) async {
    final cases = await loadUdCases();
    final index = cases.indexWhere((c) => c.id == udCase.id);
    if (index >= 0) {
      cases[index] = udCase;
    } else {
      cases.add(udCase);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_udCasesKey, jsonEncode(cases.map((e) => e.toJson()).toList()));
  }

  Future<BackendConfig> loadBackendConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_backendConfigKey);
    if (raw == null || raw.isEmpty) return BackendConfig.empty();
    return BackendConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> saveBackendConfig(BackendConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendConfigKey, jsonEncode(config.toJson()));
  }

  Future<OfficerProfile> loadOfficerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return OfficerProfile.empty();
    return OfficerProfile.fromJson(jsonDecode(raw));
  }

  Future<void> saveOfficerProfile(OfficerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<List<CaseFile>> loadCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_casesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CaseFile.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveCase(CaseFile file) async {
    final cases = await loadCases();
    final index = cases.indexWhere((c) => c.id == file.id);
    if (index >= 0) {
      cases[index] = file;
    } else {
      cases.add(file);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _casesKey,
      jsonEncode(cases.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<CdEntry>> loadCds(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cdsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CdEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => a.cdNumber.compareTo(b.cdNumber));
  }

  Future<void> saveCd(CdEntry cd) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cdsKey);
    final all = raw == null || raw.isEmpty
        ? <CdEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => CdEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == cd.id);
    if (index >= 0) {
      all[index] = cd;
    } else {
      all.add(cd);
    }
    await prefs.setString(
      _cdsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<int> nextCdNumber(String caseId) async {
    final cds = await loadCds(caseId);
    if (cds.isEmpty) return 1;
    return cds.map((e) => e.cdNumber).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<List<StatementEntry>> loadStatements(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statementsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => StatementEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveStatement(StatementEntry statement) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statementsKey);
    final all = raw == null || raw.isEmpty
        ? <StatementEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => StatementEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    all.add(statement);
    await prefs.setString(
      _statementsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }


  Future<List<FormNotice>> loadForms(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_formsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FormNotice.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveForm(FormNotice form) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_formsKey);
    final all = raw == null || raw.isEmpty
        ? <FormNotice>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => FormNotice.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == form.id);
    if (index >= 0) {
      all[index] = form;
    } else {
      all.add(form);
    }
    await prefs.setString(
      _formsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }


  Future<List<PendingCdAction>> loadPendingCdActions(String caseId, {bool includeConsumed = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId && (includeConsumed || !e.consumed))
        .toList()
      ..sort((a, b) => a.actionDate.compareTo(b.actionDate));
  }

  Future<void> savePendingCdAction(PendingCdAction action) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    final all = raw == null || raw.isEmpty
        ? <PendingCdAction>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    final duplicate = all.indexWhere((e) => e.caseId == action.caseId && e.sourceId == action.sourceId && e.title == action.title && !e.consumed);
    if (duplicate >= 0) {
      all[duplicate] = action;
    } else {
      all.add(action);
    }
    await prefs.setString(_pendingCdActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> markPendingCdActionsConsumed(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCdActionsKey);
    if (raw == null || raw.isEmpty) return;
    final all = (jsonDecode(raw) as List<dynamic>)
        .map((e) => PendingCdAction.fromJson(Map<String, dynamic>.from(e)))
        .map((e) => ids.contains(e.id) ? e.copyWith(consumed: true) : e)
        .toList();
    await prefs.setString(_pendingCdActionsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }



  Future<SketchMapEntry?> loadSketchMap(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sketchMapsKey);
    if (raw == null || raw.isEmpty) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    final maps = list
        .map((e) => SketchMapEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.caseId == caseId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return maps.isEmpty ? null : maps.first;
  }

  Future<void> saveSketchMap(SketchMapEntry map) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sketchMapsKey);
    final all = raw == null || raw.isEmpty
        ? <SketchMapEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => SketchMapEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
    final index = all.indexWhere((e) => e.id == map.id);
    if (index >= 0) {
      all[index] = map;
    } else {
      all.add(map);
    }
    await prefs.setString(_sketchMapsKey, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

}
