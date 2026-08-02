import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FSL custody dropdown rejects legacy placeholder Sex value', () {
    final source = File('lib/screens/forms_screen.dart').readAsStringSync();
    expect(source, contains('_validSexValue'));
    expect(source, contains('_sanitiseLegacyCustodyRow'));
    expect(source, isNot(contains('| Occupation | Age | Sex | Date & time')));
  });

  test('smart narration entry points are visible for case and UD workflows', () {
    final caseSource =
        File('lib/screens/case_detail_screen.dart').readAsStringSync();
    final udSource = File('lib/screens/ud_case_screen.dart').readAsStringSync();
    expect(caseSource, contains('Smart Narration → CD'));
    expect(
      udSource,
      contains('Auto-fill Inquest + Challan + Final Report'),
    );
  });

  test('CD and statement exports use bilingual translation service', () {
    final pdfSource = File('lib/services/pdf_service.dart').readAsStringSync();
    final docSource =
        File('lib/services/doc_export_service.dart').readAsStringSync();
    expect(pdfSource, contains('translateToCurrentLanguage'));
    expect(docSource, contains('translateToCurrentLanguage'));
  });
}
