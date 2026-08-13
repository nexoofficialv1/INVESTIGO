import '../models/bilingual_bnss_form.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';

class BilingualBnssFormsService {
  static const String templateVersion = 'bnss-bilingual-forms-v1';

  static const List<BilingualBnssFormTemplate> templates = [
    BilingualBnssFormTemplate(
      id: 'bnss_35_3_appearance',
      titleEn: 'Notice for Appearance before Police — Sec. 35(3) BNSS',
      titleBn: 'পুলিশের নিকট উপস্থিতির নোটিশ — ধারা 35(3) BNSS',
      categoryEn: 'Notice',
      categoryBn: 'নোটিশ',
      sectionRef: '35',
      oldLawRef: 'CrPC 41A',
      sourcePage: 'Reference forms pp. 2–3',
      sourceNote: 'Field structure adapted from the supplied BNSS forms reference. Statutory section reference is verified separately against enacted BNSS.',
    ),
    BilingualBnssFormTemplate(
      id: 'bnss_35_arrest_memo',
      titleEn: 'Arrest Memorandum — BNSS',
      titleBn: 'গ্রেপ্তারি স্মারক — BNSS',
      categoryEn: 'Arrest',
      categoryBn: 'গ্রেপ্তার',
      sectionRef: '35',
      oldLawRef: 'CrPC 41',
      sourcePage: 'Reference forms pp. 4–5',
      sourceNote: 'The supplied reference labels this form as an arrest memorandum under section 35. The unlabeled row no. 5 in the source is preserved as an unlabeled field.',
    ),
    BilingualBnssFormTemplate(
      id: 'bnss_94_production',
      titleEn: 'Notice / Written Order to Produce Document or Thing — Sec. 94 BNSS',
      titleBn: 'দলিল/বস্তু পেশের নোটিশ / লিখিত আদেশ — ধারা 94 BNSS',
      categoryEn: 'Production of documents',
      categoryBn: 'দলিল/বস্তু পেশ',
      sectionRef: '94',
      oldLawRef: 'CrPC 91',
      sourcePage: 'Reference form p. 7',
      sourceNote: 'The source form provides three item lines and date/time/place fields for production.',
    ),
    BilingualBnssFormTemplate(
      id: 'bnss_179_witness_attendance',
      titleEn: 'Notice to Witness for Attendance — Sec. 179 BNSS',
      titleBn: 'সাক্ষীকে উপস্থিতির নোটিশ — ধারা 179 BNSS',
      categoryEn: 'Witness',
      categoryBn: 'সাক্ষী',
      sectionRef: '179',
      oldLawRef: 'CrPC 160',
      sourcePage: 'Reference form p. 9',
      sourceNote: 'Includes the protected-person attendance note reflected in the supplied form; officer must verify applicability before service.',
    ),
    BilingualBnssFormTemplate(
      id: 'bnss_49_personal_search',
      titleEn: 'Personal Search Memorandum — Sec. 49 BNSS',
      titleBn: 'ব্যক্তিগত তল্লাশি স্মারক — ধারা 49 BNSS',
      categoryEn: 'Search',
      categoryBn: 'তল্লাশি',
      sectionRef: '49',
      oldLawRef: 'CrPC 51',
      sourcePage: 'Reference form index p. 1',
      sourceNote: 'Section linkage follows the supplied form index; the detailed field layout is rendered as a practical police memorandum.',
    ),
    BilingualBnssFormTemplate(
      id: 'medical_examination_reference',
      titleEn: 'Medical Examination Requisition',
      titleBn: 'চিকিৎসা পরীক্ষার অনুরোধপত্র',
      categoryEn: 'Medical',
      categoryBn: 'চিকিৎসা',
      sectionRef: '',
      sourcePage: 'Reference form p. 13',
      sourceNote: 'The supplied form itself does not state a BNSS section number; INVESTIGO therefore does not insert one automatically.',
    ),
    BilingualBnssFormTemplate(
      id: 'fsl_forwarding_reference',
      titleEn: 'FSL Forwarding Letter / Examination Requisition',
      titleBn: 'FSL-এ প্রেরণের অগ্রসারণপত্র / পরীক্ষার অনুরোধ',
      categoryEn: 'Forensic',
      categoryBn: 'ফরেনসিক',
      sectionRef: '',
      sourcePage: 'Reference forms pp. 18–19',
      sourceNote: 'Uses the supplied fields for nature of offence, brief facts, exhibit list, source/marking/page count and examination points. Existing WB Form 5203 package remains available separately.',
    ),
    BilingualBnssFormTemplate(
      id: 'bnss_193_3_ii_progress',
      titleEn: 'Investigation Progress Intimation — Sec. 193(3)(ii) BNSS',
      titleBn: 'তদন্তের অগ্রগতি জানানো — ধারা 193(3)(ii) BNSS',
      categoryEn: 'Victim / Informant communication',
      categoryBn: 'ভিকটিম / তথ্যদাতা যোগাযোগ',
      sectionRef: '193',
      sourcePage: 'Reference form p. 21',
      sourceNote: 'Based on the supplied progress-intimation form; actual progress entries must be entered by the investigating officer.',
    ),
  ];

