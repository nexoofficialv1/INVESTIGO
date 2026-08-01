import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/app_language.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../models/form_notice.dart';
import '../models/sketch_map.dart';
import '../models/ud_case.dart';
import '../models/ncr_report.dart';

class PdfService {
  String _t(String bn, String en) => L10n.t(bn, en);
  Future<pw.ThemeData> _pdfTheme() async {
    try {
      final regular = await PdfGoogleFonts.notoSerifBengaliRegular();
      final bold = await PdfGoogleFonts.notoSerifBengaliBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      final regular = await PdfGoogleFonts.notoSansBengaliRegular();
      final bold = await PdfGoogleFonts.notoSansBengaliBold();
      return pw.ThemeData.withFont(base: regular, bold: bold);
    }
  }

  Future<Uint8List> buildCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());

    // STRICT OFFICIAL CD FORMAT - West Bengal Form No. 5363 / P.R.B Form No. 43.
    // Important: no horizontal lines between individual diary entries. Entry no/time,
    // place, synopsis and proceedings are placed inside one continuous enquiry block.
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _wbOfficialCdHeader(officer: officer, caseFile: caseFile, cd: cd, continued: true),
                  _wbOfficialCdStatusRow(),
                ],
              ),
        build: (context) => [
          _wbOfficialCdHeader(officer: officer, caseFile: caseFile, cd: cd),
          _wbOfficialCdStatusRow(),
          _wbOfficialCdContinuousTable(cd, officer),
        ],
      ),
    );

    return doc.save();
  }

  String _shortPsName(String ps) => ps.replaceAll('Police Station', 'PS').trim();

  pw.Widget _wbOfficialCdHeader({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
    bool continued = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_t('পশ্চিমবঙ্গ ফর্ম নং ৫৩৬৩', 'West Bengal form No. 5363'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text(_t('${DateTime.now().year} সালের', 'OF ${DateTime.now().year}'), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Center(child: pw.Text(_t('BNSS-এর ১৯২ ধারার অধীনে কেস ডায়েরি${continued ? ' (ক্রমশ)' : ''}', 'CASE DIARY UNDER SECTION 192 BNSS${continued ? ' (Continued)' : ''}'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: '(P.R.B FROM NO. 43 – Vide ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: 'Rule 229', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: ')', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]))),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(flex: 3, child: pw.Text(_t('থানা: -${_shortPsName(officer.policeStation)}', 'Police Station: -${_shortPsName(officer.policeStation)}'), style: _cdTopStyle())),
            pw.Expanded(flex: 2, child: pw.Text(_t('জেলা: -${officer.district}', 'District: -${officer.district}'), style: _cdTopStyle())),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Expanded(flex: 2, child: pw.Text(_t('প্রথম তথ্য নং: -${caseFile.psCaseNo}', 'First information No: -${caseFile.psCaseNo}'), style: _cdTopStyle())),
            pw.Expanded(flex: 1, child: pw.Text(_t('তারিখ: -${caseFile.caseDate}', 'Dated: -${caseFile.caseDate}'), style: _cdTopStyle())),
            pw.Expanded(flex: 2, child: pw.Text(_t('ধারা: -${caseFile.sections}', 'Section: -${caseFile.sections}'), style: _cdTopStyle())),
          ],
        ),
        pw.Text(_t('অভিযোগকারীর নাম: -${caseFile.complainantName}', 'Name of Complainant: -${caseFile.complainantName}'), style: _cdTopStyle()),
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text(_t('কেস ডায়েরি নং: -${cd.cdNumber}', 'Case Diary No: -${cd.cdNumber}'), style: _cdTopStyle())),
            pw.Expanded(child: pw.Text(_t('তারিখ: -${cd.cdDate}', 'Dated: -${cd.cdDate}'), style: _cdTopStyle())),
          ],
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.TextStyle _cdTopStyle() => pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold);

  pw.Widget _wbOfficialCdStatusRow() {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.1), 2: pw.FlexColumnWidth(1.1)},
      children: [
        pw.TableRow(children: [
          _officialCell(_t('গ্রেপ্তার করে আদালতে প্রেরিত', 'Arrested and sent up'), center: true, fontSize: 11),
          _officialCell(_t('গ্রেপ্তার ও জামিনে মুক্ত।', 'Arrested and released on bail.'), center: true, fontSize: 11),
          _officialCell(_t('পলাতক।', 'At large.'), center: true, fontSize: 11),
        ]),
      ],
    );
  }

  pw.Widget _wbOfficialCdContinuousTable(CdEntry cd, OfficerProfile officer) {
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [CdTableLine(noAndHour: 'I\n${cd.startTime}', placeOfEntry: cd.placeOfEntry, synopsis: cd.cdNumber == 1 ? _t('FIR-এর কপি প্রাপ্ত\n+\nসারমর্ম', 'Received copy of FIR\n+\nGist') : _t('পরবর্তী তদন্ত', 'Further investigation'), proceedings: cd.body)];

    final leftEntryColumn = lines.map((line) => line.noAndHour).join('\n\n\n');
    final placeColumn = lines.map((line) => line.placeOfEntry).join('\n\n\n');
    final synopsisColumn = lines.map((line) => line.synopsis).join('\n\n\n');
    final proceedingsColumn = lines.map((line) => line.proceedings).where((e) => e.trim().isNotEmpty).join('\n\n');

    // Official PRB Form No. 43 layout:
    // Row 1: "Particulars of Enquiry." is merged only over the three marginal columns.
    // Row 2: three marginal columns + the large proceedings column.
    // No horizontal line is inserted between individual CD entries.
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.90),
        1: pw.FlexColumnWidth(7.10),
      },
      children: [
        pw.TableRow(children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(8, 3, 8, 3),
            child: pw.Text(_t('তদন্তের বিবরণ।', 'Particulars of Enquiry.'), style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 22),
        ]),
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.top,
          children: [
            pw.Table(
              border: const pw.TableBorder(
                verticalInside: pw.BorderSide(width: 0.55),
                horizontalInside: pw.BorderSide(width: 0.55),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.86),
                1: pw.FlexColumnWidth(0.90),
                2: pw.FlexColumnWidth(1.14),
              },
              children: [
                pw.TableRow(children: [
                  _officialCell(_t('এন্ট্রি নং\nও সময়।', 'No. and\nhour of\nentry.'), center: true, fontSize: 9.4),
                  _officialCell(_t('এন্ট্রির\nস্থান।', 'Place of\nentry.'), center: true, fontSize: 9.4),
                  _officialCell(_t('এন্ট্রির\nসারাংশ।', 'Synopsis of\nentry.'), center: true, fontSize: 9.4),
                ]),
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.top,
                  children: [
                    _officialCell(leftEntryColumn, center: true, fontSize: 9.4, minHeight: 520),
                    _officialCell(placeColumn, center: true, fontSize: 9.4, minHeight: 520),
                    _officialCell(synopsisColumn, center: true, fontSize: 9.4, minHeight: 520),
                  ],
                ),
              ],
            ),
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 575),
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(proceedingsColumn, style: const pw.TextStyle(fontSize: 10.2), textAlign: pw.TextAlign.justify),
                    pw.SizedBox(height: 18),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(_t('পেশ করা হলো', 'Submitted'), style: const pw.TextStyle(fontSize: 10.5)),
                          pw.SizedBox(height: 28),
                          pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10.5)),
                          pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10.5)),
                          pw.Text(_shortPsName(officer.policeStation), style: const pw.TextStyle(fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  pw.Widget _wbOfficialCdSignature({required OfficerProfile officer}) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, right: 80),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(_t('পেশ করা হলো', 'Submitted'), style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 28),
            pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10.5)),
            pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10.5)),
            pw.Text(_shortPsName(officer.policeStation), style: const pw.TextStyle(fontSize: 10.5)),
          ],
        ),
      ),
    );
  }



  pw.Widget _officialCell(String text, {bool bold = false, bool center = false, double fontSize = 10.5, double? minHeight}) {
    final content = pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(4, 3, 4, 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
    if (minHeight == null) return content;
    return pw.Container(constraints: pw.BoxConstraints(minHeight: minHeight), child: content);
  }

  Future<Uint8List> buildStatementPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        build: (context) => [
          _centerBold('Statement of witness recorded u/s 180 BNSS'),
          pw.SizedBox(height: 16),
          pw.Text('Case Reference: ${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}'),
          pw.SizedBox(height: 8),
          pw.Text('Name of Witness: ${statement.witnessName}'),
          pw.Text('Witness Details: ${statement.witnessDetails}'),
          pw.Text('Statement Type: ${statement.statementType}'),
          pw.SizedBox(height: 14),
          pw.Text(statement.body, style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Signature/LTI/RTI of witness'),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Recorded by'),
                  pw.SizedBox(height: 24),
                  pw.Text('${officer.rank} ${officer.name}'),
                  pw.Text(officer.policeStation),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareCaseDiaryPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final bytes = await buildCaseDiaryPdf(officer: officer, caseFile: caseFile, cd: cd);
    await Printing.sharePdf(bytes: bytes, filename: 'CD_${caseFile.psCaseNo.replaceAll('/', '_')}_${cd.cdNumber}.pdf');
  }

  Future<void> shareStatementPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final bytes = await buildStatementPdf(officer: officer, caseFile: caseFile, statement: statement);
    await Printing.sharePdf(bytes: bytes, filename: 'Statement_${statement.witnessName}.pdf');
  }


  Future<Uint8List> buildFormNoticePdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    final body = form.body;
    final is35 = form.templateId == 'bnss_35_3';
    final is94 = form.templateId == 'bnss_94' || form.templateId == 'medical_exam' || form.templateId == 'bht_injury';
    final isForwarding = form.templateId == 'forwarding';
    final isCdrCaf = form.templateId == 'cdr_caf';
    final isFsl = form.templateId == 'fsl';

    if (isFsl) {
      _addFslPackageOfficialPages(doc, officer, caseFile, body);
      return doc.save();
    }
    if (isCdrCaf) {
      _addCdrCafOfficialPages(doc, officer, caseFile, body);
      return doc.save();
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 30, 46, 30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (context) {
          if (is35) return _notice35Pdf(officer, caseFile, body);
          if (isForwarding) return _forwardingPdf(officer, caseFile, body);
          if (is94) return _notice94Pdf(officer, caseFile, body);
          return [
            _centerBold(form.title),
            pw.SizedBox(height: 10),
            pw.Text('Ref: ${officer.policeStation} Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10.5)),
            pw.SizedBox(height: 16),
            pw.Text(body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
            pw.SizedBox(height: 26),
            _rightOfficerBlock(officer),
          ];
        },
      ),
    );
    return doc.save();
  }




  List<String> _splitChunks(String text, {int max = 820}) {
    final clean = text.trim();
    if (clean.isEmpty) return [''];
    final out = <String>[];
    var rest = clean;
    while (rest.length > max) {
      var cut = rest.lastIndexOf(' ', max);
      if (cut < 250) cut = max;
      out.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) out.add(rest);
    return out;
  }

  List<List<String>> _parsePipeRows(String raw, int count, {required List<String> fallback}) {
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return [fallback];
    return lines.map((line) {
      final parts = line.split('|').map((e) => e.trim()).toList();
      while (parts.length < count) {
        parts.add('');
      }
      return parts.take(count).toList();
    }).toList();
  }

  pw.TableRow _tableRow(List<String> cells, {bool header = false, double fontSize = 9.4}) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: cells
          .map((text) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(fontSize: fontSize, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal),
                  textAlign: header ? pw.TextAlign.center : pw.TextAlign.left,
                ),
              ))
          .toList(),
    );
  }

  void _addCdrCafOfficialPages(pw.Document doc, OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} Case No-${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S-${caseFile.sections}';
    final gist = _extractFormField(body, 'GIST', fallback: caseFile.firGist.isEmpty ? '____________________________________________________________' : caseFile.firGist);
    final mobile = _extractFormField(body, 'REQUIRED MOBILE/IMEI', fallback: '____________________________');
    final user = _extractFormField(body, 'ACTUAL USER / INVOLVEMENT', fallback: '____________________________');
    final justification = _extractFormField(body, 'JUSTIFICATION', fallback: '____________________________');
    final dateRange = _extractFormField(body, 'CDR DATE RANGE', fallback: 'From ____________ To ____________');
    final sdr = _extractFormField(body, 'SDR REQUIRED', fallback: 'Yes / No');
    final caf = _extractFormField(body, 'CAF REQUIRED', fallback: 'Yes / No');
    final imei = _extractFormField(body, 'IMEI SEARCH DATE RANGE', fallback: '---');
    final other = _extractFormField(body, 'ANY OTHER POINTS', fallback: 'N/A');
    final ioName = _extractFormField(body, 'IO NAME', fallback: '${officer.rank} ${officer.name}');
    final ioPhone = _extractFormField(body, 'IO PHONE', fallback: officer.mobile);
    final rows = <pw.Widget>[
      _twoColRow('NAME OF THE P.S / O.P', _shortPsName(officer.policeStation)),
      _twoColRow('CASE REFERENCE / GDE NO.', ref),
    ];
    final gistParts = _splitChunks(gist, max: 760);
    for (var i = 0; i < gistParts.length; i++) {
      rows.add(_twoColRow(i == 0 ? 'GIST OF THE CASE / GDE' : 'GIST OF THE CASE / GDE (CONTINUED)', gistParts[i], fontSize: 9.3));
    }
    rows.addAll([
      _twoColRow('REQUIRED MOBILE NO\'S / IMEI NO\'S.', mobile),
      _twoColRow('NAME OF THE ACTUAL USER OF THE MOBILENO/IMEI NO & HIS/HER INVOLVEMENT IN THE CASE', user, fontSize: 9.6),
      _twoColRow('JUSTIFICATION OF THE REQUIRED MOBILE NO./IMEI NO. IN CASE/GDE', justification, fontSize: 9.6),
      _twoColRow('REQUIRED CDR (CALL DETAILS REPORT) FROM DATE .....TO DATE', dateRange),
      _twoColRow('REQUIRED SDR - (SUBSCRIBER DETAILS REPORT)', sdr),
      _twoColRow('REQUIRED CAF - (CUSTOMER APPLICATION FORM)', caf),
      _twoColRow('REQUIRED IMEI SEARCHING - FROM DATE .... TO DATE)', imei),
      _twoColRow('NAME OF THE I.O / E.O.', ioName),
      _twoColRow('PHONE NO. OF THE I.O / E.O.', ioPhone),
      _twoColRow('ANY OTHER POINTS', other),
      pw.SizedBox(height: 26),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_t('পেশ করা হলো', 'Submitted'), style: const pw.TextStyle(fontSize: 11))),
    ]);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
      build: (_) => [
        pw.Text('To: SP/${officer.district} =w= O/C SOG Cell, ${officer.district} =w= SDPO Kalna', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 12),
        pw.Text('From: I/C ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 18),
        pw.Center(child: pw.Text('REQUISITION FOR CDR/SDR/CAF', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
        pw.SizedBox(height: 8),
        ...rows,
      ],
    ));
  }

  void _addFslPackageOfficialPages(pw.Document doc, OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} Case No ${caseFile.psCaseNo} Date ${caseFile.caseDate} u/s ${caseFile.sections}';
    final natureCrime = _extractFormField(body, 'NATURE OF CRIME', fallback: caseFile.firGist.isEmpty ? 'The fact of the case in brief is that ________________________________________________.' : caseFile.firGist);
    final exhibitsRaw = _extractFormField(body, 'EXHIBITS', fallback: _extractFormField(body, 'EXHIBIT DESCRIPTION', fallback: 'A | One sealed packet/jar/container containing said to be ________________________________. | Seized on ____________ at ________________________________ by ${officer.rank} ${officer.name}. | Ld. C.J.M / Magistrate, ${officer.district} | May be confiscated to the State after examination / may be returned after examination'));
    final exam = _extractFormField(body, 'NATURE OF EXAMINATION', fallback: 'Whether relevant material/poison/blood/semen/chemical/biological trace could be detected in Exhibit Mark “A” or not.');
    final accusedRaw = _extractFormField(body, 'PERSONS IN CUSTODY', fallback: _extractFormField(body, 'PERSON IN CUSTODY', fallback: '${caseFile.accusedName} | Occupation | Age | Sex | Date & time of arrest | J/C / P/C / Bail / At large | Ld. Court'));
    final fslOffice = _extractFormField(body, 'FSL OFFICE', fallback: 'Head of Office & Assistant Director\nRegional Forensic Science Laboratory\nShankarpur, Durgapur\nPaschim Bardhaman, 713212');
    final court = _extractFormField(body, 'COURT', fallback: 'Ld. C.J.M / Magistrate, ${officer.district}');
    final contact = _extractFormField(body, 'IO / PS CONTACT DETAILS', fallback: 'I.O. Name:- ${officer.name}\nDesignation:- ${officer.rank}\nMobile No. of I.O.:- ${officer.mobile}\nName of the PS:- ${officer.policeStation}\nDistrict:- ${officer.district}');
    final exhibits = _parsePipeRows(exhibitsRaw, 5, fallback: ['A', 'One sealed packet/jar/container containing said to be ________________________________.', 'Seized on ____________ at ________________________________ by ${officer.rank} ${officer.name}.', court, 'May be confiscated to the State after examination / may be returned after examination']);
    final accusedRows = _parsePipeRows(accusedRaw, 7, fallback: [caseFile.accusedName.isEmpty ? '____________________' : caseFile.accusedName, 'Occupation', 'Age', 'Sex', 'Date & time of arrest', 'J/C / P/C / Bail / At large', court]);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text('West Bengal Form No- 5203', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.Text('WEST BENGAL POLICE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 12),
        pw.Text('Case No:- ${caseFile.psCaseNo}  Date ${caseFile.caseDate}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.Text('Police Station:- ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.Text('Section of Law:- ${caseFile.sections}        District- ${officer.district}', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text('I. NATURE OF CRIME', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        ..._splitLongText(natureCrime, chunkSize: 850),
        pw.SizedBox(height: 14),
        _submittedOfficerBlock(officer),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (_) => [
        pw.Center(child: pw.Text('II. LIST OF EXHIBITS SENT FOR EXAMINATION', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .5),
          columnWidths: const {0: pw.FlexColumnWidth(.75), 1: pw.FlexColumnWidth(2.7), 2: pw.FlexColumnWidth(2.1), 3: pw.FlexColumnWidth(1.55), 4: pw.FlexColumnWidth(1.55)},
          children: [
            _tableRow(['Label No', 'Description of the exhibit', 'How and when found and by whom', 'Ownership of exhibit', 'Remarks'], header: true, fontSize: 8.7),
            ...exhibits.map((e) => _tableRow(['EXHIBIT- “${e[0]}”', e[1], e[2], e[3], e[4]], fontSize: 8.5)),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Center(child: pw.Text('III. NATURE OF EXAMINATION REQUIRED', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 4),
        ..._splitLongText(exam, chunkSize: 850),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 28),
      build: (_) => [
        pw.Center(child: pw.Text('IV. PARTICULARS OF PERSONS IN CUSTODY', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: .5),
          columnWidths: const {0: pw.FlexColumnWidth(.55), 1: pw.FlexColumnWidth(2.2), 2: pw.FlexColumnWidth(1.05), 3: pw.FlexColumnWidth(.65), 4: pw.FlexColumnWidth(.65), 5: pw.FlexColumnWidth(1.25), 6: pw.FlexColumnWidth(1.25), 7: pw.FlexColumnWidth(1.25)},
          children: [
            _tableRow(['SL No.', 'Full name', 'Occupation', 'Age', 'Sex', 'Date & time of arrest', 'Whether on bail or in custody', 'Court'], header: true, fontSize: 8.2),
            ...accusedRows.asMap().entries.map((entry) => _tableRow(['${entry.key + 1}', ...entry.value], fontSize: 8.1)),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('………………………………………\nSignature and Rank of the I.O\nDated…………………', style: const pw.TextStyle(fontSize: 10.5))),
        pw.SizedBox(height: 18),
        pw.Text('Memo No……………..               Dated, the………..20………', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 8),
        pw.Text('Forwarded to\n$fslOffice', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 12),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Seal', style: const pw.TextStyle(fontSize: 10.5)), pw.Text(court, style: const pw.TextStyle(fontSize: 10.5))]),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text('Certified that the Head of office & Assistant Director, Regional Forensic Science Laboratory, to the Govt. of West Bengal has the authority to examine the exhibits sent to him in connection with the case of State versus ${caseFile.accusedName.isEmpty ? '____________________' : caseFile.accusedName} under section ${caseFile.sections} and if necessary, to take them to pieces or remove portions for the purposes of the said examination.', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 18),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Date………………\nPlace…………..', style: const pw.TextStyle(fontSize: 10.5)), pw.Text('Signature………………………………………….\nCJM / MAGISTRATE', style: const pw.TextStyle(fontSize: 10.5))]),
        pw.SizedBox(height: 18),
        pw.Text('Certified to be signed by Ld. Chief Judicial Magistrate / Magistrate and forwarded to the Head of office & Assistant Director, Regional Forensic Science Laboratory with Exhibit.', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Center(child: pw.Text('Exhibit Challan', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text('To\n$fslOffice\n\nThrough $court\nRef:- $ref', style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 10),
        pw.Text('Sir,\nI am sending herewith the following Exhibits in c/w above noted case before you for examination and your opinion for the interest of investigation of the case.\n\nKindly arrange to acknowledge and receipt the same.', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 10),
        ...exhibits.asMap().entries.map((entry) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: pw.Text('${entry.key + 1}) Exhibit Mark “${entry.value[0]}” ---- ${entry.value[1]}', style: const pw.TextStyle(fontSize: 10.5)))),
        pw.SizedBox(height: 16),
        _submittedOfficerBlock(officer),
      ],
    ));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
      build: (_) => [
        pw.Text(contact, style: const pw.TextStyle(fontSize: 10.5)),
      ],
    ));

    for (var i = 0; i < exhibits.length; i++) {
      final e = exhibits[i];
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 30, 42, 30),
        build: (_) => [
          pw.Center(child: pw.Text(i == 0 ? 'Label' : 'Label - Exhibit ${e[0]}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 8),
          pw.Text('To\n$fslOffice\n\nThrough $court\n\nRef:- $ref\n\nDescription of Article.\nExhibit Mark “${e[0]}” ---- ${e[1]}\n\nLabeled & prepared by me -', style: const pw.TextStyle(fontSize: 10.5)),
          pw.SizedBox(height: 16),
          _submittedOfficerBlock(officer),
        ],
      ));
    }
  }

  String _extractFormField(String body, String key, {String fallback = ''}) {
    final pattern = RegExp('^' + RegExp.escape(key) + r'\s*:\s*(.*)$', multiLine: true, caseSensitive: false);
    final match = pattern.firstMatch(body);
    if (match == null) return fallback;
    final value = (match.group(1) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  pw.Widget _twoColRow(String left, String right, {double leftFlex = 1.0, double rightFlex = 1.25, double fontSize = 10.5}) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),
      columnWidths: {
        0: pw.FlexColumnWidth(leftFlex),
        1: pw.FlexColumnWidth(rightFlex),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(left, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(right, style: pw.TextStyle(fontSize: fontSize))),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _cdrCafOfficialPdf(OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} Case No-${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S-${caseFile.sections}';
    final gist = _extractFormField(body, 'GIST', fallback: caseFile.firGist.isEmpty ? '____________________________________________________________' : caseFile.firGist);
    final mobile = _extractFormField(body, 'REQUIRED MOBILE/IMEI', fallback: '____________________________');
    final user = _extractFormField(body, 'ACTUAL USER / INVOLVEMENT', fallback: '____________________________');
    final justification = _extractFormField(body, 'JUSTIFICATION', fallback: '____________________________');
    final dateRange = _extractFormField(body, 'CDR DATE RANGE', fallback: 'From ____________ To ____________');
    final sdr = _extractFormField(body, 'SDR REQUIRED', fallback: 'Yes / No');
    final caf = _extractFormField(body, 'CAF REQUIRED', fallback: 'Yes / No');
    final imei = _extractFormField(body, 'IMEI SEARCH DATE RANGE', fallback: '---');
    final other = _extractFormField(body, 'ANY OTHER POINTS', fallback: 'N/A');
    final ioName = _extractFormField(body, 'IO NAME', fallback: '${officer.rank} ${officer.name}');
    final ioPhone = _extractFormField(body, 'IO PHONE', fallback: officer.mobile);

    return [
      pw.Text('To: SP/${officer.district} =w= O/C SOG Cell, ${officer.district} =w= SDPO Kalna', style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 14),
      pw.Text('From: I/C ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 11)),
      pw.SizedBox(height: 20),
      pw.Center(child: pw.Text('REQUISITION FOR CDR/SDR/CAF', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
      pw.SizedBox(height: 8),
      _twoColRow('NAME OF THE P.S / O.P', _shortPsName(officer.policeStation)),
      _twoColRow('CASE REFERENCE / GDE NO.', ref),
      _twoColRow('GIST OF THE CASE / GDE', gist, fontSize: 10.0),
      _twoColRow('REQUIRED MOBILE NO\'S / IMEI NO\'S.', mobile),
      _twoColRow('NAME OF THE ACTUAL USER OF THE MOBILENO/IMEI NO & HIS/HER INVOLVEMENT IN THE CASE', user),
      _twoColRow('JUSTIFICATION OF THE REQUIRED MOBILE NO./IMEI NO. IN CASE/GDE', justification),
      _twoColRow('REQUIRED CDR (CALL DETAILS REPORT) FROM DATE .....TO DATE', dateRange),
      _twoColRow('REQUIRED SDR - (SUBSCRIBER DETAILS REPORT)', sdr),
      _twoColRow('REQUIRED CAF - (CUSTOMER APPLICATION FORM)', caf),
      _twoColRow('REQUIRED IMEI SEARCHING - FROM DATE .... TO DATE)', imei),
      _twoColRow('NAME OF THE I.O / E.O.', ioName),
      _twoColRow('PHONE NO. OF THE I.O / E.O.', ioPhone),
      _twoColRow('ANY OTHER POINTS', other),
      pw.SizedBox(height: 26),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_t('পেশ করা হলো', 'Submitted'), style: const pw.TextStyle(fontSize: 11))),
    ];
  }

  List<pw.Widget> _splitLongText(String text, {int chunkSize = 950, double fontSize = 10.5}) {
    final clean = text.trim().replaceAll('\r', '');
    if (clean.isEmpty) return [pw.Text('')];
    final widgets = <pw.Widget>[];
    var rest = clean;
    while (rest.length > chunkSize) {
      var cut = rest.lastIndexOf('\n\n', chunkSize);
      if (cut < 300) cut = rest.lastIndexOf('\n', chunkSize);
      if (cut < 300) cut = chunkSize;
      final part = rest.substring(0, cut).trim();
      widgets.add(pw.Text(part, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.justify));
      widgets.add(pw.SizedBox(height: 10));
      rest = rest.substring(cut).trimLeft();
    }
    widgets.add(pw.Text(rest, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.justify));
    return widgets;
  }

  List<pw.Widget> _fslPackageOfficialPdf(OfficerProfile officer, CaseFile caseFile, String body) {
    final ref = '${_shortPsName(officer.policeStation)} Case No ${caseFile.psCaseNo} Date ${caseFile.caseDate} u/s ${caseFile.sections}';
    final natureCrime = _extractFormField(body, 'NATURE OF CRIME', fallback: caseFile.firGist.isEmpty ? 'The fact of the case in brief is that ________________________________________________.' : caseFile.firGist);
    final exhibit = _extractFormField(body, 'EXHIBIT DESCRIPTION', fallback: 'Exhibit Mark "A" ---- One sealed packet/jar/container containing said to be ________________________________.');
    final found = _extractFormField(body, 'HOW FOUND / SEIZED', fallback: 'Seized on ____________ at ________________________________ by ${officer.rank} ${officer.name}.');
    final exam = _extractFormField(body, 'NATURE OF EXAMINATION', fallback: 'Whether relevant material/poison/blood/semen/chemical/biological trace could be detected in Exhibit Mark "A" or not.');
    final accused = _extractFormField(body, 'PERSON IN CUSTODY', fallback: '____________________________');
    final fslOffice = _extractFormField(body, 'FSL OFFICE', fallback: 'Head of Office & Assistant Director\nRegional Forensic Science Laboratory\nShankarpur, Durgapur\nPaschim Bardhaman, 713212');
    final court = _extractFormField(body, 'COURT', fallback: 'Ld. C.J.M / Magistrate, ${officer.district}');

    final widgets = <pw.Widget>[];
    widgets.addAll([
      pw.Text('West Bengal Form No- 5203', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Center(child: pw.Text('WEST BENGAL POLICE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 12),
      pw.Text('Case No:- ${caseFile.psCaseNo}  Date ${caseFile.caseDate}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.Text('Police Station:- ${_shortPsName(officer.policeStation)}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.Text('Section of Law:- ${caseFile.sections}        District- ${officer.district}', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 10),
      pw.Center(child: pw.Text('I. NATURE OF CRIME', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      ..._splitLongText(natureCrime, chunkSize: 850),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.NewPage(),
      pw.Center(child: pw.Text('II. LIST OF EXHIBITS SENT FOR EXAMINATION', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Table(border: pw.TableBorder.all(width: .5), columnWidths: const {0: pw.FlexColumnWidth(.8), 1: pw.FlexColumnWidth(2.6), 2: pw.FlexColumnWidth(2.3), 3: pw.FlexColumnWidth(1.7), 4: pw.FlexColumnWidth(1.7)}, children: [
        pw.TableRow(children: [_cell('Label No', bold: true), _cell('Description of the exhibit', bold: true), _cell('How and when found and by whom', bold: true), _cell('Ownership of exhibit', bold: true), _cell('Remarks', bold: true)]),
        pw.TableRow(children: [_cell('EXHIBIT- "A"'), _cell(exhibit), _cell(found), _cell(court), _cell('May be confiscated to the State after examination / may be returned after examination')]),
      ]),
      pw.SizedBox(height: 14),
      pw.Center(child: pw.Text('III. NATURE OF EXAMINATION REQUIRED', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      ..._splitLongText(exam, chunkSize: 800),
      pw.NewPage(),
      pw.Center(child: pw.Text('IV. PARTICULARS OF PERSONS IN CUSTODY', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      _twoColRow('Full name / particulars', accused),
      _twoColRow('Whether on bail or in custody', '____________________________'),
      _twoColRow('Court', court),
      pw.SizedBox(height: 16),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Signature and Rank of the I.O\nDated: ____________', style: const pw.TextStyle(fontSize: 10.5))),
      pw.SizedBox(height: 18),
      pw.Text('Memo No. ____________        Dated, the ____________ 20____', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Text('Forwarded to\n$fslOffice', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 12),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Seal', style: const pw.TextStyle(fontSize: 10.5)), pw.Text(court, style: const pw.TextStyle(fontSize: 10.5))]),
      pw.NewPage(),
      pw.Text('Certified that the Head of Office & Assistant Director, Regional Forensic Science Laboratory has the authority to examine the exhibits sent in connection with the case and if necessary, to take them to pieces or remove portions for the purposes of the said examination.', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      pw.SizedBox(height: 18),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Date: ____________\nPlace: ___________', style: const pw.TextStyle(fontSize: 10.5)), pw.Text('Signature: ____________________\nCJM / MAGISTRATE', style: const pw.TextStyle(fontSize: 10.5))]),
      pw.SizedBox(height: 22),
      pw.Center(child: pw.Text('EXHIBIT CHALLAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('To\n$fslOffice\n\nThrough $court\n\nRef:- $ref', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 8),
      pw.Text('Sir,\nI am sending herewith the following exhibit(s) in c/w above noted case before you for examination and your opinion in the interest of investigation of the case. Kindly arrange to acknowledge receipt of the same.', style: const pw.TextStyle(fontSize: 10.5), textAlign: pw.TextAlign.justify),
      pw.SizedBox(height: 8),
      pw.Text('1) $exhibit', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.NewPage(),
      pw.Center(child: pw.Text('LABEL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('To\n$fslOffice\n\nThrough $court\n\nRef:- $ref\n\nDescription of Article:\n$exhibit\n\nLabeled & prepared by me -', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
      pw.SizedBox(height: 24),
      pw.Center(child: pw.Text('LABEL - DUPLICATE / COPY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('To\n$fslOffice\n\nThrough $court\n\nRef:- $ref\n\nDescription of Article:\n$exhibit\n\nLabeled & prepared by me -', style: const pw.TextStyle(fontSize: 10.5)),
      pw.SizedBox(height: 16),
      _submittedOfficerBlock(officer),
    ]);
    return widgets;
  }

  List<pw.Widget> _notice35Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('NOTICE OF APPEARANCE BY THE POLICE', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('[As per section – 35 (3) BNSS Act.]', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 20),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Serial\nNo.............', style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text('Annexure-A', style: const pw.TextStyle(fontSize: 11)),
        ]),
        pw.SizedBox(height: 12),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(_shortPsName(officer.policeStation).replaceAll('PS', 'Police Station'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.2), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 28),
        _submittedOfficerBlock(officer),
      ];

  List<pw.Widget> _notice94Pdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Center(child: pw.Text('NOTICE U/S 94 BNSS, 2023', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 18),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 30),
        _rightOfficerBlock(officer),
      ];

  List<pw.Widget> _forwardingPdf(OfficerProfile officer, CaseFile caseFile, String body) => [
        pw.Text('In the court of ${officer.courtName}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Center(child: pw.Text('Through GRO Kalna Court', style: const pw.TextStyle(fontSize: 11))),
        pw.SizedBox(height: 22),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11.3), textAlign: pw.TextAlign.justify),
        pw.SizedBox(height: 24),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(child: pw.Text('Enclosure:\n1. Original FIR.\n2. Memo of Arrest.\n3. Inspection Memos.\n4. Medical treatment Slip.\n5. Intimation of arrest.', style: const pw.TextStyle(fontSize: 10.8))),
            pw.Expanded(child: _submittedOfficerBlock(officer)),
          ],
        ),
      ];

  pw.Widget _rightOfficerBlock(OfficerProfile officer) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (officer.mobile.trim().isNotEmpty) pw.Text(officer.mobile),
          pw.Text('${_shortPsName(officer.policeStation)}, ${officer.district}'),
        ]),
      );

  pw.Widget _submittedOfficerBlock(OfficerProfile officer) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('Submitted,', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 26),
          pw.Text(officer.name, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 11)),
          pw.Text('${_shortPsName(officer.policeStation)}, ${officer.district}', style: const pw.TextStyle(fontSize: 11)),
        ]),
      );

  Future<Uint8List> buildGeneralReportPdf({
    required OfficerProfile officer,
    required FormNotice form,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 36),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9)),
        ),
        build: (context) => [
          _centerBold(form.title),
          pw.SizedBox(height: 16),
          pw.Text(form.body, style: const pw.TextStyle(fontSize: 11.5), textAlign: pw.TextAlign.justify),
          pw.SizedBox(height: 26),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('${officer.rank} ${officer.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(officer.policeStation),
                pw.Text('District: ${officer.district}'),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> shareFormNoticePdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    final bytes = await buildFormNoticePdf(officer: officer, caseFile: caseFile, form: form);
    await Printing.sharePdf(bytes: bytes, filename: "${form.title.replaceAll(' ', '_')}_${caseFile.psCaseNo.replaceAll('/', '_')}.pdf");
  }


  Future<Uint8List> buildSketchMapPdf({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required SketchMapEntry sketch,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    const canvasW = 500.0;
    const canvasH = 430.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
        build: (context) => [
          _centerBold('ROUGH SKETCH MAP WITH INDEX'),
          pw.SizedBox(height: 6),
          pw.Text('Case Reference: ${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Date: ${sketch.date}', style: const pw.TextStyle(fontSize: 10)),
          if (sketch.poDescription.trim().isNotEmpty) pw.Text('PO: ${sketch.poDescription}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Container(
            width: canvasW,
            height: canvasH,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
            child: pw.Stack(
              children: [
                pw.Positioned(top: 8, right: 10, child: pw.Text('N', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                ...sketch.objects.map((o) => pw.Positioned(
                      left: (o.x.clamp(0.0, 0.95)) * canvasW,
                      top: (o.y.clamp(0.0, 0.95)) * canvasH,
                      child: _pdfSketchObject(o, canvasW, canvasH),
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Index', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _sketchIndexTable(sketch),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('North: ${sketch.north}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('South: ${sketch.south}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text('East: ${sketch.east}', style: const pw.TextStyle(fontSize: 10))),
              pw.Expanded(child: pw.Text('West: ${sketch.west}', style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Prepared by', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 24),
                pw.Text('(${officer.name})', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(officer.rank, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(officer.policeStation, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfSketchObject(SketchMapObject o, double canvasW, double canvasH) {
    final w = o.width * canvasW;
    final h = o.height * canvasH;
    final label = o.label.trim().isEmpty ? o.marker : o.label.trim();
    final symbol = pw.Stack(children: [
      pw.Positioned.fill(child: pw.SvgImage(svg: _sketchObjectSvg(o.type))),
      pw.Positioned(
        left: 2,
        right: 2,
        top: h * .34,
        child: pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.all(1.2),
          child: pw.Text(label, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: o.type == SketchObjectType.road ? 5.4 : 5.8, fontWeight: pw.FontWeight.bold)),
        ),
      ),
    ]);
    return pw.Transform.rotate(
      angle: o.rotationDeg * math.pi / 180,
      child: pw.Container(width: w, height: h, child: symbol),
    );
  }

  String _sketchObjectSvg(SketchObjectType type) {
    switch (type) {
      case SketchObjectType.house:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <polygon points="8,34 50,5 92,34" fill="#8D4B20" stroke="#111" stroke-width="2"/>
          <rect x="18" y="34" width="64" height="38" fill="#FFE0B2" stroke="#111" stroke-width="2"/>
          <rect x="44" y="52" width="12" height="20" fill="#FFF8E1" stroke="#111" stroke-width="1.5"/>
          <rect x="26" y="43" width="14" height="10" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="60" y="43" width="14" height="10" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
        </svg>''';
      case SketchObjectType.shop:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <rect x="12" y="28" width="76" height="44" fill="#F3E5F5" stroke="#111" stroke-width="2"/>
          <rect x="8" y="12" width="84" height="20" fill="#CE93D8" stroke="#111" stroke-width="2"/>
          <rect x="14" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="38" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="62" y="12" width="12" height="20" fill="#FFFFFF" stroke="#111" stroke-width="1"/>
          <rect x="42" y="48" width="16" height="24" fill="#FFFFFF" stroke="#111" stroke-width="1.5"/>
        </svg>''';
      case SketchObjectType.pond:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <path d="M10 38 C8 12, 40 4, 65 14 C96 24, 94 62, 64 72 C36 82, 8 66, 10 38 Z" fill="#B3E5FC" stroke="#01579B" stroke-width="2"/>
          <path d="M25 34 H75 M24 47 H74 M30 60 H68" stroke="#0277BD" stroke-width="2"/>
        </svg>''';
      case SketchObjectType.tree:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 90">
          <rect x="45" y="52" width="10" height="30" fill="#795548"/>
          <circle cx="50" cy="34" r="24" fill="#A5D6A7" stroke="#111" stroke-width="1.5"/>
          <circle cx="36" cy="43" r="20" fill="#81C784" stroke="#111" stroke-width="1.2"/>
          <circle cx="64" cy="43" r="20" fill="#66BB6A" stroke="#111" stroke-width="1.2"/>
        </svg>''';
      case SketchObjectType.road:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 180 45">
          <rect x="2" y="8" width="176" height="29" rx="2" fill="#BDBDBD" stroke="#111" stroke-width="2"/>
          <path d="M15 23 H35 M55 23 H75 M95 23 H115 M135 23 H160" stroke="#FFFFFF" stroke-width="4"/>
        </svg>''';
      case SketchObjectType.field:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 80">
          <rect x="8" y="10" width="84" height="60" fill="#DCECC5" stroke="#33691E" stroke-width="2"/>
          <path d="M24 10 V70 M40 10 V70 M56 10 V70 M72 10 V70" stroke="#7CB342" stroke-width="1.5"/>
          <path d="M8 30 H92 M8 50 H92" stroke="#AED581" stroke-width="1"/>
        </svg>''';
      case SketchObjectType.po:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 70">
          <rect x="10" y="10" width="80" height="50" fill="#FFEBEE" stroke="#B71C1C" stroke-width="4"/>
          <line x1="15" y1="15" x2="85" y2="55" stroke="#B71C1C" stroke-width="2"/>
          <line x1="85" y1="15" x2="15" y2="55" stroke="#B71C1C" stroke-width="2"/>
        </svg>''';
      case SketchObjectType.arrow:
        return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 100">
          <path d="M30 90 V18" stroke="#111" stroke-width="5"/>
          <polygon points="30,5 10,28 50,28" fill="#111"/>
        </svg>''';
    }
  }

  pw.Widget _sketchIndexTable(SketchMapEntry sketch) {
    final rows = sketch.objects.isEmpty
        ? [const SketchMapObject(id: '', type: SketchObjectType.house, marker: '-', label: 'No object added', direction: '', indexDescription: '', x: 0, y: 0, width: 0, height: 0, rotationDeg: 0)]
        : sketch.objects;
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.55),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(1.0),
        3: pw.FlexColumnWidth(4.0),
      },
      children: [
        pw.TableRow(children: [
          _cell('Mark', bold: true),
          _cell('Direction', bold: true),
          _cell('Type', bold: true),
          _cell('Description', bold: true),
        ]),
        ...rows.map((o) => pw.TableRow(children: [
              _cell(o.marker),
              _cell(o.direction),
              _cell(o.type.label),
              _cell(o.indexDescription.trim().isEmpty ? o.label : o.indexDescription),
            ])),
      ],
    );
  }

  pw.Widget _centerBold(String text) => pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      );

  pw.TableRow _infoRow(String a, String b, String c, String d) {
    return pw.TableRow(children: [
      _cell(a, bold: true),
      _cell(b),
      _cell(c, bold: true),
      _cell(d),
    ]);
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }
}

extension UdInquestPdfService on PdfService {
  Future<Uint8List> buildUdInquestPdf({
    required OfficerProfile officer,
    required UdCase ud,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    pw.TextStyle normal() => const pw.TextStyle(fontSize: 10.2);
    pw.TextStyle bold() => pw.TextStyle(fontSize: 10.2, fontWeight: pw.FontWeight.bold);
    pw.Widget line(String label, String value, {double height = 18}) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: normal()),
            pw.Expanded(child: pw.Container(
              height: height,
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .35, color: PdfColors.grey600))),
              child: pw.Text(value, style: normal()),
            )),
          ]),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(50, 44, 46, 36),
        build: (context) => [
          pw.Center(child: pw.Text('INQUEST FORM', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 16),
          pw.Center(child: pw.Text('Section 194 / 196 OF BNSS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 22),
          line('1. District: ', ud.district),
          line('   PS: ', ud.policeStation),
          line('   Date & Time: ', ud.dateTime),
          line('2. FIR/UD No. ', ud.udNo),
          line('   GDE No. ', ud.gdeNo),
          line('3. a) Distance from PS ', ud.distanceFromPs.isEmpty ? '' : '${ud.distanceFromPs} Km'),
          line('   b) Direction from PS ', ud.directionFromPs),
          line('   c) Place Where Dead Body Found ', ud.placeFound, height: 22),
          line('      Longitude ', ud.longitude),
          line('      Latitude ', ud.latitude),
          line('   d) Dead body found /traced Date: ', ud.deadBodyFoundDate),
          line('      Time ', ud.deadBodyFoundTime),
          line('4. Informant’s Particulars: Name ', ud.informantName),
          line('      Age ', ud.informantAge),
          line('      Sex ', ud.informantSex),
          line('      Address ', ud.informantAddress, height: 24),
          line('5. Dead Body identified by: Name ', ud.identifiedByName),
          line('      Age ', ud.identifiedByAge),
          line('      Sex ', ud.identifiedBySex),
          line('      Relation (if any) ', ud.identifiedByRelation),
          line('      Address ', ud.identifiedByAddress, height: 24),
          line('6. Name & address of deceased: Name ', ud.deceasedName),
          line('      Sex: Male / Female ', ud.deceasedSex),
          line('      Approx. Age ', ud.deceasedAge),
          line('      Address ', ud.deceasedAddress, height: 24),
          line('7. Position of dead body (including PM staining) ', ud.bodyPosition, height: 42),
          line('8. Description of Dead Body     Build ', ud.build),
          line('   Height ', ud.height),
          line('   (Rigor Mortis) ', ud.rigorMortis),
          line('   Complexion ', ud.complexion),
          line('   Deformities, if any ', ud.deformities),
          line('   Religion/Race/Community: ', ud.religionRaceCommunity),
          line('9. Identification Mark: Teeth: ', ud.teeth),
          line('   Eyes ', ud.eyes),
          line('   Lace derma: ', ud.laceDerma),
          line('   Mole: ', ud.mole),
          line('   Tattoo: ', ud.tattoo),
          line('   Dress/wearing apparel: ', ud.dress, height: 28),
          line('   Other features (if any) ', ud.otherFeatures, height: 24),
          pw.Text('10. Description of external injuries found on Dead Body (if any). Use separate sheet if required.', style: normal()),
          line('a. Head: ', ud.injuryHead),
          line('b. Face: ', ud.injuryFace),
          line('c. Neck: ', ud.injuryNeck),
          line('d. Chest: ', ud.injuryChest),
          line('e. Stomach: ', ud.injuryStomach),
          line('f. Shoulder: ', ud.injuryShoulder),
          line('g. Right Hand: ', ud.injuryRightHand),
          line('h. Left Hand: ', ud.injuryLeftHand),
          line('i. Right Leg: ', ud.injuryRightLeg),
          line('j. Left Leg: ', ud.injuryLeftLeg),
          line('k. Private parts: ', ud.injuryPrivateParts),
          line('l. Back: ', ud.injuryBack),
          line('m. Any other injury: ', ud.injuryOther),
          pw.SizedBox(height: 20),
          pw.Text('11. Discharge form:', style: normal()),
          line('a. Nostrils: ', ud.nostrils),
          line('b. Ears / Eyes: ', ud.earsEyes),
          line('c. Mouth: ', ud.mouth),
          line('d. Penis/Vagina: ', ud.penisVagina),
          line('e. Anus: ', ud.anus),
          pw.SizedBox(height: 14),
          line('12. Opinion on nature of weapon used and manner in which injuries may have been caused/inflicted. ', ud.weaponOpinion, height: 36),
          line('13. If death by hanging strangulation, description of ligature mark, rope & Knot around the neck: ', ud.ligatureDescription, height: 36),
          line('14. Any foreign material such as weeds, straw, hair, etc. clinched in the hand of the deceased or attaches on any part of the body: ', ud.foreignMaterial, height: 36),
          line('15. Description of place of occurrence: ', ud.poDescription, height: 32),
          line('16. Description of articles at the place of occurrence including weapon of offence, ornaments etc. ', ud.articlesAtPo, height: 32),
          line('17. Opinion as to the probable cause to death: ', ud.probableCauseOfDeath, height: 26),
          line('18. Remarks (comment on condition of body & other relevant information on crime): ', ud.remarks, height: 38),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(child: line('19. Witnesses: Name /Address: ', ud.witness1NameAddress, height: 22)),
            pw.SizedBox(width: 16),
            pw.Expanded(child: line('Signature ', '', height: 22)),
          ]),
          pw.Row(children: [
            pw.Expanded(child: line('(ii) ', ud.witness2NameAddress, height: 22)),
            pw.SizedBox(width: 16),
            pw.Expanded(child: line('(ii) ', '', height: 22)),
          ]),
          pw.SizedBox(height: 14),
          pw.Text('Brief facts (please attach separate sheets)', style: normal()),
          pw.Container(
            height: 70,
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: .35, color: PdfColors.grey600))),
            child: pw.Text(ud.briefFacts, style: normal()),
          ),
          pw.SizedBox(height: 40),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Signature of Investigation Officer', style: normal()),
              pw.SizedBox(height: 18),
              pw.Text('Name: ${officer.name}', style: normal()),
              pw.Text('Rank: ${officer.rank}', style: normal()),
            ]),
          ),
        ],
      ),
    );
    return doc.save();
  }
}

extension NcrPdfExport on PdfService {
  Future<Uint8List> buildNcrPdf({
    required OfficerProfile officer,
    required NcrReport report,
  }) async {
    final doc = pw.Document(theme: await _pdfTheme());
    final bn = AppLanguageController.instance.isBengali;
    String t(String b, String e) => bn ? b : e;
    pw.TextStyle normal([double size = 8.2]) => pw.TextStyle(fontSize: size);
    pw.TextStyle bold([double size = 8.2]) => pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold);

    pw.Widget cell(String text, {bool isBold = false, bool center = false, double size = 8.2, double minHeight = 360}) {
      return pw.Container(
        constraints: pw.BoxConstraints(minHeight: minHeight),
        padding: const pw.EdgeInsets.all(4),
        alignment: center ? pw.Alignment.topCenter : pw.Alignment.topLeft,
        child: pw.Text(text, style: isBold ? bold(size) : normal(size), textAlign: center ? pw.TextAlign.center : pw.TextAlign.justify),
      );
    }

    pw.Widget verticalCell(String text, {bool isBold = false, double size = 8.0, double minHeight = 360}) {
      return pw.Container(
        constraints: pw.BoxConstraints(minHeight: minHeight),
        alignment: pw.Alignment.center,
        child: pw.Transform.rotate(
          angle: -math.pi / 2,
          child: pw.Container(
            width: minHeight - 12,
            alignment: pw.Alignment.center,
            child: pw.Text(text, style: isBold ? bold(size) : normal(size), textAlign: pw.TextAlign.center),
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(t('পশ্চিমবঙ্গ ফর্ম নং ${report.formNo}', 'West Bengal Form No. ${report.formNo}'), style: normal(8.5)),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text(t('যেসব মামলায় প্রথম তথ্য প্রতিবেদন ব্যবহৃত হয় না, সেই মামলায় প্রসিকিউশনের রিপোর্ট', 'REPORT FOR PROSECUTION IN CASES IN WHICH NON-FIRST INFORMATION REPORT IS USED'), style: bold(13))),
            pw.SizedBox(height: 3),
            pw.Center(child: pw.Text('${t('রেফারেন্স', 'Ref')}: ${report.reference}', style: normal(9))),
            pw.SizedBox(height: 12),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('${t('জেলা', 'District')}: ${report.district}', style: normal(9)),
              pw.Text('(PRB Form No. 41- Vide Rule -220)', style: normal(8.5)),
              pw.Text('${t('থানা', 'Police Station')}: ${report.policeStation}', style: normal(9)),
            ]),
            pw.Table(
              border: pw.TableBorder.all(width: .65),
              columnWidths: const {
                0: pw.FlexColumnWidth(.65),
                1: pw.FlexColumnWidth(1.05),
                2: pw.FlexColumnWidth(2.45),
                3: pw.FlexColumnWidth(.65),
                4: pw.FlexColumnWidth(.72),
                5: pw.FlexColumnWidth(5.15),
                6: pw.FlexColumnWidth(2.15),
                7: pw.FlexColumnWidth(1.35),
                8: pw.FlexColumnWidth(.78),
              },
              children: [
                pw.TableRow(children: [
                  verticalCell(t('ক্রমিক নম্বর', 'Serial Number'), isBold: true, minHeight: 78),
                  cell(t('অভিযোগকারী অথবা তথ্য', 'Complainant Or Information'), isBold: true, center: true, minHeight: 78),
                  cell(t('অভিযুক্তের নাম ও ঠিকানা (হাজতে পাঠানো হলে বা জামিনে থাকলে উল্লেখ করতে হবে। জামিনে না থাকলে বন্ড সংযুক্ত করতে হবে)', 'Name and address of accused (Note: If sent up in custody or on bail. If on bail, Bail bond should be attached)'), isBold: true, center: true, minHeight: 78),
                  verticalCell(t('গ্রেপ্তারের তারিখ', 'Date of arrest'), isBold: true, minHeight: 78),
                  verticalCell(t('শুনানির তারিখ', 'Date of hearing'), isBold: true, minHeight: 78),
                  cell(t('অপরাধের সংক্ষিপ্ত বিবরণ—তারিখ, স্থান এবং আইনের ধারা', 'Brief description of the offence with date and place of occurrence and section of law'), isBold: true, center: true, minHeight: 78),
                  cell(t('সাক্ষীর নাম ও ঠিকানা', 'Name and address of witness'), isBold: true, center: true, minHeight: 78),
                  cell(t('বিচারকারী ম্যাজিস্ট্রেটের নামসহ বিচারের ফলাফল', 'Result of trial With the name of trying Magistrate'), isBold: true, center: true, minHeight: 78),
                  verticalCell(t('মন্তব্য', 'Remarks'), isBold: true, minHeight: 78),
                ]),
                pw.TableRow(verticalAlignment: pw.TableCellVerticalAlignment.top, children: [
                  verticalCell('${report.ncrNo}\nU/S ${report.caseSections}', minHeight: 320),
                  verticalCell(report.complainantInformation, minHeight: 320),
                  cell(report.accusedDetails, center: false, minHeight: 320),
                  verticalCell(report.arrestDate, minHeight: 320),
                  verticalCell(report.hearingDate, minHeight: 320),
                  cell(report.offenceBrief, minHeight: 320),
                  cell(report.witnessDetails, minHeight: 320),
                  cell(report.trialResult, center: true, minHeight: 320),
                  verticalCell(report.remarks, minHeight: 320),
                ]),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 82),
                child: pw.Column(children: [
                  pw.Text(t('পেশ করা হলো', 'Submitted'), style: normal(9)),
                  pw.SizedBox(height: 22),
                  pw.Text(report.submittedBy.isEmpty ? '${officer.rank} ${officer.name}' : report.submittedBy, style: normal(9)),
                  pw.Text('${report.policeStation}, ${report.district}', style: normal(9)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> shareNcrPdf({required OfficerProfile officer, required NcrReport report}) async {
    final bytes = await buildNcrPdf(officer: officer, report: report);
    await Printing.sharePdf(bytes: bytes, filename: 'NCR_${report.ncrNo.replaceAll('/', '_')}.pdf');
  }
}
