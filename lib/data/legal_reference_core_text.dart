import '../models/legal_reference.dart';

const _bnsSource =
    'https://www.mha.gov.in/sites/default/files/2024-04/250883_english_01042024.pdf';
const _bnssSource =
    'https://www.mha.gov.in/sites/default/files/2024-04/250884_2_english_01042024.pdf';
const _mhaLabel = 'Ministry of Home Affairs — Gazette Act text';

const verifiedLegalTexts = <VerifiedLegalText>[
  VerifiedLegalText(
    code: LegalCode.bns,
    section: '125',
    titleEn: 'Act endangering life or personal safety of others',
    officialTextEn: 'Whoever does any act so rashly or negligently as to endanger human life or the personal safety of others is punishable under section 125. Clause (a) applies where hurt is caused; clause (b) applies where grievous hurt is caused. Under clause (b), imprisonment may extend to three years, or fine may extend to ten thousand rupees, or both.',
    bengaliGuide: 'সহজ ব্যাখ্যা: বেপরোয়া বা অবহেলাজনিত কাজে অন্যের জীবন বা ব্যক্তিগত নিরাপত্তা বিপন্ন হলে ধারা 125 প্রযোজ্য হতে পারে। Hurt হলে 125(a), আর grievous hurt হলে 125(b)-এর শাস্তির অংশ প্রাসঙ্গিক। এটি সহায়ক ব্যাখ্যা; প্রয়োগের আগে মূল আইন ও মামলার facts মিলিয়ে দেখতে হবে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnsSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bns,
    section: '125(b)',
    titleEn: 'Where grievous hurt is caused',
    officialTextEn: 'Where grievous hurt is caused by the rash or negligent act referred to in section 125, punishment may extend to three years, or fine may extend to ten thousand rupees, or both.',
    bengaliGuide: 'সহজ ব্যাখ্যা: ধারা 125-এর rash/negligent act-এর ফলে grievous hurt হলে 125(b) প্রাসঙ্গিক। সর্বোচ্চ তিন বছর কারাদণ্ড, অথবা দশ হাজার টাকা পর্যন্ত জরিমানা, অথবা উভয় হতে পারে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnsSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bns,
    section: '281',
    titleEn: 'Rash driving or riding on a public way',
    officialTextEn: 'Whoever drives any vehicle, or rides, on any public way in a manner so rash or negligent as to endanger human life, or to be likely to cause hurt or injury to any other person, shall be punished with imprisonment of either description for a term which may extend to six months, or with fine which may extend to one thousand rupees, or with both.',
    bengaliGuide: 'সহজ ব্যাখ্যা: public way-এ এমন rash বা negligent driving/riding যার ফলে মানুষের জীবন বিপন্ন হয় বা অন্যের hurt/injury হওয়ার সম্ভাবনা তৈরি হয়, তা BNS 281-এর মধ্যে পড়ে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnsSource,
    isFullSectionText: true,
  ),
  VerifiedLegalText(
    code: LegalCode.bns,
    section: '324(4)',
    titleEn: 'Mischief causing damage of ₹20,000 or more but less than ₹1 lakh',
    officialTextEn: 'Whoever commits mischief and thereby causes loss or damage to the amount of twenty thousand rupees and more but less than one lakh rupees shall be punished with imprisonment of either description for a term which may extend to two years, or with fine, or with both.',
    bengaliGuide: 'সহজ ব্যাখ্যা: mischief-এর ফলে ক্ষতি ₹20,000 বা তার বেশি কিন্তু ₹1,00,000-এর কম হলে BNS 324(4)-এর শাস্তির বিধান প্রাসঙ্গিক।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnsSource,
    isFullSectionText: true,
  ),
  VerifiedLegalText(
    code: LegalCode.bnss,
    section: '179',
    titleEn: "Police officer's power to require attendance of witnesses",
    officialTextEn: 'During investigation, a police officer may by written order require attendance of a person within the limits of his own or an adjoining station who appears acquainted with the facts and circumstances. A male under fifteen or above sixty, a woman, a mentally or physically disabled person, or a person with acute illness shall not be required to attend anywhere other than the place where that person resides; if willing, such person may be permitted to attend the police station.',
    bengaliGuide: 'সহজ ব্যাখ্যা: তদন্তের প্রয়োজনে পরিচিত facts জানা ব্যক্তিকে লিখিতভাবে হাজির হতে বলা যায়। তবে ১৫ বছরের কম বা ৬০ বছরের বেশি পুরুষ, নারী, মানসিক/শারীরিকভাবে প্রতিবন্ধী ব্যক্তি বা acute illness থাকা ব্যক্তিকে সাধারণভাবে তার বাসস্থান ছাড়া অন্য জায়গায় হাজির হতে বাধ্য করা যাবে না; স্বেচ্ছায় থানায় এলে অনুমতি দেওয়া যায়।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnssSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bnss,
    section: '180',
    titleEn: 'Examination of witnesses by police',
    officialTextEn: 'A police officer making an investigation, or another police officer of the prescribed rank acting on requisition, may orally examine a person supposed to be acquainted with the facts and circumstances of the case. The person must answer truly, except answers tending to expose that person to a criminal charge, penalty or forfeiture. If reduced to writing, a separate and true record shall be made of each person whose statement is recorded; the statement may also be recorded by audio-video electronic means.',
    bengaliGuide: 'সহজ ব্যাখ্যা: তদন্তকারী পুলিশ সাক্ষী/তথ্য-জানা ব্যক্তিকে orally examine করতে পারে। লিখিত করলে প্রত্যেক ব্যক্তির আলাদা ও সত্য record করতে হবে। Audio-video electronic means-এও statement record করা যায়।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnssSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bnss,
    section: '181',
    titleEn: 'Statements to police and use thereof',
    officialTextEn: 'A statement made to police during investigation, if reduced to writing, shall not be signed by the person making it. Its use at inquiry or trial is restricted as provided by section 181, including use of duly proved parts for contradiction subject to the statutory conditions.',
    bengaliGuide: 'সহজ ব্যাখ্যা: investigation-এর সময় police-এর কাছে দেওয়া লিখিত statement-এ statement maker-এর signature নেওয়া যাবে না। Trial/inquiry-তে এর ব্যবহারও section 181-এর সীমাবদ্ধতার মধ্যে হবে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnssSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bnss,
    section: '192',
    titleEn: 'Diary of proceedings in investigation',
    officialTextEn: 'Every police officer making an investigation shall day by day enter proceedings in the investigation diary, including the time information reached him, the time investigation began and closed, places visited, and circumstances ascertained. Statements of witnesses recorded under section 180 shall be inserted in the case diary. The diary shall be a volume and duly paginated.',
    bengaliGuide: 'সহজ ব্যাখ্যা: Case Diary day-to-day হতে হবে এবং information পাওয়ার সময়, investigation শুরু/শেষের সময়, visit করা স্থান এবং তদন্তে জানা circumstances উল্লেখ করতে হবে। Section 180-এর witness statements CD-র সঙ্গে যুক্ত থাকবে এবং diary paginated volume হবে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnssSource,
  ),
  VerifiedLegalText(
    code: LegalCode.bnss,
    section: '193',
    titleEn: 'Report of police officer on completion of investigation',
    officialTextEn: 'Investigation shall be completed without unnecessary delay. For specified BNS sexual offences and specified POCSO offences, investigation shall be completed within two months from recording of information. On completion, the police report is forwarded to the competent Magistrate and contains the statutory particulars, including, where applicable, sequence of custody of electronic devices. The police officer shall within ninety days inform the progress of investigation to the informant or victim by any means including electronic communication.',
    bengaliGuide: 'সহজ ব্যাখ্যা: investigation অযথা দেরি না করে শেষ করতে হবে। নির্দিষ্ট sexual/POCSO offences-এ দুই মাসের timeline আছে। Final police report-এ নির্ধারিত particulars থাকবে; electronic device থাকলে sequence of custody-ও প্রাসঙ্গিক। Informant/victim-কে ৯০ দিনের মধ্যে investigation progress জানাতে হবে।',
    sourceLabel: _mhaLabel,
    sourceUrl: _bnssSource,
  ),
];