  BilingualBnssFormTemplate templateById(String storageOrBaseId) {
    final base = storageOrBaseId.split('__').first;
    return templates.firstWhere(
      (e) => e.id == base,
      orElse: () => templates.first,
    );
  }

  String titleFor(BilingualBnssFormTemplate template, BnssFormLanguage language) =>
      template.title(language);

  String generate({
    required String templateId,
    required BnssFormLanguage language,
    required OfficerProfile officer,
    required CaseFile caseFile,
  }) {
    switch (templateId) {
      case 'bnss_35_3_appearance':
        return language == BnssFormLanguage.bengali
            ? _appearance35Bn(officer, caseFile)
            : _appearance35En(officer, caseFile);
      case 'bnss_35_arrest_memo':
        return language == BnssFormLanguage.bengali
            ? _arrestMemoBn(officer, caseFile)
            : _arrestMemoEn(officer, caseFile);
      case 'bnss_94_production':
        return language == BnssFormLanguage.bengali
            ? _notice94Bn(officer, caseFile)
            : _notice94En(officer, caseFile);
      case 'bnss_179_witness_attendance':
        return language == BnssFormLanguage.bengali
            ? _witness179Bn(officer, caseFile)
            : _witness179En(officer, caseFile);
      case 'bnss_49_personal_search':
        return language == BnssFormLanguage.bengali
            ? _personalSearch49Bn(officer, caseFile)
            : _personalSearch49En(officer, caseFile);
      case 'medical_examination_reference':
        return language == BnssFormLanguage.bengali
            ? _medicalBn(officer, caseFile)
            : _medicalEn(officer, caseFile);
      case 'fsl_forwarding_reference':
        return language == BnssFormLanguage.bengali
            ? _fslBn(officer, caseFile)
            : _fslEn(officer, caseFile);
      case 'bnss_193_3_ii_progress':
        return language == BnssFormLanguage.bengali
            ? _progress193Bn(officer, caseFile)
            : _progress193En(officer, caseFile);
      default:
        throw ArgumentError('Unsupported bilingual BNSS form: $templateId');
    }
  }

  String cdParagraphFor(String storageTemplateId) {
    final base = storageTemplateId.split('__').first;
    switch (base) {
      case 'bnss_35_3_appearance':
        return 'Prepared/served notice for appearance u/s 35(3) BNSS upon the concerned person in connection with this case.';
      case 'bnss_35_arrest_memo':
        return 'Prepared arrest memorandum and recorded the arrest particulars/formalities in connection with this case.';
      case 'bnss_94_production':
        return 'Issued written notice/order u/s 94 BNSS for production of relevant document/material in connection with this case.';
      case 'bnss_179_witness_attendance':
        return 'Issued notice u/s 179 BNSS requiring attendance of the concerned witness for investigation of this case.';
      case 'bnss_49_personal_search':
        return 'Prepared personal search memorandum u/s 49 BNSS and documented the articles, if any, taken into possession.';
      case 'medical_examination_reference':
        return 'Sent medical examination requisition in connection with this case.';
      case 'fsl_forwarding_reference':
        return 'Prepared FSL forwarding/examination requisition with exhibit particulars in connection with this case.';
      case 'bnss_193_3_ii_progress':
        return 'Communicated progress of investigation to the informant/victim u/s 193(3)(ii) BNSS.';
      default:
        return 'Prepared a statutory/investigation form in connection with this case.';
    }
  }

