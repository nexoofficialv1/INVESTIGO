import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/cd_workflow.dart';
import '../models/witness_examination_entry.dart';
import 'cd_workflow_service.dart';

class CdWorkflowDraftService {
  List<CdTableLine> buildTableLines({
    required CaseFile caseFile,
    required CdWorkflowPlan plan,
    required Map<String, String> answers,
    required String defaultPlace,
    CdEntry? previousCd,
  }) {
    switch (plan.phase) {
      case CdWorkflowPhase.initial:
        return _buildInitial(
          caseFile: caseFile,
          answers: answers,
          defaultPlace: defaultPlace,
        );
      case CdWorkflowPhase.continuation:
        return _buildContinuation(
          caseFile: caseFile,
          answers: answers,
          defaultPlace: defaultPlace,
          previousCd: previousCd,
        );
      case CdWorkflowPhase.finalisation:
        return _buildFinal(
          caseFile: caseFile,
          answers: answers,
          defaultPlace: defaultPlace,
          previousCd: previousCd,
        );
    }
  }

  List<CdTableLine> _buildInitial({
    required CaseFile caseFile,
    required Map<String, String> answers,
    required String defaultPlace,
  }) {
    final lines = <CdTableLine>[];
    final firTime = _answer(
      answers,
      'cd1_fir_receive_time',
      fallback: _nowTime(),
    );
    final dd = _answer(answers, 'cd1_departure_time', fallback: firTime);
    final da = _answer(answers, 'cd1_first_arrival_time', fallback: dd);
    final firstPlace = _answer(
      answers,
      'cd1_first_arrival_place',
      fallback: defaultPlace,
    );
    final ro = _answer(answers, 'cd1_ro', fallback: 'To be mentioned');
    final io = caseFile.investigationStart.ioName.trim().isEmpty
        ? 'To be mentioned'
        : caseFile.investigationStart.ioName.trim();
    final po = _answer(
      answers,
      'cd1_po_exact',
      fallback: caseFile.placeOfOccurrence.trim().isEmpty
          ? 'Not Mentioned'
          : caseFile.placeOfOccurrence.trim(),
    );
    final doText = caseFile.dateTimeOccurrence.trim().isEmpty
        ? 'Not Mentioned'
        : caseFile.dateTimeOccurrence.trim();
    final dr = caseFile.dateTimeReporting.trim().isEmpty
        ? 'Not Mentioned'
        : caseFile.dateTimeReporting.trim();

    final opening = <String>[
      'PO: -$po.',
      'DO: -$doText.',
      'DR: -$dr.',
      'DD: -On ${caseFile.caseDate} at $dd.',
      'DA: -On ${caseFile.caseDate} at $da.',
      'RO: -$ro.',
      'IO: -$io.',
      if (_isYes(answers, 'cd1_fir_received'))
        'By this marginally noted time I received copy of FIR along with the complaint through PS serestha. I perused the same.'
      else
        'By this marginally noted time I took up investigation of the above noted case.',
      if (caseFile.firGist.trim().isNotEmpty)
        'The gist of the FIR/complaint is that ${caseFile.firGist.trim()}',
      'Over the complaint the above noted case was started and on being endorsed I took up its investigation.',
    ].join('\n');

    _add(
      lines,
      time: firTime,
      place: defaultPlace,
      synopsis: 'Received copy of FIR\n+\nGist',
      proceedings: opening,
    );

    final poFirstDestination = _isYes(answers, 'cd1_po_first_destination');
    final poDept = poFirstDestination
        ? dd
        : _answer(answers, 'cd1_po_departure_time');
    final poArrival = poFirstDestination
        ? da
        : _answer(answers, 'cd1_po_arrival_time');
    final poIsFirstJourney = _isYes(answers, 'cd1_left_for_po') &&
        poFirstDestination &&
        _samePlace(firstPlace, po);

    if (!poIsFirstJourney) {
      _add(
        lines,
        time: dd,
        place: defaultPlace,
        synopsis: 'Dept',
        proceedings:
            'This time I along with force left PS for investigation of the case.',
      );
      _add(
        lines,
        time: da,
        place: firstPlace,
        synopsis: 'Arrival',
        proceedings:
            'By this marginally noted time I along with force arrived at $firstPlace for investigation of the case.',
      );
    }

    if (_isYes(answers, 'cd1_complainant_examined')) {
      final recorded = _isYes(answers, 'cd1_complainant_statement_recorded');
      _add(
        lines,
        time: _answer(
          answers,
          'cd1_complainant_exam_time',
          fallback: da,
        ),
        place: _answer(answers, 'cd1_complainant_exam_place', fallback: defaultPlace),
        synopsis: recorded
            ? 'Examine complainant\n+\nStatement record'
            : 'Examine complainant',
        proceedings: recorded
            ? 'I examined the complainant ${caseFile.complainantName.trim()} and recorded the statement u/s-180 BNSS in a separate sheet of paper which is kept with the case diary.'
            : 'I examined the complainant ${caseFile.complainantName.trim()} in connection with the case.',
      );
    }

    if (_isYes(answers, 'cd1_existing_seizure')) {
      final detail = _answer(answers, 'cd1_existing_seizure_details');
      _add(
        lines,
        time: _answer(
          answers,
          'cd1_existing_seizure_time',
          fallback: da,
        ),
        place: firstPlace,
        synopsis: 'Seizure verification\n+\nNote',
        proceedings:
            'I received and verified the seizure list/seized article/document produced with the case papers.${_detailSuffix(detail)}',
      );
    }

    if (_isYes(answers, 'cd1_accused_available')) {
      final interrogated = _isYes(answers, 'cd1_accused_interrogated');
      final detail = _answer(answers, 'cd1_accused_interrogation_details');
      _add(
        lines,
        time: interrogated
            ? _answer(
                answers,
                'cd1_accused_interrogation_time',
                fallback: da,
              )
            : da,
        place: firstPlace,
        synopsis: interrogated
            ? 'Accused interrogation'
            : 'Accused custody\n+\nNote',
        proceedings: interrogated
            ? 'I interrogated the available arrested/apprehended accused person and recorded the material facts disclosed during interrogation.${_detailSuffix(detail)}'
            : 'The arrested/apprehended accused person was available during investigation and necessary legal formalities were observed.',
      );
    }

    final policeWitnesses = _answer(answers, 'cd1_police_witnesses');
    if (policeWitnesses.isNotEmpty) {
      _add(
        lines,
        time: da,
        place: firstPlace,
        synopsis: 'Police personnel / witnesses',
        proceedings:
            'The following police personnel/witnesses were present or associated with the raid/search/seizure during investigation. Details: $policeWitnesses',
      );
    }

    _addWitnessBatchLines(
      lines,
      raw: _answer(answers, 'cd1_witness_entries_json'),
      fallbackPlace: firstPlace,
    );

    if (_isYes(answers, 'cd1_victim_contacted')) {
      final recorded = _isYes(answers, 'cd1_victim_statement_recorded');
      final victimName = _answer(
        answers,
        'cd1_victim_name',
        fallback: caseFile.victimName,
      );
      final note = _answer(answers, 'cd1_victim_exam_note');
      _add(
        lines,
        time: _answer(answers, 'cd1_victim_time', fallback: da),
        place: _answer(answers, 'cd1_victim_place', fallback: firstPlace),
        synopsis: recorded
            ? 'Examine Victim/VG\n+\nStatement record'
            : 'Examine Victim/VG',
        proceedings: recorded
            ? 'The Victim/VG${victimName.isEmpty ? '' : ' namely- $victimName'} was examined during investigation and the statement u/s-180 BNSS was recorded in a separate sheet of paper which is kept with the case diary.${_detailSuffix(note)}'
            : 'The Victim/VG${victimName.isEmpty ? '' : ' namely- $victimName'} was contacted/examined during investigation.${_detailSuffix(note)}',
      );
    }

    if (_isYes(answers, 'cd1_left_for_po')) {
      final dept = poDept.isEmpty ? dd : poDept;
      final arrival = poArrival.isEmpty ? da : poArrival;
      _add(
        lines,
        time: dept,
        place: defaultPlace,
        synopsis: 'Dept\nfor PO',
        proceedings:
            'Myself along with force left PS for visiting the place of occurrence and further investigation of the case.',
      );

      final shownBy = _answer(answers, 'cd1_po_shown_by');
      final surroundings = <String>[
        if (_answer(answers, 'cd1_po_north').isNotEmpty)
          'North: ${_answer(answers, 'cd1_po_north')}.',
        if (_answer(answers, 'cd1_po_south').isNotEmpty)
          'South: ${_answer(answers, 'cd1_po_south')}.',
        if (_answer(answers, 'cd1_po_east').isNotEmpty)
          'East: ${_answer(answers, 'cd1_po_east')}.',
        if (_answer(answers, 'cd1_po_west').isNotEmpty)
          'West: ${_answer(answers, 'cd1_po_west')}.',
      ];
      final poNarrative = <String>[
        'I arrived at the PO at $po.',
        if (shownBy.isNotEmpty) 'The PO was shown/identified by $shownBy.',
        if (_isYes(answers, 'cd1_sketch_index'))
          'I visited the PO thoroughly and prepared rough sketch map of the PO with its index in separate sheets of paper, which are kept with the case diary.',
        if (surroundings.isNotEmpty)
          'The surrounding of the PO is as follows:-\n${surroundings.join('\n')}',
      ].join('\n');
      _add(
        lines,
        time: arrival,
        place: po,
        synopsis: _isYes(answers, 'cd1_sketch_index')
            ? 'Arrival\n+\nPO Visit\n+\nSketch Map\n+\nIndex'
            : 'Arrival\n+\nPO Visit',
        proceedings: poNarrative,
      );

      if (_isYes(answers, 'cd1_clue_search')) {
        _add(
          lines,
          time: _answer(answers, 'cd1_clue_search_time', fallback: arrival),
          place: po,
          synopsis: 'Search for clue/evidence',
          proceedings:
              'I searched the PO and its surroundings for clue/evidence.${_detailSuffix(_answer(answers, 'cd1_clue_search_result'))}',
        );
      }
      if (_isYes(answers, 'cd1_local_witness_search')) {
        _add(
          lines,
          time: _answer(
            answers,
            'cd1_local_witness_search_time',
            fallback: arrival,
          ),
          place: po,
          synopsis: 'Local enquiry\n+\nWitness search',
          proceedings:
              'I held local enquiry and searched for local witnesses in and around the PO.${_detailSuffix(_answer(answers, 'cd1_local_witness_result'))}',
        );
      }
      _add(
        lines,
        time: _answer(
          answers,
          'cd1_po_departure_from_spot_time',
          fallback: arrival,
        ),
        place: po,
        synopsis: 'Dept\nfrom PO',
        proceedings:
            'After taking necessary steps at the PO, I along with force left the place of occurrence for PS.',
      );
    }

    lines.sort(_compareByTime);

    final returnTime = _answer(answers, 'cd1_return_time', fallback: _nowTime());
    _add(
      lines,
      time: returnTime,
      place: defaultPlace,
      synopsis: 'Return\n+\nClosing',
      proceedings:
          'Returned to PS after investigation of the case. Closed the diary pending for further investigation of this case.',
    );
    return _renumber(lines);
  }

