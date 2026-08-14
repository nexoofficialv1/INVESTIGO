import 'dart:async';

import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/cd_workflow.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../models/statement_entry.dart';
import '../models/witness_examination_entry.dart';
import '../models/sketch_map.dart';
import '../services/cd_workflow_draft_service.dart';
import '../services/cd_workflow_service.dart';
import '../services/cd_workflow_validation_service.dart';
import '../services/local_store_service.dart';
import '../services/linked_statement_store_service.dart';
import '../services/sketch_map_auto_service.dart';
import '../services/statement_link_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/investigo_ui.dart';
import 'auto_sketch_map_validation_screen.dart';
import 'cd_editor_screen.dart';
import 'legal_reference_screen.dart';

class CdBuilderScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CdBuilderScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<CdBuilderScreen> createState() => _CdBuilderScreenState();
}

class _CdBuilderScreenState extends State<CdBuilderScreen> {
  final LocalStoreService _store = LocalStoreService();
  final CdWorkflowService _workflow = CdWorkflowService();
  final CdWorkflowDraftService _draftService = CdWorkflowDraftService();
  final CdWorkflowValidationService _validator = CdWorkflowValidationService();
  final SketchMapAutoService _sketchAuto = SketchMapAutoService();
  final StatementLinkService _statementLink = StatementLinkService();
  final LinkedStatementStoreService _linkedStatementStore = LinkedStatementStoreService();

  Timer? _sketchDebounce;
  SketchMapEntry? _sketchMap;
  SketchMapApprovalRecord? _sketchApproval;
  bool _autoSketchGenerating = false;

  final Map<String, String> _answers = <String, String>{};
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Set<String> _selectedActions = <String>{};
  final Set<String> _selectedPendingActionIds = <String>{};

  int? _cdNumber;
  String _selectedCdDate =
      DateTime.now().toIso8601String().split('T').first;
  bool _finalisationRequested = false;
  bool _loading = true;
  int _simpleStepIndex = 0;
  List<CdEntry> _previousCds = <CdEntry>[];
  List<PendingCdAction> _pendingActions = <PendingCdAction>[];
  Set<String> _completedActions = <String>{};

  @override
  void initState() {
    super.initState();
    _loadWorkflowState();
  }

  @override
  void dispose() {
    _sketchDebounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadWorkflowState() async {
    final cds = await _store.loadCds(widget.caseFile.id);
    final pending = await _store.loadPendingCdActions(widget.caseFile.id);
    final next = cds.isEmpty
        ? 1
        : cds.map((e) => e.cdNumber).reduce((a, b) => a > b ? a : b) + 1;
    final completed = _inferCompletedActions(cds);
    final sketch = await _store.loadSketchMap(widget.caseFile.id);
    final sketchApproval = await _sketchAuto.loadApproval(widget.caseFile.id);
    if (widget.caseFile.placeOfOccurrence.trim().isNotEmpty) {
      _answers.putIfAbsent('cd1_po_exact', () => widget.caseFile.placeOfOccurrence.trim());
      _answers.putIfAbsent('po_exact', () => widget.caseFile.placeOfOccurrence.trim());
    }
    if (widget.caseFile.victimName.trim().isNotEmpty) {
      _answers.putIfAbsent('cd1_victim_name', () => widget.caseFile.victimName.trim());
      _answers.putIfAbsent('victim_name', () => widget.caseFile.victimName.trim());
    }

    if (!mounted) return;
    setState(() {
      _previousCds = cds;
      _pendingActions = pending;
      _selectedPendingActionIds.addAll(pending.map((e) => e.id));
      _cdNumber = next;
      _completedActions = completed;
      _sketchMap = sketch;
      _sketchApproval = sketchApproval;
      _loading = false;
    });
  }

  CdWorkflowPlan get _plan {
    final number = _cdNumber ?? 1;
    return _workflow.buildPlan(
      caseFile: widget.caseFile,
      cdNumber: number,
      completedActions: _completedActions,
      pendingActions: const <String>{},
      hasVictim: widget.caseFile.victimName.trim().isNotEmpty,
      hasArrestedAccused: _hasPreviousText('arrest'),
      hasPcAccused: _hasPreviousText('pc accused') ||
          _hasPreviousText('police custody'),
      finalisationRequested: _finalisationRequested,
    );
  }

  bool _hasPreviousText(String needle) {
    final lowerNeedle = needle.toLowerCase();
    for (final cd in _previousCds) {
      if (cd.body.toLowerCase().contains(lowerNeedle)) return true;
      for (final line in cd.tableLines) {
        if (line.synopsis.toLowerCase().contains(lowerNeedle) ||
            line.proceedings.toLowerCase().contains(lowerNeedle)) {
          return true;
        }
      }
    }
    return false;
  }

  Set<String> _inferCompletedActions(List<CdEntry> cds) {
    final result = <String>{};
    final text = cds
        .expand((cd) => <String>[
              cd.body,
              ...cd.tableLines.map((e) => '${e.synopsis} ${e.proceedings}'),
            ])
        .join(' ')
        .toLowerCase();

    void mark(String id, List<String> needles) {
      if (needles.any(text.contains)) result.add(id);
    }

    mark(CdWorkflowService.actionWitnessExamination,
        <String>['examined witness', 'examine witnesses', 'witness examination', 'exam & recorded']);
    mark(CdWorkflowService.actionVictimExamination,
        <String>['victim/vg', 'examine vg', 'victim examination']);
    mark(CdWorkflowService.actionPoVisit,
        <String>['po visit', 'place of occurrence', 'rough sketch map']);
    mark(CdWorkflowService.actionRecoverySeizure,
        <String>['recovery', 'recovered', 'seizure']);
    mark(CdWorkflowService.actionArrest,
        <String>['arrested accused', 'arrest memo']);
    mark(CdWorkflowService.actionCourtProduction,
        <String>['court production', 'produced before the ld', 'produced the']);
    mark(CdWorkflowService.actionJudicialStatement,
        <String>['judicial statement', 'u/s-183 bnss']);
    mark(CdWorkflowService.actionMedicalExamination,
        <String>['medico legal', 'medical examination', 'bht']);
    mark(CdWorkflowService.actionDigitalEvidence,
        <String>['cdr', 'electronic evidence', 'cctv']);
    mark(CdWorkflowService.actionExpertReport,
        <String>['arms expert', 'fsl', 'scientific report']);
    mark(CdWorkflowService.actionAgeProof,
        <String>['birth certificate', 'age proof']);
    mark(CdWorkflowService.actionMoe,
        <String>['memo of evidence', 'submitted moe']);
    mark(CdWorkflowService.actionInjuryMedicalPapers,
        <String>['injury report/bht', 'medical papers are awaited', 'medical papers collected/perused']);
    mark(CdWorkflowService.actionVehicleDriverVerification,
        <String>['verify the offending vehicle', 'driver verification', 'registered owner and the actual driver']);
    return result;
  }

  bool _isVisible(CdWorkflowQuestion question) {
    final dep = question.dependency;
    if (dep == null) return true;
    final raw = (_answers[dep.questionId] ?? '').trim();
    if (dep.equalsValue != null) return raw == dep.equalsValue;
    if (dep.containsValue != null) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .contains(dep.containsValue);
    }
    return true;
  }