  String _caseRef(OfficerProfile officer, CaseFile c) =>
      '${officer.policeStation} P.S. Case No. ${c.psCaseNo} dated ${c.caseDate} u/s ${c.sections}';

  String _accused(CaseFile c) => c.accusedName.trim().isEmpty
      ? '____________________________'
      : c.accusedName.trim();

  String _complainant(CaseFile c) => c.complainantName.trim().isEmpty
      ? '____________________________'
      : c.complainantName.trim();

  String _appearance35En(OfficerProfile o, CaseFile c) => '''
NOTICE FOR APPEARANCE BEFORE POLICE
[Section 35(3), Bharatiya Nagarik Suraksha Sanhita, 2023]

CASE NO.: ${c.psCaseNo}
SECTIONS: ${c.sections}
CASE DATE: ${c.caseDate}
POLICE STATION: ${o.policeStation}
DISTRICT: ${o.district}
DIARY / GDE NO.: ____________________________
OFFICER-IN-CHARGE / INVESTIGATING OFFICER: ${o.rank} ${o.name}

TO / NOTICE RECIPIENT: ${_accused(c)}
LAST KNOWN ADDRESS: ________________________________________________
PHONE / E-MAIL (IF ANY): __________________________________________

In connection with investigation of the above-noted case, you are required to appear before the undersigned for questioning / investigation on:
DATE: ____________________    TIME: ____________________
PLACE: ${o.policeStation}, ${o.district} / ____________________________

Directions reflected in the supplied reference form:
(a) Do not commit any offence.
(b) Do not tamper with evidence.
(c) Do not threaten, induce or promise any person acquainted with the facts of the case so as to dissuade disclosure of such facts.
(d) Appear before the Court whenever required/directed.
(e) Join and cooperate with the investigation whenever required.
(f) Disclose facts relevant to the investigation truthfully.
(g) Produce relevant documents/material required for investigation.
(h) Render cooperation/assistance as lawfully required.
(i) Do not destroy any evidence relevant to investigation/trial.
(j) OTHER CASE-SPECIFIC CONDITION, IF LAWFULLY APPLICABLE: ________________________________

Non-compliance may entail action in accordance with law. The officer must verify the current statutory requirements before service.

Police Station: ${o.policeStation}
Name & Rank of Officer: ${o.rank} ${o.name}
Date: ____________________
Seal: ____________________
''';

  String _appearance35Bn(OfficerProfile o, CaseFile c) => '''
পুলিশের নিকট উপস্থিতির নোটিশ
[ভারতীয় নাগরিক সুরক্ষা সংহিতা, 2023-এর ধারা 35(3)]

মামলা নং: ${c.psCaseNo}
আইনের ধারা: ${c.sections}
মামলার তারিখ: ${c.caseDate}
থানা: ${o.policeStation}
জেলা: ${o.district}
ডায়েরি / জিডিই নং: ____________________________
থানা/তদন্তকারী অফিসার: ${o.rank} ${o.name}

প্রাপক / নোটিশপ্রাপ্ত ব্যক্তির নাম: ${_accused(c)}
সর্বশেষ জানা ঠিকানা: ________________________________________________
ফোন / ই-মেল (যদি থাকে): __________________________________________

উপরোক্ত মামলার তদন্তের স্বার্থে জিজ্ঞাসাবাদ / তদন্তের জন্য আপনাকে নিম্নোক্ত তারিখ, সময় ও স্থানে উপস্থিত হতে বলা হচ্ছে:
তারিখ: ____________________    সময়: ____________________
স্থান: ${o.policeStation}, ${o.district} / ____________________________

আপনার দেওয়া রেফারেন্স ফর্মে উল্লিখিত নির্দেশাবলির বাংলা সহায়ক রূপ:
(ক) কোনো অপরাধে লিপ্ত হবেন না।
(খ) মামলার সাক্ষ্য/প্রমাণের সঙ্গে কোনোভাবে হস্তক্ষেপ করবেন না।
(গ) মামলার ঘটনা সম্পর্কে অবগত কোনো ব্যক্তিকে ভয়, প্রলোভন বা প্রতিশ্রুতি দিয়ে তথ্য প্রকাশ থেকে বিরত রাখার চেষ্টা করবেন না।
(ঘ) প্রয়োজন/নির্দেশ অনুযায়ী আদালতে হাজির হবেন।
(ঙ) প্রয়োজন অনুযায়ী তদন্তে যোগ দেবেন এবং সহযোগিতা করবেন।
(চ) তদন্তের প্রাসঙ্গিক তথ্য গোপন না করে সত্যভাবে জানাবেন।
(ছ) তদন্তের জন্য প্রয়োজনীয় প্রাসঙ্গিক নথি/সামগ্রী পেশ করবেন।
(জ) আইনসঙ্গতভাবে প্রয়োজনীয় সহযোগিতা করবেন।
(ঝ) তদন্ত/বিচারের জন্য প্রাসঙ্গিক কোনো প্রমাণ নষ্ট করবেন না।
(ঞ) মামলার তথ্য অনুযায়ী আইনসঙ্গত অন্য শর্ত: ________________________________

নির্দেশ অমান্য করলে আইন অনুযায়ী ব্যবস্থা নেওয়া হতে পারে। নোটিশ জারির আগে অফিসার বর্তমান আইনগত শর্ত যাচাই করবেন।

থানা: ${o.policeStation}
অফিসারের নাম ও পদ: ${o.rank} ${o.name}
তারিখ: ____________________
সিল: ____________________
''';