  List<CdTableLine> _buildContinuation({
    required CaseFile caseFile,
    required Map<String, String> answers,
    required String defaultPlace,
    CdEntry? previousCd,
  }) {
    final actionLines = <CdTableLine>[];
    final actions = _selectedActions(answers);
    for (final action in actions) {
      actionLines.addAll(
        _linesForAction(
          action: action,
          answers: answers,
          caseFile: caseFile,
          defaultPlace: defaultPlace,
        ),
      );
    }
    actionLines.sort(_compareByTime);

    final openingTime = actionLines.isEmpty
        ? _answer(
            answers,
            'continuation_return_time',
            fallback: _nowTime(),
          )
        : _cleanTime(actionLines.first.noAndHour);
    final previousText = previousCd == null
        ? ''
        : 'CD No-${_roman(previousCd.cdNumber)} dtd-${previousCd.cdDate} has duly been submitted by me.\n';

    final lines = <CdTableLine>[];
    final canMergeDeparture = actionLines.isNotEmpty &&
        _isDepartureSynopsis(actionLines.first.synopsis) &&
        _samePlace(actionLines.first.placeOfEntry, defaultPlace);

    if (canMergeDeparture) {
      final first = actionLines.removeAt(0);
      _add(
        lines,
        time: openingTime,
        place: defaultPlace,
        synopsis: 'R/I\n+\n${first.synopsis}',
        proceedings:
            '${previousText}Resumed further investigation of the case.\n${first.proceedings}',
      );
    } else {
      _add(
        lines,
        time: openingTime,
        place: defaultPlace,
        synopsis: 'R/I',
        proceedings:
            '${previousText}Resumed further investigation of the case.',
      );
    }

    lines.addAll(actionLines);

    final returnTime = _answer(
      answers,
      'continuation_return_time',
      fallback: _nowTime(),
    );
    final alreadyAtPs = actionLines.isNotEmpty &&
        _samePlace(actionLines.last.placeOfEntry, defaultPlace);
    _add(
      lines,
      time: returnTime,
      place: defaultPlace,
      synopsis: alreadyAtPs ? 'Closing' : 'Return\n+\nClosing',
      proceedings: alreadyAtPs
          ? 'Closed the diary pending for further investigation of this case.'
          : 'Returned to PS after investigation of the case. Closed the diary pending for further investigation of this case.',
    );
    return _renumber(lines);
  }

