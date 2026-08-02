import '../models/final_case_documents.dart';
import '../models/regular_case_document_data.dart';

class FinalCaseDocumentService {
  const FinalCaseDocumentService();

  FinalCaseDocumentSet buildDrafts(RegularCaseDocumentData source) {
    final caseFile = source.caseFile;
    final dailyNarrative = source.orderedCaseDiaries
        .expand((cd) => cd.tableLines)
        .map((line) => line.proceedings.trim())
        .where((value) => value.isNotEmpty)
        .join('\n\n');
    final summary = source.investigationSummary.trim().isNotEmpty
        ? source.investigationSummary.trim()
        : dailyNarrative;

    final finalCd = FinalCdDraft(
      caseId: caseFile.id,
      narrative: summary,
      witnessList: source.witnessList,
      accusedStatus: source.accusedStatusSummary,
      entryTime: '23:59 hrs',
      entryPlace: 'PS',
      synopsis: 'Closing / Final Investigation',
      updatedAt: DateTime.now(),
    );

    final chargeSheet = ChargeSheetDraft(
      caseId: caseFile.id,
      chargeSheetNo: '',
      chargeSheetDate: '',
      courtName: '',
      sections: caseFile.sections,
      accusedParticulars: source.accusedStatusSummary.trim().isNotEmpty
          ? source.accusedStatusSummary
          : caseFile.accusedName,
      witnessList: source.witnessList,
      briefFacts: summary,
      reliedDocuments: source.reliedDocumentsSummary,
      updatedAt: DateTime.now(),
    );

    final if5 = If5Draft(
      caseId: caseFile.id,
      courtName: '',
      finalReportType: 'Charge-Sheet',
      complainant: caseFile.complainantName,
      accusedParticulars: chargeSheet.accusedParticulars,
      witnessList: source.witnessList,
      propertyDocuments: source.reliedDocumentsSummary,
      briefFacts: summary,
      resultCommunication: source.resultCommunication,
      chargeSheetNo: chargeSheet.chargeSheetNo,
      chargeSheetDate: chargeSheet.chargeSheetDate,
      originalOrSupplementary: 'Original',
      investigatingOfficer: '',
      unchargedAccused: '',
      laboratoryResult: '',
      falseCaseAction: '',
      dispatchDetails: '',
      updatedAt: DateTime.now(),
    );

    return FinalCaseDocumentSet(
      source: source,
      finalCd: finalCd,
      chargeSheet: chargeSheet,
      if5: if5,
    );
  }

  List<String> validateForClosure(RegularCaseDocumentData source) {
    final issues = <String>[];
    if (source.caseFile.psCaseNo.trim().isEmpty) issues.add('Case number is missing.');
    if (source.caseFile.sections.trim().isEmpty) issues.add('Sections are missing.');
    if (!source.hasDailyCd) issues.add('At least one daily CD is required.');
    if (source.witnessStatements.isEmpty) issues.add('Witness list is empty.');
    if (source.accusedStatusSummary.trim().isEmpty) issues.add('Accused status is missing.');
    if (source.investigationSummary.trim().isEmpty && source.caseDiaries.isEmpty) {
      issues.add('Investigation summary is missing.');
    }
    return issues;
  }
}
