import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/cd_entry.dart';
import 'package:investigo/models/regular_case_document_data.dart';
import 'package:investigo/models/statement_entry.dart';
import 'package:investigo/services/final_case_document_service.dart';

void main() {
  test('Final CD, Charge Sheet and IF5 use one regular-case source', () {
    final caseFile = CaseFile.empty().copyWith(
      psCaseNo: '10/2026',
      sections: '115/351 BNS',
      complainantName: 'Complainant A',
      accusedName: 'Accused A',
    );
    final cd = CdEntry.newDraft(
      caseId: caseFile.id,
      cdNumber: 1,
      body: 'Visited PO and examined witnesses.',
    );
    final witness = StatementEntry.create(
      caseId: caseFile.id,
      witnessName: 'Witness A',
      witnessDetails: 'Village X',
      statementType: '161/180',
      body: 'Statement body',
    );
    final source = RegularCaseDocumentData(
      caseFile: caseFile,
      caseDiaries: [cd],
      witnessStatements: [witness],
      investigationSummary: 'Investigation completed.',
      accusedStatusSummary: 'Accused A - arrested',
      reliedDocumentsSummary: 'FIR, statements, sketch map',
      resultCommunication: 'Result informed to complainant.',
    );

    final set = const FinalCaseDocumentService().buildDrafts(source);
    expect(set.finalCd.caseId, caseFile.id);
    expect(set.chargeSheet.caseId, caseFile.id);
    expect(set.if5.caseId, caseFile.id);
    expect(set.chargeSheet.witnessList, contains('Witness A'));
    expect(set.if5.briefFacts, 'Investigation completed.');
  });

  test('UD and NCR are not part of the regular case source model', () {
    final fields = RegularCaseDocumentData.new.toString();
    expect(fields, isNot(contains('UdCase')));
    expect(fields, isNot(contains('NcrReport')));
  });
}
