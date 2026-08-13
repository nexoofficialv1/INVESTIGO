import '../models/bilingual_bnss_form.dart';
import '../models/case_file.dart';
import '../models/form_notice.dart';
import '../models/officer_profile.dart';
import '../models/structured_bnss_form.dart';

class StructuredBnssFormsService {
  static const String workflowVersion = 'structured-bnss-forms-v1';

  static const List<String> supportedBaseIds = [
    'bnss_35_3_appearance',
    'bnss_35_arrest_memo',
    'bnss_94_production',
    'bnss_179_witness_attendance',
    'bnss_49_personal_search',
    'medical_examination_reference',
    'fsl_forwarding_reference',
    'bnss_193_3_ii_progress',
  ];

  bool supports(String templateId) => supportedBaseIds.contains(baseId(templateId));

  String baseId(String templateId) => templateId.split('__').first;

  BnssFormLanguage languageOf(String templateId) =>
      templateId.endsWith('__bn') ? BnssFormLanguage.bengali : BnssFormLanguage.english;

  String _today() => DateTime.now().toIso8601String().split('T').first;

  StructuredFormOption _choice(String value, String en, String bn) =>
      StructuredFormOption(value, en, bn);

  StructuredFormFieldSpec _text(
    String key,
    String en,
    String bn, {
    bool required = false,
    int maxLines = 1,
    StructuredFormFieldType type = StructuredFormFieldType.text,
    List<StructuredFormOption> options = const [],
    String helperEn = '',
    String helperBn = '',
  }) =>
      StructuredFormFieldSpec(
        key: key,
        labelEn: en,
        labelBn: bn,
        required: required,
        maxLines: maxLines,
        type: type,
        options: options,
        helperEn: helperEn,
        helperBn: helperBn,
      );

