import '../models/case_file.dart';
import '../models/cd_workflow.dart';

class CdWorkflowService {
  static const String actionPcInterrogation = 'pc_interrogation';
  static const String actionWitnessExamination = 'witness_examination';
  static const String actionVictimExamination = 'victim_examination';
  static const String actionPoVisit = 'po_visit';
  static const String actionRaidSearch = 'raid_search';
  static const String actionRecoverySeizure = 'recovery_seizure';
  static const String actionArrest = 'arrest';
  static const String actionCourtProduction = 'court_production';
  static const String actionJudicialStatement = 'judicial_statement';
  static const String actionMedicalExamination = 'medical_examination';
  static const String actionReportDocument = 'report_document';
  static const String actionRequisition = 'requisition';
  static const String actionDigitalEvidence = 'digital_evidence';
  static const String actionLocalEnquiry = 'local_enquiry';
  static const String actionNotice = 'notice';
  static const String actionExpertReport = 'expert_report';
  static const String actionAgeProof = 'age_proof';
  static const String actionSanction = 'sanction';
  static const String actionMoe = 'moe';
  static const String actionInjuryMedicalPapers = 'injury_medical_papers';
  static const String actionVehicleDriverVerification = 'vehicle_driver_verification';
  static const String actionOther = 'other';

  CdCaseCategory classifyCase(CaseFile caseFile) {
    final haystack =
        '${caseFile.sections} ${caseFile.crimeHead}'.toLowerCase();

    if (haystack.contains('pocso')) return CdCaseCategory.pocso;
    if (haystack.contains('281') ||
        haystack.contains('road accident') ||
        haystack.contains('road traffic') ||
        haystack.contains('motor vehicle accident') ||
        haystack.contains('rta')) {
      return CdCaseCategory.roadTrafficAccident;
    }
    if (haystack.contains('arms act') ||
        haystack.contains('25/27') ||
        haystack.contains('25 / 27')) {
      return CdCaseCategory.arms;
    }

    if (haystack.contains('64 bns') ||
        haystack.contains('65 bns') ||
        haystack.contains('66 bns') ||
        haystack.contains('67 bns') ||
        haystack.contains('68 bns') ||
        haystack.contains('69 bns') ||
        haystack.contains('70 bns') ||
        haystack.contains('rape') ||
        haystack.contains('sexual')) {
      return CdCaseCategory.sexualOffence;
    }

    return CdCaseCategory.general;
  }

  CdWorkflowPlan buildPlan({
    required CaseFile caseFile,
    required int cdNumber,
    Set<String> completedActions = const <String>{},
    Set<String> pendingActions = const <String>{},
    bool hasVictim = false,
    bool hasArrestedAccused = false,
    bool hasPcAccused = false,
    bool finalisationRequested = false,
  }) {
    final category = classifyCase(caseFile);
    final context = CdWorkflowContext(
      cdNumber: cdNumber,
      caseCategory: category,
      completedActions: completedActions,
      pendingActions: pendingActions,
      hasVictim: hasVictim || caseFile.victimName.trim().isNotEmpty,
      hasArrestedAccused: hasArrestedAccused,
      hasPcAccused: hasPcAccused,
      finalisationRequested: finalisationRequested,
    );

    if (context.phase == CdWorkflowPhase.initial) {
      return CdWorkflowPlan(
        phase: context.phase,
        caseCategory: category,
        recommendedActionIds: _initialRecommendations(context),
        questions: _initialQuestions(context),
      );
    }

    if (context.phase == CdWorkflowPhase.finalisation) {
      return CdWorkflowPlan(
        phase: context.phase,
        caseCategory: category,
        recommendedActionIds: const <String>[],
        questions: _finalQuestions(context),
      );
    }

    return CdWorkflowPlan(
      phase: context.phase,
      caseCategory: category,
      recommendedActionIds: _continuationRecommendations(context),
      questions: _continuationQuestions(context),
    );
  }

  List<String> _initialRecommendations(CdWorkflowContext context) {
    final result = <String>[
      actionWitnessExamination,
      actionPoVisit,
    ];

    if (context.caseCategory == CdCaseCategory.pocso ||
        context.caseCategory == CdCaseCategory.sexualOffence) {
      result.add(actionVictimExamination);
    }

    return result;
  }

  List<String> _continuationRecommendations(CdWorkflowContext context) {
    final result = <String>[];

    void recommend(String id) {
      if (!context.completedActions.contains(id) && !result.contains(id)) {
        result.add(id);
      }
    }

    for (final pending in context.pendingActions) {
      if (!result.contains(pending)) result.add(pending);
    }

    if (context.hasPcAccused) recommend(actionPcInterrogation);

    switch (context.caseCategory) {
      case CdCaseCategory.roadTrafficAccident:
        recommend(actionWitnessExamination);
        recommend(actionInjuryMedicalPapers);
        recommend(actionVehicleDriverVerification);
        break;
      case CdCaseCategory.arms:
        recommend(actionRecoverySeizure);
        recommend(actionExpertReport);
        recommend(actionSanction);
        break;
      case CdCaseCategory.pocso:
        if (context.hasVictim) {
          recommend(actionVictimExamination);
          recommend(actionJudicialStatement);
          recommend(actionAgeProof);
        }
        recommend(actionMedicalExamination);
        recommend(actionMoe);
        break;
      case CdCaseCategory.sexualOffence:
        if (context.hasVictim) {
          recommend(actionVictimExamination);
          recommend(actionJudicialStatement);
        }
        recommend(actionMedicalExamination);
        recommend(actionDigitalEvidence);
        break;
      case CdCaseCategory.general:
        break;
    }

    return result;
  }

