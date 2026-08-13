import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/ud_case.dart';
import 'package:investigo/models/ud_lifecycle.dart';
import 'package:investigo/services/ud_lifecycle_validation_service.dart';

void main() {
  const validator = UdLifecycleValidationService();

  UdCase validUd() => UdCase.empty(ps: 'Kalna PS', district: 'Purba Bardhaman').copyWith({
        'udNo': '100/2026',
        'dateTime': '2026-08-13 09:00',
        'placeFound': 'STKK Road',
        'informantName': 'Informant',
        'deceasedName': 'Deceased',
        'identifiedByName': 'Identifier',
        'bodyPosition': 'Supine',
        'witness1NameAddress': 'Witness One',
        'witness2NameAddress': 'Witness Two',
      });

  test('registration blocks missing critical identity fields', () {
    final result = validator.registration(UdCase.empty());
    expect(result.ok, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('challan is expected on PM day or previous day, earlier gives warning', () {
    final ud = validUd();
    final flow = UdLifecycleRecord.empty(ud.id).copyWith(
      inquestCompleted: true,
      spotVisitDate: '2026-08-10',
      spotVisitTime: '17:00',
      inquestDate: '2026-08-10',
      pmPlannedDate: '2026-08-13',
      challanDate: '2026-08-10',
      challanTime: '18:00',
      bodyDispatchDate: '2026-08-10',
      bodyDispatchTime: '18:30',
      pmHospital: 'Kalna Hospital',
      meansOfDispatch: 'Government vehicle',
      escortDetails: 'Constable A',
    );
    final result = validator.challan(ud, flow);
    expect(result.ok, isTrue);
    expect(result.warnings, isNotEmpty);
  });

  test('challan after planned PM date is blocked', () {
    final ud = validUd();
    final flow = UdLifecycleRecord.empty(ud.id).copyWith(
      inquestCompleted: true,
      spotVisitDate: '2026-08-13',
      spotVisitTime: '07:00',
      inquestDate: '2026-08-13',
      pmPlannedDate: '2026-08-13',
      challanDate: '2026-08-14',
      challanTime: '08:00',
      bodyDispatchDate: '2026-08-13',
      bodyDispatchTime: '08:30',
      pmHospital: 'Kalna Hospital',
      meansOfDispatch: 'Government vehicle',
      escortDetails: 'Constable A',
    );
    expect(validator.challan(ud, flow).ok, isFalse);
  });

  test('final report is impossible before PM report received', () {
    final flow = UdLifecycleRecord.empty('ud1').copyWith(
      spotVisitDate: '2026-08-13',
      spotVisitTime: '08:00',
      foulPlayAssessment: UdFoulPlayAssessment.notDetected,
      finalInvestigationSummary: 'Officer-entered summary',
      finalDispatchDate: '2026-08-15',
      finalDispatchTime: '12:00',
    );
    expect(validator.finalReport(flow).ok, isFalse);
  });

  test('pending viscera/FSL/other report blocks finalization', () {
    final flow = UdLifecycleRecord.empty('ud1').copyWith(
      pmReportReceived: true,
      spotVisitDate: '2026-08-13',
      spotVisitTime: '08:00',
      foulPlayAssessment: UdFoulPlayAssessment.inconclusive,
      otherReportPending: true,
      pendingReportDetails: 'Viscera report awaited',
      finalInvestigationSummary: 'Officer-entered summary',
      finalDispatchDate: '2026-08-15',
      finalDispatchTime: '12:00',
    );
    expect(validator.finalReport(flow).ok, isFalse);
  });

  test('spot visit date/time is separately required and must not be after inquest start', () {
    final ud = validUd();
    final missing = UdLifecycleRecord.empty(ud.id).copyWith(
      inquestDate: '2026-08-13',
      inquestStartTime: '10:00',
      inquestPlace: 'PO',
    );
    expect(validator.inquest(ud, missing).ok, isFalse);

    final lateSpot = missing.copyWith(
      spotVisitDate: '2026-08-13',
      spotVisitTime: '11:00',
    );
    expect(validator.inquest(ud, lateSpot).ok, isFalse);
  });

}
