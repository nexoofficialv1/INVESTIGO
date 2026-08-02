import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily CD body is rendered directly and preserves saved entry rows', () {
    final source = File('lib/services/pdf_service.dart').readAsStringSync();
    final start = source.indexOf('Future<Uint8List> buildCaseDiaryPdf');
    final end = source.indexOf('List<CdEntry> _splitCdIntoPageChunks', start);
    final renderer = source.substring(start, end);

    expect(renderer, contains('_wbOfficialCdContinuousTable('));
    expect(renderer, isNot(contains('pw.Expanded(\n                child: _wbOfficialCdContinuousTable')));
    expect(source, contains('const maxCharsPerPage = 2100;'));
  });

  test('dead body challan avoids rotated flex layout assertion', () {
    final source = File('lib/services/pdf_service.dart').readAsStringSync();
    final start = source.indexOf('Future<Uint8List> buildUdDeadBodyChallanPdf');
    final end = source.indexOf('Future<Uint8List> buildUdFinalReportPdf', start);
    final renderer = source.substring(start, end);

    expect(renderer, contains('pw.MultiPage('));
    expect(renderer, contains('West Bengal Form No- 5371'));
    expect(renderer, isNot(contains('pw.Transform.rotate')));
    expect(renderer, isNot(contains('pw.Expanded(')));
  });

  test('FSL has a separately accessible exhibit challan preview', () {
    final pdf = File('lib/services/pdf_service.dart').readAsStringSync();
    final screen = File('lib/screens/forms_screen.dart').readAsStringSync();

    expect(pdf, contains('buildFslExhibitChallanPdf'));
    expect(pdf, contains('EXHIBIT CHALLAN'));
    expect(screen, contains('Challan Preview'));
    expect(screen, contains('_previewFslChallan'));
  });

  test('charge sheet and IF5 use official Form 39 tables in PDF and DOC', () {
    final pdf = File('lib/services/pdf_service.dart').readAsStringSync();
    final doc = File('lib/services/doc_export_service.dart').readAsStringSync();

    for (final source in [pdf, doc]) {
      expect(source, contains('FINAL FORM / FINAL REPORT'));
      expect(source, contains('Particulars of witnesses to be examined'));
      expect(source, contains('Property description'));
      expect(source, contains('Type of evidence to be tendered'));
      expect(source, contains('F-142, 143, 144'));
    }
  });
}
