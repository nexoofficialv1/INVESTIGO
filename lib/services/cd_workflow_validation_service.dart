import '../models/cd_workflow.dart';
import '../models/witness_examination_entry.dart';
import 'cd_workflow_service.dart';

enum CdValidationSeverity { error, warning }

class CdValidationIssue {
  final CdValidationSeverity severity;
  final String messageBn;
  final String messageEn;
  final List<String> questionIds;

  const CdValidationIssue({
    required this.severity,
    required this.messageBn,
    required this.messageEn,
    this.questionIds = const <String>[],
  });

  bool get isError => severity == CdValidationSeverity.error;
}

class CdWorkflowValidationService {
  List<CdValidationIssue> validate({
    required CdWorkflowPlan plan,
    required Map<String, String> answers,
  }) {
    switch (plan.phase) {
      case CdWorkflowPhase.initial:
        return _validateInitial(answers);
      case CdWorkflowPhase.continuation:
        return _validateContinuation(answers);
      case CdWorkflowPhase.finalisation:
        return _validateFinalisation(answers);
    }
  }

  List<CdValidationIssue> _validateInitial(Map<String, String> answers) {
    final issues = <CdValidationIssue>[];

    _validatePair(
      issues,
      answers,
      earlierKey: 'cd1_fir_receive_time',
      laterKey: 'cd1_departure_time',
      messageBn: 'FIR receive/peruse time-এর আগে PS departure time হতে পারে না।',
      messageEn: 'PS departure cannot be earlier than FIR receipt/perusal time.',
    );
    _validatePair(
      issues,
      answers,
      earlierKey: 'cd1_departure_time',
      laterKey: 'cd1_first_arrival_time',
      messageBn: 'প্রথম arrival time, departure time-এর আগে হতে পারে না।',
      messageEn: 'First arrival time cannot be earlier than departure time.',
    );

    if (_isYes(answers, 'cd1_left_for_po')) {
      if (_isYes(answers, 'cd1_po_first_destination')) {
        final firstPlace = _answer(answers, 'cd1_first_arrival_place').toLowerCase();
        final exactPo = _answer(answers, 'cd1_po_exact').toLowerCase();
        if (firstPlace.isNotEmpty && exactPo.isNotEmpty && firstPlace != exactPo) {
          issues.add(const CdValidationIssue(
            severity: CdValidationSeverity.warning,
            messageBn: 'PO-কে first destination বলা হয়েছে, কিন্তু First Arrival Place ও Exact PO এক নয়। দুটো তথ্য যাচাই করুন।',
            messageEn: 'PO is marked as the first destination, but First Arrival Place and Exact PO do not match.',
            questionIds: <String>['cd1_first_arrival_place', 'cd1_po_exact', 'cd1_po_first_destination'],
          ));
        }
      } else {
        _validatePair(
          issues,
          answers,
          earlierKey: 'cd1_po_departure_time',
          laterKey: 'cd1_po_arrival_time',
          messageBn: 'PO arrival time, PO departure time-এর আগে হতে পারে না।',
          messageEn: 'PO arrival time cannot be earlier than PO departure time.',
        );
      }
      final poArrivalKey = _isYes(answers, 'cd1_po_first_destination')
          ? 'cd1_first_arrival_time'
          : 'cd1_po_arrival_time';
      if (_isYes(answers, 'cd1_clue_search')) {
        _validatePair(
          issues,
          answers,
          earlierKey: poArrivalKey,
          laterKey: 'cd1_clue_search_time',
          messageBn: 'Clue/evidence search time, PO arrival-এর আগে হতে পারে না।',
          messageEn: 'Clue/evidence search cannot be earlier than PO arrival.',
        );
      }
      if (_isYes(answers, 'cd1_local_witness_search')) {
        _validatePair(
          issues,
          answers,
          earlierKey: poArrivalKey,
          laterKey: 'cd1_local_witness_search_time',
          messageBn: 'Local witness search time, PO arrival-এর আগে হতে পারে না।',
          messageEn: 'Local witness search cannot be earlier than PO arrival.',
        );
      }
      _validatePair(
        issues,
        answers,
        earlierKey: poArrivalKey,
        laterKey: 'cd1_po_departure_from_spot_time',
        messageBn: 'PO থেকে departure time, PO arrival-এর আগে হতে পারে না।',
        messageEn: 'Departure from PO cannot be earlier than PO arrival.',
      );
      _validatePair(
        issues,
        answers,
        earlierKey: 'cd1_po_departure_from_spot_time',
        laterKey: 'cd1_return_time',
        messageBn: 'PS return time, PO থেকে departure-এর আগে হতে পারে না।',
        messageEn: 'PS return time cannot be earlier than departure from PO.',
      );

      if (_isYes(answers, 'cd1_sketch_index')) {
        final requiredMapFields = <String, String>{
          'cd1_po_exact': 'Exact PO',
          'cd1_po_north': 'North boundary',
          'cd1_po_south': 'South boundary',
          'cd1_po_east': 'East boundary',
          'cd1_po_west': 'West boundary',
        };
        for (final field in requiredMapFields.entries) {
          if (_answer(answers, field.key).isEmpty) {
            issues.add(CdValidationIssue(
              severity: CdValidationSeverity.error,
              messageBn: 'Auto Sketch Map-এর জন্য ${field.value} দেওয়া বাধ্যতামূলক।',
              messageEn: '${field.value} is required for Auto Sketch Map.',
              questionIds: <String>['cd1_sketch_index', field.key],
            ));
          }
        }
      }
    }

    if (_isYes(answers, 'cd1_complainant_examined') &&
        _isYes(answers, 'cd1_complainant_statement_recorded')) {
      if (_answer(answers, 'cd1_complainant_statement').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn:
              'Complainant-এর u/s 180 BNSS statement recorded বলা হয়েছে, কিন্তু statement body লেখা হয়নি।',
          messageEn:
              'The complainant statement is marked as recorded, but the statement body is blank.',
          questionIds: <String>['cd1_complainant_statement'],
        ));
      }
      if (_answer(answers, 'cd1_complainant_identity_details').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.warning,
          messageBn:
              'Complainant statement তৈরি হবে, কিন্তু statement header-এর পরিচয়/ঠিকানা অসম্পূর্ণ।',
          messageEn:
              'A complainant statement will be created, but identity/address details for the statement header are blank.',
          questionIds: <String>['cd1_complainant_identity_details'],
        ));
      }
    }

    if (_isYes(answers, 'cd1_victim_contacted') &&
        _isYes(answers, 'cd1_victim_statement_recorded')) {
      if (_answer(answers, 'cd1_victim_name').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Victim/VG statement record করা হয়েছে, কিন্তু নাম দেওয়া হয়নি।',
          messageEn: 'Victim/VG statement is marked as recorded, but the name is blank.',
          questionIds: <String>['cd1_victim_name'],
        ));
      }
      if (_answer(answers, 'cd1_victim_statement_body').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Victim/VG statement record করা হয়েছে, কিন্তু statement body দেওয়া হয়নি।',
          messageEn: 'Victim/VG statement is marked as recorded, but the statement body is blank.',
          questionIds: <String>['cd1_victim_statement_body'],
        ));
      }
    }

    if (_isYes(answers, 'cd1_accused_interrogated') &&
        _answer(answers, 'cd1_accused_interrogation_details').isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.warning,
        messageBn:
            'Accused interrogation করা হয়েছে, কিন্তু material disclosure লেখা হয়নি।',
        messageEn:
            'Accused interrogation is marked, but material disclosure is blank.',
        questionIds: <String>['cd1_accused_interrogation_details'],
      ));
    }

    final start = _minutes(_answer(answers, 'cd1_fir_receive_time'));
    final initialEventKeys = <String>[
      'cd1_departure_time',
      'cd1_first_arrival_time',
      'cd1_complainant_exam_time',
      'cd1_existing_seizure_time',
      'cd1_accused_interrogation_time',
      'cd1_victim_time',
      'cd1_po_departure_time',
      'cd1_po_arrival_time',
      'cd1_clue_search_time',
      'cd1_local_witness_search_time',
      'cd1_po_departure_from_spot_time',
    ];
    if (start != null) {
      for (final key in initialEventKeys) {
        final value = _minutes(_answer(answers, key));
        if (value != null && value < start) {
          issues.add(CdValidationIssue(
            severity: CdValidationSeverity.error,
            messageBn:
                'একটি investigation event FIR/complaint receive/peruse time-এর আগে দেওয়া হয়েছে। Time sequence ঠিক করুন।',
            messageEn:
                'An investigation event is timed before FIR/complaint receipt/perusal. Correct the time sequence.',
            questionIds: <String>['cd1_fir_receive_time', key],
          ));
          break;
        }
      }
    }

    _validateWitnessBatch(
      issues,
      raw: _answer(answers, 'cd1_witness_entries_json'),
      questionId: 'cd1_witness_entries_json',
      required: false,
      earliestMinutes: _minutes(_answer(answers, 'cd1_fir_receive_time')),
      closingMinutes: _minutes(_answer(answers, 'cd1_return_time')),
    );

    final closing = _minutes(_answer(answers, 'cd1_return_time'));
    if (closing != null) {
      final eventKeys = <String>[
        'cd1_fir_receive_time',
        'cd1_departure_time',
        'cd1_first_arrival_time',
        'cd1_complainant_exam_time',
        'cd1_existing_seizure_time',
        'cd1_accused_interrogation_time',
        'cd1_victim_time',
        'cd1_po_departure_time',
        'cd1_po_arrival_time',
        'cd1_clue_search_time',
        'cd1_local_witness_search_time',
        'cd1_po_departure_from_spot_time',
      ];
      _validateNoEventAfterClosing(
        issues,
        answers,
        eventKeys: eventKeys,
        closingKey: 'cd1_return_time',
        closingMinutes: closing,
      );
    }

    return issues;
  }

  List<CdValidationIssue> _validateContinuation(
    Map<String, String> answers,
  ) {
    final issues = <CdValidationIssue>[];
    final actions = _selectedActions(answers);

    if (actions.isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn: 'আজকের CD-র জন্য অন্তত একটি investigation action নির্বাচন করুন।',
        messageEn: 'Select at least one investigation action for today\'s CD.',
        questionIds: <String>['today_actions'],
      ));
      return issues;
    }

    if (actions.contains(CdWorkflowService.actionPoVisit)) {
      _validatePair(
        issues,
        answers,
        earlierKey: 'po_departure_time',
        laterKey: 'po_visit_time',
        messageBn: 'PO arrival time, PO departure time-এর আগে হতে পারে না।',
        messageEn: 'PO arrival time cannot be earlier than PO departure time.',
      );
    
      if (_isYes(answers, 'po_clue_search')) {
        _validatePair(
          issues,
          answers,
          earlierKey: 'po_visit_time',
          laterKey: 'po_clue_search_time',
          messageBn: 'Clue/evidence search time, PO arrival-এর আগে হতে পারে না।',
          messageEn: 'Clue/evidence search cannot be earlier than PO arrival.',
        );
      }
      if (_isYes(answers, 'po_local_witness_search')) {
        _validatePair(
          issues,
          answers,
          earlierKey: 'po_visit_time',
          laterKey: 'po_local_witness_search_time',
          messageBn: 'Local witness search time, PO arrival-এর আগে হতে পারে না।',
          messageEn: 'Local witness search cannot be earlier than PO arrival.',
        );
      }
      _validatePair(
        issues,
        answers,
        earlierKey: 'po_visit_time',
        laterKey: 'po_departure_from_spot_time',
        messageBn: 'PO থেকে departure time, PO arrival-এর আগে হতে পারে না।',
        messageEn: 'Departure from PO cannot be earlier than PO arrival.',
      );

      if (_isYes(answers, 'po_sketch_index')) {
        final requiredMapFields = <String, String>{
          'po_exact': 'Exact PO',
          'po_north': 'North boundary',
          'po_south': 'South boundary',
          'po_east': 'East boundary',
          'po_west': 'West boundary',
        };
        for (final field in requiredMapFields.entries) {
          if (_answer(answers, field.key).isEmpty) {
            issues.add(CdValidationIssue(
              severity: CdValidationSeverity.error,
              messageBn: 'Auto Sketch Map-এর জন্য ${field.value} দেওয়া বাধ্যতামূলক।',
              messageEn: '${field.value} is required for Auto Sketch Map.',
              questionIds: <String>['po_sketch_index', field.key],
            ));
          }
        }
      }
    }

    if (actions.contains(CdWorkflowService.actionRaidSearch)) {
      _validatePair(
        issues,
        answers,
        earlierKey: 'raid_departure',
        laterKey: 'raid_arrival_time',
        messageBn: 'Raid/search arrival time, departure time-এর আগে হতে পারে না।',
        messageEn: 'Raid/search arrival time cannot be earlier than departure time.',
      );
    }

    if (actions.contains(CdWorkflowService.actionCourtProduction)) {
      _validatePair(
        issues,
        answers,
        earlierKey: 'court_departure_time',
        laterKey: 'court_arrival_time',
        messageBn: 'Court/JJB arrival time, departure time-এর আগে হতে পারে না।',
        messageEn: 'Court/JJB arrival time cannot be earlier than departure time.',
      );
    }

    if (actions.contains(CdWorkflowService.actionMedicalExamination)) {
      _validatePair(
        issues,
        answers,
        earlierKey: 'medical_departure_time',
        laterKey: 'medical_arrival_time',
        messageBn: 'Medical/MLE arrival time, departure time-এর আগে হতে পারে না।',
        messageEn: 'Medical/MLE arrival time cannot be earlier than departure time.',
      );
      _validatePair(
        issues,
        answers,
        earlierKey: 'medical_arrival_time',
        laterKey: 'medical_completion_time',
        messageBn: 'Medical completion/report collection time, hospital arrival-এর আগে হতে পারে না।',
        messageEn:
            'Medical completion/report collection cannot be earlier than hospital arrival.',
      );
    }

    if (actions.contains(CdWorkflowService.actionInjuryMedicalPapers)) {
      _validatePair(
        issues,
        answers,
        earlierKey: 'injury_doc_departure_time',
        laterKey: 'injury_doc_arrival_time',
        messageBn: 'Hospital arrival time, PS departure time-এর আগে হতে পারে না।',
        messageEn: 'Hospital arrival time cannot be earlier than PS departure time.',
      );
      _validatePair(
        issues,
        answers,
        earlierKey: 'injury_doc_arrival_time',
        laterKey: 'injury_doc_action_time',
        messageBn: 'Medical paper requisition/collection time, Hospital arrival-এর আগে হতে পারে না।',
        messageEn: 'Medical-paper requisition/collection time cannot be earlier than hospital arrival.',
      );
      _validatePair(
        issues,
        answers,
        earlierKey: 'injury_doc_action_time',
        laterKey: 'injury_doc_departure_hospital_time',
        messageBn: 'Hospital departure time, medical-paper action time-এর আগে হতে পারে না।',
        messageEn: 'Hospital departure cannot be earlier than the medical-paper action.',
      );
      _validatePair(
        issues,
        answers,
        earlierKey: 'injury_doc_departure_hospital_time',
        laterKey: 'injury_doc_return_ps_time',
        messageBn: 'PS return time, Hospital departure-এর আগে হতে পারে না।',
        messageEn: 'PS return cannot be earlier than hospital departure.',
      );
      if (_answer(answers, 'injury_doc_hospital').isEmpty ||
          _answer(answers, 'injury_doc_step').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Medical papers action-এর জন্য Hospital এবং requisition/collection step দুটোই লিখুন।',
          messageEn: 'Hospital and requisition/collection step are required for the medical-papers action.',
          questionIds: <String>['injury_doc_hospital', 'injury_doc_step'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionVehicleDriverVerification)) {
      if (_answer(answers, 'vehicle_number').isEmpty ||
          _answer(answers, 'vehicle_owner_driver_status').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Vehicle/driver verification-এর জন্য offending vehicle number এবং owner/actual driver verification status লিখুন।',
          messageEn: 'Offending vehicle number and owner/actual-driver verification status are required.',
          questionIds: <String>['vehicle_number', 'vehicle_owner_driver_status'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionPcInterrogation) &&
        _isYes(answers, 'pc_leading_to_recovery') &&
        !actions.contains(CdWorkflowService.actionRaidSearch) &&
        !actions.contains(CdWorkflowService.actionRecoverySeizure)) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.warning,
        messageBn:
            'PC interrogation-এ recovery/raid leading statement বলা হয়েছে, কিন্তু আজ Raid/Search বা Recovery/Seizure action নির্বাচন করা হয়নি। যদি action আজই হয়ে থাকে, সেটি যোগ করুন।',
        messageEn:
            'PC interrogation is marked as leading to raid/recovery, but neither Raid/Search nor Recovery/Seizure is selected for today.',
        questionIds: <String>[
          'pc_leading_to_recovery',
          'today_actions',
        ],
      ));
    }

    if (actions.contains(CdWorkflowService.actionRecoverySeizure)) {
      if (_answer(answers, 'recovery_article').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn:
              'Recovery/Seizure নির্বাচন করা হয়েছে, কিন্তু recovered/seized article-এর description দেওয়া হয়নি।',
          messageEn:
              'Recovery/Seizure is selected, but recovered/seized article description is blank.',
          questionIds: <String>['recovery_article'],
        ));
      }
      if (_answer(answers, 'recovery_basis').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.warning,
          messageBn:
              'Recovery কীভাবে/কার দেখানো মতে/কোন production-এর ভিত্তিতে হয়েছে তা লেখা হয়নি।',
          messageEn:
              'The basis of recovery/showing/production has not been entered.',
          questionIds: <String>['recovery_basis'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionCourtProduction)) {
      if (_answer(answers, 'court_name_person').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn:
              'Court/JJB action নির্বাচন করা হয়েছে, কিন্তু Court/JJB ও produced person-এর particulars নেই।',
          messageEn:
              'Court/JJB action is selected, but Court/JJB and produced person particulars are blank.',
          questionIds: <String>['court_name_person'],
        ));
      }
      if (_answer(answers, 'court_prayer_order').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.warning,
          messageBn:
              'Court prayer/order details লেখা হয়নি। Order না হয়ে থাকলে সেই factual অবস্থাই লিখুন।',
          messageEn:
              'Court prayer/order details are blank. Record the factual status if no order was passed.',
          questionIds: <String>['court_prayer_order'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionMedicalExamination) &&
        _answer(answers, 'medical_person_hospital').isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn:
            'Medical/MLE action নির্বাচন করা হয়েছে, কিন্তু person/hospital/prayer-order details নেই।',
        messageEn:
            'Medical/MLE action is selected, but person/hospital/prayer-order details are blank.',
        questionIds: <String>['medical_person_hospital'],
      ));
    }

    if (actions.contains(CdWorkflowService.actionWitnessExamination)) {
      final batch = MultiWitnessBatch.decode(_answer(answers, 'witness_entries_json'));
      if (batch.entries.isNotEmpty) {
        _validateWitnessBatch(
          issues,
          raw: _answer(answers, 'witness_entries_json'),
          questionId: 'witness_entries_json',
          required: true,
          closingMinutes: _minutes(_answer(answers, 'continuation_return_time')),
        );
      } else if (_answer(answers, 'witness_name').isNotEmpty) {
        // Backward compatibility for pre-v203 saved drafts.
        if (_isYes(answers, 'witness_statement_recorded') &&
            _answer(answers, 'witness_statement_material').isEmpty) {
          issues.add(const CdValidationIssue(
            severity: CdValidationSeverity.error,
            messageBn:
                'Witness-এর u/s 180 BNSS statement recorded বলা হয়েছে, কিন্তু statement body লেখা হয়নি।',
            messageEn:
                'The witness statement is marked as recorded, but the statement body is blank.',
            questionIds: <String>['witness_statement_material'],
          ));
        }
      } else {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness examination action নির্বাচন করা হয়েছে, কিন্তু কোনো witness যোগ করা হয়নি।',
          messageEn: 'Witness examination is selected, but no witness has been added.',
          questionIds: <String>['witness_entries_json'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionVictimExamination) &&
        _isYes(answers, 'victim_statement_recorded')) {
      if (_answer(answers, 'victim_name').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Victim/VG statement record করা হয়েছে, কিন্তু নাম দেওয়া হয়নি।',
          messageEn: 'Victim/VG statement is marked as recorded, but the name is blank.',
          questionIds: <String>['victim_name'],
        ));
      }
      if (_answer(answers, 'victim_statement_body').isEmpty) {
        issues.add(const CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Victim/VG statement record করা হয়েছে, কিন্তু statement body দেওয়া হয়নি।',
          messageEn: 'Victim/VG statement is marked as recorded, but the statement body is blank.',
          questionIds: <String>['victim_statement_body'],
        ));
      }
    }

    if (actions.contains(CdWorkflowService.actionJudicialStatement) &&
        _answer(answers, 'js_person_court').isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn:
            'Judicial statement action নির্বাচন করা হয়েছে, কিন্তু person ও Court details নেই।',
        messageEn:
            'Judicial statement action is selected, but person and Court details are blank.',
        questionIds: <String>['js_person_court'],
      ));
    }

    final closing = _minutes(_answer(answers, 'continuation_return_time'));
    if (closing != null) {
      _validateNoEventAfterClosing(
        issues,
        answers,
        eventKeys: _continuationTimeKeysFor(actions),
        closingKey: 'continuation_return_time',
        closingMinutes: closing,
      );
    }

    return issues;
  }

  List<CdValidationIssue> _validateFinalisation(
    Map<String, String> answers,
  ) {
    final issues = <CdValidationIssue>[];
    final sections = _answer(answers, 'final_sections');
    final accused = _answer(answers, 'final_accused_status');
    final summary = _answer(answers, 'final_investigation_summary');

    if (sections.isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn: 'Final established sections উল্লেখ করা আবশ্যক।',
        messageEn: 'Final established sections are required.',
        questionIds: <String>['final_sections'],
      ));
    }
    if (accused.isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn: 'Charge-sheeted accused ও present status উল্লেখ করা আবশ্যক।',
        messageEn: 'Charge-sheeted accused and present status are required.',
        questionIds: <String>['final_accused_status'],
      ));
    }
    if (summary.isEmpty) {
      issues.add(const CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn: 'Final investigation/evidence summary খালি রাখা যাবে না।',
        messageEn: 'Final investigation/evidence summary cannot be blank.',
        questionIds: <String>['final_investigation_summary'],
      ));
    }
    return issues;
  }

  List<String> _continuationTimeKeysFor(Set<String> actions) {
    final result = <String>[];
    void add(String action, List<String> keys) {
      if (actions.contains(action)) result.addAll(keys);
    }

    add(CdWorkflowService.actionPcInterrogation, <String>['pc_time']);
    add(CdWorkflowService.actionVictimExamination, <String>['victim_time']);
    add(CdWorkflowService.actionPoVisit, <String>[
      'po_departure_time',
      'po_visit_time',
      'po_clue_search_time',
      'po_local_witness_search_time',
      'po_departure_from_spot_time',
    ]);
    add(CdWorkflowService.actionRaidSearch,
        <String>['raid_departure', 'raid_arrival_time']);
    add(CdWorkflowService.actionRecoverySeizure, <String>['recovery_time']);
    add(CdWorkflowService.actionArrest, <String>['arrest_time']);
    add(CdWorkflowService.actionCourtProduction,
        <String>['court_departure_time', 'court_arrival_time']);
    add(CdWorkflowService.actionJudicialStatement, <String>['js_time']);
    add(CdWorkflowService.actionMedicalExamination, <String>[
      'medical_departure_time',
      'medical_arrival_time',
      'medical_completion_time',
    ]);
    add(CdWorkflowService.actionReportDocument, <String>['report_document_time']);
    add(CdWorkflowService.actionRequisition, <String>['requisition_time']);
    add(CdWorkflowService.actionDigitalEvidence, <String>['digital_time']);
    add(CdWorkflowService.actionLocalEnquiry, <String>['local_enquiry_time']);
    add(CdWorkflowService.actionNotice, <String>['notice_time']);
    add(CdWorkflowService.actionExpertReport, <String>['expert_time']);
    add(CdWorkflowService.actionAgeProof, <String>['age_proof_time']);
    add(CdWorkflowService.actionSanction, <String>['sanction_time']);
    add(CdWorkflowService.actionMoe, <String>['moe_time']);
    add(CdWorkflowService.actionInjuryMedicalPapers, <String>[
      'injury_doc_departure_time',
      'injury_doc_arrival_time',
      'injury_doc_action_time',
      'injury_doc_departure_hospital_time',
      'injury_doc_return_ps_time',
    ]);
    add(CdWorkflowService.actionVehicleDriverVerification, <String>['vehicle_verify_time']);
    add(CdWorkflowService.actionOther, <String>['other_time']);
    return result;
  }

  void _validateWitnessBatch(
    List<CdValidationIssue> issues, {
    required String raw,
    required String questionId,
    required bool required,
    int? earliestMinutes,
    int? closingMinutes,
  }) {
    final batch = MultiWitnessBatch.decode(raw);
    if (batch.entries.isEmpty) {
      if (required) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'কমপক্ষে একজন witness যোগ করুন।',
          messageEn: 'Add at least one witness.',
          questionIds: <String>[questionId],
        ));
      }
      return;
    }

    final seenNames = <String>{};
    for (var i = 0; i < batch.entries.length; i++) {
      final entry = batch.entries[i];
      final number = i + 1;
      final name = entry.witnessName.trim();
      final normalizedName = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর নাম দেওয়া হয়নি।',
          messageEn: 'Witness #$number has no name.',
          questionIds: <String>[questionId],
        ));
      } else if (!seenNames.add(normalizedName)) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.warning,
          messageBn: 'একই witness name একাধিকবার যোগ করা হয়েছে: $name. Duplicate কিনা যাচাই করুন।',
          messageEn: 'The same witness name appears more than once: $name. Verify whether it is a duplicate.',
          questionIds: <String>[questionId],
        ));
      }

      if (entry.recordedTime.trim().isEmpty) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর examination time দেওয়া হয়নি।',
          messageEn: 'Witness #$number has no examination time.',
          questionIds: <String>[questionId],
        ));
      }
      if (entry.recordedPlace.trim().isEmpty) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর examination place দেওয়া হয়নি।',
          messageEn: 'Witness #$number has no examination place.',
          questionIds: <String>[questionId],
        ));
      }
      if (entry.statementRecorded && entry.statementBody.trim().isEmpty) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর statement recorded বলা হয়েছে, কিন্তু statement body খালি।',
          messageEn: 'Witness #$number is marked as statement recorded, but the statement body is blank.',
          questionIds: <String>[questionId],
        ));
      }
      if (entry.statementRecorded && entry.witnessDetails.trim().isEmpty) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.warning,
          messageBn: 'Witness #$number-এর statement header-এর পরিচয়/ঠিকানা খালি।',
          messageEn: 'Witness #$number has no identity/address details for the statement header.',
          questionIds: <String>[questionId],
        ));
      }

      final minutes = _minutes(entry.recordedTime);
      if (minutes != null && earliestMinutes != null && minutes < earliestMinutes) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর examination time case diary start/FIR receive time-এর আগে।',
          messageEn: 'Witness #$number is timed before the diary/FIR receipt start time.',
          questionIds: <String>[questionId],
        ));
      }
      if (minutes != null && closingMinutes != null && minutes > closingMinutes) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn: 'Witness #$number-এর examination time CD closing time-এর পরে।',
          messageEn: 'Witness #$number is timed after the CD closing time.',
          questionIds: <String>[questionId],
        ));
      }
    }

    if (batch.mode == WitnessCdEntryMode.groupedSameSession &&
        batch.entries.length > 1) {
      final first = batch.entries.first;
      final firstTime = _minutes(first.recordedTime);
      final firstPlace = first.recordedPlace.trim().toLowerCase();
      for (final entry in batch.entries.skip(1)) {
        final sameTime = firstTime != null && _minutes(entry.recordedTime) == firstTime;
        final samePlace = firstPlace.isNotEmpty &&
            entry.recordedPlace.trim().toLowerCase() == firstPlace;
        if (!sameTime || !samePlace) {
          issues.add(CdValidationIssue(
            severity: CdValidationSeverity.error,
            messageBn: 'Grouped Same-Session mode-এ সব witness-এর examination time ও place একই হতে হবে। Separate mode নিন অথবা time/place মিলিয়ে দিন।',
            messageEn: 'Grouped Same-Session mode requires every witness to have the same examination time and place. Use Separate mode or align the session details.',
            questionIds: <String>[questionId],
          ));
          break;
        }
      }
    }
  }

  void _validatePair(
    List<CdValidationIssue> issues,
    Map<String, String> answers, {
    required String earlierKey,
    required String laterKey,
    required String messageBn,
    required String messageEn,
  }) {
    final earlier = _minutes(_answer(answers, earlierKey));
    final later = _minutes(_answer(answers, laterKey));
    if (earlier == null || later == null) return;
    if (later < earlier) {
      issues.add(CdValidationIssue(
        severity: CdValidationSeverity.error,
        messageBn: messageBn,
        messageEn: messageEn,
        questionIds: <String>[earlierKey, laterKey],
      ));
    }
  }

  void _validateNoEventAfterClosing(
    List<CdValidationIssue> issues,
    Map<String, String> answers, {
    required List<String> eventKeys,
    required String closingKey,
    required int closingMinutes,
  }) {
    for (final key in eventKeys) {
      final value = _minutes(_answer(answers, key));
      if (value != null && value > closingMinutes) {
        issues.add(CdValidationIssue(
          severity: CdValidationSeverity.error,
          messageBn:
              'একটি investigation event-এর time return/closing time-এর পরে দেওয়া হয়েছে। Time sequence ঠিক করুন।',
          messageEn:
              'An investigation event is timed after the return/closing time. Correct the time sequence.',
          questionIds: <String>[key, closingKey],
        ));
        break;
      }
    }
  }

  Set<String> _selectedActions(Map<String, String> answers) {
    final raw = _answer(answers, 'today_actions');
    if (raw.isEmpty) return <String>{};
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  bool _isYes(Map<String, String> answers, String key) =>
      _answer(answers, key).toLowerCase() == 'yes';

  String _answer(Map<String, String> answers, String key) =>
      (answers[key] ?? '').trim();

  int? _minutes(String raw) {
    final match = RegExp(r'(\d{1,2})[\.:](\d{2})').firstMatch(raw);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }
}
