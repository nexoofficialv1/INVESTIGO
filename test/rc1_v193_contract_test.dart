import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FSL custody dropdown rejects legacy placeholder Sex value', () {
    final source = File('lib/screens/forms_screen.dart').readAsStringSync();
    expect(source, contains('_validSexValue'));
    expect(source, contains('_sanitiseLegacyCustodyRow'));
    expect(source, isNot(contains('| Occupation | Age | Sex | Date & time')));
  });

  test('smart narration entry point and staged UD lifecycle are visible', () {
    final caseSource =
        File('lib/screens/case_detail_screen.dart').readAsStringSync();
    final udWorkflowSource =
        File('lib/screens/ud_case_workflow_screen.dart').readAsStringSync();

    // v207+ keeps Smart Narration as a real case action, but title/subtitle are
    // split for the simpler card UI instead of one literal legacy label.
    expect(caseSource, contains('Smart Narration'));
    expect(caseSource, contains('Narration → CD'));

    // v208+ deliberately replaced the old one-tap UD auto-fill flow with the
    // safe staged lifecycle requested for actual police work.
    expect(udWorkflowSource, contains('PM Report Received'));
    expect(udWorkflowSource, contains('UD Final Form'));
    expect(udWorkflowSource, contains('সুরতহাল / Inquest'));
  });

  test('CD and statement exports use bilingual translation service', () {
    final pdfSource = File('lib/services/pdf_service.dart').readAsStringSync();
    final docSource =
        File('lib/services/doc_export_service.dart').readAsStringSync();
    expect(pdfSource, contains('translateToCurrentLanguage'));
    expect(docSource, contains('translateToCurrentLanguage'));
  });
}
