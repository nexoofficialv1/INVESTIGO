import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/app_language.dart';
import '../models/officer_profile.dart';
import '../models/ud_case.dart';
import '../models/ud_lifecycle.dart';
import 'doc_export_service.dart';
import 'pdf_service.dart';

/// v208.1 official-format adapter.
///
/// The lifecycle controls WHEN a UD document may be prepared/finalized and
/// supplies stage-specific facts. The printable layout remains the established
/// INVESTIGO official layout:
/// - INQUEST FORM (existing detailed form)
/// - W.B. Form No. 5371 / P.R.B. Form No. 54, Rule 252
/// - W.B. Form No. 5370 / P.R.B. Form No. 53, Rule 276
///
/// Do not add lifecycle/debug notes, extra columns, or replacement headings to
/// these official outputs.
class UdLifecycleDocumentService {
  Future<pw.ThemeData> _theme() async {
    try {
      final regular = await PdfGoogleFonts.notoSerifBengaliRegular();
      final bold = await PdfGoogleFonts.notoSerifBengaliBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      try {
        final regular = await PdfGoogleFonts.notoSansBengaliRegular();
        final bold = await PdfGoogleFonts.notoSansBengaliBold();
        return pw.ThemeData.withFont(base: regular, bold: bold);
      } catch (_) {
        return pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        );
      }
    }
  }

  String _t(String bn, String en) =>
      AppLanguageController.instance.isBengali ? bn : en;

  String _join(Iterable<String> parts, {String separator = '\n'}) => parts
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .join(separator);

  String _stageDateTime(String date, String time) =>
      _join([date, time], separator: ' ');

  /// Reuses the established detailed INQUEST FORM renderer. Only the stage
  /// date/time and officer-entered observation are adapted into the legacy
  /// document payload; the underlying UD registration record is not mutated.
  UdCase _inquestDocumentUd(UdCase ud, UdLifecycleRecord flow) {
    final remarks = _join([
      ud.remarks,
      if (flow.inquestObservation.trim().isNotEmpty)
        '${_t('সুরতহালকারী অফিসারের পর্যবেক্ষণ', 'Inquest officer observation')}: ${flow.inquestObservation}',
    ]);
    return ud.copyWith({
      'dateTime': _stageDateTime(flow.inquestDate, flow.inquestStartTime),
      'remarks': remarks,
    });
  }

  /// Reuses the established W.B. Form 5371 renderer. Lifecycle-only fields
  /// which have no dedicated column in Form 5371 are placed in the existing
  /// Remarks cell; no new column is introduced.
  UdCase _challanDocumentUd(
    OfficerProfile officer,
    UdCase ud,
    UdLifecycleRecord flow,
  ) {
    final remarks = _join([
      ud.remarks,
      if (flow.challanDate.trim().isNotEmpty)
        '${_t('চালানের তারিখ/সময়', 'Challan date/time')}: ${_stageDateTime(flow.challanDate, flow.challanTime)}',
      if (flow.pmHospital.trim().isNotEmpty)
        '${_t('PM হাসপাতাল/মর্গ', 'PM Hospital/Morgue')}: ${flow.pmHospital}',
      if (flow.escortDetails.trim().isNotEmpty)
        '${_t('এসকর্ট/মেসেঞ্জার', 'Escort/Messenger')}: ${flow.escortDetails}',
      if (flow.documentsSent.trim().isNotEmpty)
        '${_t('সঙ্গে পাঠানো কাগজপত্র', 'Documents sent')}: ${flow.documentsSent}',
      if (flow.pmPlannedDate.trim().isNotEmpty)
        '${_t('নির্ধারিত PM তারিখ', 'Proposed PM date')}: ${flow.pmPlannedDate}',
    ]);

    final articles = flow.articlesSent.trim().isNotEmpty
        ? flow.articlesSent.trim()
        : ud.articlesAtPo;

    return ud.copyWith({
      // In the established 5371 template this field is used for the reference
      // date and the dispatch-date/hour column.
      'dateTime': _stageDateTime(flow.bodyDispatchDate, flow.bodyDispatchTime),
      // Existing 5371 field: Means of Dispatch. This corrects the previous
      // misuse of Direction from PS without changing the printed column.
      'directionFromPs': flow.meansOfDispatch,
      // The 5371 column specifically asks for identifying Police officer.
      'identifiedByName': '${officer.rank} ${officer.name}'.trim(),
      'identifiedByAddress': officer.policeStation,
      'articlesAtPo': articles,
      'remarks': remarks,
    });
  }

  Future<Uint8List> buildInquestPdf({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) {
    return PdfService().buildUdInquestPdf(
      officer: officer,
      ud: _inquestDocumentUd(ud, flow),
    );
  }

  Future<Uint8List> buildInquestDoc({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) {
    return DocExportService().buildUdInquestDoc(
      officer: officer,
      ud: _inquestDocumentUd(ud, flow),
    );
  }

  Future<Uint8List> buildDeadBodyChallanPdf({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) {
    return PdfService().buildUdDeadBodyChallanPdf(
      officer: officer,
      ud: _challanDocumentUd(officer, ud, flow),
    );
  }

  Future<Uint8List> buildDeadBodyChallanDoc({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) {
    return DocExportService().buildUdDeadBodyChallanDoc(
      officer: officer,
      ud: _challanDocumentUd(officer, ud, flow),
    );
  }

  String _assessmentText(UdFoulPlayAssessment value) {
    switch (value) {
      case UdFoulPlayAssessment.detected:
        return _t(
          'তদন্তকারী/অনুসন্ধানকারী অফিসার তদন্তে foul play / criminality পাওয়া গেছে বলে নথিভুক্ত করেছেন।',
          'The investigating/enquiring officer has recorded that foul play / criminality was detected during enquiry.',
        );
      case UdFoulPlayAssessment.notDetected:
        return _t(
          'তদন্তকারী/অনুসন্ধানকারী অফিসার তদন্তে foul play পাওয়া যায়নি বলে নথিভুক্ত করেছেন।',
          'The investigating/enquiring officer has recorded that no foul play was detected during enquiry.',
        );
      case UdFoulPlayAssessment.inconclusive:
        return _t(
          'তদন্তকারী/অনুসন্ধানকারী অফিসার উপলব্ধ উপাদানের ভিত্তিতে মতামত অনির্ণীত (inconclusive) বলে নথিভুক্ত করেছেন।',
          'The investigating/enquiring officer has recorded that the assessment remained inconclusive on the available materials.',
        );
      case UdFoulPlayAssessment.notSelected:
        return '';
    }
  }

  String _finalNarrative(UdLifecycleRecord flow) {
    final parts = <String>[
      if (flow.pmNumber.trim().isNotEmpty || flow.pmDate.trim().isNotEmpty)
        _t(
          'ময়নাতদন্তের বিবরণ: PM No. ${flow.pmNumber}, তারিখ ${flow.pmDate}${flow.pmHospital.trim().isEmpty ? '' : ', স্থান ${flow.pmHospital}'}${flow.doctorName.trim().isEmpty ? '' : ', চিকিৎসক ${flow.doctorName}'}।',
          'Post-mortem particulars: PM No. ${flow.pmNumber}, dated ${flow.pmDate}${flow.pmHospital.trim().isEmpty ? '' : ', at ${flow.pmHospital}'}${flow.doctorName.trim().isEmpty ? '' : ', Doctor ${flow.doctorName}'}.',
        ),
      if (flow.pmReportNo.trim().isNotEmpty ||
          flow.pmReportDate.trim().isNotEmpty ||
          flow.pmReportReceivedDate.trim().isNotEmpty)
        _t(
          'PM Report No. ${flow.pmReportNo}, report date ${flow.pmReportDate}, প্রাপ্তির তারিখ ${flow.pmReportReceivedDate}।',
          'PM Report No. ${flow.pmReportNo}, report date ${flow.pmReportDate}, received on ${flow.pmReportReceivedDate}.',
        ),
      if (flow.causeOfDeath.trim().isNotEmpty)
        _t(
          'PM Report অনুযায়ী মৃত্যুর কারণ: ${flow.causeOfDeath}',
          'Cause of death as recorded from the PM Report: ${flow.causeOfDeath}',
        ),
      if (flow.injuryFindings.trim().isNotEmpty)
        _t(
          'PM Report-এর injury findings: ${flow.injuryFindings}',
          'Injury findings recorded from the PM Report: ${flow.injuryFindings}',
        ),
      if (flow.medicalOpinion.trim().isNotEmpty)
        _t('Medical opinion: ${flow.medicalOpinion}', 'Medical opinion: ${flow.medicalOpinion}'),
      if (flow.otherMedicalOpinion.trim().isNotEmpty)
        _t('Other medical opinion: ${flow.otherMedicalOpinion}', 'Other medical opinion: ${flow.otherMedicalOpinion}'),
      flow.finalInvestigationSummary,
    ];
    return _join(parts, separator: '\n\n');
  }

  String _finalPrayer(UdFoulPlayAssessment value) {
    switch (value) {
      case UdFoulPlayAssessment.notDetected:
        return _t(
          'অতএব, উপরোক্ত U/D মামলাটি নথিভুক্ত করে বাধিত করার প্রার্থনা করছি।',
          'Therefore, I am praying that this U/D Case may kindly be filed and obliged.',
        );
      case UdFoulPlayAssessment.detected:
        return _t(
          'উপরোক্ত officer-recorded finding অনুযায়ী প্রতিবেদনটি সদয় অবগতি ও প্রয়োজনীয় আদেশ/ব্যবস্থার জন্য পেশ করা হলো।',
          'The report is submitted for kind perusal and necessary order/action in accordance with the officer-recorded finding above.',
        );
      case UdFoulPlayAssessment.inconclusive:
        return _t(
          'উপরোক্ত অনির্ণীত (inconclusive) finding অনুযায়ী প্রতিবেদনটি সদয় অবগতি ও প্রয়োজনীয় আদেশের জন্য পেশ করা হলো।',
          'The report is submitted for kind perusal and necessary order, the assessment having been recorded as inconclusive.',
        );
      case UdFoulPlayAssessment.notSelected:
        return '';
    }
  }

  /// Preserves the established W.B. Form 5370 / P.R.B. Form 53 layout. The
  /// v208 lifecycle only supplies corrected spot-visit/dispatch times and
  /// officer-confirmed PM/final findings.
  Future<Uint8List> buildFinalReportPdf({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) async {
    final doc = pw.Document(theme: await _theme());
    pw.TextStyle normal([double size = 10.5]) => pw.TextStyle(fontSize: size);
    pw.TextStyle bold([double size = 10.5]) =>
        pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold);
    pw.Widget numbered(int no, String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 22, child: pw.Text('$no.', style: normal())),
              pw.SizedBox(width: 300, child: pw.Text(label, style: normal())),
              pw.Text(': ', style: normal()),
              pw.Expanded(child: pw.Text(value, style: normal())),
            ],
          ),
        );

    final spotTime = _stageDateTime(flow.spotVisitDate, flow.spotVisitTime);
    final finalDispatch =
        _stageDateTime(flow.finalDispatchDate, flow.finalDispatchTime);
    final narrative = _finalNarrative(flow);
    final conclusion = _assessmentText(flow.foulPlayAssessment);
    final prayer = _finalPrayer(flow.foulPlayAssessment);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 36),
        build: (_) => [
          pw.Text(
            _t('পশ্চিমবঙ্গ ফর্ম নং ৫৩৭০', 'West Bengal form No. 5370'),
            style: bold(10.8),
          ),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              _t(
                'অস্বাভাবিক মৃত্যুর নথিভুক্ত মামলার চূড়ান্ত প্রতিবেদন ম্যাজিস্ট্রেটের নিকট প্রেরণ',
                'FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE',
              ),
              style: bold(13),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Center(
            child: pw.Text(
              _t(
                '(BNSS-এর প্রযোজ্য ধারা অনুযায়ী)',
                'UNDER THE APPLICABLE SECTION OF BNSS',
              ),
              style: bold(11.5),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '(P.R.B. Form No.- 53 Vide Rule 276)',
              style: bold(10.5),
            ),
          ),
          pw.SizedBox(height: 18),
          numbered(
            1,
            _t(
              'থানা, প্রথম তথ্যের নম্বর ও তারিখ',
              'Station, Number and date of first information',
            ),
            '${ud.policeStation} U/D Case No. ${ud.udNo}, Dated- ${ud.dateTime}',
          ),
          numbered(
            2,
            _t('মৃত ব্যক্তির নাম', 'Name of the deceased'),
            '${ud.deceasedName} (${ud.deceasedSex}, Age- ${ud.deceasedAge})',
          ),
          numbered(
            3,
            _t(
              'ঘটনাস্থলে যাওয়ার তারিখ ও সময়',
              'Date and hour of going to the spot',
            ),
            spotTime,
          ),
          numbered(
            4,
            _t(
              'চূড়ান্ত প্রতিবেদন প্রেরণের তারিখ ও সময়',
              'Date and hour of dispatch of the final report',
            ),
            finalDispatch,
          ),
          pw.SizedBox(height: 36),
          pw.Center(
            child: pw.Text(
              '${_t('অফিসার-ইন-চার্জ', 'Officer-In-Charge of')} ${ud.policeStation}',
              style: pw.TextStyle(
                fontSize: 11.2,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Paragraph(
            text: narrative,
            style: normal(10.7),
            textAlign: pw.TextAlign.justify,
            margin: const pw.EdgeInsets.only(bottom: 12),
          ),
          pw.Paragraph(
            text: conclusion,
            style: normal(10.7),
            textAlign: pw.TextAlign.justify,
            margin: const pw.EdgeInsets.only(bottom: 12),
          ),
          pw.Paragraph(
            text: prayer,
            style: normal(10.7),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 28),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(_t('পেশ করা হলো', 'Submitted'), style: normal(10.5)),
                pw.SizedBox(height: 24),
                pw.Text('(${officer.name})', style: normal(10.5)),
                pw.Text(
                  '${officer.rank}, ${officer.policeStation}',
                  style: normal(10.5),
                ),
                pw.Text(
                  '${officer.district}, ${_t('তারিখ', 'Dt')}- ${flow.finalDispatchDate}',
                  style: normal(10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Uint8List buildFinalReportDoc({
    required OfficerProfile officer,
    required UdCase ud,
    required UdLifecycleRecord flow,
  }) {
    final narrative = _finalNarrative(flow);
    final conclusion = _assessmentText(flow.foulPlayAssessment);
    final prayer = _finalPrayer(flow.foulPlayAssessment);
    final spotTime = _stageDateTime(flow.spotVisitDate, flow.spotVisitTime);
    final finalDispatch =
        _stageDateTime(flow.finalDispatchDate, flow.finalDispatchTime);

    final body = '''
<div class="bold">${_e(_t('পশ্চিমবঙ্গ ফর্ম নং ৫৩৭০', 'West Bengal form No. 5370'))}</div><br/>
<div class="center bold">${_e(_t('অস্বাভাবিক মৃত্যুর নথিভুক্ত মামলার চূড়ান্ত প্রতিবেদন ম্যাজিস্ট্রেটের নিকট প্রেরণ', 'FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE'))}</div>
<div class="center bold">(P.R.B. Form No.- 53 Vide Rule 276)</div><br/>
<p>1. ${_e(_t('থানা, প্রথম তথ্যের নম্বর ও তারিখ', 'Station, Number and date of first information'))} : ${_e(ud.policeStation)} U/D Case No. ${_e(ud.udNo)}, Dated- ${_e(ud.dateTime)}</p>
<p>2. ${_e(_t('মৃত ব্যক্তির নাম', 'Name of the deceased'))} : ${_e(ud.deceasedName)} (${_e(ud.deceasedSex)}, Age- ${_e(ud.deceasedAge)})</p>
<p>3. ${_e(_t('ঘটনাস্থলে যাওয়ার তারিখ ও সময়', 'Date and hour of going to the spot'))} : ${_e(spotTime)}</p>
<p>4. ${_e(_t('চূড়ান্ত প্রতিবেদন প্রেরণের তারিখ ও সময়', 'Date and hour of dispatch of the final report'))} : ${_e(finalDispatch)}</p><br/>
<div class="center bold"><u>${_e(_t('অফিসার-ইন-চার্জ', 'Officer-In-Charge of'))} ${_e(ud.policeStation)}</u></div>
<p class="justify">${_e(narrative)}</p>
<p class="justify">${_e(conclusion)}</p>
<p>${_e(prayer)}</p>
<div class="right" style="margin-top:35px">${_e(_t('পেশ করা হলো', 'Submitted'))}<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}, ${_e(officer.policeStation)}<br/>${_e(officer.district)}, ${_e(_t('তারিখ', 'Dt'))}- ${_e(flow.finalDispatchDate)}</div>
''';
    return _htmlDoc('UD Final Report', body);
  }

  Uint8List _htmlDoc(String title, String body) => Uint8List.fromList(
        utf8.encode('''
<html>
<head>
<meta charset="utf-8">
<title>${_e(title)}</title>
<style>
  @page { size: A4; margin: 18mm 14mm 18mm 14mm; }
  body { font-family: "Noto Serif Bengali", "Times New Roman", serif; font-size: 12pt; color: #000; }
  table { border-collapse: collapse; width: 100%; }
  td, th { border: 1px solid #000; padding: 4px; vertical-align: top; }
  .center { text-align: center; }
  .right { text-align: right; }
  .bold { font-weight: bold; }
  .small { font-size: 10.5pt; }
  .justify { text-align: justify; }
</style>
</head>
<body>$body</body>
</html>
'''),
      );

  String _e(String value) => const HtmlEscape()
      .convert(value)
      .replaceAll('&#47;', '/')
      .replaceAll('&#x2F;', '/')
      .replaceAll('\n', '<br/>');
}
