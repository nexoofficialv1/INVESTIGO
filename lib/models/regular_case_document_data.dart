import 'case_file.dart';
import 'cd_entry.dart';
import 'statement_entry.dart';

/// Shared source used only by Regular Police Case documents:
/// CD, Final CD, Charge Sheet and IF-5.
/// UD and NCR are intentionally excluded from this domain.
class RegularCaseDocumentData {
  final CaseFile caseFile;
  final List<CdEntry> caseDiaries;
  final List<StatementEntry> witnessStatements;
  final String investigationSummary;
  final String accusedStatusSummary;
  final String reliedDocumentsSummary;
  final String resultCommunication;

  const RegularCaseDocumentData({
    required this.caseFile,
    required this.caseDiaries,
    required this.witnessStatements,
    required this.investigationSummary,
    required this.accusedStatusSummary,
    required this.reliedDocumentsSummary,
    required this.resultCommunication,
  });

  List<CdEntry> get orderedCaseDiaries {
    final items = [...caseDiaries];
    items.sort((a, b) => a.cdNumber.compareTo(b.cdNumber));
    return items;
  }

  String get witnessList => witnessStatements
      .map((item) => [item.witnessName.trim(), item.witnessDetails.trim()]
          .where((value) => value.isNotEmpty)
          .join(', '))
      .where((value) => value.isNotEmpty)
      .join('\n');

  bool get hasDailyCd => caseDiaries.any((item) => !item.isFinal);
  bool get hasFinalCd => caseDiaries.any((item) => item.isFinal);
}
