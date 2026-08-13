import '../models/ud_case.dart';
import '../models/ud_lifecycle.dart';

class UdValidationResult {
  final List<String> errors;
  final List<String> warnings;

  const UdValidationResult({this.errors = const [], this.warnings = const []});

  bool get ok => errors.isEmpty;
}

class UdLifecycleValidationService {
  const UdLifecycleValidationService();

  UdValidationResult registration(UdCase ud) {
    final errors = <String>[];
    if (ud.udNo.trim().isEmpty) errors.add('UD Case No. দিন।');
    if (ud.dateTime.trim().isEmpty) errors.add('UD registration date/time দিন।');
    if (ud.placeFound.trim().isEmpty) errors.add('মৃতদেহ যেখানে পাওয়া গেছে সেই স্থান দিন।');
    if (ud.deceasedName.trim().isEmpty) errors.add('মৃত ব্যক্তির নাম দিন।');
    if (ud.informantName.trim().isEmpty) errors.add('Informant-এর নাম দিন।');
    return UdValidationResult(errors: errors);
  }

  UdValidationResult inquest(UdCase ud, UdLifecycleRecord flow) {
    final errors = <String>[...registration(ud).errors];
    if (flow.spotVisitDate.trim().isEmpty) errors.add('ঘটনাস্থলে যাওয়ার তারিখ দিন।');
    if (flow.spotVisitTime.trim().isEmpty) errors.add('ঘটনাস্থলে যাওয়ার সময় দিন।');
    if (flow.inquestDate.trim().isEmpty) errors.add('সুরতহালের তারিখ দিন।');
    if (flow.inquestStartTime.trim().isEmpty) errors.add('সুরতহাল শুরুর সময় দিন।');
    if (flow.inquestPlace.trim().isEmpty) errors.add('সুরতহালের স্থান দিন।');
    if (ud.identifiedByName.trim().isEmpty) errors.add('মৃতদেহ কে শনাক্ত করেছেন তার নাম দিন।');
    if (ud.witness1NameAddress.trim().isEmpty) errors.add('সুরতহাল সাক্ষী ১ দিন।');
    if (ud.witness2NameAddress.trim().isEmpty) errors.add('সুরতহাল সাক্ষী ২ দিন।');
    if (ud.bodyPosition.trim().isEmpty) errors.add('মৃতদেহের অবস্থার বিবরণ দিন।');

    final spotAt = _dateTime(flow.spotVisitDate, flow.spotVisitTime);
    final inquestAt = _dateTime(flow.inquestDate, flow.inquestStartTime);
    if (spotAt != null && inquestAt != null && spotAt.isAfter(inquestAt)) {
      errors.add('ঘটনাস্থলে যাওয়ার সময় সুরতহাল শুরুর সময়ের পরে হতে পারে না।');
    }
    return UdValidationResult(errors: errors);
  }

