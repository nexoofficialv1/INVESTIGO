import 'dart:convert';
import 'dart:typed_data';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/sketch_map.dart';
import '../models/statement_entry.dart';
import '../models/ud_case.dart';
import '../models/ncr_report.dart';
import '../models/final_case_documents.dart';
import '../core/app_language.dart';

class DocExportService {
  Uint8List _docBytes(String html) => Uint8List.fromList(utf8.encode(html));

  String _e(String value) => const HtmlEscape()
      .convert(value)
      .replaceAll('&#47;', '/')
      .replaceAll('&#x2F;', '/')
      .replaceAll('\n', '<br/>');


  String _shortPsName(String ps) => ps
      .replaceAll(RegExp(r'Police\s+Station', caseSensitive: false), 'PS')
      .replaceAll(RegExp(r'P\.?\s*S\.?$', caseSensitive: false), 'PS')
      .trim();

  String _barePsName(String ps) => ps
      .replaceAll(
        RegExp(r'\s+(Police\s+Station|P\.?\s*S\.?)$', caseSensitive: false),
        '',
      )
      .trim();

  String _officialDate(String raw) {
    final value = raw.trim();
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day.$month.${parsed.year}';
  }

  String _caseYear(CaseFile caseFile) {
    final dateMatch = RegExp(r'(?:19|20)\d{2}').firstMatch(caseFile.caseDate);
    if (dateMatch != null) return dateMatch.group(0)!;
    final numberMatch = RegExp(r'(?:19|20)\d{2}').firstMatch(caseFile.psCaseNo);
    return numberMatch?.group(0) ?? DateTime.now().year.toString();
  }

  String _roman(int number) {
    if (number <= 0) return number.toString();
    const values = <int>[1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = <String>['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    var remaining = number;
    final out = StringBuffer();
    for (var i = 0; i < values.length; i++) {
      while (remaining >= values[i]) {
        out.write(symbols[i]);
        remaining -= values[i];
      }
    }
    return out.toString();
  }

  String _page(String title, String body) => '''
<html>
<head>
<meta charset="utf-8">
<title>${_e(title)}</title>
<style>
  @page { size: A4; margin: 18mm 14mm 18mm 14mm; }
  body { font-family: "Times New Roman", serif; font-size: 12pt; color: #000; }
  table { border-collapse: collapse; width: 100%; }
  td, th { border: 1px solid #000; padding: 4px; vertical-align: top; }
  .center { text-align: center; }
  .right { text-align: right; }
  .bold { font-weight: bold; }
  .small { font-size: 10.5pt; }
  .cd td { font-size: 10.5pt; }
  .cd .entry-row td { border-top: 0; border-bottom: 0; }
  .cd .signature-row td { border-top: 0; }
  .no-border td, .no-border th { border: none; }
  .justify { text-align: justify; }
  .page-break { page-break-before: always; }
</style>
</head>
<body>$body</body>
</html>
''';

  Future<Uint8List> buildCaseDiaryDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required CdEntry cd,
  }) async {
    final lines = cd.tableLines.isNotEmpty
        ? cd.tableLines
        : [
            CdTableLine(
              noAndHour: 'I\n${cd.startTime}',
              placeOfEntry: cd.placeOfEntry,
              synopsis: cd.cdNumber == 1
                  ? 'Received copy of FIR\n+\nGist'
                  : 'Further investigation',
              proceedings: cd.body,
            ),
          ];
    final entryRows = lines
        .map(
          (line) => '''
<tr class="entry-row">
  <td class="center" style="width:9%">${_e(line.noAndHour)}</td>
  <td class="center" style="width:9%">${_e(line.placeOfEntry)}</td>
  <td class="center" style="width:11%">${_e(line.synopsis)}</td>
  <td class="justify" style="width:71%">${_e(line.proceedings)}</td>
</tr>''',
        )
        .join();
    final year = _caseYear(caseFile);
    final psHeader = _barePsName(officer.policeStation);
    final psSignature = _shortPsName(officer.policeStation);
    final html = '''
<div class="bold">
  <span>West Bengal form No. 5363</span><span style="float:right">OF $year</span>
</div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div>
<div class="center bold">(P.R.B FROM NO. 43 - Vide <i>Rule 229</i>)</div>
<table class="no-border small">
<tr><td class="bold">Police Station: -${_e(psHeader)}</td><td class="bold right">District: -${_e(officer.district)}</td></tr>
<tr><td class="bold">First information No: -${_e(caseFile.psCaseNo)}</td><td class="bold">Dated: -${_e(_officialDate(caseFile.caseDate))} &nbsp;&nbsp;&nbsp; Section: -${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">Name of Complainant: -${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">Case Diary No: -${_roman(cd.cdNumber)}</td><td class="bold">Dated: -${_e(_officialDate(cd.cdDate))}</td></tr>
</table>
<table class="cd">
<colgroup><col style="width:33.33%"><col style="width:33.33%"><col style="width:33.34%"></colgroup>
<tr><td class="center">Arrested and sent up</td><td class="center">Arrested and released on bail.</td><td class="center">At large.</td></tr>
</table>
<table class="cd">
<colgroup><col style="width:9%"><col style="width:9%"><col style="width:11%"><col style="width:71%"></colgroup>
<tr><td colspan="3" class="bold">Particulars of Enquiry.</td><td></td></tr>
<tr><td class="center">No. and<br/>hour of<br/>entry.</td><td class="center">Place of<br/>entry.</td><td class="center">Synopsis of<br/>entry.</td><td></td></tr>
$entryRows
<tr class="signature-row"><td></td><td></td><td></td><td class="right" style="padding-right:70px;padding-top:20px">Submitted<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(psSignature)}</td></tr>
</table>
''';
    return _docBytes(_page('CD-${cd.cdNumber}', html));
  }