  List<CdWorkflowQuestion> _initialQuestions(CdWorkflowContext context) {
    final q = <CdWorkflowQuestion>[
      const CdWorkflowQuestion(
        id: 'cd1_departure_time',
        group: 'case_start',
        order: 10,
        type: CdQuestionType.time,
        titleBn: 'তদন্তের জন্য থানা থেকে কখন রওনা হয়েছেন? (DD)',
        titleEn: 'At what time did you depart the PS for investigation? (DD)',
        required: true,
      ),
      const CdWorkflowQuestion(
        id: 'cd1_fir_receive_time',
        group: 'case_start',
        order: 5,
        type: CdQuestionType.time,
        titleBn: 'FIR/complaint copy কখন receive/peruse করেছেন?',
        titleEn: 'At what time did you receive/peruse the FIR/complaint copy?',
        required: true,
      ),
      const CdWorkflowQuestion(
        id: 'cd1_first_arrival_time',
        group: 'case_start',
        order: 20,
        type: CdQuestionType.time,
        titleBn: 'প্রথম তদন্তস্থলে কখন পৌঁছেছেন? (DA)',
        titleEn: 'At what time did you first arrive at the investigation place? (DA)',
        required: true,
      ),
      const CdWorkflowQuestion(
        id: 'cd1_first_arrival_place',
        group: 'case_start',
        order: 25,
        type: CdQuestionType.shortText,
        titleBn: 'প্রথম investigation place/location কোথায়?',
        titleEn: 'What was the first investigation place/location?',
        required: true,
      ),
      const CdWorkflowQuestion(
        id: 'cd1_ro',
        group: 'case_start',
        order: 30,
        type: CdQuestionType.shortText,
        titleBn: 'Recording/Receiving Officer (RO)-এর নাম ও পদবি কী?',
        titleEn: 'Name and rank of the Recording/Receiving Officer (RO)?',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_fir_received',
        group: 'fir',
        order: 40,
        type: CdQuestionType.yesNo,
        titleBn: 'FIR ও complaint-এর copy গ্রহণ ও peruse করেছেন?',
        titleEn: 'Did you receive and peruse the FIR and complaint copy?',
        required: true,
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_examined',
        group: 'complainant',
        order: 50,
        type: CdQuestionType.yesNo,
        titleBn: 'Complainant-কে examine করেছেন?',
        titleEn: 'Did you examine the complainant?',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_exam_time',
        group: 'complainant',
        order: 55,
        type: CdQuestionType.time,
        titleBn: 'Complainant-কে কখন examine করেছেন?',
        titleEn: 'At what time did you examine the complainant?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_complainant_examined',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_exam_place',
        group: 'complainant',
        order: 57,
        type: CdQuestionType.shortText,
        titleBn: 'Complainant-কে কোথায় examine করেছেন?',
        titleEn: 'Where did you examine the complainant?',
        hintBn: 'থানায় হলে Police Station-এর নাম দিন।',
        hintEn: 'If examined at the PS, enter the Police Station name.',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_complainant_examined',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_identity_details',
        group: 'complainant',
        order: 58,
        type: CdQuestionType.longText,
        titleBn: 'Statement header-এর জন্য complainant-এর পরিচয় লিখুন (পিতা/স্বামী, ঠিকানা, বয়স/মোবাইল—যা প্রযোজ্য)।',
        titleEn: 'Enter complainant identity details for the statement header (parent/spouse, address, age/mobile as applicable).',
        hintBn: 'Case Entry-তে না থাকলে এখানেই দিন; এই data Statement sheet-এ যাবে, CD narration-এ নয়।',
        hintEn: 'If not available in Case Entry, enter it here. It feeds the statement sheet, not the CD narration.',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_complainant_examined',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_statement_recorded',
        group: 'complainant',
        order: 59,
        type: CdQuestionType.yesNo,
        titleBn: 'Complainant-এর statement u/s 180 BNSS আলাদা sheet-এ record করেছেন?',
        titleEn: 'Did you record the complainant statement u/s 180 BNSS on a separate sheet?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_complainant_examined',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_complainant_statement',
        group: 'complainant',
        order: 60,
        type: CdQuestionType.longText,
        titleBn: 'Complainant-এর statement body হুবহু record করুন।',
        titleEn: 'Record the complainant statement body exactly as stated.',
        hintBn: 'Witness-এর নিজের ভাষা/first-person narration লিখুন। App এটাকেই u/s 180 BNSS Statement sheet বানাবে; CD-তে শুধু statement recorded হয়েছে বলে mention করবে।',
        hintEn: "Enter the witness narrative in the witness's own words/first person. The app will create the u/s 180 BNSS statement sheet and only mention the recording in the CD.",
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_complainant_statement_recorded',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_existing_seizure',
        group: 'seizure',
        order: 70,
        type: CdQuestionType.yesNo,
        titleBn: 'FIR/complaint-এর সঙ্গে কোনো seizure list বা seized article পেয়েছেন?',
        titleEn: 'Did you receive any seizure list or seized article with the FIR/complaint?',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_existing_seizure_time',
        group: 'seizure',
        order: 75,
        type: CdQuestionType.time,
        titleBn: 'Existing seizure/seized article কখন verify/receive করেছেন?',
        titleEn: 'At what time did you receive/verify the existing seizure or seized article?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_existing_seizure',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_existing_seizure_details',
        group: 'seizure',
        order: 80,
        type: CdQuestionType.longText,
        titleBn: 'Seized article/document-এর description, seizure time এবং কোথায় রাখা হয়েছে লিখুন।',
        titleEn: 'Enter description, seizure time and custody/storage of the seized article/document.',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_existing_seizure',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_accused_available',
        group: 'accused',
        order: 90,
        type: CdQuestionType.yesNo,
        titleBn: 'কোনো arrested/apprehended accused আপনার কাছে available ছিল?',
        titleEn: 'Was any arrested/apprehended accused available with you?',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_accused_interrogated',
        group: 'accused',
        order: 100,
        type: CdQuestionType.yesNo,
        titleBn: 'Accused-কে interrogate করেছেন?',
        titleEn: 'Did you interrogate the accused?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_accused_available',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_accused_interrogation_time',
        group: 'accused',
        order: 105,
        type: CdQuestionType.time,
        titleBn: 'Accused-কে কখন interrogate করেছেন?',
        titleEn: 'At what time did you interrogate the accused?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_accused_interrogated',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_accused_interrogation_details',
        group: 'accused',
        order: 110,
        type: CdQuestionType.longText,
        titleBn: 'Interrogation-এ material কী তথ্য পাওয়া গেছে? শুধু factual disclosure লিখুন।',
        titleEn: 'What material facts emerged during interrogation? Record factual disclosure only.',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_accused_interrogated',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_police_witnesses',
        group: 'witness',
        order: 120,
        type: CdQuestionType.longText,
        titleBn: 'Raid/search/seizure-এ উপস্থিত police personnel/witness-দের নাম ও ভূমিকা লিখুন।',
        titleEn: 'Enter police personnel/witnesses present during raid/search/seizure and their roles.',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_witness_entries_json',
        group: 'witness',
        order: 125,
        type: CdQuestionType.witnessRepeater,
        titleBn: 'CD-I-তে অন্য কোনো witness examine/statement record করলে যোগ করুন।',
        titleEn: 'Add any other witness examined/statement recorded in CD-I.',
        hintBn: 'Police witness, seizure witness, eye witness, local witness—প্রত্যেকের data একবারই দিন। Statement record না করলে সেটিও আলাদাভাবে mark করা যাবে।',
        hintEn: 'Add police, seizure, eye or local witnesses once. You may also mark an examination where no statement was recorded.',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_left_for_po',
        group: 'po',
        order: 130,
        type: CdQuestionType.yesNo,
        titleBn: 'আজ PO visit করেছেন?',
        titleEn: 'Did you visit the PO today?',
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_first_destination',
        group: 'po',
        order: 135,
        type: CdQuestionType.yesNo,
        titleBn: 'PO-ই কি FIR নেওয়ার পর আপনার প্রথম investigation destination ছিল?',
        titleEn: 'Was the PO your first investigation destination after taking up the case?',
        hintBn: 'Yes হলে DD/DA সময়ই PO departure/arrival হিসেবে ব্যবহার হবে; একই সময় আবার দিতে হবে না।',
        hintEn: 'If Yes, DD/DA will be reused for PO departure/arrival and will not be asked again.',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_departure_time',
        group: 'po',
        order: 140,
        type: CdQuestionType.time,
        titleBn: 'PO visit-এর জন্য কখন রওনা হয়েছেন?',
        titleEn: 'At what time did you depart for the PO?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_po_first_destination',
          value: 'no',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_arrival_time',
        group: 'po',
        order: 150,
        type: CdQuestionType.time,
        titleBn: 'PO-তে কখন পৌঁছেছেন?',
        titleEn: 'At what time did you arrive at the PO?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_po_first_destination',
          value: 'no',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_exact',
        group: 'po',
        order: 155,
        type: CdQuestionType.shortText,
        titleBn: 'Exact PO কোথায়?',
        titleEn: 'What is the exact place of occurrence?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_shown_by',
        group: 'po',
        order: 160,
        type: CdQuestionType.shortText,
        titleBn: 'PO কে দেখিয়েছেন?',
        titleEn: 'Who showed/identified the PO?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_sketch_index',
        group: 'po',
        order: 170,
        type: CdQuestionType.yesNo,
        titleBn: 'Rough sketch map ও index প্রস্তুত করেছেন?',
        titleEn: 'Did you prepare the rough sketch map and index?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_north',
        group: 'po_surroundings',
        order: 180,
        type: CdQuestionType.shortText,
        titleBn: 'PO-এর উত্তর দিকে কী আছে?',
        titleEn: 'What is on the north side of the PO?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_south',
        group: 'po_surroundings',
        order: 190,
        type: CdQuestionType.shortText,
        titleBn: 'PO-এর দক্ষিণ দিকে কী আছে?',
        titleEn: 'What is on the south side of the PO?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_east',
        group: 'po_surroundings',
        order: 200,
        type: CdQuestionType.shortText,
        titleBn: 'PO-এর পূর্ব দিকে কী আছে?',
        titleEn: 'What is on the east side of the PO?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_west',
        group: 'po_surroundings',
        order: 210,
        type: CdQuestionType.shortText,
        titleBn: 'PO-এর পশ্চিম দিকে কী আছে?',
        titleEn: 'What is on the west side of the PO?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_clue_search',
        group: 'po',
        order: 220,
        type: CdQuestionType.yesNo,
        titleBn: 'PO ও আশপাশে clue/evidence search করেছেন?',
        titleEn: 'Did you search the PO and surroundings for clue/evidence?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_clue_search_time',
        group: 'po',
        order: 221,
        type: CdQuestionType.time,
        titleBn: 'Clue/evidence search কখন করেছেন?',
        titleEn: 'At what time did you search for clue/evidence?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_clue_search',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_clue_search_result',
        group: 'po',
        order: 222,
        type: CdQuestionType.longText,
        titleBn: 'Clue/evidence search-এর factual result লিখুন।',
        titleEn: 'Record the factual result of the clue/evidence search.',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_clue_search',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_local_witness_search',
        group: 'po',
        order: 230,
        type: CdQuestionType.yesNo,
        titleBn: 'Local witness খুঁজেছেন/পেয়েছেন?',
        titleEn: 'Did you search for/find local witnesses?',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_local_witness_search_time',
        group: 'po',
        order: 231,
        type: CdQuestionType.time,
        titleBn: 'Local witness search/enquiry কখন করেছেন?',
        titleEn: 'At what time did you search/enquire for local witnesses?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_local_witness_search',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_local_witness_result',
        group: 'po',
        order: 232,
        type: CdQuestionType.longText,
        titleBn: 'Local witness search/enquiry-এর factual result লিখুন।',
        titleEn: 'Record the factual result of local witness search/enquiry.',
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_local_witness_search',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_po_departure_from_spot_time',
        group: 'po',
        order: 235,
        type: CdQuestionType.time,
        titleBn: 'PO থেকে কখন রওনা হয়েছেন?',
        titleEn: 'At what time did you depart from the PO?',
        required: true,
        dependency: CdQuestionDependency.equals(
          questionId: 'cd1_left_for_po',
          value: 'yes',
        ),
      ),
      const CdWorkflowQuestion(
        id: 'cd1_return_time',
        group: 'closing',
        order: 240,
        type: CdQuestionType.time,
        titleBn: 'তদন্ত শেষে কখন থানায়/ক্যাম্পে ফিরেছেন?',
        titleEn: 'At what time did you return to the PS/camp after investigation?',
        required: true,
      ),
    ];

    if (context.caseCategory == CdCaseCategory.pocso ||
        context.caseCategory == CdCaseCategory.sexualOffence) {
      q.addAll(const <CdWorkflowQuestion>[
        CdWorkflowQuestion(
          id: 'cd1_victim_contacted',
          group: 'victim',
          order: 115,
          type: CdQuestionType.yesNo,
          titleBn: 'Victim/VG-এর সঙ্গে যোগাযোগ বা examination হয়েছে?',
          titleEn: 'Was the victim/VG contacted or examined?',
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_name',
          group: 'victim',
          order: 116,
          type: CdQuestionType.shortText,
          titleBn: 'Victim/VG-এর নাম কী?',
          titleEn: 'What is the name of the victim/VG?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_identity_details',
          group: 'victim',
          order: 117,
          type: CdQuestionType.longText,
          titleBn: 'Victim/VG-এর statement header-এর পরিচয়/ঠিকানা লিখুন।',
          titleEn: 'Enter victim/VG identity/address details for the statement header.',
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_time',
          group: 'victim',
          order: 118,
          type: CdQuestionType.time,
          titleBn: 'Victim/VG examination/contact কখন হয়েছে?',
          titleEn: 'At what time was the victim/VG contacted or examined?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_place',
          group: 'victim',
          order: 119,
          type: CdQuestionType.shortText,
          titleBn: 'Victim/VG-কে কোথায় examine/contact করেছেন?',
          titleEn: 'Where was the victim/VG examined/contacted?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_exam_note',
          group: 'victim',
          order: 120,
          type: CdQuestionType.longText,
          titleBn: 'Examination/contact-এর factual note লিখুন (non-cooperation থাকলে সেটাও)।',
          titleEn: 'Record the factual examination/contact note, including non-cooperation if any.',
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_statement_recorded',
          group: 'victim',
          order: 121,
          type: CdQuestionType.yesNo,
          titleBn: 'Victim/VG-এর statement u/s 180 BNSS আলাদা sheet-এ record হয়েছে?',
          titleEn: 'Was the victim/VG statement u/s 180 BNSS recorded on a separate sheet?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_contacted',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'cd1_victim_statement_body',
          group: 'victim',
          order: 122,
          type: CdQuestionType.longText,
          titleBn: 'Victim/VG-এর statement body হুবহু record করুন।',
          titleEn: 'Record the victim/VG statement body exactly as stated.',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'cd1_victim_statement_recorded',
            value: 'yes',
          ),
        ),
      ]);
    }

