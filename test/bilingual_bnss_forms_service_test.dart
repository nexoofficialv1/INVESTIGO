import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/bilingual_bnss_form.dart';
import 'package:investigo/models/case_file.dart';
import 'package:investigo/models/officer_profile.dart';
import 'package:investigo/services/bilingual_bnss_forms_service.dart';

CaseFile _case() => CaseFile.empty(ioName: 'SI Test').copyWith(
      psCaseNo: '605/2026',
      caseDate: '2026-07-25',
      sections: '281/125(b)/324(4) BNS',
      complainantName: 'Subhankar Biswas',
      accusedName: 'Driver of WB16BM/6158',
      firGist: 'Road traffic accident on STKK Road.',
    );

OfficerProfile _profile() => OfficerProfile.empty().copyWith(
      name: 'Partha Sarathi Chowdhury',
      rank: 'SI',
      policeStation: 'Kalna PS',
      district: 'Purba Bardhaman',
      mobile: '8942811798',
      defaultFslOffice: 'Regional Forensic Science Laboratory',
    );

void main() {
  final service = BilingualBnssFormsService();

  test('v205 exposes core bilingual BNSS form library', () {
    final ids = BilingualBnssFormsService.templates.map((e) => e.id).toSet();
    expect(ids, containsAll(<String>{
      'bnss_35_3_appearance',
      'bnss_35_arrest_memo',
      'bnss_94_production',
      'bnss_179_witness_attendance',
      'bnss_49_personal_search',
      'medical_examination_reference',
      'fsl_forwarding_reference',
      'bnss_193_3_ii_progress',
    }));
  });

  test('English and Bengali variants preserve the same case identity', () {
    final en = service.generate(
      templateId: 'bnss_94_production',
      language: BnssFormLanguage.english,
      officer: _profile(),
      caseFile: _case(),
    );
    final bn = service.generate(
      templateId: 'bnss_94_production',
      language: BnssFormLanguage.bengali,
      officer: _profile(),
      caseFile: _case(),
    );
    expect(en, contains('605/2026'));
    expect(en, contains('281/125(b)/324(4) BNS'));
    expect(bn, contains('605/2026'));
    expect(bn, contains('281/125(b)/324(4) BNS'));
    expect(bn, contains('ধারা 94'));
  });

  test('medical reference does not invent a BNSS section', () {
    final template = BilingualBnssFormsService.templates
        .firstWhere((e) => e.id == 'medical_examination_reference');
    expect(template.sectionRef, isEmpty);
    final en = service.generate(
      templateId: template.id,
      language: BnssFormLanguage.english,
      officer: _profile(),
      caseFile: _case(),
    );
    expect(en, isNot(contains('U/S 51 BNSS')));
    expect(en, isNot(contains('U/S 52 BNSS')));
    expect(en, isNot(contains('U/S 53 BNSS')));
  });

  test('arrest memo preserves source row 5 as unlabeled instead of guessing', () {
    final en = service.generate(
      templateId: 'bnss_35_arrest_memo',
      language: BnssFormLanguage.english,
      officer: _profile(),
      caseFile: _case(),
    );
    expect(en, contains('Row 5 is unlabeled in the supplied reference form'));
  });

  test('CD auto-link paragraph is specific to form action', () {
    expect(
      service.cdParagraphFor('bnss_179_witness_attendance__bn'),
      contains('u/s 179 BNSS'),
    );
    expect(
      service.cdParagraphFor('bnss_193_3_ii_progress__en'),
      contains('progress of investigation'),
    );
  });
}