  String _arrestMemoEn(OfficerProfile o, CaseFile c) => '''
ARREST MEMORANDUM
[Reference form supplied for BNSS arrest particulars]

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
SECTIONS: ${c.sections}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}

1. NAME / ALIAS OF ARRESTED PERSON AND PARENT(S): ${_accused(c)}
2. MOBILE / WHATSAPP / E-MAIL: ______________________________________
3. PRESENT ADDRESS: _________________________________________________
4. PERMANENT ADDRESS: ______________________________________________
5. ________________________________  [Row 5 is unlabeled in the supplied reference form]
6. PLACE OF ARREST: _________________________________________________
7. DATE & TIME OF ARREST: ___________________________________________
8. PERSON INFORMED ABOUT ARREST — NAME / ADDRESS / E-MAIL / PHONE: ________________________________________________________________
9. ARRESTING OFFICER — NAME / RANK / NUMBER: ${o.rank} ${o.name} / __________________
10. REASON(S) FOR ARREST — record only those actually applicable:
    (a) To prevent commission / continuation of the alleged offence: ________________________________
    (b) For proper investigation of the offence: ________________________________
    (c) To prevent disappearance / tampering / destruction of evidence: ________________________________
    (d) To prevent inducement / threat to persons acquainted with facts: ________________________________
    (e) To secure presence before Court where otherwise not likely to be ensured: ________________________________
    OTHER LAWFUL REASON, IF APPLICABLE: ________________________________

SIGNATURE / ACKNOWLEDGEMENT OF ARRESTED PERSON: ______________________
WITNESS 1: ____________________
WITNESS 2: ____________________
WITNESS 3: ____________________

SIGNATURE OF INVESTIGATING / ARRESTING OFFICER: ______________________
NAME & RANK: ${o.rank} ${o.name}
POLICE STATION: ${o.policeStation}
DATE: ____________________
''';