  Future<Uint8List> buildStatementDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StatementEntry statement,
  }) async {
    final html = '''
<div class="center bold">Statement of witness recorded u/s 180 BNSS</div><br/>
<p>Case Reference: ${_e(officer.policeStation)} PS Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p>Name of Witness: ${_e(statement.witnessName)}<br/>Witness Details: ${_e(statement.witnessDetails)}<br/>Statement Type: ${_e(statement.statementType)}</p>
<p class="justify">${_e(statement.body)}</p>
<table class="no-border" style="margin-top:40px"><tr><td>Signature/LTI/RTI of witness</td><td class="right">Recorded by<br/><br/>${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}</td></tr></table>
''';
    return _docBytes(_page('Statement', html));
  }

  String _field(String body, String key, {String fallback = ''}) {
    final match = RegExp(
      r'(?:^|\n)' +
          RegExp.escape(key) +
          r'\s*:\s*(.*?)(?=\n[A-Z][A-Z /&-]{2,}\s*:|\nNote:|$)',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(body);
    final value = (match?.group(1) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  List<List<String>> _pipeRows(String raw, int columns, List<String> fallback) {
    final rows = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
      final parts = line.split('|').map((part) => part.trim()).toList();
      while (parts.length < columns) {
        parts.add('');
      }
      return parts.take(columns).toList();
    }).toList();
    return rows.isEmpty ? [fallback] : rows;
  }

  Uint8List _buildFslPackageDoc(
    OfficerProfile officer,
    CaseFile caseFile,
    FormNotice form,
  ) {
    final body = form.body;
    final nature = _field(
      body,
      'NATURE OF CRIME',
      fallback: caseFile.firGist,
    );
    final examination = _field(body, 'NATURE OF EXAMINATION');
    final fslOffice = _field(
      body,
      'FSL OFFICE',
      fallback: officer.defaultFslOffice,
    );
    final court = _field(
      body,
      'COURT',
      fallback: officer.courtName,
    );
    final exhibits = _pipeRows(
      _field(body, 'EXHIBITS', fallback: _field(body, 'EXHIBIT DESCRIPTION')),
      5,
      ['A', '____________________________', '____________________________', court, '________________'],
    );
    final persons = _pipeRows(
      _field(body, 'PERSONS IN CUSTODY', fallback: _field(body, 'PERSON IN CUSTODY')),
      7,
      [caseFile.accusedName, '', '', '', '', '', court],
    );
    final exhibitRows = exhibits.map((row) => '<tr>${row.map((cell) => '<td>${_e(cell)}</td>').join()}</tr>').join();
    final custodyRows = persons.map((row) => '<tr>${row.map((cell) => '<td>${_e(cell)}</td>').join()}</tr>').join();
    final ref = '${officer.policeStation} Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}';
    final html = '''
<html><head><meta charset="utf-8"><style>
@page{size:A4;margin:14mm 12mm} body{font-family:"Times New Roman",serif;font-size:10.5pt} table{width:100%;border-collapse:collapse;table-layout:fixed} td,th{border:1px solid #000;padding:4px;vertical-align:top}.center{text-align:center}.right{text-align:right}.bold{font-weight:bold}.justify{text-align:justify}.page-break{page-break-before:always}.small{font-size:9pt}
</style></head><body>
<div>West Bengal Form No- 5203</div>
<div class="center bold">WEST BENGAL POLICE</div><br/>
<p>Case No:- ${_e(caseFile.psCaseNo)} &nbsp; Date ${_e(caseFile.caseDate)}<br/>Police Station:- ${_e(officer.policeStation)}<br/>Section of Law:- ${_e(caseFile.sections)} &nbsp; District- ${_e(officer.district)}</p>
<div class="center bold">I. NATURE OF CRIME</div><p class="justify">${_e(nature)}</p>
<div class="right">Submitted<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}</div>
<div class="page-break"></div>
<div class="center bold">II. LIST OF EXHIBITS SENT FOR EXAMINATION</div><br/>
<table><tr><th>Label No</th><th>Description of the exhibit</th><th>How and when found and by whom</th><th>Ownership of exhibit</th><th>Remarks</th></tr>$exhibitRows</table>
<br/><div class="center bold">III. NATURE OF EXAMINATION REQUIRED</div><p class="justify">${_e(examination)}</p>
<div class="page-break"></div>
<div class="center bold">IV. PARTICULARS OF PERSONS IN CUSTODY</div><br/>
<table><tr><th>Full name</th><th>Occupation</th><th>Age</th><th>Sex</th><th>Date & time of arrest</th><th>Bail/Custody</th><th>Court</th></tr>$custodyRows</table>
<div class="right" style="margin-top:30px">Signature and Rank of the I.O.<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}</div>
<p>Forwarded to:<br/>${_e(fslOffice)}</p><p>Through: ${_e(court)}</p>
<div class="page-break"></div>
<div class="center bold">EXHIBIT CHALLAN</div><p>Ref: ${_e(ref)}</p><p class="justify">I am sending herewith the following exhibit(s) for examination and opinion for the interest of investigation of the case.</p>
<table><tr><th>Mark</th><th>Description</th></tr>${exhibits.map((row) => '<tr><td>${_e(row[0])}</td><td>${_e(row[1])}</td></tr>').join()}</table>
<div class="right" style="margin-top:30px">Yours faithfully<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}<br/>Mobile: ${_e(officer.mobile)}</div>
<div class="page-break"></div>
${exhibits.map((row) => '<div class="center bold">LABEL</div><p>To<br/>${_e(fslOffice)}<br/>Through ${_e(court)}</p><p>Ref: ${_e(ref)}</p><p>Description of Article:<br/>Exhibit Mark “${_e(row[0])}” — ${_e(row[1])}</p><div class="right">Labeled & prepared by me<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}</div><div class="page-break"></div>').join()}
</body></html>
''';
    return _docBytes(html);
  }

  Uint8List _buildAFormDoc(
    OfficerProfile officer,
    CaseFile caseFile,
    FormNotice form,
  ) {
    final body = form.body;
    final court = _field(body, 'COURT NAME', fallback: officer.courtName);
    final through = _field(body, 'THROUGH', fallback: 'Bench Clerk');
    final totalPages = _field(body, 'TOTAL DOCKET PAGES', fallback: '__________');
    final csNo = _field(body, 'CHARGE SHEET NO', fallback: '__________');
    final indexRaw = _field(body, 'DOCUMENT INDEX');
    final rows = _pipeRows(indexRaw, 3, ['1', 'F.I.R.', '']);
    final tableRows = rows.map((row) => '<tr><td>${_e(row[0])}</td><td>${_e(row[1])}</td><td>${_e(row[2])}</td></tr>').join();
    return _docBytes('''<html><head><meta charset="utf-8"><style>@page{size:A4;margin:14mm}body{font-family:"Times New Roman",serif;font-size:11pt}table{width:100%;border-collapse:collapse}td,th{border:1px solid #000;padding:5px}.center{text-align:center}.right{text-align:right}.bold{font-weight:bold}</style></head><body>
<div class="center bold">A FORM</div><br/>
<p>In the Court of: ${_e(court)}<br/>Through: ${_e(through)}</p>
<p>Ref: ${_e(officer.policeStation)} Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p>Charge Sheet No.: ${_e(csNo)} &nbsp;&nbsp; Total Docket Pages: ${_e(totalPages)}</p>
<table><tr><th>Sl. No.</th><th>Description of Document</th><th>Page No.</th></tr>$tableRows</table>
<div class="right" style="margin-top:36px">Submitted<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}</div>
</body></html>''');
  }

  Future<Uint8List> buildFormNoticeDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
    if (form.templateId == 'fsl') {
      return _buildFslPackageDoc(officer, caseFile, form);
    }
    if (form.templateId == 'a_form') {
      return _buildAFormDoc(officer, caseFile, form);
    }
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="small">Ref: ${_e(officer.policeStation)} Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">Submitted,<br/><br/>${_e(officer.name)}<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}, ${_e(officer.district)}</div>
''';
    return _docBytes(_page(form.title, html));
  }

  Future<Uint8List> buildGeneralReportDoc({
    required OfficerProfile officer,
    required FormNotice form,
  }) async {
    final html = '''
<div class="center bold">${_e(form.title)}</div><br/>
<p class="justify">${_e(form.body)}</p>
<div class="right" style="margin-top:36px">${_e(officer.rank)} ${_e(officer.name)}<br/>${_e(officer.policeStation)}<br/>District: ${_e(officer.district)}</div>
''';
    return _docBytes(_page(form.title, html));
  }

  Future<Uint8List> buildSketchMapDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required SketchMapEntry sketch,
  }) async {
    final rows = sketch.objects.map((o) => '<tr><td>${_e(o.marker)}</td><td>${_e(o.label)}</td><td>${_e(o.direction)}</td><td>${_e(o.indexDescription)}</td></tr>').join();
    final html = '''
<div class="center bold">ROUGH SKETCH MAP WITH INDEX</div>
<p>Case Reference: ${_e(officer.policeStation)} PS Case No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} u/s ${_e(caseFile.sections)}</p>
<p>PO: ${_e(sketch.poDescription)}</p>
<table><tr><th>Marker</th><th>Label</th><th>Direction</th><th>Index Description</th></tr>$rows</table>
<p>North: ${_e(sketch.north)}<br/>South: ${_e(sketch.south)}<br/>East: ${_e(sketch.east)}<br/>West: ${_e(sketch.west)}</p>
<div class="right" style="margin-top:36px">Prepared by<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(officer.policeStation)}</div>
''';
    return _docBytes(_page('Sketch Map', html));
  }
}

extension UdInquestDocExport on DocExportService {
  Future<Uint8List> buildUdInquestDoc({
    required OfficerProfile officer,
    required UdCase ud,
  }) async {
    String e(String v) => _e(v);
    String row(String label, String value) => '<p>$label <span style="border-bottom:1px dotted #777;display:inline-block;min-width:480px">${e(value)}</span></p>';
    final html = _page('UD Inquest', '''
