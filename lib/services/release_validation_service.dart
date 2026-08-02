import '../models/case_file.dart';
import '../models/ud_case.dart';
import '../models/ncr_report.dart';

/// A deterministic, offline readiness checker used before a release build.
/// It does not transmit case data and it never modifies stored records.
class ReleaseValidationIssue {
  const ReleaseValidationIssue({
    required this.code,
    required this.message,
    required this.blocking,
  });

  final String code;
  final String message;
  final bool blocking;
}

class ReleaseValidationReport {
  const ReleaseValidationReport(this.issues);

  final List<ReleaseValidationIssue> issues;

  bool get isReady => !issues.any((issue) => issue.blocking);
  int get blockingCount => issues.where((issue) => issue.blocking).length;
  int get warningCount => issues.where((issue) => !issue.blocking).length;
}

class ReleaseValidationService {
  const ReleaseValidationService();

  ReleaseValidationReport validateRegularCase(CaseFile caseFile) {
    final issues = <ReleaseValidationIssue>[];
    _required(issues, 'CASE_NO', caseFile.psCaseNo, 'Case number is missing.');
    _required(issues, 'CASE_DATE', caseFile.caseDate, 'Case date is missing.');
    _required(issues, 'SECTIONS', caseFile.sections, 'Act/sections are missing.');
    _required(
      issues,
      'COMPLAINANT',
      caseFile.complainantName,
      'Complainant/informant is missing.',
    );

    if (caseFile.accusedName.trim().isEmpty) {
      issues.add(const ReleaseValidationIssue(
        code: 'NO_ACCUSED',
        message: 'No accused particulars are available.',
        blocking: false,
      ));
    }

    return ReleaseValidationReport(issues);
  }

  ReleaseValidationReport validateUdCase(UdCase udCase) {
    final issues = <ReleaseValidationIssue>[];
    _required(issues, 'UD_NO', udCase.udNo, 'UD number is missing.');
    _required(issues, 'UD_DATE', udCase.dateTime, 'UD date is missing.');
    _required(
      issues,
      'DECEASED_NAME',
      udCase.deceasedName,
      'Deceased name is missing.',
    );
    _required(
      issues,
      'PLACE_FOUND',
      udCase.placeFound,
      'Place where the body was found is missing.',
    );
    if (udCase.probableCauseOfDeath.trim().isEmpty) {
      issues.add(const ReleaseValidationIssue(
        code: 'CAUSE_PENDING',
        message: 'Probable/final cause of death is not recorded.',
        blocking: false,
      ));
    }
    return ReleaseValidationReport(issues);
  }

  ReleaseValidationReport validateNcr(NcrReport report) {
    final issues = <ReleaseValidationIssue>[];
    _required(issues, 'NCR_NO', report.ncrNo, 'NCR number is missing.');
    _required(
      issues,
      'NCR_COMPLAINANT',
      report.complainantInformation,
      'Complainant/information details are missing.',
    );
    _required(
      issues,
      'NCR_OFFENCE',
      report.offenceBrief,
      'Brief description of the offence is missing.',
    );
    return ReleaseValidationReport(issues);
  }

  void _required(
    List<ReleaseValidationIssue> issues,
    String code,
    String value,
    String message,
  ) {
    if (value.trim().isEmpty) {
      issues.add(ReleaseValidationIssue(
        code: code,
        message: message,
        blocking: true,
      ));
    }
  }
}