  StructuredFormSchema schemaFor(String templateId) {
    switch (baseId(templateId)) {
      case 'bnss_35_3_appearance':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('diaryNo', 'Diary / GDE No.', 'ডায়েরি / জিডিই নং'),
            _text('recipientName', 'Notice recipient', 'নোটিশ প্রাপক', required: true),
            _text('recipientAddress', 'Last known address', 'সর্বশেষ জানা ঠিকানা', required: true, maxLines: 3),
            _text('recipientContact', 'Phone / e-mail', 'ফোন / ই-মেল'),
            _text('appearanceDate', 'Appearance date', 'উপস্থিতির তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('appearanceTime', 'Appearance time', 'উপস্থিতির সময়', required: true, type: StructuredFormFieldType.time),
            _text('appearancePlace', 'Appearance place', 'উপস্থিতির স্থান', required: true),
            _text(
              'serviceStatus',
              'Service status',
              'সার্ভিস স্ট্যাটাস',
              type: StructuredFormFieldType.choice,
              options: [
                _choice('Draft', 'Draft', 'খসড়া'),
                _choice('Issued', 'Issued', 'ইস্যু করা হয়েছে'),
                _choice('Served', 'Served', 'সার্ভ হয়েছে'),
                _choice('Refused', 'Refused', 'গ্রহণে অস্বীকার'),
                _choice('Returned', 'Returned / not served', 'ফেরত / সার্ভ হয়নি'),
              ],
            ),
            _text('serviceDate', 'Service / issue date', 'সার্ভ / ইস্যুর তারিখ', type: StructuredFormFieldType.date),
            _text('serviceTime', 'Service / issue time', 'সার্ভ / ইস্যুর সময়', type: StructuredFormFieldType.time),
            _text('servedAt', 'Served / issued at', 'সার্ভ / ইস্যুর স্থান'),
            _text('acknowledgedBy', 'Acknowledged / received by', 'গ্রহণ / স্বীকার করেছেন'),
            _text('serviceRemarks', 'Service remarks', 'সার্ভিস সংক্রান্ত মন্তব্য', maxLines: 3),
          ],
        );
      case 'bnss_35_arrest_memo':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('arrestedName', 'Arrested person name / alias / parentage', 'গ্রেপ্তার ব্যক্তির নাম / উপনাম / পিতা-মাতা', required: true, maxLines: 2),
            _text('contact', 'Mobile / WhatsApp / e-mail', 'মোবাইল / WhatsApp / ই-মেল'),
            _text('presentAddress', 'Present address', 'বর্তমান ঠিকানা', required: true, maxLines: 2),
            _text('permanentAddress', 'Permanent address', 'স্থায়ী ঠিকানা', maxLines: 2),
            _text('sourceRow5', 'Source form row 5 (unlabelled)', 'সোর্স ফর্মের ৫ নং ঘর (লেবেল নেই)', maxLines: 2, helperEn: 'The supplied source does not label row 5; INVESTIGO does not guess it.', helperBn: 'প্রদত্ত সোর্সে ৫ নং ঘরের লেবেল নেই; INVESTIGO অনুমান করে না।'),
            _text('arrestPlace', 'Place of arrest', 'গ্রেপ্তারের স্থান', required: true),
            _text('arrestDate', 'Date of arrest', 'গ্রেপ্তারের তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('arrestTime', 'Time of arrest', 'গ্রেপ্তারের সময়', required: true, type: StructuredFormFieldType.time),
            _text('informedPerson', 'Person informed about arrest — name/address/contact', 'গ্রেপ্তার সম্পর্কে যাকে জানানো হয়েছে — নাম/ঠিকানা/যোগাযোগ', required: true, maxLines: 3),
            _text('arrestingOfficer', 'Arresting officer', 'গ্রেপ্তারকারী অফিসার', required: true),
            _text('grounds', 'Grounds / reasons for arrest', 'গ্রেপ্তারের কারণ / গ্রাউন্ডস', required: true, type: StructuredFormFieldType.checklist, options: [
              _choice('preventFurtherOffence', 'To prevent commission of further offence', 'পরবর্তী অপরাধ প্রতিরোধের জন্য'),
              _choice('properInvestigation', 'For proper investigation of the offence', 'অপরাধের সঠিক তদন্তের জন্য'),
              _choice('preventEvidenceTampering', 'To prevent disappearance/tampering of evidence', 'সাক্ষ্য নষ্ট/পরিবর্তন প্রতিরোধের জন্য'),
              _choice('preventThreatInducement', 'To prevent threat/inducement to persons acquainted with facts', 'তথ্য জানা ব্যক্তিকে ভয়/প্রলোভন দেওয়া রোধে'),
              _choice('ensureCourtPresence', 'To ensure presence before Court when required', 'প্রয়োজনমতো আদালতে উপস্থিতি নিশ্চিত করতে'),
            ]),
            _text('otherGround', 'Other case-specific arrest ground', 'অন্যান্য মামলা-নির্দিষ্ট গ্রেপ্তারের কারণ', maxLines: 3),
            _text('accusedAcknowledgement', 'Arrested person acknowledgement / signature status', 'গ্রেপ্তার ব্যক্তির স্বীকৃতি / স্বাক্ষরের অবস্থা', maxLines: 2),
          ],
          rowGroups: [
            StructuredFormRowGroupSpec(
              key: 'arrestWitnesses',
              titleEn: 'Arrest memo witnesses',
              titleBn: 'গ্রেপ্তারি স্মারকের সাক্ষী',
              minRows: 2,
              maxRows: 4,
              columns: [
                StructuredFormRowColumnSpec(key: 'name', labelEn: 'Name', labelBn: 'নাম', required: true),
                StructuredFormRowColumnSpec(key: 'details', labelEn: 'Address / details', labelBn: 'ঠিকানা / বিবরণ', maxLines: 2),
              ],
            ),
          ],
        );
      case 'bnss_94_production':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('diaryNo', 'Diary No.', 'ডায়েরি নং'),
            _text('recipientName', 'Recipient / authority', 'প্রাপক / কর্তৃপক্ষ', required: true),
            _text('recipientAddress', 'Recipient address', 'প্রাপকের ঠিকানা', required: true, maxLines: 3),
            _text('productionDate', 'Production date', 'পেশের তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('productionTime', 'Production time', 'পেশের সময়', required: true, type: StructuredFormFieldType.time),
            _text('productionPlace', 'Production place', 'পেশের স্থান', required: true),
            _text('serviceStatus', 'Notice status', 'নোটিশ স্ট্যাটাস', type: StructuredFormFieldType.choice, options: [
              _choice('Draft', 'Draft', 'খসড়া'), _choice('Issued', 'Issued', 'ইস্যু'), _choice('Served', 'Served', 'সার্ভ'), _choice('Complied', 'Complied', 'অনুপালিত'), _choice('NotComplied', 'Not complied', 'অনুপালিত নয়'),
            ]),
            _text('serviceDate', 'Issue / service date', 'ইস্যু / সার্ভ তারিখ', type: StructuredFormFieldType.date),
            _text('serviceTime', 'Issue / service time', 'ইস্যু / সার্ভ সময়', type: StructuredFormFieldType.time),
            _text('acknowledgement', 'Receipt / acknowledgement details', 'রিসিট / স্বীকৃতির বিবরণ', maxLines: 3),
          ],
          rowGroups: [
            StructuredFormRowGroupSpec(
              key: 'productionItems',
              titleEn: 'Documents / things required',
              titleBn: 'প্রয়োজনীয় দলিল / বস্তু',
              minRows: 3,
              maxRows: 20,
              columns: [
                StructuredFormRowColumnSpec(key: 'description', labelEn: 'Document / thing', labelBn: 'দলিল / বস্তু', required: true, maxLines: 2),
                StructuredFormRowColumnSpec(key: 'remarks', labelEn: 'Remarks', labelBn: 'মন্তব্য', maxLines: 2),
              ],
            ),
          ],
        );
      case 'bnss_179_witness_attendance':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('diaryNo', 'Diary No.', 'ডায়েরি নং'),
            _text('witnessName', 'Witness name', 'সাক্ষীর নাম', required: true),
            _text('parentage', 'Father / mother / spouse', 'পিতা / মাতা / স্বামী/স্ত্রী'),
            _text('witnessAddress', 'Address', 'ঠিকানা', required: true, maxLines: 3),
            _text('attendanceDate', 'Attendance date', 'উপস্থিতির তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('attendanceTime', 'Attendance time', 'উপস্থিতির সময়', required: true, type: StructuredFormFieldType.time),
            _text('attendancePlace', 'Place of attendance', 'উপস্থিতির স্থান', required: true),
            _text('protectedPersonCheck', 'Protected-person attendance safeguard reviewed?', 'বিশেষ সুরক্ষাপ্রাপ্ত ব্যক্তির উপস্থিতি সংক্রান্ত বিধান যাচাই করা হয়েছে?', type: StructuredFormFieldType.yesNo),
            _text('serviceStatus', 'Notice status', 'নোটিশ স্ট্যাটাস', type: StructuredFormFieldType.choice, options: [
              _choice('Draft', 'Draft', 'খসড়া'), _choice('Issued', 'Issued', 'ইস্যু'), _choice('Served', 'Served', 'সার্ভ'), _choice('Refused', 'Refused', 'গ্রহণে অস্বীকার'), _choice('Returned', 'Returned', 'ফেরত'),
            ]),
            _text('serviceDate', 'Issue / service date', 'ইস্যু / সার্ভ তারিখ', type: StructuredFormFieldType.date),
            _text('serviceTime', 'Issue / service time', 'ইস্যু / সার্ভ সময়', type: StructuredFormFieldType.time),
            _text('acknowledgement', 'Acknowledgement / service remarks', 'স্বীকৃতি / সার্ভ মন্তব্য', maxLines: 3),
          ],
        );
      case 'bnss_49_personal_search':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('personName', 'Searched person name', 'তল্লাশিকৃত ব্যক্তির নাম', required: true),
            _text('parentage', 'Parentage', 'পিতৃ/মাতৃ পরিচয়'),
            _text('age', 'Age', 'বয়স'),
            _text('mobile', 'Mobile', 'মোবাইল'),
            _text('idParticulars', 'Identity particulars', 'পরিচয়পত্রের বিবরণ'),
            _text('searchPlace', 'Place of search', 'তল্লাশির স্থান', required: true),
            _text('searchDate', 'Search date', 'তল্লাশির তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('searchTime', 'Search time', 'তল্লাশির সময়', required: true, type: StructuredFormFieldType.time),
            _text('receiptGiven', 'Receipt of articles given?', 'জব্দ/নেওয়া সামগ্রীর রসিদ দেওয়া হয়েছে?', type: StructuredFormFieldType.yesNo),
            _text('personSignatureStatus', 'Person signature / acknowledgement', 'ব্যক্তির স্বাক্ষর / স্বীকৃতি', maxLines: 2),
          ],
          rowGroups: [
            StructuredFormRowGroupSpec(
              key: 'searchArticles',
              titleEn: 'Articles taken into possession',
              titleBn: 'পুলিশের হেফাজতে নেওয়া সামগ্রী',
              minRows: 1,
              maxRows: 20,
              columns: [
                StructuredFormRowColumnSpec(key: 'description', labelEn: 'Article', labelBn: 'সামগ্রী', required: true, maxLines: 2),
                StructuredFormRowColumnSpec(key: 'quantity', labelEn: 'Quantity', labelBn: 'পরিমাণ'),
                StructuredFormRowColumnSpec(key: 'remarks', labelEn: 'Remarks', labelBn: 'মন্তব্য'),
              ],
            ),
            StructuredFormRowGroupSpec(
              key: 'searchWitnesses',
              titleEn: 'Witnesses',
              titleBn: 'সাক্ষী',
              minRows: 2,
              maxRows: 6,
              columns: [
                StructuredFormRowColumnSpec(key: 'name', labelEn: 'Name', labelBn: 'নাম', required: true),
                StructuredFormRowColumnSpec(key: 'details', labelEn: 'Address / details', labelBn: 'ঠিকানা / বিবরণ', maxLines: 2),
              ],
            ),
          ],
        );
      case 'medical_examination_reference':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('hospital', 'Hospital / Medical Officer', 'হাসপাতাল / মেডিক্যাল অফিসার', required: true, maxLines: 2),
            _text('personName', 'Person sent for examination', 'পরীক্ষার জন্য প্রেরিত ব্যক্তির নাম', required: true),
            _text('relationDetails', 'S/O / D/O / W/O and name', 'S/O / D/O / W/O ও নাম'),
            _text('address', 'Address', 'ঠিকানা', maxLines: 3),
            _text('age', 'Age', 'বয়স'),
            _text('examDate', 'Examination / forwarding date', 'পরীক্ষা / প্রেরণের তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('examTime', 'Examination / forwarding time', 'পরীক্ষা / প্রেরণের সময়', type: StructuredFormFieldType.time),
            _text('requestedExamination', 'Examination requested / injuries / samples', 'প্রয়োজনীয় পরীক্ষা / আঘাত / নমুনা', required: true, maxLines: 4),
            _text('preserveExhibits', 'Preserve relevant exhibits/samples if available?', 'প্রাসঙ্গিক আলামত/নমুনা থাকলে সংরক্ষণ করতে হবে?', type: StructuredFormFieldType.yesNo),
            _text('reportStatus', 'Report status', 'রিপোর্ট স্ট্যাটাস', type: StructuredFormFieldType.choice, options: [
              _choice('Requested', 'Requested', 'অনুরোধ করা হয়েছে'), _choice('Examined', 'Examined', 'পরীক্ষা সম্পন্ন'), _choice('ReportReceived', 'Report received', 'রিপোর্ট পাওয়া গেছে'), _choice('Pending', 'Pending', 'অপেক্ষমাণ'),
            ]),
            _text('reportReceiptDate', 'Report received date', 'রিপোর্ট পাওয়ার তারিখ', type: StructuredFormFieldType.date),
            _text('reportReceiptTime', 'Report received time', 'রিপোর্ট পাওয়ার সময়', type: StructuredFormFieldType.time),
            _text('reportRemarks', 'Report / medical remarks', 'রিপোর্ট / চিকিৎসা মন্তব্য', maxLines: 3),
          ],
        );
      case 'fsl_forwarding_reference':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('fslOffice', 'FSL office / forwarding authority', 'FSL অফিস / প্রেরণ কর্তৃপক্ষ', required: true, maxLines: 3),
            _text('natureOfCrime', 'Nature of offence', 'অপরাধের প্রকৃতি', required: true, maxLines: 3),
            _text('briefFacts', 'Brief history / relevant facts', 'সংক্ষিপ্ত ইতিহাস / প্রাসঙ্গিক তথ্য', required: true, maxLines: 6),
            _text('examinationRequired', 'Nature of examination required / points for opinion', 'প্রয়োজনীয় পরীক্ষা / মতামতের প্রশ্ন', required: true, maxLines: 6),
            _text('forwardingDate', 'Forwarding date', 'প্রেরণের তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('forwardingTime', 'Forwarding time', 'প্রেরণের সময়', type: StructuredFormFieldType.time),
            _text('messenger', 'Messenger name / force no. / contact', 'মেসেঞ্জারের নাম / ফোর্স নং / যোগাযোগ', maxLines: 2),
            _text('ackStatus', 'FSL receipt status', 'FSL রিসিট স্ট্যাটাস', type: StructuredFormFieldType.choice, options: [
              _choice('Prepared', 'Prepared', 'প্রস্তুত'), _choice('Dispatched', 'Dispatched', 'প্রেরিত'), _choice('Received', 'Received by FSL', 'FSL গ্রহণ করেছে'), _choice('Returned', 'Returned / objection', 'ফেরত / আপত্তি'),
            ]),
            _text('ackDate', 'Acknowledgement date', 'স্বীকৃতির তারিখ', type: StructuredFormFieldType.date),
            _text('ackTime', 'Acknowledgement time', 'স্বীকৃতির সময়', type: StructuredFormFieldType.time),
            _text('ackNo', 'Acknowledgement / receipt no.', 'স্বীকৃতি / রিসিট নং'),
            _text('sealSample', 'Sample seal / seal description', 'সিলের নমুনা / সিলের বিবরণ', maxLines: 3),
          ],
          rowGroups: [
            StructuredFormRowGroupSpec(
              key: 'fslExhibits',
              titleEn: 'Exhibits sent for examination',
              titleBn: 'পরীক্ষার জন্য প্রেরিত আলামত',
              minRows: 1,
              maxRows: 30,
              columns: [
                StructuredFormRowColumnSpec(key: 'description', labelEn: 'Exhibit description', labelBn: 'আলামতের বিবরণ', required: true, maxLines: 2),
                StructuredFormRowColumnSpec(key: 'source', labelEn: 'Source / how found', labelBn: 'উৎস / কীভাবে পাওয়া', maxLines: 2),
                StructuredFormRowColumnSpec(key: 'mark', labelEn: 'Mark / label', labelBn: 'মার্ক / লেবেল', required: true),
                StructuredFormRowColumnSpec(key: 'pages', labelEn: 'Page(s) / packet count', labelBn: 'পৃষ্ঠা / প্যাকেট সংখ্যা'),
              ],
            ),
          ],
        );
      case 'bnss_193_3_ii_progress':
        return StructuredFormSchema(
          templateId: baseId(templateId),
          fields: [
            _text('recipientName', 'Informant / victim name', 'তথ্যদাতা / ভিকটিমের নাম', required: true),
            _text('recipientAddress', 'Address / contact', 'ঠিকানা / যোগাযোগ', required: true, maxLines: 3),
            _text('communicationDate', 'Communication date', 'যোগাযোগের তারিখ', required: true, type: StructuredFormFieldType.date),
            _text('communicationTime', 'Communication time', 'যোগাযোগের সময়', type: StructuredFormFieldType.time),
            _text('communicationMode', 'Mode', 'মাধ্যম', required: true, type: StructuredFormFieldType.choice, options: [
              _choice('Phone', 'Phone', 'ফোন'), _choice('WhatsApp', 'WhatsApp', 'WhatsApp'), _choice('SMS', 'SMS', 'SMS'), _choice('Email', 'E-mail', 'ই-মেল'), _choice('Written', 'Written notice', 'লিখিত নোটিশ'), _choice('InPerson', 'In person', 'সরাসরি'),
            ]),
            _text('acknowledgement', 'Acknowledgement / delivery status', 'স্বীকৃতি / ডেলিভারি স্ট্যাটাস', maxLines: 3),
          ],
          rowGroups: [
            StructuredFormRowGroupSpec(
              key: 'progressItems',
              titleEn: 'Investigation progress communicated',
              titleBn: 'জানানো তদন্তের অগ্রগতি',
              minRows: 4,
              maxRows: 20,
              columns: [
                StructuredFormRowColumnSpec(key: 'progress', labelEn: 'Progress point', labelBn: 'অগ্রগতির পয়েন্ট', required: true, maxLines: 3),
              ],
            ),
          ],
        );
      default:
        throw ArgumentError('Unsupported structured form: $templateId');
    }
  }

  StructuredBnssFormState initialState({
    required String templateId,
    required OfficerProfile officer,
    required CaseFile caseFile,
    Map<String, dynamic> existing = const {},
  }) {
    if (existing.isNotEmpty && existing['version'] == 'structured-bnss-form-v1') {
      return StructuredBnssFormState.fromJson(existing);
    }
    final values = <String, String>{};
    final checks = <String, List<String>>{};
    final rows = <String, List<Map<String, String>>>{};
    final base = baseId(templateId);

    values.addAll({
      'serviceStatus': 'Draft',
      'serviceDate': _today(),
      'appearanceDate': _today(),
      'productionDate': _today(),
      'attendanceDate': _today(),
      'searchDate': _today(),
      'examDate': _today(),
      'forwardingDate': _today(),
      'communicationDate': _today(),
      'appearancePlace': officer.policeStation,
      'productionPlace': officer.policeStation,
      'attendancePlace': officer.policeStation,
      'arrestingOfficer': '${officer.rank} ${officer.name}',
      'recipientName': caseFile.accusedName,
      'witnessName': caseFile.complainantName,
      'personName': caseFile.accusedName,
      'arrestedName': caseFile.accusedName,
      'fslOffice': officer.defaultFslOffice,
      'natureOfCrime': caseFile.crimeHead.isNotEmpty ? caseFile.crimeHead : caseFile.firGist,
      'briefFacts': caseFile.firGist,
      'recipientAddress': '',
    });

    switch (base) {
      case 'bnss_35_3_appearance':
        values['recipientName'] = caseFile.accusedName;
        break;
      case 'bnss_35_arrest_memo':
        values['arrestedName'] = caseFile.accusedName;
        rows['arrestWitnesses'] = [
          {'name': '', 'details': ''},
          {'name': '', 'details': ''},
        ];
        checks['grounds'] = [];
        break;
      case 'bnss_94_production':
        values['recipientName'] = '';
        rows['productionItems'] = List.generate(3, (_) => {'description': '', 'remarks': ''});
        break;
      case 'bnss_179_witness_attendance':
        values['witnessName'] = caseFile.complainantName;
        break;
      case 'bnss_49_personal_search':
        rows['searchArticles'] = [{'description': '', 'quantity': '', 'remarks': ''}];
        rows['searchWitnesses'] = [
          {'name': '', 'details': ''},
          {'name': '', 'details': ''},
        ];
        break;
      case 'medical_examination_reference':
        values['hospital'] = officer.defaultHospital;
        values['personName'] = caseFile.victimName.isNotEmpty ? caseFile.victimName : caseFile.complainantName;
        values['reportStatus'] = 'Requested';
        break;
      case 'fsl_forwarding_reference':
        values['ackStatus'] = 'Prepared';
        rows['fslExhibits'] = [
          {'description': '', 'source': '', 'mark': 'A', 'pages': ''},
        ];
        break;
      case 'bnss_193_3_ii_progress':
        values['recipientName'] = caseFile.victimName.isNotEmpty ? caseFile.victimName : caseFile.complainantName;
        values['communicationMode'] = 'Phone';
        rows['progressItems'] = List.generate(4, (_) => {'progress': ''});
        break;
    }

    final schema = schemaFor(templateId);
    for (final group in schema.rowGroups) {
      rows.putIfAbsent(
        group.key,
        () => List.generate(group.minRows, (_) => {
          for (final c in group.columns) c.key: '',
        }),
      );
    }
    return StructuredBnssFormState(values: values, checks: checks, rows: rows);
  }

  List<String> validate(String templateId, StructuredBnssFormState state) {
    final schema = schemaFor(templateId);
    final errors = <String>[];
    for (final field in schema.fields) {
      if (!field.required) continue;
      if (field.type == StructuredFormFieldType.checklist) {
        if ((state.checks[field.key] ?? const []).isEmpty) {
          errors.add('${field.labelEn} is required.');
        }
      } else if ((state.values[field.key] ?? '').trim().isEmpty) {
        errors.add('${field.labelEn} is required.');
      }
    }
    for (final group in schema.rowGroups) {
      final groupRows = state.rows[group.key] ?? const [];
      if (groupRows.length < group.minRows) {
        errors.add('${group.titleEn}: minimum ${group.minRows} row(s) required.');
      }
      for (var i = 0; i < groupRows.length; i++) {
        for (final column in group.columns.where((e) => e.required)) {
          if ((groupRows[i][column.key] ?? '').trim().isEmpty) {
            errors.add('${group.titleEn} row ${i + 1}: ${column.labelEn} is required.');
          }
        }
      }
    }
    return errors;
  }

  String renderBody({
    required String templateId,
    required OfficerProfile officer,
    required CaseFile caseFile,
    required StructuredBnssFormState state,
  }) {
    final bn = languageOf(templateId) == BnssFormLanguage.bengali;
    String t(String en, String bnText) => bn ? bnText : en;
    String v(String key, [String blank = '____________________________']) {
      final value = (state.values[key] ?? '').trim();
      return value.isEmpty ? blank : value;
    }
    String yesNo(String key) {
      final value = v(key, '');
      if (value == 'Yes') return t('Yes', 'হ্যাঁ');
      if (value == 'No') return t('No', 'না');
      return '__________';
    }
    String ref() => '${officer.policeStation} P.S. Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}';
    String numberedRows(String key, String column) {
      final rows = state.rows[key] ?? const [];
      return rows.asMap().entries.map((e) {
        final text = (e.value[column] ?? '').trim();
        return '${e.key + 1}. ${text.isEmpty ? '________________________________________' : text}';
      }).join('\n');
    }

    switch (baseId(templateId)) {
      case 'bnss_35_3_appearance':
        return '''${t('NOTICE FOR APPEARANCE BEFORE POLICE', 'পুলিশের নিকট উপস্থিতির নোটিশ')}
[${t('Section 35(3), Bharatiya Nagarik Suraksha Sanhita, 2023', 'ধারা 35(3), ভারতীয় নাগরিক সুরক্ষা সংহিতা, 2023')}]

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('Diary / GDE No.', 'ডায়েরি / জিডিই নং')}: ${v('diaryNo')}
${t('To', 'প্রাপক')}: ${v('recipientName')}
${t('Address', 'ঠিকানা')}: ${v('recipientAddress')}
${t('Phone / E-mail', 'ফোন / ই-মেল')}: ${v('recipientContact')}

${t('You are directed to appear before the undersigned investigating officer for the purpose of investigation on', 'তদন্তের স্বার্থে আপনাকে নিম্নস্বাক্ষরকারী তদন্তকারী অফিসারের নিকট উপস্থিত হতে নির্দেশ দেওয়া হলো')}: ${v('appearanceDate')} ${t('at', 'তারিখে সময়')} ${v('appearanceTime')} ${t('at', 'স্থানে')} ${v('appearancePlace')}.

${t('You are directed to comply with the following conditions reflected in the supplied reference form:', 'প্রদত্ত রেফারেন্স ফর্ম অনুযায়ী নিম্নলিখিত শর্তগুলি মানতে নির্দেশ দেওয়া হলো:')}
(a) ${t('You will not commit any offence in future.', 'আপনি ভবিষ্যতে কোনো অপরাধ করবেন না।')}
(b) ${t('You will not tamper with evidence in any manner.', 'আপনি কোনোভাবেই সাক্ষ্যপ্রমাণ নষ্ট বা পরিবর্তন করবেন না।')}
(c) ${t('You will not threaten, induce or promise any person acquainted with the facts so as to dissuade disclosure to the Court or police.', 'ঘটনার তথ্য জানা কোনো ব্যক্তিকে আদালত বা পুলিশের কাছে তথ্য প্রকাশ থেকে বিরত রাখতে ভয়, প্রলোভন বা প্রতিশ্রুতি দেবেন না।')}
(d) ${t('You will appear before the Court as and when lawfully required/directed.', 'আইনসঙ্গতভাবে প্রয়োজন বা নির্দেশ হলে আদালতে উপস্থিত হবেন।')}
(e) ${t('You will join and cooperate with the investigation as and when required.', 'প্রয়োজনমতো তদন্তে যোগ দেবেন এবং সহযোগিতা করবেন।')}
(f) ${t('You will disclose relevant facts truthfully without concealment.', 'প্রাসঙ্গিক তথ্য সত্যভাবে প্রকাশ করবেন এবং গোপন করবেন না।')}
(g) ${t('You will produce relevant documents/material lawfully required for investigation.', 'তদন্তের জন্য আইনসঙ্গতভাবে চাওয়া প্রাসঙ্গিক দলিল/সামগ্রী পেশ করবেন।')}
(h) ${t('You will render lawful cooperation/assistance regarding involved persons as required.', 'প্রয়োজনমতো জড়িত ব্যক্তিদের বিষয়ে আইনসঙ্গত সহযোগিতা/সহায়তা করবেন।')}
(i) ${t('You will not permit destruction of evidence relevant to investigation/trial.', 'তদন্ত/বিচারের প্রাসঙ্গিক কোনো সাক্ষ্য নষ্ট হতে দেবেন না।')}
(j) ${t('Any other lawful condition recorded by the Investigating Officer / Officer-in-Charge according to case facts.', 'মামলার তথ্য অনুযায়ী তদন্তকারী অফিসার / অফিসার-ইন-চার্জের নথিভুক্ত অন্য কোনো আইনসঙ্গত শর্ত।')}

${t('Reference-form note: failure to comply may have consequences under the applicable BNSS provision. Officer should verify the current enacted text before service.', 'রেফারেন্স-ফর্ম নোট: অনুপালন না করলে প্রযোজ্য BNSS বিধান অনুযায়ী আইনগত ফল হতে পারে। সার্ভিসের আগে অফিসার বর্তমান কার্যকর আইন যাচাই করবেন।')}

${t('Service / Issue Status', 'সার্ভ / ইস্যু স্ট্যাটাস')}: ${v('serviceStatus')}
${t('Date / Time', 'তারিখ / সময়')}: ${v('serviceDate')} ${v('serviceTime', '')}
${t('Place', 'স্থান')}: ${v('servedAt')}
${t('Acknowledged / Received by', 'গ্রহণ / স্বীকার করেছেন')}: ${v('acknowledgedBy')}
${t('Remarks', 'মন্তব্য')}: ${v('serviceRemarks')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'bnss_35_arrest_memo':
        final selected = state.checks['grounds'] ?? const [];
        final optionMap = {
          'preventFurtherOffence': t('To prevent commission of further offence', 'পরবর্তী অপরাধ প্রতিরোধের জন্য'),
          'properInvestigation': t('For proper investigation of the offence', 'অপরাধের সঠিক তদন্তের জন্য'),
          'preventEvidenceTampering': t('To prevent disappearance/tampering of evidence', 'সাক্ষ্য নষ্ট/পরিবর্তন প্রতিরোধের জন্য'),
          'preventThreatInducement': t('To prevent threat/inducement to persons acquainted with facts', 'তথ্য জানা ব্যক্তিকে ভয়/প্রলোভন দেওয়া রোধে'),
          'ensureCourtPresence': t('To ensure presence before Court when required', 'প্রয়োজনমতো আদালতে উপস্থিতি নিশ্চিত করতে'),
        };
        final grounds = selected.isEmpty
            ? '1. ______________________________'
            : selected.asMap().entries.map((e) => '${e.key + 1}. ${optionMap[e.value] ?? e.value}').join('\n');
        final witnesses = (state.rows['arrestWitnesses'] ?? const []).asMap().entries.map((e) {
          final name = (e.value['name'] ?? '').trim();
          final details = (e.value['details'] ?? '').trim();
          return '${e.key + 1}. ${name.isEmpty ? '________________' : name}${details.isEmpty ? '' : ' — $details'}';
        }).join('\n');
        return '''${t('ARREST MEMORANDUM', 'গ্রেপ্তারি স্মারক')}
[${t('As per the supplied reference form under Section 35 BNSS', 'প্রদত্ত রেফারেন্স ফর্ম অনুযায়ী ধারা 35 BNSS')}]

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
1. ${t('Arrested person', 'গ্রেপ্তার ব্যক্তি')}: ${v('arrestedName')}
2. ${t('Mobile / WhatsApp / E-mail', 'মোবাইল / WhatsApp / ই-মেল')}: ${v('contact')}
3. ${t('Present address', 'বর্তমান ঠিকানা')}: ${v('presentAddress')}
4. ${t('Permanent address', 'স্থায়ী ঠিকানা')}: ${v('permanentAddress')}
5. ${t('Source form row 5 (unlabelled)', 'সোর্স ফর্মের ৫ নং ঘর (লেবেল নেই)')}: ${v('sourceRow5')}
6. ${t('Place of arrest', 'গ্রেপ্তারের স্থান')}: ${v('arrestPlace')}
7. ${t('Date & time of arrest', 'গ্রেপ্তারের তারিখ ও সময়')}: ${v('arrestDate')} ${v('arrestTime')}
8. ${t('Person informed about arrest', 'গ্রেপ্তার সম্পর্কে যাকে জানানো হয়েছে')}: ${v('informedPerson')}
9. ${t('Arresting officer', 'গ্রেপ্তারকারী অফিসার')}: ${v('arrestingOfficer')}
10. ${t('Grounds / reasons for arrest', 'গ্রেপ্তারের কারণ / গ্রাউন্ডস')}:
$grounds
${v('otherGround', '')}

${t('Witnesses', 'সাক্ষী')}:
$witnesses
${t('Arrested person acknowledgement / signature status', 'গ্রেপ্তার ব্যক্তির স্বীকৃতি / স্বাক্ষরের অবস্থা')}: ${v('accusedAcknowledgement')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'bnss_94_production':
        final itemLines = (state.rows['productionItems'] ?? const []).asMap().entries.map((e) {
          final d = (e.value['description'] ?? '').trim();
          final r = (e.value['remarks'] ?? '').trim();
          return '${e.key + 1}. ${d.isEmpty ? '________________________________________' : d}${r.isEmpty ? '' : ' — $r'}';
        }).join('\n');
        return '''${t('NOTICE / WRITTEN ORDER U/S 94 BNSS, 2023', 'ধারা 94 BNSS, 2023 অনুযায়ী নোটিশ / লিখিত আদেশ')}

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('Diary No.', 'ডায়েরি নং')}: ${v('diaryNo')}
${t('To', 'প্রাপক')}: ${v('recipientName')}
${t('Address', 'ঠিকানা')}: ${v('recipientAddress')}

${t('For the purpose of investigation, you are required to produce / furnish the following document(s) / thing(s)', 'তদন্তের স্বার্থে আপনাকে নিম্নলিখিত দলিল / বস্তু পেশ / সরবরাহ করতে বলা হচ্ছে')}:
$itemLines

${t('Production date', 'পেশের তারিখ')}: ${v('productionDate')}
${t('Production time', 'পেশের সময়')}: ${v('productionTime')}
${t('Production place', 'পেশের স্থান')}: ${v('productionPlace')}

${t('Status', 'স্ট্যাটাস')}: ${v('serviceStatus')}
${t('Issue / service date-time', 'ইস্যু / সার্ভ তারিখ-সময়')}: ${v('serviceDate')} ${v('serviceTime', '')}
${t('Receipt / acknowledgement', 'রিসিট / স্বীকৃতি')}: ${v('acknowledgement')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'bnss_179_witness_attendance':
        return '''${t('NOTICE TO WITNESS FOR ATTENDANCE — SECTION 179 BNSS', 'সাক্ষীকে উপস্থিতির নোটিশ — ধারা 179 BNSS')}

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('Diary No.', 'ডায়েরি নং')}: ${v('diaryNo')}
${t('Witness', 'সাক্ষী')}: ${v('witnessName')}
${t('Parentage', 'পিতৃ/মাতৃ/দাম্পত্য পরিচয়')}: ${v('parentage')}
${t('Address', 'ঠিকানা')}: ${v('witnessAddress')}

${t('As it appears that you are acquainted with the facts and circumstances of the case, you are required to attend for investigation on', 'আপনি মামলার ঘটনা ও পরিস্থিতি সম্পর্কে অবগত বলে প্রতীয়মান হওয়ায় তদন্তের জন্য আপনাকে উপস্থিত হতে বলা হচ্ছে')}: ${v('attendanceDate')} ${t('at', 'তারিখে সময়')} ${v('attendanceTime')} ${t('at', 'স্থানে')} ${v('attendancePlace')}.

${t('Reference-form safeguard: persons under 15 years or above 60 years, women, mentally or physically disabled persons, and persons with acute illness are shown in the supplied form as protected from being required to attend at the police station unless they are willing; officer must verify the current enacted provision and applicability before service.', 'রেফারেন্স-ফর্মের সুরক্ষা নোট: প্রদত্ত ফর্মে ১৫ বছরের কম বা ৬০ বছরের বেশি বয়সী ব্যক্তি, মহিলা, মানসিক বা শারীরিকভাবে প্রতিবন্ধী ব্যক্তি এবং গুরুতর অসুস্থ ব্যক্তিকে তাদের ইচ্ছা ব্যতীত থানায় উপস্থিত হতে বাধ্য না করার কথা উল্লেখ আছে; সার্ভিসের আগে অফিসার বর্তমান কার্যকর বিধান ও প্রযোজ্যতা যাচাই করবেন।')}
${t('Protected-person attendance safeguard reviewed', 'বিশেষ সুরক্ষাপ্রাপ্ত ব্যক্তির উপস্থিতি সংক্রান্ত বিধান যাচাই')}: ${yesNo('protectedPersonCheck')}
${t('Reference-form note: non-attendance may attract legal action under the applicable provision; verify current law before service.', 'রেফারেন্স-ফর্ম নোট: অনুপস্থিতির ক্ষেত্রে প্রযোজ্য বিধান অনুযায়ী আইনগত ব্যবস্থা হতে পারে; সার্ভিসের আগে বর্তমান আইন যাচাই করুন।')}
${t('Notice status', 'নোটিশ স্ট্যাটাস')}: ${v('serviceStatus')}
${t('Issue / service date-time', 'ইস্যু / সার্ভ তারিখ-সময়')}: ${v('serviceDate')} ${v('serviceTime', '')}
${t('Acknowledgement / service remarks', 'স্বীকৃতি / সার্ভ মন্তব্য')}: ${v('acknowledgement')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'bnss_49_personal_search':
        final articles = (state.rows['searchArticles'] ?? const []).asMap().entries.map((e) {
          final d = e.value['description'] ?? '';
          final q = e.value['quantity'] ?? '';
          final r = e.value['remarks'] ?? '';
          return '${e.key + 1}. $d${q.trim().isEmpty ? '' : ' | Qty: $q'}${r.trim().isEmpty ? '' : ' | $r'}';
        }).join('\n');
        final witnesses = (state.rows['searchWitnesses'] ?? const []).asMap().entries.map((e) => '${e.key + 1}. ${e.value['name'] ?? ''} — ${e.value['details'] ?? ''}').join('\n');
        return '''${t('PERSONAL SEARCH MEMORANDUM — SECTION 49 BNSS', 'ব্যক্তিগত তল্লাশি স্মারক — ধারা 49 BNSS')}

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('Name', 'নাম')}: ${v('personName')}
${t('Parentage', 'পিতৃ/মাতৃ পরিচয়')}: ${v('parentage')}
${t('Age', 'বয়স')}: ${v('age')}    ${t('Mobile', 'মোবাইল')}: ${v('mobile')}
${t('ID particulars', 'পরিচয়পত্রের বিবরণ')}: ${v('idParticulars')}
${t('Place / date / time of search', 'তল্লাশির স্থান / তারিখ / সময়')}: ${v('searchPlace')} / ${v('searchDate')} / ${v('searchTime')}

${t('Articles taken into possession', 'পুলিশের হেফাজতে নেওয়া সামগ্রী')}:
$articles

${t('Receipt of articles given', 'সামগ্রীর রসিদ দেওয়া হয়েছে')}: ${yesNo('receiptGiven')}
${t('Person acknowledgement / signature', 'ব্যক্তির স্বীকৃতি / স্বাক্ষর')}: ${v('personSignatureStatus')}
${t('Witnesses', 'সাক্ষী')}:
$witnesses

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'medical_examination_reference':
        return '''${t('MEDICAL EXAMINATION REQUISITION', 'চিকিৎসা পরীক্ষার অনুরোধপত্র')}

${t('To', 'প্রাপক')}: ${v('hospital')}
${t('Case Reference', 'মামলার সূত্র')}: ${ref()}

${t('The following person is being sent / referred for medical examination', 'নিম্নলিখিত ব্যক্তিকে চিকিৎসা পরীক্ষার জন্য প্রেরণ / রেফার করা হচ্ছে')}:
${t('Name', 'নাম')}: ${v('personName')}
${t('Relation details', 'সম্পর্কের বিবরণ')}: ${v('relationDetails')}
${t('Address', 'ঠিকানা')}: ${v('address')}
${t('Age', 'বয়স')}: ${v('age')}
${t('Forwarding / examination date-time', 'প্রেরণ / পরীক্ষার তারিখ-সময়')}: ${v('examDate')} ${v('examTime', '')}

${t('Examination / samples / opinion requested', 'প্রয়োজনীয় পরীক্ষা / নমুনা / মতামত')}: ${v('requestedExamination')}
${t('Preserve relevant exhibits / samples if available', 'প্রাসঙ্গিক আলামত / নমুনা থাকলে সংরক্ষণ')}: ${yesNo('preserveExhibits')}

${t('Report status', 'রিপোর্ট স্ট্যাটাস')}: ${v('reportStatus')}
${t('Report received date-time', 'রিপোর্ট পাওয়ার তারিখ-সময়')}: ${v('reportReceiptDate')} ${v('reportReceiptTime', '')}
${t('Remarks', 'মন্তব্য')}: ${v('reportRemarks')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'fsl_forwarding_reference':
        final exhibits = (state.rows['fslExhibits'] ?? const []).asMap().entries.map((e) {
          final row = e.value;
          return '${e.key + 1}. ${row['mark'] ?? ''} | ${row['description'] ?? ''} | ${row['source'] ?? ''} | ${row['pages'] ?? ''}';
        }).join('\n');
        return '''${t('FSL FORWARDING LETTER / EXAMINATION REQUISITION', 'FSL-এ প্রেরণের অগ্রসারণপত্র / পরীক্ষার অনুরোধ')}

${t('To', 'প্রাপক')}:
${v('fslOffice')}
${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('Nature of offence', 'অপরাধের প্রকৃতি')}: ${v('natureOfCrime')}
${t('Brief facts', 'সংক্ষিপ্ত ঘটনা')}: ${v('briefFacts')}

${t('Exhibits sent for examination', 'পরীক্ষার জন্য প্রেরিত আলামত')}:
$exhibits

${t('Nature of examination required / points for opinion', 'প্রয়োজনীয় পরীক্ষা / মতামতের প্রশ্ন')}:
${v('examinationRequired')}

${t('Forwarding date-time', 'প্রেরণের তারিখ-সময়')}: ${v('forwardingDate')} ${v('forwardingTime', '')}
${t('Messenger', 'মেসেঞ্জার')}: ${v('messenger')}
${t('Sample seal / seal description', 'সিলের নমুনা / বিবরণ')}: ${v('sealSample')}
${t('FSL receipt status', 'FSL রিসিট স্ট্যাটাস')}: ${v('ackStatus')}
${t('Acknowledgement date-time / no.', 'স্বীকৃতি তারিখ-সময় / নং')}: ${v('ackDate')} ${v('ackTime', '')} / ${v('ackNo')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      case 'bnss_193_3_ii_progress':
        return '''${t('INVESTIGATION PROGRESS INTIMATION — SECTION 193(3)(ii) BNSS', 'তদন্তের অগ্রগতি জানানো — ধারা 193(3)(ii) BNSS')}

${t('Case Reference', 'মামলার সূত্র')}: ${ref()}
${t('To', 'প্রাপক')}: ${v('recipientName')}
${t('Address / contact', 'ঠিকানা / যোগাযোগ')}: ${v('recipientAddress')}

${t('The following progress of investigation is communicated', 'তদন্তের নিম্নলিখিত অগ্রগতি জানানো হলো')}:
${numberedRows('progressItems', 'progress')}

${t('Communication date-time', 'যোগাযোগের তারিখ-সময়')}: ${v('communicationDate')} ${v('communicationTime', '')}
${t('Mode', 'মাধ্যম')}: ${v('communicationMode')}
${t('Acknowledgement / delivery status', 'স্বীকৃতি / ডেলিভারি স্ট্যাটাস')}: ${v('acknowledgement')}

${officer.rank} ${officer.name}
${officer.policeStation}, ${officer.district}''';
      default:
        throw ArgumentError('Unsupported structured form: $templateId');
    }
  }

  String cdActionDate(FormNotice form) {
    final state = StructuredBnssFormState.fromJson(form.workflowData);
    for (final key in const [
      'serviceDate', 'arrestDate', 'searchDate', 'examDate', 'forwardingDate', 'communicationDate', 'productionDate', 'attendanceDate',
    ]) {
      final value = (state.values[key] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return _today();
  }

  String cdActionTime(FormNotice form) {
    final state = StructuredBnssFormState.fromJson(form.workflowData);
    for (final key in const [
      'serviceTime', 'arrestTime', 'searchTime', 'examTime', 'forwardingTime', 'communicationTime', 'productionTime', 'attendanceTime',
    ]) {
      final value = (state.values[key] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String cdPlace(FormNotice form, OfficerProfile officer) {
    final state = StructuredBnssFormState.fromJson(form.workflowData);
    for (final key in const [
      'servedAt', 'arrestPlace', 'searchPlace', 'productionPlace', 'attendancePlace', 'hospital', 'fslOffice',
    ]) {
      final value = (state.values[key] ?? '').trim();
      if (value.isNotEmpty) return value.split('\n').first;
    }
    return officer.policeStation;
  }

  String cdSynopsis(FormNotice form) {
    switch (baseId(form.templateId)) {
      case 'bnss_35_3_appearance': return '35(3) BNSS Notice';
      case 'bnss_35_arrest_memo': return 'Arrest Memo';
      case 'bnss_94_production': return '94 BNSS Notice';
      case 'bnss_179_witness_attendance': return '179 BNSS Notice';
      case 'bnss_49_personal_search': return 'Personal Search';
      case 'medical_examination_reference': return 'Medical Requisition';
      case 'fsl_forwarding_reference': return 'FSL Forwarding';
      case 'bnss_193_3_ii_progress': return 'Progress Intimation';
      default: return form.title;
    }
  }

  String cdParagraph(FormNotice form) {
    final state = StructuredBnssFormState.fromJson(form.workflowData);
    String v(String key) => (state.values[key] ?? '').trim();
    switch (baseId(form.templateId)) {
      case 'bnss_35_3_appearance':
        final status = v('serviceStatus');
        final recipient = v('recipientName');
        return '${status == 'Served' ? 'Served' : 'Prepared/issued'} notice u/s 35(3) BNSS upon ${recipient.isEmpty ? 'the concerned person' : recipient} requiring appearance/cooperation in connection with this case.';
      case 'bnss_35_arrest_memo':
        return 'Prepared arrest memorandum in respect of ${v('arrestedName').isEmpty ? 'the arrested accused person' : v('arrestedName')} after recording the arrest particulars and grounds/formalities.';
      case 'bnss_94_production':
        return 'Issued notice/written order u/s 94 BNSS to ${v('recipientName').isEmpty ? 'the concerned person/authority' : v('recipientName')} for production of relevant document(s)/thing(s) for investigation.';
      case 'bnss_179_witness_attendance':
        return 'Issued notice u/s 179 BNSS to ${v('witnessName').isEmpty ? 'the concerned witness' : v('witnessName')} requiring attendance for investigation of this case.';
      case 'bnss_49_personal_search':
        return 'Prepared personal search memorandum u/s 49 BNSS in respect of ${v('personName').isEmpty ? 'the concerned person' : v('personName')} and documented the articles, if any, taken into possession.';
      case 'medical_examination_reference':
        final reportStatus = v('reportStatus');
        return reportStatus == 'ReportReceived'
            ? 'Received/perused the medical examination report in connection with this case and kept the same with the case records.'
            : 'Sent medical examination requisition in respect of ${v('personName').isEmpty ? 'the concerned person' : v('personName')} for investigation of this case.';
      case 'fsl_forwarding_reference':
        return 'Prepared/sent FSL forwarding and examination requisition with exhibit particulars in connection with this case.';
      case 'bnss_193_3_ii_progress':
        return 'Communicated progress of investigation to ${v('recipientName').isEmpty ? 'the informant/victim' : v('recipientName')} u/s 193(3)(ii) BNSS through ${v('communicationMode').isEmpty ? 'the recorded mode' : v('communicationMode')}.';
      default:
        return 'Prepared ${form.title} in connection with this case.';
    }
  }
}