<div class="center bold">INQUEST FORM</div>
<div class="center bold">Section 194 / 196 OF BNSS</div>
${row('1. District:', ud.district)}
${row('PS:', ud.policeStation)}
${row('Date & Time:', ud.dateTime)}
${row('2. FIR/UD No.:', ud.udNo)}
${row('GDE No. & Date:', ud.gdeNo)}
${row('3. a) Distance from PS:', ud.distanceFromPs)}
${row('b) Direction from PS:', ud.directionFromPs)}
${row('c) Place Where Dead Body Found:', ud.placeFound)}
${row('Longitude:', ud.longitude)} ${row('Latitude:', ud.latitude)}
${row('d) Dead body found/traced Date:', ud.deadBodyFoundDate)} ${row('Time:', ud.deadBodyFoundTime)}
${row('4. Informant’s Particulars: Name:', ud.informantName)}
${row('Age:', ud.informantAge)} ${row('Sex:', ud.informantSex)}
${row('Address:', ud.informantAddress)}
${row('5. Dead Body identified by: Name:', ud.identifiedByName)}
${row('Age:', ud.identifiedByAge)} ${row('Sex:', ud.identifiedBySex)}
${row('Relation (if any):', ud.identifiedByRelation)}
${row('Address:', ud.identifiedByAddress)}
${row('6. Name & address of deceased: Name:', ud.deceasedName)}
${row('Sex: Male/Female:', ud.deceasedSex)} ${row('Approx. Age:', ud.deceasedAge)}
${row('Address:', ud.deceasedAddress)}
${row('7. Position of dead body (including PM staining):', ud.bodyPosition)}
${row('8. Description of Dead Body Build:', ud.build)} ${row('Height:', ud.height)}
${row('(Rigor Mortis):', ud.rigorMortis)} ${row('Complexion:', ud.complexion)}
${row('Deformities, if any:', ud.deformities)} ${row('Religion/Race/Community:', ud.religionRaceCommunity)}
${row('9. Identification Mark Teeth:', ud.teeth)} ${row('Eyes:', ud.eyes)} ${row('Lace derma:', ud.laceDerma)}
${row('Mole:', ud.mole)} ${row('Tattoo:', ud.tattoo)}
${row('Dress/wearing apparel:', ud.dress)}
${row('Other features (if any):', ud.otherFeatures)}
<p>10. Description of external injuries found on Dead Body (if any). Use separate sheet if required.</p>
${row('a. Head:', ud.injuryHead)} ${row('b. Face:', ud.injuryFace)} ${row('c. Neck:', ud.injuryNeck)} ${row('d. Chest:', ud.injuryChest)}
${row('e. Stomach:', ud.injuryStomach)} ${row('f. Shoulder:', ud.injuryShoulder)} ${row('g. Right Hand:', ud.injuryRightHand)}
${row('h. Left Hand:', ud.injuryLeftHand)} ${row('i. Right Leg:', ud.injuryRightLeg)} ${row('j. Left Leg:', ud.injuryLeftLeg)}
${row('k. Private parts:', ud.injuryPrivateParts)} ${row('l. Back:', ud.injuryBack)} ${row('m. Any other injury:', ud.injuryOther)}
${row('11. a. Nostrils:', ud.nostrils)} ${row('b. Ears/Eyes:', ud.earsEyes)} ${row('c. Mouth:', ud.mouth)}
${row('d. Penis/Vagina:', ud.penisVagina)} ${row('e. Anus:', ud.anus)}
${row('12. Opinion on nature of weapon used and manner in which injuries may have been caused/inflicted:', ud.weaponOpinion)}
${row('13. If death by hanging strangulation, description of ligature mark, rope & knot around the neck:', ud.ligatureDescription)}
${row('14. Foreign material:', ud.foreignMaterial)}
${row('15. Description of place of occurrence:', ud.poDescription)}
${row('16. Description of articles at the PO including weapon, ornaments etc.:', ud.articlesAtPo)}
${row('17. Opinion as to probable cause to death:', ud.probableCauseOfDeath)}
${row('18. Remarks:', ud.remarks)}
${row('19. Witness (i) Name/Address:', ud.witness1NameAddress)}
${row('Witness (ii) Name/Address:', ud.witness2NameAddress)}
<p>Brief facts (please attach separate sheets)</p>
<p>${e(ud.briefFacts)}</p>
<div class="right" style="margin-top:40px">Signature of Investigation Officer<br/><br/>Name: ${e(officer.name)}<br/>Rank: ${e(officer.rank)}</div>
''');
    return _docBytes(html);
  }
}
extension UdOfficialSupportingDocExport on DocExportService {
  Future<Uint8List> buildUdDeadBodyChallanDoc({required OfficerProfile officer, required UdCase ud}) async {
    final bn = AppLanguageController.instance.isBengali;
    String t(String b, String e) => bn ? b : e;
    String e(String v) => _e(v);
    final identity = '${e(ud.deceasedName)} (${e(ud.religionRaceCommunity)}, ${e(ud.deceasedSex)}, ${t('বয়স','Age')}- ${e(ud.deceasedAge)})';
    final narrative = t(
      '${e(ud.deceasedName)} নামীয় মৃত ব্যক্তির মৃতদেহটি ময়নাতদন্তের মাধ্যমে মৃত্যুর প্রকৃত কারণ নির্ণয়ের জন্য সংশ্লিষ্ট কাগজপত্রসহ প্রেরণ করা হলো।',
      'Forwarded the dead body of the deceased namely ${e(ud.deceasedName)}, (${e(ud.deceasedSex)}, Age- ${e(ud.deceasedAge)}) of ${e(ud.deceasedAddress)} with all connected papers for holding Post Mortem Examination to ascertain the actual cause of death.',
    );
    return _docBytes('''<html><head><meta charset="utf-8"><style>
