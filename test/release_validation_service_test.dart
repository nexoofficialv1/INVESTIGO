import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/services/release_validation_service.dart';

void main() {
  const service = ReleaseValidationService();

  test('regular case without core fields is blocked', () {
    final report = service.validateRegularCase(CaseFile.empty());
    expect(report.isReady, isFalse);
    expect(report.blockingCount, greaterThan(0));
  });
}
