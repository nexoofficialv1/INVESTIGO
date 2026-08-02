import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CD preview is not blocked by translation model preparation', () {
    final source = File('lib/screens/cd_editor_screen.dart').readAsStringSync();
    final start = source.indexOf('Future<void> _previewPdf()');
    final end = source.indexOf('void _addEntry()', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final method = source.substring(start, end);
    expect(method, contains('PdfPreviewScreen'));
    expect(method, isNot(contains('prepareForTexts')));
    expect(method, isNot(contains('prepareModels')));
  });

  test('preview caches PDF and exposes retry and export errors', () {
    final source = File('lib/screens/pdf_preview_screen.dart').readAsStringSync();
    expect(source, contains('class PdfPreviewScreen extends StatefulWidget'));
    expect(source, contains('late Future<Uint8List> _pdfFuture'));
    expect(source, contains('FutureBuilder<Uint8List>'));
    expect(source, contains("label: const Text('Retry')"));
    expect(source, contains("_showError('PDF export/share'"));
    expect(source, contains("_showError('DOC export/share'"));
  });

  test('translation and font dependencies have operational fallbacks', () {
    final translation = File(
      'lib/services/bilingual_translation_service.dart',
    ).readAsStringSync();
    final pdf = File('lib/services/pdf_service.dart').readAsStringSync();
    expect(translation, contains('Duration(seconds: 20)'));
    expect(translation, contains('Duration(minutes: 1)'));
    expect(pdf, contains('pw.Font.helvetica()'));
  });
}