    q.sort((a, b) => a.order.compareTo(b.order));
    return q;
  }

  List<CdWorkflowQuestion> _continuationQuestions(
    CdWorkflowContext context,
  ) {
    final q = <CdWorkflowQuestion>[
      CdWorkflowQuestion(
        id: 'today_actions',
        group: 'action_selector',
        order: 10,
        type: CdQuestionType.multiChoice,
        titleBn: 'আজ এই মামলায় কী কী investigation করেছেন?',
        titleEn: 'What investigation actions did you perform today?',
        required: true,
        options: _actionOptions(context),
      ),
      ..._timelineQuestions(),
      ..._pcInterrogationQuestions(),
      ..._witnessQuestions(),
      ..._victimQuestions(),
      ..._poQuestions(),
      ..._raidQuestions(),
      ..._recoveryQuestions(),
      ..._arrestQuestions(),
      ..._courtQuestions(),
      ..._judicialStatementQuestions(),
      ..._medicalQuestions(),
      ..._reportDocumentQuestions(),
      ..._requisitionQuestions(),
      ..._digitalEvidenceQuestions(),
      ..._localEnquiryQuestions(),
      ..._noticeQuestions(),
      ..._expertQuestions(),
      ..._ageProofQuestions(),
      ..._sanctionQuestions(),
      ..._moeQuestions(),
      ..._injuryMedicalPaperQuestions(),
      ..._vehicleDriverVerificationQuestions(),
      ..._otherQuestions(),
      const CdWorkflowQuestion(
        id: 'continuation_return_time',
        group: 'closing',
        order: 900,
        type: CdQuestionType.time,
        titleBn: 'আজকের investigation শেষে return/closing time কী?',
        titleEn: 'What is today\'s return/closing time?',
        required: true,
      ),
    ];

    q.sort((a, b) => a.order.compareTo(b.order));
    return q;
  }

  List<CdQuestionOption> _actionOptions(CdWorkflowContext context) {
    final values = <CdQuestionOption>[
      const CdQuestionOption(
        value: actionPcInterrogation,
        labelBn: 'PC accused interrogation',
        labelEn: 'PC accused interrogation',
      ),
      const CdQuestionOption(
        value: actionWitnessExamination,
        labelBn: 'Witness examination / u/s 180 BNSS statement',
        labelEn: 'Witness examination / u/s 180 BNSS statement',
      ),
      const CdQuestionOption(
        value: actionVictimExamination,
        labelBn: 'Victim/VG examination',
        labelEn: 'Victim/VG examination',
      ),
      const CdQuestionOption(
        value: actionPoVisit,
        labelBn: 'PO visit / sketch / local search',
        labelEn: 'PO visit / sketch / local search',
      ),
      const CdQuestionOption(
        value: actionRaidSearch,
        labelBn: 'Raid / search',
        labelEn: 'Raid / search',
      ),
      const CdQuestionOption(
        value: actionRecoverySeizure,
        labelBn: 'Recovery / seizure',
        labelEn: 'Recovery / seizure',
      ),
      const CdQuestionOption(
        value: actionArrest,
        labelBn: 'Arrest / apprehension',
        labelEn: 'Arrest / apprehension',
      ),
      const CdQuestionOption(
        value: actionCourtProduction,
        labelBn: 'Court/JJB production / prayer / order',
        labelEn: 'Court/JJB production / prayer / order',
      ),
      const CdQuestionOption(
        value: actionJudicialStatement,
        labelBn: 'Judicial statement u/s 183 BNSS',
        labelEn: 'Judicial statement u/s 183 BNSS',
      ),
      const CdQuestionOption(
        value: actionMedicalExamination,
        labelBn: 'Medical examination / MLE / BHT / injury',
        labelEn: 'Medical examination / MLE / BHT / injury',
      ),
      const CdQuestionOption(
        value: actionReportDocument,
        labelBn: 'Report / order sheet / document collected',
        labelEn: 'Report / order sheet / document collected',
      ),
      const CdQuestionOption(
        value: actionRequisition,
        labelBn: 'Requisition / prayer sent',
        labelEn: 'Requisition / prayer sent',
      ),
      const CdQuestionOption(
        value: actionDigitalEvidence,
        labelBn: 'CDR / electronic / digital evidence',
        labelEn: 'CDR / electronic / digital evidence',
      ),
      const CdQuestionOption(
        value: actionLocalEnquiry,
        labelBn: 'Local enquiry / verification',
        labelEn: 'Local enquiry / verification',
      ),
      const CdQuestionOption(
        value: actionNotice,
        labelBn: 'Notice / service',
        labelEn: 'Notice / service',
      ),
      const CdQuestionOption(
        value: actionExpertReport,
        labelBn: 'FSL / Arms Expert / Scientific report',
        labelEn: 'FSL / Arms Expert / Scientific report',
      ),
      const CdQuestionOption(
        value: actionAgeProof,
        labelBn: 'Age proof collection/seizure',
        labelEn: 'Age proof collection/seizure',
      ),
      const CdQuestionOption(
        value: actionSanction,
        labelBn: 'Sanction prayer/order',
        labelEn: 'Sanction prayer/order',
      ),
      const CdQuestionOption(
        value: actionMoe,
        labelBn: 'MOE / superior permission for CS',
        labelEn: 'MOE / superior permission for CS',
      ),
      if (context.caseCategory == CdCaseCategory.roadTrafficAccident) ...const <CdQuestionOption>[
        CdQuestionOption(
          value: actionInjuryMedicalPapers,
          labelBn: 'Injured-এর Injury Report / BHT / Medical papers',
          labelEn: 'Injured person Injury Report / BHT / Medical papers',
        ),
        CdQuestionOption(
          value: actionVehicleDriverVerification,
          labelBn: 'Offending vehicle / driver verification',
          labelEn: 'Offending vehicle / driver verification',
        ),
      ],
      const CdQuestionOption(
        value: actionOther,
        labelBn: 'Other important investigation',
        labelEn: 'Other important investigation',
      ),
    ];

    return values;
  }

  List<CdWorkflowQuestion> _timelineQuestions() => const [
        CdWorkflowQuestion(
          id: 'pc_time',
          group: actionPcInterrogation,
          order: 90,
          type: CdQuestionType.time,
          titleBn: 'PC accused interrogation কখন শুরু করেছেন?',
          titleEn: 'At what time did PC accused interrogation start?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPcInterrogation,
          ),
        ),
        CdWorkflowQuestion(
          id: 'pc_place',
          group: actionPcInterrogation,
          order: 91,
          type: CdQuestionType.shortText,
          titleBn: 'PC interrogation কোথায় হয়েছে?',
          titleEn: 'Where was the PC interrogation conducted?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPcInterrogation,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_time',
          group: actionVictimExamination,
          order: 160,
          type: CdQuestionType.time,
          titleBn: 'Victim/VG examination কখন হয়েছে?',
          titleEn: 'At what time was the victim/VG examined?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_place',
          group: actionVictimExamination,
          order: 161,
          type: CdQuestionType.shortText,
          titleBn: 'Victim/VG কোথায় examine হয়েছে?',
          titleEn: 'Where was the victim/VG examined?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_departure_time',
          group: actionPoVisit,
          order: 190,
          type: CdQuestionType.time,
          titleBn: 'PO visit-এর জন্য PS/camp থেকে কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you depart the PS/camp for the PO?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'raid_arrival_time',
          group: actionRaidSearch,
          order: 231,
          type: CdQuestionType.time,
          titleBn: 'Raid/search-এর স্থানে কখন পৌঁছেছেন?',
          titleEn: 'At what time did you arrive at the raid/search place?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRaidSearch,
          ),
        ),
        CdWorkflowQuestion(
          id: 'raid_place',
          group: actionRaidSearch,
          order: 232,
          type: CdQuestionType.shortText,
          titleBn: 'Raid/search-এর exact place কী?',
          titleEn: 'What was the exact raid/search place?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRaidSearch,
          ),
        ),
        CdWorkflowQuestion(
          id: 'recovery_time',
          group: actionRecoverySeizure,
          order: 250,
          type: CdQuestionType.time,
          titleBn: 'Recovery/seizure কখন হয়েছে?',
          titleEn: 'At what time was the recovery/seizure made?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRecoverySeizure,
          ),
        ),
        CdWorkflowQuestion(
          id: 'recovery_place',
          group: actionRecoverySeizure,
          order: 251,
          type: CdQuestionType.shortText,
          titleBn: 'Recovery/seizure কোথায় হয়েছে?',
          titleEn: 'Where was the recovery/seizure made?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRecoverySeizure,
          ),
        ),
        CdWorkflowQuestion(
          id: 'arrest_time',
          group: actionArrest,
          order: 290,
          type: CdQuestionType.time,
          titleBn: 'Accused-কে কখন arrest/apprehend করেছেন?',
          titleEn: 'At what time was the accused arrested/apprehended?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionArrest,
          ),
        ),
        CdWorkflowQuestion(
          id: 'arrest_place',
          group: actionArrest,
          order: 291,
          type: CdQuestionType.shortText,
          titleBn: 'Arrest/apprehension কোথায় হয়েছে?',
          titleEn: 'Where did the arrest/apprehension take place?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionArrest,
          ),
        ),
        CdWorkflowQuestion(
          id: 'court_departure_time',
          group: actionCourtProduction,
          order: 320,
          type: CdQuestionType.time,
          titleBn: 'Court/JJB-এর জন্য কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you depart for Court/JJB?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionCourtProduction,
          ),
        ),
        CdWorkflowQuestion(
          id: 'court_arrival_time',
          group: actionCourtProduction,
          order: 321,
          type: CdQuestionType.time,
          titleBn: 'Court/JJB-তে কখন পৌঁছেছেন?',
          titleEn: 'At what time did you arrive at Court/JJB?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionCourtProduction,
          ),
        ),
        CdWorkflowQuestion(
          id: 'court_place',
          group: actionCourtProduction,
          order: 322,
          type: CdQuestionType.shortText,
          titleBn: 'Court/JJB-এর নাম ও স্থান লিখুন।',
          titleEn: 'Enter the Court/JJB name and place.',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionCourtProduction,
          ),
        ),
        CdWorkflowQuestion(
          id: 'js_time',
          group: actionJudicialStatement,
          order: 350,
          type: CdQuestionType.time,
          titleBn: 'Judicial statement-এর prayer/production কখন হয়েছে?',
          titleEn: 'At what time was prayer/production for judicial statement made?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionJudicialStatement,
          ),
        ),
        CdWorkflowQuestion(
          id: 'js_place',
          group: actionJudicialStatement,
          order: 351,
          type: CdQuestionType.shortText,
          titleBn: 'Judicial statement-এর Court-এর নাম ও স্থান লিখুন।',
          titleEn: 'Enter the Court name and place for the judicial statement.',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionJudicialStatement,
          ),
        ),
        CdWorkflowQuestion(
          id: 'medical_departure_time',
          group: actionMedicalExamination,
          order: 380,
          type: CdQuestionType.time,
          titleBn: 'Medical/MLE-এর জন্য কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you depart for medical/MLE?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'medical_arrival_time',
          group: actionMedicalExamination,
          order: 381,
          type: CdQuestionType.time,
          titleBn: 'Hospital/medical facility-তে কখন পৌঁছেছেন?',
          titleEn: 'At what time did you arrive at the hospital/medical facility?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'medical_completion_time',
          group: actionMedicalExamination,
          order: 382,
          type: CdQuestionType.time,
          titleBn: 'Examination/report collection কখন complete হয়েছে?',
          titleEn: 'At what time was examination/report collection completed?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'medical_place',
          group: actionMedicalExamination,
          order: 383,
          type: CdQuestionType.shortText,
          titleBn: 'Hospital/medical facility-এর নাম ও স্থান লিখুন।',
          titleEn: 'Enter the hospital/medical facility name and place.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'report_document_time',
          group: actionReportDocument,
          order: 410,
          type: CdQuestionType.time,
          titleBn: 'Report/order/document কখন receive/peruse করেছেন?',
          titleEn: 'At what time was the report/order/document received/perused?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionReportDocument,
          ),
        ),
        CdWorkflowQuestion(
          id: 'requisition_time',
          group: actionRequisition,
          order: 440,
          type: CdQuestionType.time,
          titleBn: 'Requisition/prayer কখন send/submit করেছেন?',
          titleEn: 'At what time was the requisition/prayer sent/submitted?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRequisition,
          ),
        ),
        CdWorkflowQuestion(
          id: 'digital_time',
          group: actionDigitalEvidence,
          order: 460,
          type: CdQuestionType.time,
          titleBn: 'Digital/electronic evidence collection/analysis কখন হয়েছে?',
          titleEn: 'At what time was digital/electronic evidence collected/analysed?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionDigitalEvidence,
          ),
        ),
        CdWorkflowQuestion(
          id: 'local_enquiry_time',
          group: actionLocalEnquiry,
          order: 490,
          type: CdQuestionType.time,
          titleBn: 'Local enquiry/verification কখন হয়েছে?',
          titleEn: 'At what time was local enquiry/verification conducted?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionLocalEnquiry,
          ),
        ),
        CdWorkflowQuestion(
          id: 'notice_time',
          group: actionNotice,
          order: 520,
          type: CdQuestionType.time,
          titleBn: 'Notice কখন issue/serve করেছেন?',
          titleEn: 'At what time was the notice issued/served?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionNotice,
          ),
        ),
        CdWorkflowQuestion(
          id: 'expert_time',
          group: actionExpertReport,
          order: 540,
          type: CdQuestionType.time,
          titleBn: 'Expert/FSL/Arms report কখন receive/peruse করেছেন?',
          titleEn: 'At what time was the expert/FSL/Arms report received/perused?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionExpertReport,
          ),
        ),
        CdWorkflowQuestion(
          id: 'age_proof_time',
          group: actionAgeProof,
          order: 560,
          type: CdQuestionType.time,
          titleBn: 'Age-proof document কখন collect/verify করেছেন?',
          titleEn: 'At what time was the age-proof document collected/verified?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionAgeProof,
          ),
        ),
        CdWorkflowQuestion(
          id: 'sanction_time',
          group: actionSanction,
          order: 580,
          type: CdQuestionType.time,
          titleBn: 'Sanction-related prayer/step কখন নিয়েছেন?',
          titleEn: 'At what time was the sanction-related prayer/step taken?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionSanction,
          ),
        ),
        CdWorkflowQuestion(
          id: 'moe_time',
          group: actionMoe,
          order: 600,
          type: CdQuestionType.time,
          titleBn: 'MOE কখন submit করেছেন/permission কখন পেয়েছেন?',
          titleEn: 'At what time was MOE submitted/permission received?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMoe,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_departure_time',
          group: actionInjuryMedicalPapers,
          order: 610,
          type: CdQuestionType.time,
          titleBn: 'Medical papers/BHT-এর জন্য থানা থেকে কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you leave the PS for medical papers/BHT?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_arrival_time',
          group: actionInjuryMedicalPapers,
          order: 611,
          type: CdQuestionType.time,
          titleBn: 'Hospital-এ কখন পৌঁছেছেন?',
          titleEn: 'At what time did you arrive at the hospital?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_action_time',
          group: actionInjuryMedicalPapers,
          order: 612,
          type: CdQuestionType.time,
          titleBn: 'Requisition/collection step কখন নিয়েছেন?',
          titleEn: 'At what time did you submit requisition/take the collection step?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_departure_hospital_time',
          group: actionInjuryMedicalPapers,
          order: 613,
          type: CdQuestionType.time,
          titleBn: 'Hospital থেকে কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you depart from the hospital?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_return_ps_time',
          group: actionInjuryMedicalPapers,
          order: 614,
          type: CdQuestionType.time,
          titleBn: 'Hospital থেকে ফিরে থানায় কখন পৌঁছেছেন?',
          titleEn: 'At what time did you return to the PS from the hospital?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'vehicle_verify_time',
          group: actionVehicleDriverVerification,
          order: 650,
          type: CdQuestionType.time,
          titleBn: 'Offending vehicle/driver verification কখন করেছেন?',
          titleEn: 'At what time did you verify the offending vehicle/driver?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVehicleDriverVerification,
          ),
        ),
        CdWorkflowQuestion(
          id: 'other_time',
          group: actionOther,
          order: 620,
          type: CdQuestionType.time,
          titleBn: 'Other investigation step কখন হয়েছে?',
          titleEn: 'At what time did the other investigation step occur?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionOther,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _pcInterrogationQuestions() => const [
        CdWorkflowQuestion(
          id: 'pc_accused_name',
          group: actionPcInterrogation,
          order: 100,
          type: CdQuestionType.shortText,
          titleBn: 'PC accused-এর নাম, পরিচয় ও PC period লিখুন।',
          titleEn: 'Enter the PC accused identity and PC period.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPcInterrogation,
          ),
        ),
        CdWorkflowQuestion(
          id: 'pc_interrogation_material',
          group: actionPcInterrogation,
          order: 110,
          type: CdQuestionType.longText,
          titleBn: 'Interrogation-এ কী material disclosure হয়েছে?',
          titleEn: 'What material disclosure emerged during interrogation?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPcInterrogation,
          ),
        ),
        CdWorkflowQuestion(
          id: 'pc_leading_to_recovery',
          group: actionPcInterrogation,
          order: 120,
          type: CdQuestionType.yesNo,
          titleBn: 'Disclosure-এর ভিত্তিতে recovery/raid করার মতো leading statement হয়েছে?',
          titleEn: 'Did the disclosure lead to a recovery/raid?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPcInterrogation,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _witnessQuestions() => const [
        CdWorkflowQuestion(
          id: 'witness_entries_json',
          group: actionWitnessExamination,
          order: 140,
          type: CdQuestionType.witnessRepeater,
          titleBn: 'আজ examine করা witness-দের একে একে যোগ করুন।',
          titleEn: 'Add every witness examined today.',
          hintBn: 'প্রত্যেক witness-এর নাম, role, সময়, স্থান এবং statement body একবারই দিন। Separate Timed Entry অথবা Grouped Same-Session Entry বেছে নেওয়া যাবে।',
          hintEn: 'Enter each witness once with role, time, place and statement body. Choose Separate Timed Entry or Grouped Same-Session Entry.',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionWitnessExamination,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _victimQuestions() => const [
        CdWorkflowQuestion(
          id: 'victim_name',
          group: actionVictimExamination,
          order: 165,
          type: CdQuestionType.shortText,
          titleBn: 'Victim/VG-এর নাম কী?',
          titleEn: 'What is the name of the victim/VG?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_identity_details',
          group: actionVictimExamination,
          order: 166,
          type: CdQuestionType.longText,
          titleBn: 'Statement header-এর জন্য Victim/VG-এর পরিচয়/ঠিকানা লিখুন।',
          titleEn: 'Enter victim/VG identity/address details for the statement header.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_examined_by',
          group: actionVictimExamination,
          order: 170,
          type: CdQuestionType.shortText,
          titleBn: 'Victim/VG-কে কে examine করেছেন?',
          titleEn: 'Who examined the victim/VG?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_exam_note',
          group: actionVictimExamination,
          order: 175,
          type: CdQuestionType.longText,
          titleBn: 'Victim/VG examination-এর factual note/non-cooperation লিখুন।',
          titleEn: 'Record the factual victim/VG examination or non-cooperation note.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_statement_recorded',
          group: actionVictimExamination,
          order: 178,
          type: CdQuestionType.yesNo,
          titleBn: 'Victim/VG-এর statement u/s 180 BNSS আলাদা sheet-এ record হয়েছে?',
          titleEn: 'Was the victim/VG statement u/s 180 BNSS recorded on a separate sheet?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVictimExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'victim_statement_body',
          group: actionVictimExamination,
          order: 180,
          type: CdQuestionType.longText,
          titleBn: 'Victim/VG-এর statement body হুবহু record করুন।',
          titleEn: 'Record the victim/VG statement body exactly as stated.',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'victim_statement_recorded',
            value: 'yes',
          ),
        ),
      ];

  List<CdWorkflowQuestion> _poQuestions() => const [
        CdWorkflowQuestion(
          id: 'po_visit_time',
          group: actionPoVisit,
          order: 200,
          type: CdQuestionType.time,
          titleBn: 'PO-তে কখন পৌঁছেছেন?',
          titleEn: 'At what time did you arrive at the PO?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_exact',
          group: actionPoVisit,
          order: 201,
          type: CdQuestionType.shortText,
          titleBn: 'Exact PO কোথায়?',
          titleEn: 'What is the exact place of occurrence?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_shown_by',
          group: actionPoVisit,
          order: 202,
          type: CdQuestionType.shortText,
          titleBn: 'PO কে দেখিয়েছেন/identify করেছেন?',
          titleEn: 'Who showed or identified the PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_sketch_index',
          group: actionPoVisit,
          order: 203,
          type: CdQuestionType.yesNo,
          titleBn: 'এই PO-এর rough sketch map ও index প্রস্তুত করবেন?',
          titleEn: 'Will you prepare the rough sketch map and index for this PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_north',
          group: actionPoVisit,
          order: 204,
          type: CdQuestionType.shortText,
          titleBn: 'PO-এর উত্তর দিকে কী আছে?',
          titleEn: 'What is on the north side of the PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_south',
          group: actionPoVisit,
          order: 205,
          type: CdQuestionType.shortText,
          titleBn: 'PO-এর দক্ষিণ দিকে কী আছে?',
          titleEn: 'What is on the south side of the PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_east',
          group: actionPoVisit,
          order: 206,
          type: CdQuestionType.shortText,
          titleBn: 'PO-এর পূর্ব দিকে কী আছে?',
          titleEn: 'What is on the east side of the PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_west',
          group: actionPoVisit,
          order: 207,
          type: CdQuestionType.shortText,
          titleBn: 'PO-এর পশ্চিম দিকে কী আছে?',
          titleEn: 'What is on the west side of the PO?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_clue_search',
          group: actionPoVisit,
          order: 208,
          type: CdQuestionType.yesNo,
          titleBn: 'PO ও আশপাশে clue/evidence search করেছেন?',
          titleEn: 'Did you search the PO and surroundings for clue/evidence?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_clue_search_time',
          group: actionPoVisit,
          order: 209,
          type: CdQuestionType.time,
          titleBn: 'Clue/evidence search কখন করেছেন?',
          titleEn: 'At what time did you search for clue/evidence?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'po_clue_search',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_clue_search_result',
          group: actionPoVisit,
          order: 210,
          type: CdQuestionType.longText,
          titleBn: 'Clue/evidence search-এর factual result লিখুন।',
          titleEn: 'Record the factual result of clue/evidence search.',
          dependency: CdQuestionDependency.equals(
            questionId: 'po_clue_search',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_local_witness_search',
          group: actionPoVisit,
          order: 209,
          type: CdQuestionType.yesNo,
          titleBn: 'Local witness খুঁজেছেন/পেয়েছেন?',
          titleEn: 'Did you search for/find local witnesses?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_local_witness_search_time',
          group: actionPoVisit,
          order: 212,
          type: CdQuestionType.time,
          titleBn: 'Local witness search/enquiry কখন করেছেন?',
          titleEn: 'At what time did you search/enquire for local witnesses?',
          required: true,
          dependency: CdQuestionDependency.equals(
            questionId: 'po_local_witness_search',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_local_witness_result',
          group: actionPoVisit,
          order: 213,
          type: CdQuestionType.longText,
          titleBn: 'Local witness search/enquiry-এর factual result লিখুন।',
          titleEn: 'Record the factual result of local witness search/enquiry.',
          dependency: CdQuestionDependency.equals(
            questionId: 'po_local_witness_search',
            value: 'yes',
          ),
        ),
        CdWorkflowQuestion(
          id: 'po_departure_from_spot_time',
          group: actionPoVisit,
          order: 214,
          type: CdQuestionType.time,
          titleBn: 'PO থেকে কখন রওনা হয়েছেন?',
          titleEn: 'At what time did you depart from the PO?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionPoVisit,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _raidQuestions() => const [
        CdWorkflowQuestion(
          id: 'raid_departure',
          group: actionRaidSearch,
          order: 230,
          type: CdQuestionType.time,
          titleBn: 'Raid/search-এর জন্য কখন এবং কোথা থেকে রওনা হয়েছেন?',
          titleEn: 'When and from where did you depart for raid/search?',
          required: true,
        dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRaidSearch,
          ),
        ),
        CdWorkflowQuestion(
          id: 'raid_place_force_result',
          group: actionRaidSearch,
          order: 240,
          type: CdQuestionType.longText,
          titleBn: 'Raid/search-এর স্থান, সঙ্গে কারা ছিলেন এবং ফলাফল কী?',
          titleEn: 'Enter raid/search place, accompanying personnel and result.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRaidSearch,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _recoveryQuestions() => const [
        CdWorkflowQuestion(
          id: 'recovery_basis',
          group: actionRecoverySeizure,
          order: 260,
          type: CdQuestionType.longText,
          titleBn: 'Recovery কার দেখানো/leading statement/production-এর ভিত্তিতে হয়েছে?',
          titleEn: 'On whose showing/leading statement/production was the recovery made?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRecoverySeizure,
          ),
        ),
        CdWorkflowQuestion(
          id: 'recovery_article',
          group: actionRecoverySeizure,
          order: 270,
          type: CdQuestionType.longText,
          titleBn: 'Recovered/seized article-এর complete description, quantity ও seizure time লিখুন।',
          titleEn: 'Enter complete description, quantity and seizure time of recovered/seized article.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRecoverySeizure,
          ),
        ),
        CdWorkflowQuestion(
          id: 'recovery_witness_custody',
          group: actionRecoverySeizure,
          order: 280,
          type: CdQuestionType.longText,
          titleBn: 'Seizure witness কারা? Article কোথায় রাখা/zimma দেওয়া হয়েছে?',
          titleEn: 'Who witnessed the seizure and where was the article kept/given in zimma?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRecoverySeizure,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _arrestQuestions() => const [
        CdWorkflowQuestion(
          id: 'arrest_identity_time',
          group: actionArrest,
          order: 300,
          type: CdQuestionType.longText,
          titleBn: 'Arrested accused-এর পরিচয়, arrest date/time এবং place লিখুন।',
          titleEn: 'Enter arrested accused identity, arrest date/time and place.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionArrest,
          ),
        ),
        CdWorkflowQuestion(
          id: 'arrest_formalities',
          group: actionArrest,
          order: 310,
          type: CdQuestionType.longText,
          titleBn: 'Arrest memo, inspection memo, grounds of arrest intimation ও custody/lock-up details লিখুন।',
          titleEn: 'Enter arrest memo, inspection memo, grounds-of-arrest intimation and custody/lock-up details.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionArrest,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _courtQuestions() => const [
        CdWorkflowQuestion(
          id: 'court_name_person',
          group: actionCourtProduction,
          order: 330,
          type: CdQuestionType.longText,
          titleBn: 'কোন Court/JJB-তে কাকে produce করেছেন?',
          titleEn: 'Whom did you produce before which Court/JJB?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionCourtProduction,
          ),
        ),
        CdWorkflowQuestion(
          id: 'court_prayer_order',
          group: actionCourtProduction,
          order: 340,
          type: CdQuestionType.longText,
          titleBn: 'কী prayer করেছেন, Court কী order দিয়েছে, order sheet পেয়েছেন কি না লিখুন।',
          titleEn: 'Enter prayer, Court order and whether the order sheet was received.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionCourtProduction,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _judicialStatementQuestions() => const [
        CdWorkflowQuestion(
          id: 'js_person_court',
          group: actionJudicialStatement,
          order: 360,
          type: CdQuestionType.longText,
          titleBn: 'কার u/s 183 BNSS judicial statement-এর জন্য কোন Court-এ prayer/production হয়েছে?',
          titleEn: 'For whose u/s 183 BNSS judicial statement was prayer/production made and before which Court?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionJudicialStatement,
          ),
        ),
        CdWorkflowQuestion(
          id: 'js_copy_collected',
          group: actionJudicialStatement,
          order: 370,
          type: CdQuestionType.yesNo,
          titleBn: 'Judicial statement-এর copy collect করে CD-তে রেখেছেন?',
          titleEn: 'Did you collect the judicial statement copy and keep it with the CD?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionJudicialStatement,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _medicalQuestions() => const [
        CdWorkflowQuestion(
          id: 'medical_person_hospital',
          group: actionMedicalExamination,
          order: 390,
          type: CdQuestionType.longText,
          titleBn: 'কার medical/MLE, কোন hospital/doctor-এর কাছে, কী prayer/order অনুযায়ী হয়েছে?',
          titleEn: 'Whose medical/MLE was done, at which hospital/doctor, and under what prayer/order?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
        CdWorkflowQuestion(
          id: 'medical_report_result',
          group: actionMedicalExamination,
          order: 400,
          type: CdQuestionType.longText,
          titleBn: 'Medical/BHT/injury report collect করেছেন? Material result লিখুন।',
          titleEn: 'Was medical/BHT/injury report collected? Enter material result.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMedicalExamination,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _reportDocumentQuestions() => const [
        CdWorkflowQuestion(
          id: 'report_document_identity',
          group: actionReportDocument,
          order: 420,
          type: CdQuestionType.longText,
          titleBn: 'কোন report/order/document, কার কাছ থেকে, memo/date সহ পেয়েছেন?',
          titleEn: 'Which report/order/document was received, from whom, with memo/date?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionReportDocument,
          ),
        ),
        CdWorkflowQuestion(
          id: 'report_document_material',
          group: actionReportDocument,
          order: 430,
          type: CdQuestionType.longText,
          titleBn: 'Peruse করে material finding কী পেলেন এবং CD-তে কীভাবে kept করেছেন?',
          titleEn: 'What material finding emerged on perusal and how was it kept with the CD?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionReportDocument,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _requisitionQuestions() => const [
        CdWorkflowQuestion(
          id: 'requisition_to_purpose',
          group: actionRequisition,
          order: 450,
          type: CdQuestionType.longText,
          titleBn: 'কাকে, কোন purpose-এ, memo/reference সহ requisition/prayer পাঠিয়েছেন?',
          titleEn: 'To whom, for what purpose, and with what memo/reference was requisition/prayer sent?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionRequisition,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _digitalEvidenceQuestions() => const [
        CdWorkflowQuestion(
          id: 'digital_source_details',
          group: actionDigitalEvidence,
          order: 470,
          type: CdQuestionType.longText,
          titleBn: 'CDR/device/CCTV/other electronic evidence-এর source, period এবং collection details লিখুন।',
          titleEn: 'Enter source, period and collection details of CDR/device/CCTV/other electronic evidence.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionDigitalEvidence,
          ),
        ),
        CdWorkflowQuestion(
          id: 'digital_material_finding',
          group: actionDigitalEvidence,
          order: 480,
          type: CdQuestionType.longText,
          titleBn: 'Analysis-এ material finding কী পাওয়া গেছে?',
          titleEn: 'What material finding emerged from analysis?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionDigitalEvidence,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _localEnquiryQuestions() => const [
        CdWorkflowQuestion(
          id: 'local_enquiry_place_persons',
          group: actionLocalEnquiry,
          order: 500,
          type: CdQuestionType.longText,
          titleBn: 'কোথায় local enquiry/verification করেছেন এবং কার সঙ্গে কথা বলেছেন?',
          titleEn: 'Where was local enquiry/verification conducted and whom did you contact?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionLocalEnquiry,
          ),
        ),
        CdWorkflowQuestion(
          id: 'local_enquiry_result',
          group: actionLocalEnquiry,
          order: 510,
          type: CdQuestionType.longText,
          titleBn: 'Enquiry-তে কী factual result পাওয়া গেছে?',
          titleEn: 'What factual result emerged from the enquiry?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionLocalEnquiry,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _noticeQuestions() => const [
        CdWorkflowQuestion(
          id: 'notice_details',
          group: actionNotice,
          order: 530,
          type: CdQuestionType.longText,
          titleBn: 'কাকে কোন notice, কোন section/reference-এ, কীভাবে serve করেছেন?',
          titleEn: 'Which notice was served on whom, under which section/reference, and by what mode?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionNotice,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _expertQuestions() => const [
        CdWorkflowQuestion(
          id: 'expert_report_details',
          group: actionExpertReport,
          order: 550,
          type: CdQuestionType.longText,
          titleBn: 'FSL/Arms Expert/Scientific report-এর memo/date ও opinion-এর material points লিখুন।',
          titleEn: 'Enter memo/date and material opinion points of FSL/Arms Expert/Scientific report.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionExpertReport,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _ageProofQuestions() => const [
        CdWorkflowQuestion(
          id: 'age_proof_details',
          group: actionAgeProof,
          order: 570,
          type: CdQuestionType.longText,
          titleBn: 'কার age proof, কী document, DOB/registration details, কার কাছ থেকে পেয়েছেন?',
          titleEn: 'Whose age proof, which document, DOB/registration details, and from whom was it received?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionAgeProof,
          ),
        ),
        CdWorkflowQuestion(
          id: 'age_proof_seizure_zimma',
          group: actionAgeProof,
          order: 580,
          type: CdQuestionType.longText,
          titleBn: 'Age proof document seizure/zimma details লিখুন।',
          titleEn: 'Enter seizure/zimma details of the age-proof document.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionAgeProof,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _sanctionQuestions() => const [
        CdWorkflowQuestion(
          id: 'sanction_prayer_details',
          group: actionSanction,
          order: 600,
          type: CdQuestionType.longText,
          titleBn: 'কোন authority-র কাছে কোন section-এর sanction-এর জন্য prayer পাঠিয়েছেন/পেয়েছেন?',
          titleEn: 'To which authority was sanction prayer sent/received and for which section?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionSanction,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _moeQuestions() => const [
        CdWorkflowQuestion(
          id: 'moe_sections_accused',
          group: actionMoe,
          order: 620,
          type: CdQuestionType.longText,
          titleBn: 'MOE-তে কোন accused-এর বিরুদ্ধে কোন sections propose করেছেন?',
          titleEn: 'Which sections against which accused were proposed in the MOE?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMoe,
          ),
        ),
        CdWorkflowQuestion(
          id: 'moe_superior_direction',
          group: actionMoe,
          order: 630,
          type: CdQuestionType.longText,
          titleBn: 'Superior officer-এর direction/permission কী পেয়েছেন?',
          titleEn: 'What direction/permission was received from the superior officer?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionMoe,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _injuryMedicalPaperQuestions() => const [
        CdWorkflowQuestion(
          id: 'injury_doc_hospital',
          group: actionInjuryMedicalPapers,
          order: 620,
          type: CdQuestionType.shortText,
          titleBn: 'কোন Hospital/medical facility-তে গিয়েছেন?',
          titleEn: 'Which hospital/medical facility did you visit?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_step',
          group: actionInjuryMedicalPapers,
          order: 630,
          type: CdQuestionType.longText,
          titleBn: 'Injury Report/BHT/medical paper-এর জন্য কী requisition/step নিয়েছেন?',
          titleEn: 'What requisition/step did you take for Injury Report/BHT/medical papers?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_collected',
          group: actionInjuryMedicalPapers,
          order: 635,
          type: CdQuestionType.yesNo,
          titleBn: 'Medical papers আজ collect হয়েছে?',
          titleEn: 'Were the medical papers collected today?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionInjuryMedicalPapers,
          ),
        ),
        CdWorkflowQuestion(
          id: 'injury_doc_result',
          group: actionInjuryMedicalPapers,
          order: 640,
          type: CdQuestionType.longText,
          titleBn: 'Collect হলে material medical finding লিখুন।',
          titleEn: 'If collected, record the material medical finding.',
          dependency: CdQuestionDependency.equals(
            questionId: 'injury_doc_collected',
            value: 'yes',
          ),
        ),
      ];

  List<CdWorkflowQuestion> _vehicleDriverVerificationQuestions() => const [
        CdWorkflowQuestion(
          id: 'vehicle_number',
          group: actionVehicleDriverVerification,
          order: 660,
          type: CdQuestionType.shortText,
          titleBn: 'Offending vehicle registration number কী?',
          titleEn: 'What is the offending vehicle registration number?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVehicleDriverVerification,
          ),
        ),
        CdWorkflowQuestion(
          id: 'vehicle_owner_driver_status',
          group: actionVehicleDriverVerification,
          order: 670,
          type: CdQuestionType.longText,
          titleBn: 'Registered owner/actual driver identification ও verification-এর factual status লিখুন।',
          titleEn: 'Record the factual status of registered owner/actual driver identification and verification.',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVehicleDriverVerification,
          ),
        ),
        CdWorkflowQuestion(
          id: 'vehicle_found',
          group: actionVehicleDriverVerification,
          order: 680,
          type: CdQuestionType.yesNo,
          titleBn: 'Offending vehicle আজ trace/found হয়েছে?',
          titleEn: 'Was the offending vehicle traced/found today?',
          required: true,
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVehicleDriverVerification,
          ),
        ),
        CdWorkflowQuestion(
          id: 'vehicle_step_taken',
          group: actionVehicleDriverVerification,
          order: 690,
          type: CdQuestionType.longText,
          titleBn: 'Vehicle/driver বিষয়ে আজ কী step নিয়েছেন (notice/seizure/search/verification/MVI requisition ইত্যাদি)?',
          titleEn: 'What step was taken regarding the vehicle/driver today (notice/seizure/search/verification/MVI requisition etc.)?',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionVehicleDriverVerification,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _otherQuestions() => const [
        CdWorkflowQuestion(
          id: 'other_investigation_details',
          group: actionOther,
          order: 650,
          type: CdQuestionType.longText,
          titleBn: 'আজকের অন্য গুরুত্বপূর্ণ investigation step factualভাবে লিখুন।',
          titleEn: 'Record any other important investigation step factually.',
          dependency: CdQuestionDependency.contains(
            questionId: 'today_actions',
            value: actionOther,
          ),
        ),
      ];

  List<CdWorkflowQuestion> _finalQuestions(CdWorkflowContext context) {
    return const <CdWorkflowQuestion>[
      CdWorkflowQuestion(
        id: 'final_superior_order',
        group: 'final_permission',
        order: 10,
        type: CdQuestionType.longText,
        titleBn: 'Charge Sheet submit করার superior order/permission/MOE reference লিখুন।',
        titleEn: 'Enter superior order/permission/MOE reference for submission of Charge Sheet.',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_sections',
        group: 'final_charge',
        order: 20,
        type: CdQuestionType.shortText,
        titleBn: 'Final investigation-এ কোন sections prima facie established হয়েছে?',
        titleEn: 'Which sections are prima facie established on final investigation?',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_accused_status',
        group: 'final_charge',
        order: 30,
        type: CdQuestionType.longText,
        titleBn: 'প্রত্যেক charge-sheeted accused-এর নাম, role ও present status লিখুন।',
        titleEn: 'Enter each charge-sheeted accused, role and present status.',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_investigation_summary',
        group: 'final_summary',
        order: 40,
        type: CdQuestionType.longText,
        titleBn: 'PO visit থেকে শেষ investigation পর্যন্ত relied-upon steps/evidence chronologicalভাবে confirm করুন।',
        titleEn: 'Confirm relied-upon investigation steps/evidence chronologically from PO visit to final stage.',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_supplementary_provision',
        group: 'final_charge',
        order: 50,
        type: CdQuestionType.yesNo,
        titleBn: 'ভবিষ্যতে clue/evidence পেলে supplementary charge sheet/report-এর provision রাখতে হবে?',
        titleEn: 'Should provision be kept for supplementary charge sheet/report if further clue/evidence emerges?',
      ),
      CdWorkflowQuestion(
        id: 'final_witnesses',
        group: 'final_witness',
        order: 60,
        type: CdQuestionType.longText,
        titleBn: 'Final prosecution witness list confirm করুন।',
        titleEn: 'Confirm the final prosecution witness list.',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_complainant_informed',
        group: 'final_closing',
        order: 70,
        type: CdQuestionType.yesNo,
        titleBn: 'Complainant/informant-কে result of investigation জানানো হয়েছে?',
        titleEn: 'Has the complainant/informant been informed of the result of investigation?',
        required: true,
      ),
      CdWorkflowQuestion(
        id: 'final_cs_number_date',
        group: 'final_closing',
        order: 80,
        type: CdQuestionType.shortText,
        titleBn: 'Charge Sheet No. ও Date লিখুন।',
        titleEn: 'Enter Charge Sheet number and date.',
        required: true,
      ),
    ];
  }
}