  String _arrestMemoBn(OfficerProfile o, CaseFile c) => '''
গ্রেপ্তারি স্মারক
[আপনার দেওয়া BNSS গ্রেপ্তার-সংক্রান্ত রেফারেন্স ফর্ম অনুসারে]

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
আইনের ধারা: ${c.sections}
থানা: ${o.policeStation}    জেলা: ${o.district}

1. গ্রেপ্তার ব্যক্তির নাম / উপনাম এবং পিতা-মাতা/অভিভাবকের নাম: ${_accused(c)}
2. মোবাইল / WhatsApp / ই-মেল: ______________________________________
3. বর্তমান ঠিকানা: _________________________________________________
4. স্থায়ী ঠিকানা: _________________________________________________
5. ________________________________  [আপনার দেওয়া রেফারেন্স ফর্মে 5 নং ঘরটির শিরোনাম নেই]
6. গ্রেপ্তারের স্থান: ________________________________________________
7. গ্রেপ্তারের তারিখ ও সময়: _________________________________________
8. গ্রেপ্তারের সংবাদ যাকে জানানো হয়েছে — নাম / ঠিকানা / ই-মেল / ফোন: ________________________________________________________________
9. গ্রেপ্তারকারী অফিসার — নাম / পদ / নম্বর: ${o.rank} ${o.name} / __________________
10. গ্রেপ্তারের কারণ — বাস্তবে প্রযোজ্য কারণই লিখবেন:
    (ক) অভিযোগিত অপরাধ সংঘটন/চলমান থাকা প্রতিরোধের জন্য: ________________________________
    (খ) অপরাধের সঠিক তদন্তের জন্য: ________________________________
    (গ) প্রমাণ লোপাট/নষ্ট/স্থানান্তর প্রতিরোধের জন্য: ________________________________
    (ঘ) ঘটনার তথ্য জানা ব্যক্তিকে প্রলোভন/ভয় দেখানো প্রতিরোধের জন্য: ________________________________
    (ঙ) অন্যথায় আদালতে উপস্থিতি নিশ্চিত করা সম্ভব নয় বলে: ________________________________
    অন্য আইনসঙ্গত কারণ (যদি প্রযোজ্য): ________________________________

গ্রেপ্তার ব্যক্তির স্বাক্ষর / প্রাপ্তিস্বীকার: __________________________
সাক্ষী 1: ____________________
সাক্ষী 2: ____________________
সাক্ষী 3: ____________________

তদন্তকারী / গ্রেপ্তারকারী অফিসারের স্বাক্ষর: __________________________
নাম ও পদ: ${o.rank} ${o.name}
থানা: ${o.policeStation}
তারিখ: ____________________
''';

  String _notice94En(OfficerProfile o, CaseFile c) => '''
NOTICE / WRITTEN ORDER U/S 94 BNSS, 2023

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
SECTIONS: ${c.sections}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}
DIARY / GDE NO.: ____________________________

TO:
NAME / OFFICE: ________________________________________________
ADDRESS: ______________________________________________________

The above-noted case was registered on the complaint/information of ${_complainant(c)} and is under investigation. For the purpose of investigation, production of the document(s) / electronic communication / communication device(s) / other thing(s) described below is considered necessary or desirable.

You are therefore required to produce / cause to be produced the following at the time and place stated below:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________

DATE FOR PRODUCTION: ____________________
TIME: ____________________
PLACE: ${o.policeStation} / __________________________________________
MODE, IF ELECTRONIC PRODUCTION IS ACCEPTED: __________________________

Issued by:
${o.rank} ${o.name}
${o.policeStation}, ${o.district}
Date: ____________________
''';

  String _notice94Bn(OfficerProfile o, CaseFile c) => '''
ধারা 94 BNSS, 2023 অনুযায়ী দলিল/বস্তু পেশের নোটিশ / লিখিত আদেশ

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
আইনের ধারা: ${c.sections}
থানা: ${o.policeStation}    জেলা: ${o.district}
ডায়েরি / জিডিই নং: ____________________________

প্রাপক:
নাম / অফিস: _________________________________________________
ঠিকানা: _____________________________________________________

${_complainant(c)}-এর অভিযোগ/তথ্যের ভিত্তিতে উপরোক্ত মামলা রুজু হয়েছে এবং তদন্তাধীন। তদন্তের প্রয়োজনে নিম্নোক্ত দলিল / ইলেকট্রনিক যোগাযোগ / যোগাযোগের ডিভাইস / অন্যান্য বস্তু পেশ করা প্রয়োজন বা কাম্য বলে বিবেচিত হয়েছে।

অতএব নিম্নোক্ত দলিল/বস্তু নির্ধারিত সময় ও স্থানে পেশ করতে / পেশ করাতে বলা হচ্ছে:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________

পেশের তারিখ: ____________________
সময়: ____________________
স্থান: ${o.policeStation} / __________________________________________
ইলেকট্রনিকভাবে পেশ গ্রহণযোগ্য হলে মাধ্যম: _____________________________

জারি করেছেন:
${o.rank} ${o.name}
${o.policeStation}, ${o.district}
তারিখ: ____________________
''';

