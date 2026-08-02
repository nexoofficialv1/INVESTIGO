import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/form_notice.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/services/doc_export_service.dart';

void main() {
  const officer = OfficerProfile(
    name: 'Demo Officer',
    rank: 'SI of Police',
    beltNo: '123',
    policeStation: 'Demo Police Station',
    district: 'Demo District',
    courtName: 'Ld. CJM Court',
    mobile: '9000000000',
    cugMobile: '9000000001',
    whatsApp: '9000000000',
    email: 'demo@example.com',
    psAddress: 'Demo Address',
    pinCode: '700000',
    defaultHospital: 'Demo Hospital',
    defaultMorgue: 'Demo Morgue',
    defaultFslOffice: 'Regional Forensic Science Laboratory',
    defaultSdpoOffice: 'SDPO Office',
  );

  final caseFile = CaseFile.empty(ioName: officer.name).copyWith(
    psCaseNo: '1/2026',
    caseDate: '2026-08-02',
    sections: '103 BNS',
    complainantName: 'Complainant',
    accusedName: 'Accused',
    firGist: 'Brief nature of crime.',
  );

  test('FSL DOC contains official packet sections and profile data', () async {
    final form = FormNotice.create(
      caseId: caseFile.id,
      templateId: 'fsl',
      title: 'FSL Form + Challan + Label Package',
      body: '''FSL PACKAGE STRUCTURED ENTRY

NATURE OF CRIME: Brief nature of crime.
EXHIBITS: A | Sealed jar | Seized at PS | Ld. Court | Return after examination
NATURE OF EXAMINATION: Whether poison could be detected.
PERSONS IN CUSTODY: Accused | Labour | 30 | Male | 2026-08-02 | J/C | Ld. Court
FSL OFFICE: Regional Forensic Science Laboratory
COURT: Ld. CJM Court
''',
    );
    final bytes = await DocExportService().buildFormNoticeDoc(
      officer: officer,
      caseFile: caseFile,
      form: form,
    );
    final text = utf8.decode(bytes);
    expect(text, contains('West Bengal Form No- 5203'));
    expect(text, contains('EXHIBIT CHALLAN'));
    expect(text, contains('LABEL'));
    expect(text, contains('Demo Police Station'));
  });

  test('A Form DOC contains docket index and profile data', () async {
    final form = FormNotice.create(
      caseId: caseFile.id,
      templateId: 'a_form',
      title: 'A Form — Charge Sheet Docket Index',
      body: '''A FORM STRUCTURED ENTRY

COURT NAME: Ld. CJM Court
THROUGH: Bench Clerk
TOTAL DOCKET PAGES: 25
CHARGE SHEET NO: 10/2026
DOCUMENT INDEX:
1 | F.I.R. | 1-3
2 | Sketch Map | 4
''',
    );
    final bytes = await DocExportService().buildFormNoticeDoc(
      officer: officer,
      caseFile: caseFile,
      form: form,
    );
    final text = utf8.decode(bytes);
    expect(text, contains('A FORM'));
    expect(text, contains('10/2026'));
    expect(text, contains('Sketch Map'));
    expect(text, contains('Demo Police Station'));
  });
}
