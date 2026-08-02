import '../../models/case_file.dart';
import '../../models/cd_entry.dart';
import '../../models/form_notice.dart';
import '../../models/investigation_action.dart';
import '../../models/pending_cd_action.dart';
import '../../models/sketch_map.dart';
import '../../models/statement_entry.dart';
import '../../models/final_case_documents.dart';
import '../../services/local_store_service.dart';
import 'domain_kind.dart';

/// Storage boundary for regular police cases only.
///
/// CD, Final CD, Charge Sheet, IF-5, Sketch Map and Index must read from this
/// domain. UD and NCR records are intentionally not exposed here.
class CaseInvestigationStore {
  CaseInvestigationStore({LocalStoreService? localStore})
      : _localStore = localStore ?? LocalStoreService();

  final LocalStoreService _localStore;

  DomainKind get domain => DomainKind.caseInvestigation;

  Future<List<CaseFile>> loadCases() => _localStore.loadCases();
  Future<void> saveCase(CaseFile file) => _localStore.saveCase(file);

  Future<List<CdEntry>> loadCds(String caseId) =>
      _localStore.loadCds(caseId);
  Future<void> saveCd(CdEntry entry) => _localStore.saveCd(entry);
  Future<int> nextCdNumber(String caseId) =>
      _localStore.nextCdNumber(caseId);

  Future<List<StatementEntry>> loadStatements(String caseId) =>
      _localStore.loadStatements(caseId);
  Future<void> saveStatement(StatementEntry entry) =>
      _localStore.saveStatement(entry);

  Future<List<FormNotice>> loadForms(String caseId) =>
      _localStore.loadForms(caseId);
  Future<void> saveForm(FormNotice form) => _localStore.saveForm(form);

  Future<List<PendingCdAction>> loadPendingCdActions(
    String caseId, {
    bool includeConsumed = false,
  }) =>
      _localStore.loadPendingCdActions(
        caseId,
        includeConsumed: includeConsumed,
      );
  Future<void> savePendingCdAction(PendingCdAction action) =>
      _localStore.savePendingCdAction(action);
  Future<void> markPendingCdActionsConsumed(List<String> ids) =>
      _localStore.markPendingCdActionsConsumed(ids);

  Future<List<InvestigationActionEntry>> loadInvestigationActions(
    String caseId,
  ) =>
      _localStore.loadInvestigationActions(caseId);
  Future<void> saveInvestigationAction(InvestigationActionEntry entry) =>
      _localStore.saveInvestigationAction(entry);

  Future<FinalCdDraft?> loadFinalCdDraft(String caseId) =>
      _localStore.loadFinalCdDraft(caseId);
  Future<void> saveFinalCdDraft(FinalCdDraft draft) =>
      _localStore.saveFinalCdDraft(draft);

  Future<ChargeSheetDraft?> loadChargeSheetDraft(String caseId) =>
      _localStore.loadChargeSheetDraft(caseId);
  Future<void> saveChargeSheetDraft(ChargeSheetDraft draft) =>
      _localStore.saveChargeSheetDraft(draft);

  Future<If5Draft?> loadIf5Draft(String caseId) =>
      _localStore.loadIf5Draft(caseId);
  Future<void> saveIf5Draft(If5Draft draft) =>
      _localStore.saveIf5Draft(draft);

  Future<SketchMapEntry?> loadSketchMap(String caseId) =>
      _localStore.loadSketchMap(caseId);
  Future<void> saveSketchMap(SketchMapEntry map) =>
      _localStore.saveSketchMap(map);
}
