import '../../models/ud_case.dart';
import '../../services/local_store_service.dart';
import 'domain_kind.dart';

/// Storage boundary for UD Case documents only.
///
/// Inquest, Surathal, Dead Body Challan, PM Requisition and UD Final Report
/// share this domain. Regular Case and NCR records are intentionally absent.
class UdCaseStore {
  UdCaseStore({LocalStoreService? localStore})
      : _localStore = localStore ?? LocalStoreService();

  final LocalStoreService _localStore;

  DomainKind get domain => DomainKind.udCase;

  Future<List<UdCase>> loadUdCases() => _localStore.loadUdCases();
  Future<void> saveUdCase(UdCase udCase) =>
      _localStore.saveUdCase(udCase);
}