  List<CdTableLine> _linesForAction({
    required String action,
    required Map<String, String> answers,
    required CaseFile caseFile,
    required String defaultPlace,
  }) {
    final result = <CdTableLine>[];

    void add({
      required String time,
      required String place,
      required String synopsis,
      required String proceedings,
    }) {
      _add(
        result,
        time: time,
        place: place,
        synopsis: synopsis,
        proceedings: proceedings,
      );
    }

    switch (action) {
      case CdWorkflowService.actionPcInterrogation:
        final identity = _answer(answers, 'pc_accused_name');
        final material = _answer(answers, 'pc_interrogation_material');
        final leading = _isYes(answers, 'pc_leading_to_recovery');
        add(
          time: _answer(answers, 'pc_time', fallback: _nowTime()),
          place: _answer(answers, 'pc_place', fallback: defaultPlace),
          synopsis: 'PC accused\ninterrogation',
          proceedings:
              'I interrogated the PC accused person${identity.isEmpty ? '' : ' namely- $identity'}. ${material.isEmpty ? '' : 'During interrogation the following material facts surfaced: $material.'}${leading ? ' The disclosure disclosed a lead for raid/recovery and necessary steps were taken accordingly.' : ''}',
        );
        break;

      case CdWorkflowService.actionWitnessExamination:
        _addWitnessBatchLines(
          result,
          raw: _answer(answers, 'witness_entries_json'),
          fallbackPlace: defaultPlace,
        );
        // Backward compatibility for a pre-v203 saved draft.
        if (result.isEmpty && _answer(answers, 'witness_name').isNotEmpty) {
          final name = _answer(answers, 'witness_name');
          final role = _answer(answers, 'witness_role');
          final recorded = _isYes(answers, 'witness_statement_recorded');
          add(
            time: _answer(answers, 'witness_time', fallback: _nowTime()),
            place: _answer(answers, 'witness_place', fallback: defaultPlace),
            synopsis: recorded
                ? 'Exam & recorded\nu/s-180 BNSS'
                : 'Witness examination',
            proceedings: recorded
                ? 'I examined the witness namely- $name${role.isEmpty ? '' : ' ($role)'} and recorded the statement u/s-180 BNSS in a separate sheet of paper which is kept with the case diary.'
                : 'I examined the witness namely- $name${role.isEmpty ? '' : ' ($role)'} in connection with the case.',
          );
        }
        break;

      case CdWorkflowService.actionVictimExamination:
        final name = _answer(answers, 'victim_name', fallback: caseFile.victimName);
        final by = _answer(answers, 'victim_examined_by');
        final note = _answer(answers, 'victim_exam_note');
        final recorded = _isYes(answers, 'victim_statement_recorded');
        add(
          time: _answer(answers, 'victim_time', fallback: _nowTime()),
          place: _answer(answers, 'victim_place', fallback: defaultPlace),
          synopsis: recorded
              ? 'Victim/VG\nexamination + statement'
              : 'Victim/VG\nexamination',
          proceedings: recorded
              ? 'The Victim/VG${name.isEmpty ? '' : ' namely- $name'} was examined during investigation${by.isEmpty ? '' : ' by $by'} and the statement u/s-180 BNSS was recorded in a separate sheet of paper which is kept with the case diary.${_detailSuffix(note)}'
              : 'The Victim/VG${name.isEmpty ? '' : ' namely- $name'} was examined/contacted during investigation${by.isEmpty ? '' : ' by $by'}.${_detailSuffix(note)}',
        );
        break;

      case CdWorkflowService.actionPoVisit:
        final po = _answer(
          answers,
          'po_exact',
          fallback: caseFile.placeOfOccurrence.trim().isEmpty
              ? defaultPlace
              : caseFile.placeOfOccurrence.trim(),
        );
        add(
          time: _answer(answers, 'po_departure_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Dept\nfor PO',
          proceedings:
              'Myself along with force left PS for visiting the place of occurrence and further investigation of the case.',
        );
        final shownBy = _answer(answers, 'po_shown_by');
        final surroundings = <String>[
          if (_answer(answers, 'po_north').isNotEmpty)
            'North: ${_answer(answers, 'po_north')}.',
          if (_answer(answers, 'po_south').isNotEmpty)
            'South: ${_answer(answers, 'po_south')}.',
          if (_answer(answers, 'po_east').isNotEmpty)
            'East: ${_answer(answers, 'po_east')}.',
          if (_answer(answers, 'po_west').isNotEmpty)
            'West: ${_answer(answers, 'po_west')}.',
        ];
        final narrative = <String>[
          'I arrived at the PO at $po and visited the place thoroughly.',
          if (shownBy.isNotEmpty) 'The PO was shown/identified by $shownBy.',
          if (_isYes(answers, 'po_sketch_index'))
            'I prepared rough sketch map of the PO with its index in separate sheets of paper, which are kept with the case diary.',
          if (surroundings.isNotEmpty)
            'The surrounding of the PO is as follows:-\n${surroundings.join('\n')}',
        ].join('\n');
        add(
          time: _answer(answers, 'po_visit_time', fallback: _nowTime()),
          place: po,
          synopsis: _isYes(answers, 'po_sketch_index')
              ? 'Arrival\n+\nPO Visit\n+\nSketch Map\n+\nIndex'
              : 'Arrival\n+\nPO Visit',
          proceedings: narrative,
        );
        if (_isYes(answers, 'po_clue_search')) {
          add(
            time: _answer(
              answers,
              'po_clue_search_time',
              fallback: _answer(answers, 'po_visit_time', fallback: _nowTime()),
            ),
            place: po,
            synopsis: 'Search for clue/evidence',
            proceedings:
                'I searched the PO and its surroundings for clue/evidence.${_detailSuffix(_answer(answers, 'po_clue_search_result'))}',
          );
        }
        if (_isYes(answers, 'po_local_witness_search')) {
          add(
            time: _answer(
              answers,
              'po_local_witness_search_time',
              fallback: _answer(answers, 'po_visit_time', fallback: _nowTime()),
            ),
            place: po,
            synopsis: 'Local enquiry\n+\nWitness search',
            proceedings:
                'I held local enquiry and searched for local witnesses in and around the PO.${_detailSuffix(_answer(answers, 'po_local_witness_result'))}',
          );
        }
        add(
          time: _answer(
            answers,
            'po_departure_from_spot_time',
            fallback: _answer(answers, 'po_visit_time', fallback: _nowTime()),
          ),
          place: po,
          synopsis: 'Dept\nfrom PO',
          proceedings:
              'After taking necessary steps at the PO, I along with force left the place of occurrence for PS/further investigation.',
        );
        break;

      case CdWorkflowService.actionRaidSearch:
        final place = _answer(answers, 'raid_place', fallback: defaultPlace);
        add(
          time: _answer(answers, 'raid_departure', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Dept\n+\nRaid/Search',
          proceedings:
              'Myself along with force left PS for holding raid/search in connection with the case.',
        );
        add(
          time: _answer(answers, 'raid_arrival_time', fallback: _nowTime()),
          place: place,
          synopsis: 'Arrival\n+\nRaid/Search',
          proceedings:
              'Arrived at the raid/search place and conducted raid/search in connection with the case.${_detailSuffix(_answer(answers, 'raid_place_force_result'))}',
        );
        break;

      case CdWorkflowService.actionRecoverySeizure:
        final basis = _answer(answers, 'recovery_basis');
        final article = _answer(answers, 'recovery_article');
        final witnessCustody = _answer(answers, 'recovery_witness_custody');
        add(
          time: _answer(answers, 'recovery_time', fallback: _nowTime()),
          place: _answer(answers, 'recovery_place', fallback: defaultPlace),
          synopsis: 'Recovery\n+\nSeizure',
          proceedings:
              'During investigation recovery was made${basis.isEmpty ? '' : ' on the basis of $basis'}. ${article.isEmpty ? '' : 'The following article/document was recovered/seized under proper seizure list: $article.'} ${witnessCustody.isEmpty ? '' : 'Seizure witness/custody details: $witnessCustody.'}',
        );
        break;

      case CdWorkflowService.actionArrest:
        final identity = _answer(answers, 'arrest_identity_time');
        final formalities = _answer(answers, 'arrest_formalities');
        add(
          time: _answer(answers, 'arrest_time', fallback: _nowTime()),
          place: _answer(answers, 'arrest_place', fallback: defaultPlace),
          synopsis: 'Arrest\n+\nLegal formalities',
          proceedings:
              'I arrested/apprehended the accused person after observing all legal formalities.${_detailSuffix(identity)}${formalities.isEmpty ? '' : ' Formalities/custody: $formalities'}',
        );
        break;

      case CdWorkflowService.actionCourtProduction:
        final person = _answer(answers, 'court_name_person');
        final order = _answer(answers, 'court_prayer_order');
        final courtPlace = _answer(answers, 'court_place', fallback: _courtPlaceFrom(person, defaultPlace));
        add(
          time: _answer(answers, 'court_departure_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Dept\nfor Court/JJB',
          proceedings:
              'Myself along with force/concerned person left PS for the concerned Court/JJB in connection with the case.',
        );
        add(
          time: _answer(answers, 'court_arrival_time', fallback: _nowTime()),
          place: courtPlace,
          synopsis: 'Arrival\n+\nProduction\n+\nPrayer/Order',
          proceedings:
              'Arrived at the concerned Court/JJB and took necessary steps regarding production/prayer in connection with the case.${_detailSuffix(person)}${order.isEmpty ? '' : ' Prayer/order details: $order'}',
        );
        break;

      case CdWorkflowService.actionJudicialStatement:
        final detail = _answer(answers, 'js_person_court');
        final copy = _isYes(answers, 'js_copy_collected');
        add(
          time: _answer(answers, 'js_time', fallback: _nowTime()),
          place: _answer(answers, 'js_place', fallback: _courtPlaceFrom(detail, defaultPlace)),
          synopsis: 'Judicial statement\nu/s-183 BNSS',
          proceedings:
              'Necessary prayer/production was made for recording judicial statement u/s-183 BNSS.${_detailSuffix(detail)}${copy ? ' The copy of the judicial statement was collected, perused and kept with the CD.' : ''}',
        );
        break;

      case CdWorkflowService.actionMedicalExamination:
        final detail = _answer(answers, 'medical_person_hospital');
        final material = _answer(answers, 'medical_report_result');
        final place = _answer(
          answers,
          'medical_place',
          fallback: _placeFromText(detail, defaultPlace),
        );
        add(
          time: _answer(answers, 'medical_departure_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Dept\nfor Medical/MLE',
          proceedings:
              'Myself along with force/concerned person left for medical/medico-legal examination in connection with the case.',
        );
        add(
          time: _answer(answers, 'medical_arrival_time', fallback: _nowTime()),
          place: place,
          synopsis: 'Arrival\n+\nSubmitted prayer\n+\nProduced',
          proceedings:
              'Arrived at the medical facility and submitted necessary prayer/produced the concerned person for medical/medico-legal examination.${_detailSuffix(detail)}',
        );
        add(
          time: _answer(
            answers,
            'medical_completion_time',
            fallback: _answer(answers, 'medical_arrival_time', fallback: _nowTime()),
          ),
          place: place,
          synopsis: 'Medical complete\n+\nReport collected',
          proceedings:
              'After completion of medical/medico-legal examination, the relevant report/material was received/perused and kept with the case diary.${_detailSuffix(material)}',
        );
        break;

      case CdWorkflowService.actionReportDocument:
        final identity = _answer(answers, 'report_document_identity');
        final material = _answer(answers, 'report_document_material');
        add(
          time: _answer(answers, 'report_document_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Received document\n+\nPerused',
          proceedings:
              'I received and perused the relevant report/order/document and kept the same with the case diary.${_detailSuffix(identity)}${material.isEmpty ? '' : ' Material finding: $material'}',
        );
        break;

      case CdWorkflowService.actionRequisition:
        add(
          time: _answer(answers, 'requisition_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Requisition/Prayer',
          proceedings:
              'I sent/submitted requisition/prayer for the purpose of investigation.${_detailSuffix(_answer(answers, 'requisition_to_purpose'))}',
        );
        break;

      case CdWorkflowService.actionDigitalEvidence:
        final source = _answer(answers, 'digital_source_details');
        final finding = _answer(answers, 'digital_material_finding');
        add(
          time: _answer(answers, 'digital_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Digital evidence\n+\nAnalysis',
          proceedings:
              'I collected/took steps regarding electronic/digital evidence in connection with the case.${_detailSuffix(source)}${finding.isEmpty ? '' : ' Analysis revealed: $finding'}',
        );
        break;

      case CdWorkflowService.actionLocalEnquiry:
        final placePersons = _answer(answers, 'local_enquiry_place_persons');
        final factual = _answer(answers, 'local_enquiry_result');
        add(
          time: _answer(answers, 'local_enquiry_time', fallback: _nowTime()),
          place: _placeFromText(placePersons, defaultPlace),
          synopsis: 'Local enquiry\n+\nVerification',
          proceedings:
              'I conducted local enquiry/verification in connection with the case.${_detailSuffix(placePersons)}${factual.isEmpty ? '' : ' Factual result: $factual'}',
        );
        break;

      case CdWorkflowService.actionNotice:
        add(
          time: _answer(answers, 'notice_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Notice\n+\nService',
          proceedings:
              'Necessary notice was issued/served in connection with the investigation.${_detailSuffix(_answer(answers, 'notice_details'))}',
        );
        break;

      case CdWorkflowService.actionExpertReport:
        add(
          time: _answer(answers, 'expert_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Expert report\n+\nPerused',
          proceedings:
              'I received/perused the relevant FSL/Arms Expert/Scientific report.${_detailSuffix(_answer(answers, 'expert_report_details'))}',
        );
        break;

      case CdWorkflowService.actionAgeProof:
        final detail = _answer(answers, 'age_proof_details');
        final seizure = _answer(answers, 'age_proof_seizure_zimma');
        add(
          time: _answer(answers, 'age_proof_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Age proof\n+\nSeizure/Zimma',
          proceedings:
              'I collected/verified the age-proof document during investigation.${_detailSuffix(detail)}${seizure.isEmpty ? '' : ' Seizure/zimma details: $seizure'}',
        );
        break;

      case CdWorkflowService.actionSanction:
        add(
          time: _answer(answers, 'sanction_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Sanction\n+\nPrayer/Order',
          proceedings:
              'Necessary steps were taken regarding statutory sanction in connection with the case.${_detailSuffix(_answer(answers, 'sanction_prayer_details'))}',
        );
        break;

      case CdWorkflowService.actionMoe:
        final sections = _answer(answers, 'moe_sections_accused');
        final direction = _answer(answers, 'moe_superior_direction');
        add(
          time: _answer(answers, 'moe_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Submitted MOE\n+\nSuperior direction',
          proceedings:
              'I submitted Memo of Evidence before my superior officer through proper channel for necessary direction/permission.${_detailSuffix(sections)}${direction.isEmpty ? '' : ' Superior direction/permission: $direction'}',
        );
        break;

      case CdWorkflowService.actionInjuryMedicalPapers:
        final hospital =
            _answer(answers, 'injury_doc_hospital', fallback: defaultPlace);
        final step = _answer(answers, 'injury_doc_step');
        final collected = _isYes(answers, 'injury_doc_collected');
        final resultText = _answer(answers, 'injury_doc_result');
        add(
          time: _answer(
            answers,
            'injury_doc_departure_time',
            fallback: _nowTime(),
          ),
          place: defaultPlace,
          synopsis: 'Dept\nfor Medical papers',
          proceedings:
              'Myself along with force left PS for $hospital for taking necessary steps regarding Injury Report/BHT/medical papers of the injured person in connection with the case.',
        );
        add(
          time: _answer(
            answers,
            'injury_doc_arrival_time',
            fallback: _nowTime(),
          ),
          place: hospital,
          synopsis: 'Arrival\n+\nMedical enquiry',
          proceedings:
              'I arrived at $hospital and made necessary enquiry regarding the treatment and medical documents of the injured person in connection with the case.',
        );
        add(
          time: _answer(
            answers,
            'injury_doc_action_time',
            fallback: _nowTime(),
          ),
          place: hospital,
          synopsis: collected
              ? 'Medical papers\ncollected/perused'
              : 'Requisition\nfor Medical papers',
          proceedings: collected
              ? 'I took necessary steps regarding the medical documents. $step${resultText.isEmpty ? '' : ' On perusal, the material medical finding is: $resultText'}'
              : 'I took necessary steps regarding the medical documents. $step The relevant Injury Report/BHT/medical papers are awaited.',
        );
        add(
          time: _answer(
            answers,
            'injury_doc_departure_hospital_time',
            fallback: _nowTime(),
          ),
          place: hospital,
          synopsis: 'Dept\nfrom Hospital',
          proceedings:
              'After taking necessary steps regarding the medical papers, I left $hospital for PS.',
        );
        add(
          time: _answer(
            answers,
            'injury_doc_return_ps_time',
            fallback: _nowTime(),
          ),
          place: defaultPlace,
          synopsis: 'Return\nto PS',
          proceedings:
              'I returned to PS after taking necessary steps regarding the medical documents of the injured person.',
        );
        break;

      case CdWorkflowService.actionVehicleDriverVerification:
        final number = _answer(answers, 'vehicle_number');
        final status = _answer(answers, 'vehicle_owner_driver_status');
        final found = _isYes(answers, 'vehicle_found');
        final step = _answer(answers, 'vehicle_step_taken');
        add(
          time: _answer(answers, 'vehicle_verify_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Offending vehicle\n+\nDriver verification',
          proceedings:
              'I took further steps to verify the offending vehicle${number.isEmpty ? '' : ' bearing Registration No. $number'} and to ascertain the registered owner and the actual driver who was driving the vehicle at the relevant time. ${status.isEmpty ? '' : 'Verification status: $status.'} ${found ? 'The offending vehicle was traced/found during investigation.' : 'The offending vehicle could not be traced/found at this stage.'}${step.isEmpty ? '' : ' Further step taken: $step'}',
        );
        break;

      case CdWorkflowService.actionOther:
        add(
          time: _answer(answers, 'other_time', fallback: _nowTime()),
          place: defaultPlace,
          synopsis: 'Important development',
          proceedings: _answer(answers, 'other_investigation_details'),
        );
        break;
    }

    return result;
  }

  bool _isDepartureSynopsis(String synopsis) {
    final lower = synopsis.toLowerCase();
    return lower.startsWith('dept') || lower.contains('\ndep');
  }

  bool _samePlace(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  bool _sameTime(String a, String b) {
    final left = _timeMinutes(a);
    final right = _timeMinutes(b);
    return left != null && right != null && left == right;
  }

  String _courtPlaceFrom(String text, String fallback) {
    final value = text.trim();
    if (value.isEmpty) return fallback;
    final lower = value.toLowerCase();
    if (lower.contains('court') || lower.contains('jjb')) return value;
    return fallback;
  }

  String _placeFromText(String text, String fallback) {
    final value = text.trim();
    return value.isEmpty ? fallback : value;
  }

  int _compareByTime(CdTableLine a, CdTableLine b) {
    final left = _timeMinutes(_cleanTime(a.noAndHour));
    final right = _timeMinutes(_cleanTime(b.noAndHour));
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  String _cleanTime(String raw) {
    return raw
        .split(RegExp(r'\s+'))
        .where((part) => !RegExp(r'^[IVX]+$').hasMatch(part))
        .join(' ')
        .trim();
  }

  int? _timeMinutes(String raw) {
    final match = RegExp(r'(\d{1,2})[\.:](\d{2})').firstMatch(raw);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  void _addWitnessBatchLines(
    List<CdTableLine> lines, {
    required String raw,
    required String fallbackPlace,
  }) {
    final batch = MultiWitnessBatch.decode(raw);
    if (batch.entries.isEmpty) return;

    if (batch.mode == WitnessCdEntryMode.groupedSameSession &&
        batch.entries.length > 1) {
      final first = batch.entries.first;
      final allRecorded = batch.entries.every((e) => e.statementRecorded);
      final anyRecorded = batch.entries.any((e) => e.statementRecorded);
      final listed = <String>[];
      for (var i = 0; i < batch.entries.length; i++) {
        final entry = batch.entries[i];
        final role = entry.role.trim();
        final status = entry.statementRecorded
            ? 'statement u/s-180 BNSS recorded in separate sheet'
            : 'examined; no separate statement sheet marked';
        listed.add(
          '(${i + 1}) ${entry.witnessName.trim()}${role.isEmpty ? '' : ' ($role)'} — $status${entry.examinationNote.trim().isEmpty ? '' : '; ${entry.examinationNote.trim()}'}',
        );
      }
      final opening = allRecorded
          ? 'I examined the below noted witnesses and recorded their statements u/s-180 BNSS in separate sheets of paper, which are kept with the case diary.'
          : anyRecorded
              ? 'I examined the below noted witnesses during investigation. Separate u/s-180 BNSS statement sheets were recorded for the witnesses marked below.'
              : 'I examined the below noted witnesses during investigation.';
      _add(
        lines,
        time: first.recordedTime.trim().isEmpty
            ? _nowTime()
            : first.recordedTime.trim(),
        place: first.recordedPlace.trim().isEmpty
            ? fallbackPlace
            : first.recordedPlace.trim(),
        synopsis: allRecorded
            ? 'Exam witnesses\n+\nu/s-180 BNSS'
            : 'Witness examination',
        proceedings: '$opening\n${listed.join('\n')}',
      );
      return;
    }

    for (final entry in batch.entries) {
      final name = entry.witnessName.trim();
      if (name.isEmpty) continue;
      final role = entry.role.trim();
      final note = entry.examinationNote.trim();
      _add(
        lines,
        time: entry.recordedTime.trim().isEmpty
            ? _nowTime()
            : entry.recordedTime.trim(),
        place: entry.recordedPlace.trim().isEmpty
            ? fallbackPlace
            : entry.recordedPlace.trim(),
        synopsis: entry.statementRecorded
            ? 'Exam & recorded\nu/s-180 BNSS'
            : 'Witness examination',
        proceedings: entry.statementRecorded
            ? 'I examined the witness namely- $name${role.isEmpty ? '' : ' ($role)'} and recorded the statement u/s-180 BNSS in a separate sheet of paper which is kept with the case diary.${note.isEmpty ? '' : ' $note'}'
            : 'I examined the witness namely- $name${role.isEmpty ? '' : ' ($role)'} in connection with the case.${note.isEmpty ? '' : ' $note'}',
      );
    }
  }

  List<CdTableLine> _buildFinal({
    required CaseFile caseFile,
    required Map<String, String> answers,
    required String defaultPlace,
    CdEntry? previousCd,
  }) {
    final lines = <CdTableLine>[];
    final time = _nowTime();
    final previousText = previousCd == null
        ? ''
        : 'CD No-${_roman(previousCd.cdNumber)} dtd-${previousCd.cdDate} has duly been submitted by me.\n';
    _add(
      lines,
      time: time,
      place: defaultPlace,
      synopsis: 'R/I\n+\nSuperior order',
      proceedings:
          '${previousText}Resumed further investigation of the case.\nThis time I received/acted upon the superior order/permission for submission of Charge Sheet. ${_answer(answers, 'final_superior_order')}',
    );

    final summary = _answer(answers, 'final_investigation_summary');
    _add(
      lines,
      time: time,
      place: defaultPlace,
      synopsis: 'Investigation note\n+\nEvidence',
      proceedings:
          'During investigation the material investigation steps and relied-upon evidence were as follows: $summary',
    );

    final sections = _answer(answers, 'final_sections');
    final accused = _answer(answers, 'final_accused_status');
    _add(
      lines,
      time: time,
      place: defaultPlace,
      synopsis: 'Prima facie charge\n+\nCS submitted',
      proceedings:
          'From the statements of witnesses and other evidence collected during investigation, prima facie charge under $sections has been established against the charge-sheeted accused person/persons. Accused particulars/status: $accused. Hence, after consulting with my superior officers I have submitted Charge Sheet ${_answer(answers, 'final_cs_number_date')} under $sections to face trial in the open Court of law.${_isYes(answers, 'final_supplementary_provision') ? ' Provision is kept to submit supplementary charge sheet/report if further clue/evidence is obtained in future.' : ''}',
    );

    final witnesses = _answer(answers, 'final_witnesses');
    _add(
      lines,
      time: time,
      place: defaultPlace,
      synopsis: 'Witness list',
      proceedings:
          'The following witnesses will prove the charge and during trial they may kindly be summoned: $witnesses',
    );

    final informed = _isYes(answers, 'final_complainant_informed');
    _add(
      lines,
      time: time,
      place: defaultPlace,
      synopsis: 'Result informed\n+\nClosing',
      proceedings:
          '${informed ? 'The complainant/informant is being informed about the result of investigation. ' : ''}Closed the diary as well as investigation of the case.',
    );
    return _renumber(lines);
  }

  List<CdTableLine> _renumber(List<CdTableLine> lines) {
    return List<CdTableLine>.generate(lines.length, (index) {
      final line = lines[index];
      final roman = _roman(index + 1);
      final raw = line.noAndHour.trim();
      return CdTableLine(
        noAndHour: raw.isEmpty ? roman : '$roman\n$raw',
        placeOfEntry: line.placeOfEntry,
        synopsis: line.synopsis,
        proceedings: line.proceedings,
      );
    });
  }

  void _add(
    List<CdTableLine> lines, {
    required String time,
    required String place,
    required String synopsis,
    required String proceedings,
  }) {
    if (proceedings.trim().isEmpty) return;
    lines.add(CdTableLine(
      noAndHour: time.trim(),
      placeOfEntry: place.trim(),
      synopsis: synopsis.trim(),
      proceedings: proceedings.trim(),
    ));
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

  String _firstUsefulTime(Map<String, String> answers) {
    const keys = <String>[
      'po_visit_time',
      'raid_departure',
      'continuation_return_time',
    ];
    for (final key in keys) {
      final value = _answer(answers, key);
      if (value.isNotEmpty) return value;
    }
    return _nowTime();
  }

  bool _isYes(Map<String, String> answers, String key) =>
      _answer(answers, key).toLowerCase() == 'yes';

  String _answer(
    Map<String, String> answers,
    String key, {
    String fallback = '',
  }) {
    final value = (answers[key] ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  String _detailSuffix(String detail) =>
      detail.trim().isEmpty ? '' : ' Details: ${detail.trim()}';

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} hrs.';
  }

  String _roman(int value) {
    const romans = <int, String>{
      1: 'I',
      2: 'II',
      3: 'III',
      4: 'IV',
      5: 'V',
      6: 'VI',
      7: 'VII',
      8: 'VIII',
      9: 'IX',
      10: 'X',
      11: 'XI',
      12: 'XII',
      13: 'XIII',
      14: 'XIV',
      15: 'XV',
      16: 'XVI',
      17: 'XVII',
      18: 'XVIII',
      19: 'XIX',
      20: 'XX',
    };
    return romans[value] ?? value.toString();
  }
}