  String _witness179En(OfficerProfile o, CaseFile c) => '''
NOTICE TO WITNESS FOR ATTENDANCE U/S 179 BNSS

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
SECTIONS: ${c.sections}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}
DIARY / GDE NO.: ____________________________

TO:
WITNESS NAME: ________________________________________________
PARENTAGE: ___________________________________________________
ADDRESS: _____________________________________________________

The above-noted case is under investigation by the undersigned. It appears that you are acquainted with facts and circumstances relevant to the case/investigation. You are therefore required, subject to the statutory provisos and protections applicable to you, to attend before the undersigned for investigation on:

DATE: ____________________    TIME: ____________________
PLACE: ${o.policeStation} / __________________________________________

IMPORTANT OFFICER CHECK BEFORE SERVICE:
The supplied reference form notes protected categories relating to age, women, persons with mental/physical disability and persons with acute illness. Verify the current text of Section 179 BNSS and record why the selected place of attendance is lawful.

Investigating Officer: ${o.rank} ${o.name}
Police Station: ${o.policeStation}
Date: ____________________
''';

  String _witness179Bn(OfficerProfile o, CaseFile c) => '''
ধারা 179 BNSS অনুযায়ী সাক্ষীকে উপস্থিতির নোটিশ

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
আইনের ধারা: ${c.sections}
থানা: ${o.policeStation}    জেলা: ${o.district}
ডায়েরি / জিডিই নং: ____________________________

প্রাপক:
সাক্ষীর নাম: _________________________________________________
পিতা/মাতা/স্বামী/অভিভাবক: ____________________________________
ঠিকানা: ______________________________________________________

উপরোক্ত মামলা নিম্নস্বাক্ষরকারীর দ্বারা তদন্তাধীন। মনে হচ্ছে যে আপনি মামলার/তদন্তের প্রাসঙ্গিক ঘটনা ও পরিস্থিতি সম্পর্কে অবগত। অতএব আপনার ক্ষেত্রে প্রযোজ্য আইনগত proviso ও সুরক্ষা সাপেক্ষে, তদন্তের জন্য নিম্নোক্ত তারিখ, সময় ও স্থানে উপস্থিত হতে বলা হচ্ছে:

তারিখ: ____________________    সময়: ____________________
স্থান: ${o.policeStation} / __________________________________________

নোটিশ জারির আগে অফিসারের বাধ্যতামূলক যাচাই:
আপনার দেওয়া রেফারেন্স ফর্মে বয়স, মহিলা, মানসিক/শারীরিক প্রতিবন্ধী এবং গুরুতর অসুস্থ ব্যক্তিদের ক্ষেত্রে বিশেষ সুরক্ষার উল্লেখ আছে। বর্তমান ধারা 179 BNSS দেখে উপস্থিতির স্থান আইনসঙ্গত কি না যাচাই করে নথিভুক্ত করুন।

তদন্তকারী অফিসার: ${o.rank} ${o.name}
থানা: ${o.policeStation}
তারিখ: ____________________
''';

  String _personalSearch49En(OfficerProfile o, CaseFile c) => '''
PERSONAL SEARCH MEMORANDUM U/S 49 BNSS

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
SECTIONS: ${c.sections}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}

NAME OF ARRESTED / SEARCHED PERSON: ${_accused(c)}
PARENTAGE: ____________________________________________________
AGE: __________    SEX: __________
ADDRESS: ______________________________________________________
DATE & TIME OF SEARCH: ________________________________________
PLACE OF SEARCH: ______________________________________________
SEARCH CONDUCTED BY: ${o.rank} ${o.name}

ARTICLES / PROPERTY / DOCUMENTS TAKEN INTO POSSESSION, IF ANY:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________
4. __________________________________________________________________

RECEIPT / COPY DELIVERED TO THE SEARCHED PERSON: Yes / No / Not applicable
REMARKS: ______________________________________________________

SIGNATURE / ACKNOWLEDGEMENT OF SEARCHED PERSON: _________________
WITNESS 1: ____________________
WITNESS 2: ____________________
SIGNATURE OF OFFICER: ____________________
DATE: ____________________
''';