  UdValidationResult challan(UdCase ud, UdLifecycleRecord flow) {
    final errors = <String>[];
    final warnings = <String>[];
    if (!flow.inquestCompleted) errors.add('আগে সুরতহাল Final করুন।');
    if (flow.pmPlannedDate.trim().isEmpty) errors.add('নির্ধারিত PM date দিন।');
    if (flow.challanDate.trim().isEmpty) errors.add('Dead Body Challan date দিন।');
    if (flow.challanTime.trim().isEmpty) errors.add('Dead Body Challan time দিন।');
    if (flow.bodyDispatchDate.trim().isEmpty) errors.add('মৃতদেহ dispatch date দিন।');
    if (flow.bodyDispatchTime.trim().isEmpty) errors.add('মৃতদেহ dispatch time দিন।');
    if (flow.pmHospital.trim().isEmpty) errors.add('PM Hospital/Morgue দিন।');
    if (flow.meansOfDispatch.trim().isEmpty) errors.add('মৃতদেহ কীভাবে পাঠানো হবে তা দিন।');
    if (flow.escortDetails.trim().isEmpty) errors.add('Escort/Messenger details দিন।');

    final pm = _date(flow.pmPlannedDate);
    final challan = _date(flow.challanDate);
    final inquest = _date(flow.inquestDate);
    final challanDay = _date(flow.challanDate);
    final dispatch = _date(flow.bodyDispatchDate);
    if (pm != null && challan != null) {
      final days = pm.difference(challan).inDays;
      if (days < 0) errors.add('Dead Body Challan date PM date-এর পরে হতে পারে না।');
      if (days > 1) warnings.add('Challan PM-এর এক দিনের বেশি আগে তৈরি হচ্ছে। তারিখ যাচাই করুন।');
    }
    if (pm != null && inquest != null && inquest.isAfter(pm)) {
      errors.add('সুরতহালের তারিখ PM date-এর পরে হতে পারে না।');
    }
    if (challanDay != null && inquest != null && challanDay.isBefore(inquest)) {
      errors.add('Dead Body Challan date সুরতহালের তারিখের আগে হতে পারে না।');
    }
    if (dispatch != null && inquest != null && dispatch.isBefore(inquest)) {
      errors.add('Body dispatch date সুরতহালের তারিখের আগে হতে পারে না।');
    }
    if (pm != null && dispatch != null && dispatch.isAfter(pm)) {
      errors.add('Body dispatch date PM date-এর পরে হতে পারে না।');
    }
    return UdValidationResult(errors: errors, warnings: warnings);
  }

  UdValidationResult pmCompleted(UdLifecycleRecord flow) {
    final errors = <String>[];
    if (!flow.challanFinalized) errors.add('আগে Dead Body Challan/PM forwarding Final করুন।');
    if (flow.pmDate.trim().isEmpty) errors.add('PM সম্পন্ন হওয়ার তারিখ দিন।');
    if (flow.pmTime.trim().isEmpty) errors.add('PM সম্পন্ন হওয়ার সময় দিন।');
    if (flow.pmNumber.trim().isEmpty) errors.add('PM No./Reference দিন।');
    return UdValidationResult(errors: errors);
  }

  UdValidationResult pmReport(UdLifecycleRecord flow) {
    final errors = <String>[];
    if (!flow.pmCompleted) errors.add('আগে Post Mortem completed mark করুন।');
    if (flow.pmReportNo.trim().isEmpty) errors.add('PM Report No. দিন।');
    if (flow.pmReportReceivedDate.trim().isEmpty) errors.add('PM Report পাওয়ার তারিখ দিন।');
    if (flow.causeOfDeath.trim().isEmpty) errors.add('PM Report অনুযায়ী cause of death লিখুন।');
    return UdValidationResult(errors: errors);
  }

  UdValidationResult finalReport(UdLifecycleRecord flow) {
    final errors = <String>[];
    if (!flow.pmReportReceived) errors.add('PM Report পাওয়ার আগে Final Form তৈরি করা যাবে না।');
    if (flow.foulPlayAssessment == UdFoulPlayAssessment.notSelected) {
      errors.add('Investigation অনুযায়ী foul play assessment নির্বাচন করুন।');
    }
    if (flow.otherReportPending) {
      errors.add('অন্য report pending আছে। Final Form এখন Final করা যাবে না।');
    }
    if (flow.finalInvestigationSummary.trim().isEmpty) {
      errors.add('Officer-verified final investigation summary লিখুন।');
    }
    if (flow.spotVisitDate.trim().isEmpty || flow.spotVisitTime.trim().isEmpty) {
      errors.add('Final Form-এর জন্য ঘটনাস্থলে যাওয়ার তারিখ ও সময় Inquest stage-এ পূরণ করুন।');
    }
    if (flow.finalDispatchDate.trim().isEmpty) errors.add('Final Report dispatch date দিন।');
    if (flow.finalDispatchTime.trim().isEmpty) errors.add('Final Report dispatch time দিন।');
    return UdValidationResult(errors: errors);
  }

  DateTime? _dateTime(String date, String time) {
    if (date.trim().isEmpty || time.trim().isEmpty) return null;
    return DateTime.tryParse('${date.trim()}T${time.trim()}');
  }

  DateTime? _date(String raw) {
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}