  TextEditingController _controllerFor(CdWorkflowQuestion question) {
    return _controllers.putIfAbsent(
      question.id,
      () => TextEditingController(text: _answers[question.id] ?? ''),
    );
  }

  void _setAnswer(String id, String value) {
    setState(() {
      _answers[id] = value;
      final controller = _controllers[id];
      if (controller != null && controller.text != value) {
        controller.text = value;
      }

      if (id == 'cd1_complainant_examined' && value == 'yes') {
        final place = (_answers['cd1_complainant_exam_place'] ?? '').trim();
        if (place.isEmpty && widget.profile.policeStation.trim().isNotEmpty) {
          _answers['cd1_complainant_exam_place'] = widget.profile.policeStation.trim();
          _controllers['cd1_complainant_exam_place']?.text = widget.profile.policeStation.trim();
        }
      }

      if (id == 'cd1_po_first_destination' && value == 'yes') {
        final exactPo = (_answers['cd1_po_exact'] ?? widget.caseFile.placeOfOccurrence).trim();
        if (exactPo.isNotEmpty) {
          _answers['cd1_first_arrival_place'] = exactPo;
          _controllers['cd1_first_arrival_place']?.text = exactPo;
        }
      }
    });
    if (id == 'cd1_sketch_index' || id == 'po_sketch_index' || id == 'cd1_left_for_po') {
      _scheduleAutoSketch();
    }
  }

  bool get _sketchRequested {
    final number = _cdNumber ?? 1;
    if (number == 1) {
      return (_answers['cd1_left_for_po'] ?? '') == 'yes' &&
          (_answers['cd1_sketch_index'] ?? '') == 'yes';
    }
    return _selectedActions.contains(CdWorkflowService.actionPoVisit) &&
        (_answers['po_sketch_index'] ?? '') == 'yes';
  }

  String _sketchAnswer(String initialKey, String continuationKey) {
    return ((_cdNumber ?? 1) == 1
            ? _answers[initialKey]
            : _answers[continuationKey])
        ?.trim() ?? '';
  }

  String get _sketchExactPo => _sketchAnswer('cd1_po_exact', 'po_exact');
  String get _sketchNorth => _sketchAnswer('cd1_po_north', 'po_north');
  String get _sketchSouth => _sketchAnswer('cd1_po_south', 'po_south');
  String get _sketchEast => _sketchAnswer('cd1_po_east', 'po_east');
  String get _sketchWest => _sketchAnswer('cd1_po_west', 'po_west');

  bool get _hasCompleteSketchData =>
      _sketchExactPo.isNotEmpty &&
      _sketchNorth.isNotEmpty &&
      _sketchSouth.isNotEmpty &&
      _sketchEast.isNotEmpty &&
      _sketchWest.isNotEmpty;

  bool get _sketchApproved =>
      _sketchAuto.isApprovedFor(_sketchMap, _sketchApproval);

  bool get _sketchMatchesCurrentAnswers {
    final map = _sketchMap;
    if (map == null) return false;
    return map.poDescription.trim() == _sketchExactPo &&
        map.north.trim() == _sketchNorth &&
        map.south.trim() == _sketchSouth &&
        map.east.trim() == _sketchEast &&
        map.west.trim() == _sketchWest;
  }

  void _onTextAnswerChanged(String id, String value) {
    _answers[id] = value;
    if (id == 'cd1_po_exact' && (_answers['cd1_po_first_destination'] ?? '') == 'yes') {
      _answers['cd1_first_arrival_place'] = value.trim();
      _controllers['cd1_first_arrival_place']?.text = value.trim();
    }
    const sketchIds = <String>{
      'cd1_po_exact', 'cd1_po_north', 'cd1_po_south', 'cd1_po_east', 'cd1_po_west',
      'po_exact', 'po_north', 'po_south', 'po_east', 'po_west',
    };
    if (sketchIds.contains(id)) _scheduleAutoSketch();
  }

  void _scheduleAutoSketch() {
    _sketchDebounce?.cancel();
    if (!_sketchRequested || !_hasCompleteSketchData || _sketchApproved) return;
    _sketchDebounce = Timer(const Duration(milliseconds: 750), () {
      if (mounted && (_sketchMap == null || _sketchMap!.objects.isEmpty)) {
        _createAutoSketch();
      }
    });
  }