  String _personalSearch49Bn(OfficerProfile o, CaseFile c) => '''
ধারা 49 BNSS অনুযায়ী ব্যক্তিগত তল্লাশি স্মারক

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
আইনের ধারা: ${c.sections}
থানা: ${o.policeStation}    জেলা: ${o.district}

গ্রেপ্তার / তল্লাশি করা ব্যক্তির নাম: ${_accused(c)}
পিতা/মাতা/স্বামী/অভিভাবক: ______________________________________
বয়স: __________    লিঙ্গ: __________
ঠিকানা: ______________________________________________________
তল্লাশির তারিখ ও সময়: __________________________________________
তল্লাশির স্থান: _________________________________________________
তল্লাশি করেছেন: ${o.rank} ${o.name}

তল্লাশিতে হেফাজতে নেওয়া সামগ্রী / সম্পত্তি / দলিল, যদি থাকে:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________
4. __________________________________________________________________

তল্লাশি করা ব্যক্তিকে রসিদ / কপি দেওয়া হয়েছে: হ্যাঁ / না / প্রযোজ্য নয়
মন্তব্য: _______________________________________________________

তল্লাশি করা ব্যক্তির স্বাক্ষর / প্রাপ্তিস্বীকার: ______________________
সাক্ষী 1: ____________________
সাক্ষী 2: ____________________
অফিসারের স্বাক্ষর: ____________________
তারিখ: ____________________
''';

  String _medicalEn(OfficerProfile o, CaseFile c) => '''
MEDICAL EXAMINATION REQUISITION

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
SECTIONS: ${c.sections}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}

TO,
THE CHIEF MEDICAL OFFICER / MEDICAL OFFICER,
_______________________________________________________________

Sir / Madam,
I am sending the following person for medical examination in connection with the above-noted case:

NAME: _________________________________________________________
S/O / D/O / W/O: ______________________________________________
ADDRESS: ______________________________________________________
AGE: __________
STATUS / ROLE (patient / victim / injured / accused / other): __________________

It is requested that the person be medically examined and that the material/exhibit(s), if any, necessary for investigation be preserved and made available in accordance with law and medical protocol.

SPECIFIC EXAMINATION / QUESTION, IF ANY: _________________________
________________________________________________________________

Investigating Officer: ${o.rank} ${o.name}
Police Station: ${o.policeStation}
Date: ____________________
''';

  String _medicalBn(OfficerProfile o, CaseFile c) => '''
চিকিৎসা পরীক্ষার অনুরোধপত্র

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
আইনের ধারা: ${c.sections}
থানা: ${o.policeStation}    জেলা: ${o.district}

প্রাপক,
প্রধান চিকিৎসা আধিকারিক / মেডিক্যাল অফিসার,
_______________________________________________________________

মহাশয়/মহাশয়া,
উপরোক্ত মামলার প্রেক্ষিতে নিম্নলিখিত ব্যক্তিকে চিকিৎসা পরীক্ষার জন্য প্রেরণ করা হচ্ছে:

নাম: _________________________________________________________
পিতা/মাতা/স্বামী: ______________________________________________
ঠিকানা: ______________________________________________________
বয়স: __________
অবস্থা/ভূমিকা (রোগী / ভিকটিম / আহত / অভিযুক্ত / অন্যান্য): __________________

অনুগ্রহ করে আইন ও চিকিৎসা প্রোটোকল অনুযায়ী উক্ত ব্যক্তির চিকিৎসা পরীক্ষা করে তদন্তের জন্য প্রয়োজনীয় সামগ্রী/প্রদর্শ, যদি থাকে, সংরক্ষণ ও উপলব্ধ করার ব্যবস্থা করবেন।

বিশেষ পরীক্ষা / প্রশ্ন, যদি থাকে: __________________________________
________________________________________________________________

তদন্তকারী অফিসার: ${o.rank} ${o.name}
থানা: ${o.policeStation}
তারিখ: ____________________
''';

  String _fslEn(OfficerProfile o, CaseFile c) => '''
FSL FORWARDING LETTER / EXAMINATION REQUISITION

CASE NO.: ${c.psCaseNo}    CASE DATE: ${c.caseDate}
POLICE STATION: ${o.policeStation}    DISTRICT: ${o.district}
SECTIONS OF LAW: ${c.sections}

NATURE OF OFFENCE / RELEVANT FACTS:
${c.firGist.trim().isEmpty ? '________________________________________________________________' : c.firGist.trim()}

BRIEF CASE HISTORY / RELEVANT DETAILS:
________________________________________________________________
________________________________________________________________

LIST OF EXHIBITS SENT FOR EXAMINATION:
Sl. | Description of Exhibit | Source of Exhibit | Marking No. | No. of Pages / Packets
1   |                        |                   |             |
2   |                        |                   |             |
3   |                        |                   |             |
4   |                        |                   |             |

NATURE OF EXAMINATION REQUIRED / QUESTIONS FOR OPINION:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________

SAMPLE OF SEAL / SEAL DESCRIPTION: ______________________________
FORWARDED TO FSL / RFSL: ${o.defaultFslOffice.trim().isEmpty ? '______________________________' : o.defaultFslOffice}
FORWARDING MEMO NO.: ____________________    DATE: ____________________

Forwarding Officer / I.O.: ${o.rank} ${o.name}
Police Station: ${o.policeStation}
District: ${o.district}
''';

