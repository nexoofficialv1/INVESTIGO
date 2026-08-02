import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF CD uses official continuous four-column body', () {
    final source = File('lib/services/pdf_service.dart').readAsStringSync();
    final start = source.indexOf('pw.Widget _wbOfficialCdContinuousTable');
    final end = source.indexOf('pw.Widget _wbOfficialCdSignature', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final renderer = source.substring(start, end);
    expect(renderer, contains('columnWidths: widths'));
    expect(renderer, contains("'Particulars of Enquiry.'"));
    expect(renderer.contains('_roman(cd.cdNumber)'), isFalse);
    expect(renderer, isNot(contains('horizontalInside:')));
  });

  test('CD header derives official year, date and station name', () {
    final source = File('lib/services/pdf_service.dart').readAsStringSync();
    expect(source, contains('_caseYear(caseFile)'));
    expect(source, contains('_officialDate(caseFile.caseDate)'));
    expect(source, contains('_officialDate(cd.cdDate)'));
    expect(source, contains('_barePsName(officer.policeStation)'));
    expect(source, contains('_roman(cd.cdNumber)'));
  });

  test('DOC CD uses same locked 9-9-11-71 column proportions', () {
    final source = File('lib/services/doc_export_service.dart').readAsStringSync();
    expect(
      source,
      contains(
        '<colgroup><col style="width:9%"><col style="width:9%"><col style="width:11%"><col style="width:71%"></colgroup>',
      ),
    );
    expect(source, contains(r'Case Diary No: -${_roman(cd.cdNumber)}'));
    expect(source, contains('class="entry-row"'));
  });
}
