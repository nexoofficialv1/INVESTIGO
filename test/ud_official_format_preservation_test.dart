import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lifecycle inquest delegates to established detailed INQUEST FORM renderer', () {
    final source = File('lib/services/ud_lifecycle_document_service.dart').readAsStringSync();
    expect(source.contains('PdfService().buildUdInquestPdf'), isTrue);
    expect(source.contains('DocExportService().buildUdInquestDoc'), isTrue);
    expect(source.contains("'INQUEST / SURATHAL REPORT'"), isFalse);
  });

  test('dead body challan preserves W.B. Form 5371 renderer and does not add replacement columns', () {
    final source = File('lib/services/ud_lifecycle_document_service.dart').readAsStringSync();
    expect(source.contains('PdfService().buildUdDeadBodyChallanPdf'), isTrue);
    expect(source.contains('DocExportService().buildUdDeadBodyChallanDoc'), isTrue);
    expect(source.contains("'DEAD BODY CHALLAN / POST-MORTEM FORWARDING'"), isFalse);
    expect(source.contains("'directionFromPs': flow.meansOfDispatch"), isTrue);
  });

  test('UD final report preserves Form 5370 and PRB Form 53 layout markers', () {
    final source = File('lib/services/ud_lifecycle_document_service.dart').readAsStringSync();
    expect(source.contains('West Bengal form No. 5370'), isTrue);
    expect(source.contains('P.R.B. Form No.- 53 Vide Rule 276'), isTrue);
    expect(source.contains('FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE'), isTrue);
    expect(source.contains('Date and hour of going to the spot'), isTrue);
    expect(source.contains('Date and hour of dispatch of the final report'), isTrue);
    expect(source.contains('This final report is generated only from facts'), isFalse);
  });

  test('spot visit date and time are separate lifecycle fields', () {
    final model = File('lib/models/ud_lifecycle.dart').readAsStringSync();
    final screen = File('lib/screens/ud_case_workflow_screen.dart').readAsStringSync();
    expect(model.contains('spotVisitDate'), isTrue);
    expect(model.contains('spotVisitTime'), isTrue);
    expect(screen.contains('ঘটনাস্থলে যাওয়ার তারিখ'), isTrue);
    expect(screen.contains('ঘটনাস্থলে যাওয়ার সময়'), isTrue);
  });

  test('full established inquest fields remain fillable behind a simple expansion', () {
    final screen = File('lib/screens/ud_case_workflow_screen.dart').readAsStringSync();
    for (final marker in [
      'সম্পূর্ণ সুরতহাল ফর্মের আরও তথ্য',
      'Rigor Mortis',
      'Ligature mark / rope / knot description',
      'Articles at P.O. including weapon/ornaments',
      'Brief facts — separate sheet text',
    ]) {
      expect(screen.contains(marker), isTrue, reason: marker);
    }
  });
}