  String _fslBn(OfficerProfile o, CaseFile c) => '''
FSL-এ প্রেরণের অগ্রসারণপত্র / পরীক্ষার অনুরোধ

মামলা নং: ${c.psCaseNo}    মামলার তারিখ: ${c.caseDate}
থানা: ${o.policeStation}    জেলা: ${o.district}
আইনের ধারা: ${c.sections}

অপরাধের প্রকৃতি / প্রাসঙ্গিক তথ্য:
${c.firGist.trim().isEmpty ? '________________________________________________________________' : c.firGist.trim()}

মামলার সংক্ষিপ্ত ইতিহাস / প্রাসঙ্গিক বিবরণ:
________________________________________________________________
________________________________________________________________

পরীক্ষার জন্য প্রেরিত প্রদর্শের তালিকা:
ক্রম | প্রদর্শের বিবরণ | প্রদর্শের উৎস | মার্কিং নং | পৃষ্ঠা / প্যাকেট সংখ্যা
1   |                 |              |            |
2   |                 |              |            |
3   |                 |              |            |
4   |                 |              |            |

প্রয়োজনীয় পরীক্ষার প্রকৃতি / মতামতের জন্য প্রশ্ন:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________

সিলের নমুনা / সিলের বিবরণ: ______________________________________
যে FSL / RFSL-এ পাঠানো হচ্ছে: ${o.defaultFslOffice.trim().isEmpty ? '______________________________' : o.defaultFslOffice}
অগ্রসারণ মেমো নং: ____________________    তারিখ: ____________________

অগ্রসারণকারী অফিসার / I.O.: ${o.rank} ${o.name}
থানা: ${o.policeStation}
জেলা: ${o.district}
''';

  String _progress193En(OfficerProfile o, CaseFile c) => '''
INTIMATION OF PROGRESS OF INVESTIGATION U/S 193(3)(ii) BNSS

CASE REFERENCE: ${_caseRef(o, c)}

TO:
NAME OF INFORMANT / VICTIM: ${_complainant(c)}
ADDRESS / CONTACT: _____________________________________________

You are informed that the following progress has been made in the investigation of the above-noted case:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________
4. __________________________________________________________________

MODE OF COMMUNICATION: In person / Phone / SMS / WhatsApp / E-mail / Other: __________
DATE & TIME OF COMMUNICATION: ___________________________________

For clarification, contact:
Investigating Officer: ${o.rank} ${o.name}
Phone: ${o.mobile}
Police Station: ${o.policeStation}
''';

  String _progress193Bn(OfficerProfile o, CaseFile c) => '''
ধারা 193(3)(ii) BNSS অনুযায়ী তদন্তের অগ্রগতি জানানো

মামলার সূত্র: ${_caseRef(o, c)}

প্রাপক:
তথ্যদাতা / ভিকটিমের নাম: ${_complainant(c)}
ঠিকানা / যোগাযোগ: ______________________________________________

আপনাকে জানানো যাচ্ছে যে উপরোক্ত মামলার তদন্তে নিম্নলিখিত অগ্রগতি হয়েছে:
1. __________________________________________________________________
2. __________________________________________________________________
3. __________________________________________________________________
4. __________________________________________________________________

যোগাযোগের মাধ্যম: সরাসরি / ফোন / SMS / WhatsApp / E-mail / অন্যান্য: __________
যোগাযোগের তারিখ ও সময়: _________________________________________

প্রয়োজনে যোগাযোগ করুন:
তদন্তকারী অফিসার: ${o.rank} ${o.name}
ফোন: ${o.mobile}
থানা: ${o.policeStation}
''';
}
