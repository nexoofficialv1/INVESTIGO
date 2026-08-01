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
import '../core/app_language.dart';

class DocExportService {
  Uint8List _docBytes(String html) => Uint8List.fromList(utf8.encode(html));

  String _e(String value) => const HtmlEscape().convert(value).replaceAll('\n', '<br/>');

  String _page(String title, String body) => '''
<html>
<head>
<meta charset="utf-8">
<title>${_e(title)}</title>
<style>
  @page { size: A4; margin: 18mm 14mm 18mm 14mm; }
  body { font-family: "Times New Roman", serif; font-size: 12pt; color: #000; }
  table { border-collapse: collapse; width: 100%; }
  td, th { border: 1px solid #555; padding: 4px; vertical-align: top; }
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
  <td class="center" style="width:10%">${_e(line.noAndHour)}</td>
  <td class="center" style="width:10%">${_e(line.placeOfEntry)}</td>
  <td class="center" style="width:13%">${_e(line.synopsis)}</td>
  <td class="justify" style="width:67%">${_e(line.proceedings)}</td>
</tr>''',
        )
        .join();
    final year = DateTime.now().year;
    final ps = officer.policeStation.replaceAll('Police Station', 'PS').trim();
    final html = '''
<div class="bold">
  <span>West Bengal form No. 5363</span><span style="float:right">OF $year</span>
</div>
<div class="center bold">CASE DIARY UNDER SECTION 192 BNSS</div>
<div class="center bold">(P.R.B FROM NO. 43 - Vide <i>Rule 229</i>)</div>
<table class="no-border small">
<tr><td class="bold">Police Station: -${_e(ps)}</td><td class="bold right">District: -${_e(officer.district)}</td></tr>
<tr><td class="bold">First information No: -${_e(caseFile.psCaseNo)}</td><td class="bold">Dated: -${_e(caseFile.caseDate)} &nbsp;&nbsp;&nbsp; Section: -${_e(caseFile.sections)}</td></tr>
<tr><td colspan="2" class="bold">Name of Complainant: - ${_e(caseFile.complainantName)}</td></tr>
<tr><td class="bold">Case Diary No: -${cd.cdNumber}</td><td class="bold">Dated: -${_e(cd.cdDate)}</td></tr>
</table>
<table class="cd">
<tr><td class="center">Arrested and sent up</td><td class="center">Arrested and released on bail.</td><td class="center" colspan="2">At large.</td></tr>
<tr><td colspan="3" class="bold">Particulars of Enquiry.</td><td></td></tr>
<tr><td class="center" style="width:10%">No. and<br/>hour of<br/>entry.</td><td class="center" style="width:10%">Place of<br/>entry.</td><td class="center" style="width:13%">Synopsis of<br/>entry.</td><td style="width:67%"></td></tr>
$entryRows
<tr class="signature-row"><td></td><td></td><td></td><td class="right" style="padding-right:70px;padding-top:20px">Submitted<br/><br/><br/>(${_e(officer.name)})<br/>${_e(officer.rank)}<br/>${_e(ps)}</td></tr>
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

  Future<Uint8List> buildFormNoticeDoc({
    required OfficerProfile officer,
    required CaseFile caseFile,
    required FormNotice form,
  }) async {
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
    String e(String v) => const HtmlEscape().convert(v).replaceAll('\n', '<br/>');
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

extension NcrDocExport on DocExportService {
  Future<Uint8List> buildNcrDoc({
    required OfficerProfile officer,
    required NcrReport report,
  }) async {
    final bn = AppLanguageController.instance.isBengali;
    String t(String b, String e) => bn ? b : e;
    String e(String value) => const HtmlEscape().convert(value).replaceAll('\n', '<br/>');
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
