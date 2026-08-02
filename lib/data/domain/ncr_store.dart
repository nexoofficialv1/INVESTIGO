import '../../models/ncr_report.dart';
import '../../services/local_store_service.dart';
import 'domain_kind.dart';

/// Storage boundary for NCR records only.
class NcrStore {
  NcrStore({LocalStoreService? localStore})
      : _localStore = localStore ?? LocalStoreService();

  final LocalStoreService _localStore;

  DomainKind get domain => DomainKind.ncr;

  Future<List<NcrReport>> loadNcrReports() =>
      _localStore.loadNcrReports();
  Future<void> saveNcrReport(NcrReport report) =>
      _localStore.saveNcrReport(report);
  Future<void> deleteNcrReport(String id) =>
      _localStore.deleteNcrReport(id);
}
