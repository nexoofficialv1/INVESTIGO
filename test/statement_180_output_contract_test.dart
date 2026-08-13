import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _method(String source, String start, String end) {
  final from = source.indexOf(start);
  final to = source.indexOf(end, from + start.length);
  expect(from, greaterThanOrEqualTo(0));
  expect(to, greaterThan(from));
  return source.substring(from, to);
}

void main() {
  test('u/s 180 statement outputs do not request maker signature', () {
    final pdf = File('lib/services/pdf_service.dart').readAsStringSync();
    final doc = File('lib/services/doc_export_service.dart').readAsStringSync();

    final pdfMethod = _method(
      pdf,
      'Future<Uint8List> buildStatementPdf',
      'Future<void> shareCaseDiaryPdf',
    );
    final docMethod = _method(
      doc,
      'Future<Uint8List> buildStatementDoc',
      'String _field(',
    );

    for (final source in <String>[pdfMethod, docMethod]) {
      expect(source, isNot(contains('Signature/LTI/RTI of witness')));
      expect(source, isNot(contains('সাক্ষীর স্বাক্ষর/এলটিআই/আরটিআই')));
      expect(source, contains('Recorded by'));
      expect(source, contains('sourceCdNumber'));
      expect(source, contains('recordedTime'));
      expect(source, contains('recordedPlace'));
    }
  });
}
