import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UD lifecycle document service has no automatic no-foul-play fallback', () {
    final source = File('lib/services/ud_lifecycle_document_service.dart').readAsStringSync();
    expect(source.contains('no foul play was detected during enquiry'), isTrue);
    expect(source.contains('UdFoulPlayAssessment.notDetected'), isTrue);
    expect(source.contains('No foul play could be detected'), isFalse);
  });

  test('dashboard routes UD to lifecycle workflow', () {
    final source = File('lib/screens/dashboard_screen.dart').readAsStringSync();
    expect(source.contains('UdCaseWorkflowScreen'), isTrue);
    expect(source.contains('ReportScreen(profile: _profile, caseFile: null)'), isTrue);
  });

  test('case detail exposes case-linked report path', () {
    final source = File('lib/screens/case_detail_screen.dart').readAsStringSync();
    expect(source.contains("'রিপোর্ট'"), isTrue);
    expect(source.contains('ReportScreen('), isTrue);
  });
}
