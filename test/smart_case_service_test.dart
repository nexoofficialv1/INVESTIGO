import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/investigation_action.dart';
import 'package:investigo/services/smart_case_service.dart';

InvestigationActionEntry action(String type, {String date = '2026-08-02'}) {
  return InvestigationActionEntry.create(
    caseId: 'case-1',
    actionDate: date,
    actionType: type,
    outsidePs: false,
    departureTime: '',
    actionArrivalTime: '',
    returnTime: '',
    place: '',
    accompaniedBy: '',
    sopResponse: '',
    details: 'details',
    arrestInvolved: false,
    seizureInvolved: false,
    courtForwardingSuggested: false,
    pcPrayerSuggested: false,
  );
}

void main() {
  final service = SmartCaseService();

  test('second PO visit needs justification', () {
    final result = service.assessBeforeSave(
      proposed: action('PO Visit / Local Enquiry'),
      existing: [action('PO Visit / Local Enquiry', date: '2026-08-01')],
    );
    expect(result.needsReason, isTrue);
    expect(result.message, contains('2026-08-01'));
  });

  test('witness statements are repeatable', () {
    final result = service.assessBeforeSave(
      proposed: action('Witness Examination / Statement Record'),
      existing: [action('Witness Examination / Statement Record')],
    );
    expect(result.needsReason, isFalse);
  });
}