  Future<void> _createAutoSketch({bool force = false}) async {
    if (_autoSketchGenerating || !_sketchRequested || !_hasCompleteSketchData) return;
    if (!force && _sketchMap != null && _sketchMap!.objects.isNotEmpty) return;
    setState(() => _autoSketchGenerating = true);
    try {
      final map = _sketchAuto.generateDraft(
        caseId: widget.caseFile.id,
        sourceCdNumber: _cdNumber ?? 1,
        exactPo: _sketchExactPo,
        north: _sketchNorth,
        south: _sketchSouth,
        east: _sketchEast,
        west: _sketchWest,
        date: _selectedCdDate,
      );
      await _store.saveSketchMap(map);
      await _sketchAuto.invalidate(widget.caseFile.id);
      if (!mounted) return;
      setState(() {
        _sketchMap = map;
        _sketchApproval = null;
      });
    } finally {
      if (mounted) setState(() => _autoSketchGenerating = false);
    }
  }

  Future<void> _refreshSketchState() async {
    final map = await _store.loadSketchMap(widget.caseFile.id);
    final approval = await _sketchAuto.loadApproval(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _sketchMap = map;
      _sketchApproval = approval;
    });
  }

  Future<void> _openSketchValidation({bool forceRegenerate = false}) async {
    if (!_hasCompleteSketchData) {
      _showMissing('Exact PO এবং North/South/East/West পূরণ করুন।');
      return;
    }
    if (forceRegenerate || _sketchMap == null || !_sketchMatchesCurrentAnswers) {
      await _createAutoSketch(force: true);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutoSketchMapValidationScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          sourceCdNumber: _cdNumber ?? 1,
          exactPo: _sketchExactPo,
          north: _sketchNorth,
          south: _sketchSouth,
          east: _sketchEast,
          west: _sketchWest,
        ),
      ),
    );
    await _refreshSketchState();
  }

  Future<bool> _ensureSketchApproved() async {
    if (!_sketchRequested) return true;
    if (!_hasCompleteSketchData) {
      _showMissing('Auto Sketch Map-এর জন্য Exact PO এবং North/South/East/West পূরণ করুন।');
      return false;
    }
    if (_sketchMap == null || !_sketchMatchesCurrentAnswers) {
      await _createAutoSketch(force: true);
    }
    await _refreshSketchState();
    if (_sketchApproved) return true;
    if (!mounted) return false;
    await _openSketchValidation();
    await _refreshSketchState();
    return _sketchApproved;
  }

  Future<void> _pickTime(CdWorkflowQuestion question) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    _setAnswer(question.id, '$hour.$minute hrs.');
  }

  Future<void> _generate() async {
    final number = _cdNumber;
    if (number == null) return;

    final plan = _plan;
    final visibleQuestions =
        plan.questions.where(_isVisible).toList(growable: false);
    for (final q in visibleQuestions) {
      if (!q.required) continue;
      final value = (_answers[q.id] ?? '').trim();
      if (value.isEmpty) {
        _showMissing(q.titleBn);
        return;
      }
      if (q.type == CdQuestionType.multiChoice &&
          _selectedActions.isEmpty) {
        _showMissing(q.titleBn);
        return;
      }
    }

    if (plan.phase == CdWorkflowPhase.continuation &&
        _selectedActions.isEmpty) {
      _showMissing('আজ কী investigation করেছেন—কমপক্ষে একটি action বাছুন।');
      return;
    }

    _answers['today_actions'] = _selectedActions.join(',');

    if (!await _ensureSketchApproved()) return;

    final validationIssues = _validator.validate(
      plan: plan,
      answers: Map<String, String>.from(_answers),
    );
    if (validationIssues.isNotEmpty) {
      final proceed = await _showValidationIssues(validationIssues);
      if (!proceed) return;
    }

    final previous = _previousCds.isEmpty ? null : _previousCds.last;
    final generatedLines = _draftService.buildTableLines(
      caseFile: widget.caseFile,
      plan: plan,
      answers: Map<String, String>.from(_answers),
      defaultPlace: widget.profile.policeStation,
      previousCd: previous,
    );
    final selectedPending = _pendingActions
        .where((e) => _selectedPendingActionIds.contains(e.id))
        .toList(growable: false);
    final tableLines = _mergePendingActions(
      generatedLines: generatedLines,
      pending: selectedPending,
      fallbackPlace: widget.profile.policeStation,
    );
    final body = tableLines.map((e) => e.proceedings).join('\n\n');
    final firstTime = _extractTime(tableLines.first.noAndHour);
    final lastTime = _extractTime(tableLines.last.noAndHour);
    final draft = CdEntry.newDraft(
      caseId: widget.caseFile.id,
      cdNumber: number,
      body: body,
      placeOfEntry: widget.profile.policeStation,
      tableLines: tableLines,
      diaryDate: _selectedCdDate,
    ).copyWith(
      startTime: firstTime,
      endTime: lastTime,
      isFinal: plan.phase == CdWorkflowPhase.finalisation,
    );

    final linkedStatements = _statementLink.buildLinkedStatements(
      caseFile: widget.caseFile,
      profile: widget.profile,
      plan: plan,
      cdNumber: number,
      cdDate: draft.cdDate,
      answers: Map<String, String>.from(_answers),
    );

    // Sync statement sheets first. If the CD write fails, remove the just-created
    // linked sheets so an orphan statement is not left behind for this new CD.
    try {
      await _linkedStatementStore.replaceLinkedStatementsForCd(
        caseId: widget.caseFile.id,
        cdNumber: number,
        entries: linkedStatements,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked statement save failed: $error')),
      );
      return;
    }

    try {
      await _store.saveCd(draft);
    } catch (error) {
      // Best-effort rollback. This CD number has not been committed, so the
      // generated linked sheets for it must not survive independently.
      try {
        await _linkedStatementStore.replaceLinkedStatementsForCd(
          caseId: widget.caseFile.id,
          cdNumber: number,
          entries: const <StatementEntry>[],
        );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CD save failed: $error')),
      );
      return;
    }

    try {
      await _store.markPendingCdActionsConsumed(
        selectedPending.map((e) => e.id).toList(growable: false),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CD saved, but pending-form status could not be updated: $error',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CdEditorScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          cd: draft,
        ),
      ),
    );
  }

  void _showMissing(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('এই তথ্যটি পূরণ করুন: $title')),
    );
  }

  Future<bool> _showValidationIssues(
    List<CdValidationIssue> issues,
  ) async {
    final hasError = issues.any((e) => e.isError);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasError
            ? 'CD validation error'
            : 'CD validation warning'),
        content: SizedBox(
          width: 520,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: issues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final issue = issues[index];
              final icon = issue.isError ? Icons.error_outline : Icons.warning_amber;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(issue.messageBn),
                subtitle: Text(issue.messageEn),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(hasError ? 'ঠিক করি' : 'Cancel'),
          ),
          if (!hasError)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Warning জেনেও Continue'),
            ),
        ],
      ),
    );
    return result == true;
  }

  List<CdTableLine> _mergePendingActions({
    required List<CdTableLine> generatedLines,
    required List<PendingCdAction> pending,
    required String fallbackPlace,
  }) {
    if (pending.isEmpty || generatedLines.isEmpty) {
      return _renumber(generatedLines);
    }

    final opening = generatedLines.first;
    final closing = generatedLines.last;
    final middle = <CdTableLine>[
      if (generatedLines.length > 2)
        ...generatedLines.sublist(1, generatedLines.length - 1),
    ];

    for (final action in pending) {
      middle.add(CdTableLine(
        noAndHour: action.entryTime.trim().isEmpty
            ? _nowTime()
            : action.entryTime.trim(),
        placeOfEntry: action.placeOfEntry.trim().isEmpty
            ? fallbackPlace
            : action.placeOfEntry.trim(),
        synopsis: action.synopsis.trim().isEmpty
            ? action.title.trim()
            : action.synopsis.trim(),
        proceedings: action.paragraph.trim(),
      ));
    }

    middle.sort((a, b) {
      final left = _timeMinutes(_extractTime(a.noAndHour));
      final right = _timeMinutes(_extractTime(b.noAndHour));
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });

    return _renumber(<CdTableLine>[
      opening,
      ...middle,
      closing,
    ]);
  }

  List<CdTableLine> _renumber(List<CdTableLine> lines) {
    const romans = <String>[
      'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
      'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
    ];
    return List<CdTableLine>.generate(lines.length, (index) {
      final line = lines[index];
      final time = _extractTime(line.noAndHour);
      final roman = index < romans.length ? romans[index] : '${index + 1}';
      return CdTableLine(
        noAndHour: time.isEmpty ? roman : '$roman\n$time',
        placeOfEntry: line.placeOfEntry,
        synopsis: line.synopsis,
        proceedings: line.proceedings,
      );
    });
  }

  String _extractTime(String raw) {
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

  DateTime? _parseCdDate(String raw) {
    final value = raw.trim().split(' ').first;
    return DateTime.tryParse(value);
  }

  String _formatCdDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickCdDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final caseDate = _parseCdDate(widget.caseFile.caseDate);

    DateTime? lastCdDate;
    for (final cd in _previousCds) {
      final parsed = _parseCdDate(cd.cdDate);
      if (parsed != null &&
          (lastCdDate == null || parsed.isAfter(lastCdDate))) {
        lastCdDate = parsed;
      }
    }

    var firstDate = lastCdDate ?? caseDate ?? DateTime(2000);
    if (firstDate.isAfter(today)) firstDate = today;

    var initialDate = _parseCdDate(_selectedCdDate) ?? today;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(today)) initialDate = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
      helpText: 'Case Diary Date / সিডির তারিখ',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedCdDate = _formatCdDate(picked));
  }

  String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} hrs.';
  }

  bool _simpleQuestionComplete(CdWorkflowQuestion question) {
    if (!question.required) return true;
    final value = (_answers[question.id] ?? '').trim();
    if (question.type == CdQuestionType.witnessRepeater) {
      return _witnessBatchFor(question).entries.isNotEmpty;
    }
    return value.isNotEmpty;
  }

  void _simpleBack() {
    if (_simpleStepIndex <= 0) return;
    setState(() => _simpleStepIndex -= 1);
  }

  Future<void> _simpleNext(
    CdWorkflowPlan plan,
    List<CdWorkflowQuestion> questions,
  ) async {
    if (questions.isEmpty) {
      await _generate();
      return;
    }
    final currentIndex = _simpleStepIndex.clamp(0, questions.length - 1).toInt();
    final current = questions[currentIndex];
    if (!_simpleQuestionComplete(current)) {
      _showMissing(current.titleBn);
      return;
    }
    if (currentIndex >= questions.length - 1) {
      await _generate();
      return;
    }
    setState(() => _simpleStepIndex = currentIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _cdNumber == null) {
      return const Scaffold(
        backgroundColor: InvestigoUi.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final plan = _plan;
    final questions = plan.questions.where(_isVisible).toList(growable: false);
    final safeIndex = questions.isEmpty
        ? 0
        : _simpleStepIndex.clamp(0, questions.length - 1).toInt();
    if (safeIndex != _simpleStepIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _simpleStepIndex = safeIndex);
      });
    }
    final current = questions.isEmpty ? null : questions[safeIndex];

    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: Text('CD-${_cdNumber!}'),
        actions: [
          IconButton(
            tooltip: 'BNS / BNSS Law Search',
            icon: const Icon(Icons.gavel_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LegalReferenceScreen(
                  initialQuery: widget.caseFile.sections,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        children: [
          InvestigoProgressHeader(
            title: plan.phase == CdWorkflowPhase.finalisation
                ? 'শেষ CD / Last CD'
                : 'CD-${_cdNumber!} তৈরি',
            subtitle: current == null
                ? widget.caseFile.displayTitle
                : '${current.group} • ${widget.caseFile.displayTitle}',
            current: questions.isEmpty ? 1 : safeIndex + 1,
            total: questions.isEmpty ? 1 : questions.length,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: InvestigoUi.cardDecoration(),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(
                Icons.calendar_month_rounded,
                color: InvestigoUi.primary,
              ),
              title: const Text(
                'সিডির তারিখ / Case Diary Date',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '$_selectedCdDate\n'
                'আজ অ্যাপে লিখলেও যে দিনের তদন্তের কার্যক্রম লিপিবদ্ধ করছেন, '
                'সেই তারিখ নির্বাচন করুন।',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickCdDate,
            ),
          ),
          if (_cdNumber! > 1) ...[
            const SizedBox(height: 12),
            Container(
              decoration: InvestigoUi.cardDecoration(),
              child: SwitchListTile.adaptive(
                value: _finalisationRequested,
                title: const Text(
                  'এটাই কি Last CD?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('হ্যাঁ হলে final investigation প্রশ্ন আসবে।'),
                onChanged: (value) {
                  setState(() {
                    _finalisationRequested = value;
                    _answers.clear();
                    _selectedActions.clear();
                    _simpleStepIndex = 0;
                    for (final controller in _controllers.values) {
                      controller.clear();
                    }
                  });
                },
              ),
            ),
          ],
          if (safeIndex == 0 &&
              plan.recommendedActionIds.isNotEmpty &&
              plan.phase == CdWorkflowPhase.continuation) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              leading: const Icon(Icons.lightbulb_outline_rounded,
                  color: InvestigoUi.warning),
              title: const Text(
                'App-এর পরামর্শ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('চাইলে খুলে দেখুন — কিছু auto select হবে না'),
              children: [_recommendedActions(plan)],
            ),
          ],
          if (safeIndex == 0 && _pendingActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              leading: const Icon(Icons.schedule_outlined,
                  color: InvestigoUi.primary),
              title: Text(
                'আগের Form/Notice থেকে ${_pendingActions.length}টি pending entry',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('প্রয়োজনে দেখে নির্বাচন করুন'),
              children: [_pendingEntriesCard()],
            ),
          ],
          const SizedBox(height: 14),
          if (current != null)
            Container(
              decoration: InvestigoUi.cardDecoration(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.titleBn,
                    style: const TextStyle(
                      color: InvestigoUi.text,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  if (current.titleEn.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      current.titleEn,
                      style: const TextStyle(
                        color: InvestigoUi.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (current.hintBn.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4FB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        current.hintBn,
                        style: const TextStyle(
                          color: InvestigoUi.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _questionInput(current, plan),
                ],
              ),
            )
          else
            Container(
              decoration: InvestigoUi.cardDecoration(),
              padding: const EdgeInsets.all(20),
              child: const Text(
                'সব তথ্য প্রস্তুত। নিচের Generate বাটনে চাপুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          if (_linkedStatementPreview(plan) != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InvestigoUi.radius),
                side: const BorderSide(color: Color(0xFFE7EBF3)),
              ),
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Auto-linked Statement', style: TextStyle(fontWeight: FontWeight.w900)),
              children: [_linkedStatementPreview(plan)!],
            ),
          ],
          if (_sketchRequested) ...[
            const SizedBox(height: 12),
            _autoSketchCard(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7EBF3))),
          ),
          child: Row(
            children: [
              if (safeIndex > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _simpleBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('আগের / Back'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: safeIndex > 0 ? 1 : 2,
                child: FilledButton.icon(
                  onPressed: () => _simpleNext(plan, questions),
                  icon: Icon(
                    questions.isEmpty || safeIndex >= questions.length - 1
                        ? Icons.auto_awesome_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    questions.isEmpty || safeIndex >= questions.length - 1
                        ? (plan.phase == CdWorkflowPhase.finalisation
                            ? 'Last CD তৈরি করুন'
                            : 'CD-${_cdNumber!} তৈরি করুন')
                        : 'পরবর্তী / Next',
                  ),
                  style: InvestigoUi.primaryButtonStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _linkedStatementPreview(CdWorkflowPlan plan) {
    final number = _cdNumber;
    if (number == null) return null;
    final today = DateTime.now().toIso8601String().split('T').first;
    final entries = _statementLink.buildLinkedStatements(
      caseFile: widget.caseFile,
      profile: widget.profile,
      plan: plan,
      cdNumber: number,
      cdDate: today,
      answers: Map<String, String>.from(_answers),
    );
    if (entries.isEmpty) return null;
    return AppSectionCard(
      title: 'CD ↔ Statement Auto-Link',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate CD চাপলে নিচের u/s 180 BNSS Statement sheet-গুলো একই input থেকে automatic save হবে। Statement body CD-তে repeat হবে না।',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...entries.map(
            (entry) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(entry.witnessName),
              subtitle: Text(
                '${entry.statementType} • ${entry.recordedTime.isEmpty ? 'time pending' : entry.recordedTime} • ${entry.recordedPlace.isEmpty ? 'place pending' : entry.recordedPlace}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoSketchCard() {
    final mapExists = _sketchMap != null && _sketchMap!.objects.isNotEmpty;
    final matches = _sketchMatchesCurrentAnswers;
    final status = !_hasCompleteSketchData
        ? 'Exact PO + North/South/East/West সম্পূর্ণ হলে draft নিজে তৈরি হবে।'
        : _sketchApproved
            ? 'Approved • এই sketch map CD-এর সঙ্গে linked থাকবে।'
            : mapExists && matches
                ? 'Auto draft generated • Officer validation pending.'
                : mapExists
                    ? 'PO data changed • Regenerate and validate required.'
                    : 'Auto draft generating...';
    return AppSectionCard(
      title: 'Auto Sketch Map + Index',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(status, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_hasCompleteSketchData)
            Text('PO: $_sketchExactPo\nN: $_sketchNorth\nS: $_sketchSouth\nE: $_sketchEast\nW: $_sketchWest'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _autoSketchGenerating || !_hasCompleteSketchData
                      ? null
                      : () => _openSketchValidation(forceRegenerate: true),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Regenerate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: !_hasCompleteSketchData
                      ? null
                      : () => _openSketchValidation(),
                  icon: Icon(_sketchApproved ? Icons.verified : Icons.rule),
                  label: Text(_sketchApproved ? 'View Approved' : 'Validate / Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workflowHeader(CdWorkflowPlan plan) {
    final category = switch (plan.caseCategory) {
      CdCaseCategory.roadTrafficAccident => 'Road Traffic Accident Case',
      CdCaseCategory.arms => 'Arms Case',
      CdCaseCategory.pocso => 'POCSO Case',
      CdCaseCategory.sexualOffence => 'Sexual Offence Case',
      CdCaseCategory.general => 'General Case',
    };
    final phase = switch (plan.phase) {
      CdWorkflowPhase.initial => 'CD-I • Initial Investigation',
      CdWorkflowPhase.continuation => 'CD-${_cdNumber!} • Further Investigation',
      CdWorkflowPhase.finalisation => 'CD-${_cdNumber!} • Last CD / Finalisation',
    };
    final previous = _previousCds.isEmpty
        ? 'আগের CD নেই।'
        : 'Previous: CD-${_previousCds.last.cdNumber} dated ${_previousCds.last.cdDate}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 5),
            Text('$category • $previous'),
            const SizedBox(height: 8),
            const Text(
              'শুধু যা বাস্তবে তদন্তে করেছেন সেটাই উত্তর দিন। INVESTIGO উত্তর অনুযায়ী relevant প্রশ্ন দেখাবে এবং CD draft তৈরি করবে।',
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendedActions(CdWorkflowPlan plan) {
    final optionById = <String, CdQuestionOption>{};
    for (final q in plan.questions) {
      if (q.id == 'today_actions') {
        for (final option in q.options) {
          optionById[option.value] = option;
        }
      }
    }
    return AppSectionCard(
      title: 'Previous CD অনুযায়ী Suggested Next Steps',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: plan.recommendedActionIds.map((id) {
          final label = optionById[id]?.labelBn ?? id;
          return ActionChip(
            avatar: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(label),
            onPressed: () {
              setState(() {
                _selectedActions.add(id);
                _answers['today_actions'] = _selectedActions.join(',');
              });
            },
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _pendingEntriesCard() {
    return AppSectionCard(
      title: 'Saved Forms/Requisitions থেকে Pending CD Entries',
      child: Column(
        children: _pendingActions.map((action) {
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selectedPendingActionIds.contains(action.id),
            title: Text(
              action.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${action.actionDate} • ${action.paragraph}'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedPendingActionIds.add(action.id);
                } else {
                  _selectedPendingActionIds.remove(action.id);
                }
              });
            },
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _questionWidget(CdWorkflowQuestion question, CdWorkflowPlan plan) {
    final requiredMark = question.required ? ' *' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${question.titleBn}$requiredMark',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 3),
        Text(question.titleEn, style: Theme.of(context).textTheme.bodySmall),
        if (question.hintBn.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(question.hintBn, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 10),
        _questionInput(question, plan),
      ],
    );
  }

  MultiWitnessBatch _witnessBatchFor(CdWorkflowQuestion question) =>
      MultiWitnessBatch.decode(_answers[question.id] ?? '');

  void _setWitnessBatch(
    CdWorkflowQuestion question,
    MultiWitnessBatch batch,
  ) {
    setState(() {
      _answers[question.id] = batch.encode();
    });
  }

  Widget _multiWitnessInput(CdWorkflowQuestion question) {
    final batch = _witnessBatchFor(question);
    final grouped = batch.mode == WitnessCdEntryMode.groupedSameSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Separate Timed Entries'),
              selected: !grouped,
              onSelected: (_) => _setWitnessBatch(
                question,
                batch.copyWith(mode: WitnessCdEntryMode.separate),
              ),
            ),
            ChoiceChip(
              label: const Text('Grouped Same-Session Entry'),
              selected: grouped,
              onSelected: (_) => _setWitnessBatch(
                question,
                batch.copyWith(mode: WitnessCdEntryMode.groupedSameSession),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          grouped
              ? 'Grouped mode-এ সব witness-এর examination time ও place একই হতে হবে। প্রত্যেকের Statement sheet আলাদা থাকবে।'
              : 'Separate mode-এ প্রত্যেক witness-এর নিজস্ব time/place অনুযায়ী আলাদা CD marginal entry হবে।',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (grouped && batch.entries.length > 1) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _setWitnessBatch(
              question,
              batch.copyFirstSessionToAll(),
            ),
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy first witness time/place to all'),
          ),
        ],
        const SizedBox(height: 10),
        if (batch.entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'এখনও কোনো witness যোগ করা হয়নি। + Add Witness চাপুন।',
              ),
            ),
          )
        else
          ...batch.entries.asMap().entries.map((row) {
            final index = row.key;
            final entry = row.value;
            final role = entry.role.trim().isEmpty ? 'Witness' : entry.role.trim();
            final status = entry.statementRecorded
                ? 'u/s 180 BNSS statement linked'
                : 'Examined • no statement sheet';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  entry.witnessName.trim().isEmpty
                      ? 'Unnamed witness'
                      : entry.witnessName.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '$role\n${entry.recordedTime.isEmpty ? 'time pending' : entry.recordedTime} • ${entry.recordedPlace.isEmpty ? 'place pending' : entry.recordedPlace}\n$status',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      tooltip: 'Edit witness',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editWitnessEntry(
                        question,
                        entry,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove witness',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _setWitnessBatch(
                        question,
                        batch.remove(entry.id),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _addWitnessEntry(question),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('+ Add Witness'),
        ),
      ],
    );
  }

  Future<void> _addWitnessEntry(CdWorkflowQuestion question) async {
    final batch = _witnessBatchFor(question);
    final first = batch.entries.isEmpty ? null : batch.entries.first;
    final grouped = batch.mode == WitnessCdEntryMode.groupedSameSession;
    final entry = await _openWitnessEditor(
      seedTime: grouped ? first?.recordedTime ?? '' : '',
      seedPlace: grouped ? first?.recordedPlace ?? '' : '',
    );
    if (entry == null || !mounted) return;
    _setWitnessBatch(question, batch.upsert(entry));
  }

  Future<void> _editWitnessEntry(
    CdWorkflowQuestion question,
    WitnessExaminationEntry current,
  ) async {
    final updated = await _openWitnessEditor(existing: current);
    if (updated == null || !mounted) return;
    _setWitnessBatch(question, _witnessBatchFor(question).upsert(updated));
  }

  Future<WitnessExaminationEntry?> _openWitnessEditor({
    WitnessExaminationEntry? existing,
    String seedTime = '',
    String seedPlace = '',
  }) async {
    final nameCtrl = TextEditingController(text: existing?.witnessName ?? '');
    final detailsCtrl = TextEditingController(text: existing?.witnessDetails ?? '');
    final roleCtrl = TextEditingController(text: existing?.role ?? '');
    final timeCtrl = TextEditingController(
      text: existing?.recordedTime ?? seedTime,
    );
    final placeCtrl = TextEditingController(
      text: existing?.recordedPlace ?? seedPlace,
    );
    final bodyCtrl = TextEditingController(text: existing?.statementBody ?? '');
    final noteCtrl = TextEditingController(text: existing?.examinationNote ?? '');
    var statementRecorded = existing?.statementRecorded ?? true;
    String errorText = '';

    final result = await showModalBottomSheet<WitnessExaminationEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked == null) return;
              final hour = picked.hour.toString().padLeft(2, '0');
              final minute = picked.minute.toString().padLeft(2, '0');
              setSheetState(() => timeCtrl.text = '$hour.$minute hrs.');
            }

            void chooseRole(String role) {
              setSheetState(() => roleCtrl.text = role);
            }

            void save() {
              final name = nameCtrl.text.trim();
              final time = timeCtrl.text.trim();
              final place = placeCtrl.text.trim();
              final body = bodyCtrl.text.trim();
              if (name.isEmpty) {
                setSheetState(() => errorText = 'Witness name required.');
                return;
              }
              if (time.isEmpty) {
                setSheetState(() => errorText = 'Examination time required.');
                return;
              }
              if (place.isEmpty) {
                setSheetState(() => errorText = 'Examination place required.');
                return;
              }
              if (statementRecorded && body.isEmpty) {
                setSheetState(
                  () => errorText =
                      'Statement recorded হলে statement body required.',
                );
                return;
              }
              Navigator.pop(
                sheetContext,
                WitnessExaminationEntry(
                  id: existing?.id ??
                      'wx_${DateTime.now().microsecondsSinceEpoch}',
                  witnessName: name,
                  witnessDetails: detailsCtrl.text.trim(),
                  role: roleCtrl.text.trim(),
                  recordedTime: time,
                  recordedPlace: place,
                  statementRecorded: statementRecorded,
                  statementBody: statementRecorded ? body : '',
                  examinationNote: noteCtrl.text.trim(),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Add Witness' : 'Edit Witness',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Witness Name *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailsCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Identity / Parentage / Age / Address',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Role / Category',
                        hintText: 'Eye witness / Seizure witness / Police witness...',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <String>[
                        'Eye Witness',
                        'Seizure Witness',
                        'Police Witness',
                        'Local Witness',
                        'Recovery Witness',
                        'Other',
                      ]
                          .map(
                            (role) => ActionChip(
                              label: Text(role),
                              onPressed: () => chooseRole(role),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeCtrl,
                      readOnly: true,
                      onTap: pickTime,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Examination Time *',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: placeCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Examination Place *',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Statement u/s 180 BNSS recorded in separate sheet?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      value: statementRecorded,
                      onChanged: (value) =>
                          setSheetState(() => statementRecorded = value),
                    ),
                    if (statementRecorded) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: bodyCtrl,
                        minLines: 5,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Statement Body *',
                          helperText:
                              'Witness-এর নিজের narration লিখুন। এই text separate statement sheet হবে; CD-তে repeat হবে না।',
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Examination Note (optional)',
                        hintText:
                            'e.g. appeared voluntarily / examined at PO / non-cooperation noted',
                      ),
                    ),
                    if (errorText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: save,
                            icon: const Icon(Icons.check),
                            label: const Text('Save Witness'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    detailsCtrl.dispose();
    roleCtrl.dispose();
    timeCtrl.dispose();
    placeCtrl.dispose();
    bodyCtrl.dispose();
    noteCtrl.dispose();
    return result;
  }

  Widget _questionInput(CdWorkflowQuestion question, CdWorkflowPlan plan) {
    switch (question.type) {
      case CdQuestionType.yesNo:
        final value = _answers[question.id];
        Widget answerButton(String answer, String label, IconData icon) {
          final selected = value == answer;
          return Expanded(
            child: SizedBox(
              height: 58,
              child: OutlinedButton.icon(
                onPressed: () => _setAnswer(question.id, answer),
                icon: Icon(icon),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected ? InvestigoUi.primary : Colors.white,
                  foregroundColor: selected ? Colors.white : InvestigoUi.text,
                  side: BorderSide(
                    color: selected ? InvestigoUi.primary : const Color(0xFFDDE3EF),
                    width: 1.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          );
        }
        return Row(
          children: [
            answerButton('yes', 'হ্যাঁ / Yes', Icons.check_rounded),
            const SizedBox(width: 10),
            answerButton('no', 'না / No', Icons.close_rounded),
          ],
        );
      case CdQuestionType.time:
        final controller = _controllerFor(question);
        return TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _pickTime(question),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'সময় নির্বাচন করুন',
            suffixIcon: Icon(Icons.access_time),
          ),
        );
      case CdQuestionType.multiChoice:
        return Column(
          children: question.options.map((option) {
            final selected = _selectedActions.contains(option.value);
            final recommended = plan.recommendedActionIds.contains(option.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedActions.remove(option.value);
                    } else {
                      _selectedActions.add(option.value);
                    }
                    _answers[question.id] = _selectedActions.join(',');
                  });
                  _scheduleAutoSketch();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? InvestigoUi.primary.withOpacity(.08) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? InvestigoUi.primary : const Color(0xFFDDE3EF),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: selected ? InvestigoUi.primary : InvestigoUi.muted,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          recommended ? '${option.labelBn}  •  Suggested' : option.labelBn,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      case CdQuestionType.singleChoice:
        final current = _answers[question.id];
        return Column(
          children: question.options.map((option) {
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: option.value,
              groupValue: current,
              title: Text(option.labelBn),
              subtitle: Text(option.labelEn),
              onChanged: (value) {
                if (value != null) _setAnswer(question.id, value);
              },
            );
          }).toList(growable: false),
        );
      case CdQuestionType.witnessRepeater:
        return _multiWitnessInput(question);
      case CdQuestionType.shortText:
      case CdQuestionType.longText:
        final controller = _controllerFor(question);
        return TextField(
          controller: controller,
          minLines: question.type == CdQuestionType.longText ? 3 : 1,
          maxLines: question.type == CdQuestionType.longText ? 6 : 2,
          onChanged: (value) => _onTextAnswerChanged(question.id, value),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: question.hintEn.isNotEmpty ? question.hintEn : 'তথ্য লিখুন',
          ),
        );
    }
  }

  String _groupTitle(String group) {
    const names = <String, String>{
      'case_start': '1. Case Start / Diary Timing',
      'fir': '2. FIR / Complaint',
      'complainant': '3. Complainant Examination',
      'seizure': '4. Existing Seizure / Property',
      'accused': '5. Accused / Interrogation',
      'victim': '6. Victim / VG',
      'witness': '7. Witness Examination',
      'po': '8. Place of Occurrence',
      'po_surroundings': '9. PO Surroundings',
      'closing': 'Closing / Return',
      'action_selector': 'আজকের Investigation Action',
      'final_permission': 'Final Permission / MOE',
      'final_charge': 'Charge & Accused',
      'final_summary': 'Final Investigation Summary',
      'final_witness': 'Prosecution Witnesses',
      'final_closing': 'Charge Sheet & Closing',
    };
    return names[group] ?? _actionGroupTitle(group);
  }

  String _actionGroupTitle(String group) {
    const names = <String, String>{
      CdWorkflowService.actionPcInterrogation: 'PC Accused Interrogation',
      CdWorkflowService.actionWitnessExamination: 'Witness Examination',
      CdWorkflowService.actionVictimExamination: 'Victim / VG Examination',
      CdWorkflowService.actionPoVisit: 'PO Visit',
      CdWorkflowService.actionRaidSearch: 'Raid / Search',
      CdWorkflowService.actionRecoverySeizure: 'Recovery / Seizure',
      CdWorkflowService.actionArrest: 'Arrest',
      CdWorkflowService.actionCourtProduction: 'Court / JJB',
      CdWorkflowService.actionJudicialStatement: 'Judicial Statement',
      CdWorkflowService.actionMedicalExamination: 'Medical / MLE / BHT',
      CdWorkflowService.actionReportDocument: 'Report / Order / Document',
      CdWorkflowService.actionRequisition: 'Requisition / Prayer',
      CdWorkflowService.actionDigitalEvidence: 'Digital / Electronic Evidence',
      CdWorkflowService.actionLocalEnquiry: 'Local Enquiry / Verification',
      CdWorkflowService.actionNotice: 'Notice / Service',
      CdWorkflowService.actionExpertReport: 'Expert / FSL Report',
      CdWorkflowService.actionAgeProof: 'Age Proof',
      CdWorkflowService.actionSanction: 'Sanction',
      CdWorkflowService.actionMoe: 'MOE / Superior Direction',
      CdWorkflowService.actionInjuryMedicalPapers: 'Injury Report / BHT / Medical Papers',
      CdWorkflowService.actionVehicleDriverVerification: 'Offending Vehicle / Driver Verification',
      CdWorkflowService.actionOther: 'Other Investigation',
    };
    return names[group] ?? group;
  }
}