@page { size:A4 landscape; margin:10mm 9mm; } body{font-family:"Noto Serif Bengali","Times New Roman",serif;font-size:9pt} table{border-collapse:collapse;width:100%;table-layout:fixed}td,th{border:1px solid #000;padding:3px;vertical-align:middle}.c{text-align:center}.v{writing-mode:vertical-rl;transform:rotate(180deg);text-align:center}.j{text-align:justify}
</style></head><body>
<div>${t('পশ্চিমবঙ্গ ফর্ম নং- ৫৩৭১','West Bengal Form No- 5371')}</div>
<div class="c"><b>${t('রেফারেন্স','Ref')}: ${e(ud.policeStation)} U/D Case No: ${e(ud.udNo)}, ${t('তারিখ','Date')}: ${e(ud.dateTime)}</b><br/>(P.R.B Form No-54 vide Rule-252)</div><br/>
<table><colgroup><col style="width:9%"><col style="width:6%"><col style="width:8%"><col style="width:8%"><col style="width:10%"><col style="width:9%"><col style="width:10%"><col style="width:7%"><col style="width:7%"><col style="width:13%"></colgroup>
<tr style="height:80px"><th>${t('মৃত ব্যক্তির নাম ও জাতি','Name and caste of deceased')}</th><th>${t('লিঙ্গ ও বয়স','Sex and Age')}</th><th>${t('বাসস্থান','Residence')}</th><th>${t('মৃতদেহ যেখানে পাওয়া যায়','Where dead body was found')}</th><th>${t('প্রেরণের তারিখ-সময় ও দূরত্ব','Date and hours of dispatch and distance from place of postmortem')}</th><th>${t('প্রেরণের মাধ্যম','Means of Dispatch')}</th><th>${t('সনাক্তকারী পুলিশ অফিসারের নাম','Name of identifying Police officer')}</th><th>${t('মৃতদেহের চিহ্ন','Marks on the body')}</th><th>${t('মৃত্যুর কারণ','Cause of death as far as known')}</th><th>${t('মন্তব্য','Remarks')}</th></tr>
<tr style="height:280px"><td class="v">$identity</td><td class="v">${e(ud.deceasedSex)}, ${e(ud.deceasedAge)}</td><td class="v">${e(ud.deceasedAddress)}</td><td class="v">${e(ud.placeFound)}</td><td class="v">${e(ud.dateTime)} ${e(ud.distanceFromPs)}</td><td class="v">${e(ud.directionFromPs)}</td><td class="v">${e(ud.identifiedByName.isEmpty ? '${officer.rank} ${officer.name}' : ud.identifiedByName)}</td><td class="v">${e(ud.otherFeatures)}</td><td class="v">${e(ud.probableCauseOfDeath)}</td><td>${e(ud.dress)}<br/>${e(ud.articlesAtPo)}<br/>${e(ud.remarks)}</td></tr>
<tr><td colspan="5"></td><td colspan="5" class="j">$narrative<br/><br/><div class="c">${t('পেশ করা হলো –','Submitted –')}<br/><br/>(${e(officer.name)})<br/>${e(officer.rank)}, ${e(officer.policeStation)}<br/>${t('তারিখ','Date')}: ${e(ud.dateTime)}</div></td></tr></table>
</body></html>''');
  }

  Future<Uint8List> buildUdFinalReportDoc({required OfficerProfile officer, required UdCase ud}) async {
    final bn = AppLanguageController.instance.isBengali;
    String t(String b, String e) => bn ? b : e;
    String e(String v) => _e(v);
    final narrative = ud.briefFacts.isNotEmpty ? e(ud.briefFacts) : e(ud.remarks);
    return _docBytes(_page('UD Final Report', '''
<div class="bold">${t('পশ্চিমবঙ্গ ফর্ম নং ৫৩৭০','West Bengal form No. 5370')}</div><br/>
<div class="center bold">${t('অস্বাভাবিক মৃত্যুর নথিভুক্ত মামলার চূড়ান্ত প্রতিবেদন ম্যাজিস্ট্রেটের নিকট প্রেরণ','FINAL REPORT OF A REPORTED CASE OF UNNATURAL DEATH SENT TO THE MAGISTRATE')}</div>
<div class="center bold">(P.R.B. Form No.- 53 Vide Rule 276)</div><br/>
<p>1. ${t('থানা, প্রথম তথ্যের নম্বর ও তারিখ','Station, Number and date of first information')} : ${e(ud.policeStation)} U/D Case No. ${e(ud.udNo)}, Dated- ${e(ud.dateTime)}</p>
<p>2. ${t('মৃত ব্যক্তির নাম','Name of the deceased')} : ${e(ud.deceasedName)} (${e(ud.deceasedSex)}, Age- ${e(ud.deceasedAge)})</p>
<p>3. ${t('ঘটনাস্থলে যাওয়ার তারিখ ও সময়','Date and hour of going to the spot')} : ${e(ud.deadBodyFoundDate)} ${e(ud.deadBodyFoundTime)}</p>
<p>4. ${t('চূড়ান্ত প্রতিবেদন প্রেরণের তারিখ ও সময়','Date and hour of dispatch of the final report')} : ${e(ud.dateTime)}</p><br/>
<div class="center bold"><u>${t('অফিসার-ইন-চার্জ','Officer-In-Charge of')} ${e(ud.policeStation)}</u></div>
<p class="justify">$narrative</p>
<p class="justify">${e(ud.remarks)}</p>
<p>${t('অতএব, উপরোক্ত U/D মামলাটি নথিভুক্ত করে বাধিত করার প্রার্থনা করছি।','Therefore, I am praying that this U/D Case may kindly be filed and obliged.')}</p>
<div class="right" style="margin-top:35px">${t('পেশ করা হলো','Submitted')}<br/><br/>(${e(officer.name)})<br/>${e(officer.rank)}, ${e(officer.policeStation)}<br/>${e(officer.district)}, ${t('তারিখ','Dt')}- ${e(ud.dateTime)}</div>
'''));
  }
}

extension NcrDocExport on DocExportService {
  Future<Uint8List> buildNcrDoc({
    required OfficerProfile officer,
    required NcrReport report,
  }) async {
    final bn = AppLanguageController.instance.isBengali;
    String t(String b, String e) => bn ? b : e;
    String e(String value) => _e(value);
    final html = '''
<html><head><meta charset="utf-8"><title>NCR</title>
<style>
@page { size: A4 landscape; margin: 10mm 8mm 10mm 8mm; }
body { font-family: "Noto Serif Bengali", "Times New Roman", serif; font-size: 9pt; color:#000; }
table { border-collapse: collapse; width:100%; table-layout:fixed; }
td,th { border:1px solid #000; padding:3px; vertical-align:top; }
.center{text-align:center}.right{text-align:right}.bold{font-weight:bold}.justify{text-align:justify}
.v { writing-mode: vertical-rl; transform: rotate(180deg); text-align:center; vertical-align:middle; }
</style></head><body>
<div>${t('পশ্চিমবঙ্গ ফর্ম নং', 'West Bengal Form No.')} ${e(report.formNo)}</div>
<h2 class="center">${t('যেসব মামলায় প্রথম তথ্য প্রতিবেদন ব্যবহৃত হয় না, সেই মামলায় প্রসিকিউশনের রিপোর্ট', 'REPORT FOR PROSECUTION IN CASES IN WHICH NON-FIRST INFORMATION REPORT IS USED')}</h2>
<div class="center">${t('রেফারেন্স', 'Ref')}: ${e(report.reference)}</div><br/>
<table style="border:none"><tr><td style="border:none">${t('জেলা','District')}: ${e(report.district)}</td><td style="border:none" class="center">(PRB Form No. 41- Vide Rule -220)</td><td style="border:none" class="right">${t('থানা','Police Station')}: ${e(report.policeStation)}</td></tr></table>
<table>
<colgroup><col style="width:5%"><col style="width:8%"><col style="width:17%"><col style="width:5%"><col style="width:5%"><col style="width:36%"><col style="width:14%"><col style="width:7%"><col style="width:5%"></colgroup>
<tr style="height:75px">
<th class="v">${t('ক্রমিক নম্বর','Serial Number')}</th>
<th>${t('অভিযোগকারী অথবা তথ্য','Complainant Or Information')}</th>
<th>${t('অভিযুক্তের নাম ও ঠিকানা (হাজতে পাঠানো হলে বা জামিনে থাকলে উল্লেখ করতে হবে। জামিনে না থাকলে বন্ড সংযুক্ত করতে হবে)','Name and address of accused (Note: If sent up in custody or on bail. If on bail, Bail bond should be attached)')}</th>
<th class="v">${t('গ্রেপ্তারের তারিখ','Date of arrest')}</th>
<th class="v">${t('শুনানির তারিখ','Date of hearing')}</th>
<th>${t('অপরাধের সংক্ষিপ্ত বিবরণ—তারিখ, স্থান এবং আইনের ধারা','Brief description of the offence with date and place of occurrence and section of law')}</th>
<th>${t('সাক্ষীর নাম ও ঠিকানা','Name and address of witness')}</th>
<th>${t('বিচারকারী ম্যাজিস্ট্রেটের নামসহ বিচারের ফলাফল','Result of trial With the name of trying Magistrate')}</th>
<th class="v">${t('মন্তব্য','Remarks')}</th>
</tr>
<tr style="height:390px">
<td class="v">${e(report.ncrNo)}<br/>U/S ${e(report.caseSections)}</td>
<td class="v">${e(report.complainantInformation)}</td>
<td>${e(report.accusedDetails)}</td>
<td class="v">${e(report.arrestDate)}</td>
<td class="v">${e(report.hearingDate)}</td>
<td class="justify">${e(report.offenceBrief)}</td>
<td>${e(report.witnessDetails)}</td>
<td>${e(report.trialResult)}</td>
<td class="v">${e(report.remarks)}</td>
</tr></table>
<div class="right" style="margin-right:70px;margin-top:5px">${t('পেশ করা হলো','Submitted')}<br/><br/>${e(report.submittedBy.isEmpty ? '${officer.rank} ${officer.name}' : report.submittedBy)}<br/>${e(report.policeStation)}, ${e(report.district)}</div>
</body></html>''';
    return _docBytes(html);
  }
}

extension FinalCaseDocumentDocExport on DocExportService {
  Future<Uint8List> buildFinalCdDoc({required OfficerProfile officer, required CaseFile caseFile, required FinalCdDraft draft}) async {
    final html = '''
<div class="small">West Bengal Form No. 5363 <span style="float:right">B.P. Form No. 38</span></div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div><div class="center small">(Regulation 264)</div>
<p class="small">Police Station: ${_e(officer.policeStation)} &nbsp; District: ${_e(officer.district)}<br/>First Information No. ${_e(caseFile.psCaseNo)} dated ${_e(caseFile.caseDate)} U/S ${_e(caseFile.sections)}<br/>Name of Complainant: ${_e(caseFile.complainantName)}<br/><b>Case Diary: FINAL</b></p>
<table class="cd"><tr><th style="width:10%">No. and hour of entry</th><th style="width:10%">Place of entry</th><th style="width:13%">Synopsis of entry</th><th style="width:67%">Particulars of enquiry</th></tr>
<tr><td>I<br/>${_e(draft.entryTime)}</td><td>${_e(draft.entryPlace)}</td><td>${_e(draft.synopsis)}</td><td class="justify">${_e(draft.narrative)}<br/><br/><b>Status of accused:</b> ${_e(draft.accusedStatus)}<br/><br/><b>Witnesses:</b> ${_e(draft.witnessList)}<div class="right" style="margin-top:28px">Submitted<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}, ${_e(officer.policeStation)}</div></td></tr></table>''';
    return _docBytes(_page('Final CD', html));
  }

  Future<Uint8List> buildChargeSheetDoc({required OfficerProfile officer, required CaseFile caseFile, required ChargeSheetDraft draft}) async {
    String row(String n,String l,String v)=>'<tr><td style="width:6%">$n</td><td style="width:32%"><b>${_e(l)}</b></td><td>${_e(v)}</td></tr>';
    final html='''<div class="center bold">POLICE REPORT / CHARGE SHEET</div><div class="center small">(Under Section 193 BNSS)</div><br/><table>${row('1','In the Court of',draft.courtName)}${row('2','District / Police Station / Case','${officer.district} / ${officer.policeStation} / ${caseFile.psCaseNo} dated ${caseFile.caseDate}')}${row('3','Charge Sheet No. and Date','${draft.chargeSheetNo} ${draft.chargeSheetDate}')}${row('4','Acts and Sections',draft.sections)}${row('5','Complainant / Informant',caseFile.complainantName)}${row('6','Particulars and status of accused',draft.accusedParticulars)}${row('7','Relied documents / property',draft.reliedDocuments)}${row('8','Witnesses to be examined',draft.witnessList)}</table><p><b>Brief facts of the case</b></p><p class="justify">${_e(draft.briefFacts)}</p><div class="right" style="margin-top:38px">Signature of Investigating Officer<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}, ${_e(officer.policeStation)}</div>''';
    return _docBytes(_page('Charge Sheet',html));
  }

  Future<Uint8List> buildIf5Doc({required OfficerProfile officer, required CaseFile caseFile, required If5Draft draft}) async {
    String item(String n,String l,String v)=>'<p><b>$n. ${_e(l)}:</b> ${_e(v)}</p>';
    final html='''<div class="small">P.R.B. 1943. VOL.-II</div><div class="center bold">W.B.P. FORM NO. 39 - FINAL FORM / FINAL REPORT</div><div class="center small">(Under Section 193 BNSS)</div>
${item('1','IN THE COURT OF',draft.courtName)}${item('2','District, Police Station, FIR No. and Date','${officer.district}; ${officer.policeStation}; ${caseFile.psCaseNo}; ${caseFile.caseDate}')}${item('3','Charge-Sheet / Final Report No. and Date','${draft.chargeSheetNo} ${draft.chargeSheetDate}')}${item('4','Acts and Sections',caseFile.sections)}${item('5','Type of Final Report',draft.finalReportType)}${item('6','If F.R. unoccurred / false / mistake / non-cognizable / civil nature','')}${item('7','Supplementary or Original',draft.originalOrSupplementary)}${item('8','Name, rank and number of I.O.',draft.investigatingOfficer.isEmpty?'${officer.name}, ${officer.rank}, ${officer.policeStation}':draft.investigatingOfficer)}${item('9','Complainant / Informant',draft.complainant)}${item('10','Communication of result',draft.resultCommunication)}${item('11','Properties / Articles / Documents',draft.propertyDocuments)}${item('11A','Accused persons charge-sheeted',draft.accusedParticulars)}${item('11B','Accused persons not charge-sheeted',draft.unchargedAccused)}${item('12','Particulars of accused persons charge-sheeted',draft.accusedParticulars)}${item('13','Particulars of accused persons not charge-sheeted',draft.unchargedAccused)}${item('14','Witnesses to be examined',draft.witnessList)}${item('15','Action in false case',draft.falseCaseAction)}${item('16','Result of Laboratory Analysis',draft.laboratoryResult)}<p><b>17. Brief facts of the case:</b></p><p class="justify">${_e(draft.briefFacts)}</p>${item('Dispatch','Despatched at / date / time',draft.dispatchDetails)}<table class="no-border" style="margin-top:36px"><tr><td>Officer-in-Charge<br/><br/>${_e(officer.policeStation)}</td><td class="right">Signature of Investigating Officer<br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}</td></tr></table>''';
    return _docBytes(_page('IF-5',html));
  }

}
