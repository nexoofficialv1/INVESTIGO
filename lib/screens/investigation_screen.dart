import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/investigation_action.dart';
import '../models/officer_profile.dart';
import '../models/pending_cd_action.dart';
import '../services/local_store_service.dart';
import '../services/sop_compliance_service.dart';
import '../widgets/app_section_card.dart';
import '../widgets/form_helpers.dart';

class InvestigationScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const InvestigationScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  final LocalStoreService _store = LocalStoreService();
  final SopComplianceService _sop = SopComplianceService();
  final _date = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
  final _departureTime = TextEditingController();
  final _arrivalTime = TextEditingController();
  final _returnTime = TextEditingController();
  final _place = TextEditingController();
  final _accompaniedBy = TextEditingController();
  final _details = TextEditingController();
  final _sopResponse = TextEditingController();

  String _actionType = 'PO Visit / Local Enquiry';
  bool _outsidePs = true;
  bool _arrestInvolved = false;
  bool _seizureInvolved = false;
  bool _courtForwardingSuggested = false;
  bool _pcPrayerSuggested = false;
  List<InvestigationActionEntry> _history = [];

  final List<String> _actions = const [
    'PO Visit / Local Enquiry',
    'Raid',
    'Accused Search',
    'Arrest / Apprehension',
    'Witness Examination',
    'Complainant Examination',
    'Victim Examination',
    'Hospital / Medical Work',
    'Court Work / Prayer',
    'Report / Document Collection',
    'Notice Service',
    'General Investigation Note',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _place.text = widget.caseFile.placeOfOccurrence;
  }

  Future<void> _loadHistory() async {
    final entries = await _store.loadInvestigationActions(widget.caseFile.id);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  @override
  void dispose() {
    for (final c in [_date, _departureTime, _arrivalTime, _returnTime, _place, _accompaniedBy, _details, _sopResponse]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isFieldAction {
    final t = _actionType.toLowerCase();
    return _outsidePs || t.contains('po') || t.contains('raid') || t.contains('search') || t.contains('hospital') || t.contains('court') || t.contains('notice');
  }

  List<String> _buildCdParagraphs() {
    final place = _place.text.trim().isEmpty ? 'the place concerned' : _place.text.trim();
    final force = _accompaniedBy.text.trim().isEmpty ? 'force' : _accompaniedBy.text.trim();
    final details = _details.text.trim();
    final paragraphs = <String>[];

    if (_isFieldAction) {
      paragraphs.add('By this marginally noted time I along with $force left ${widget.profile.policeStation} for $place for ${_actionType.toLowerCase()} in connection with this case.');
      paragraphs.add('By this marginally noted time I arrived at $place and conducted ${_actionType.toLowerCase()}. ${details.isEmpty ? '' : 'Details: $details'}'.trim());
      if (_returnTime.text.trim().isNotEmpty) {
        paragraphs.add('By this marginally noted time I along with $force returned at ${widget.profile.policeStation} after completing the above noted investigation work.');
      }
    } else {
      paragraphs.add('By this marginally noted time I conducted ${_actionType.toLowerCase()} in connection with this case. ${details.isEmpty ? '' : 'Details: $details'}'.trim());
    }

    if (_arrestInvolved) {
      paragraphs.add('As arrest/apprehension of accused is involved, arrest formalities, medical examination, intimation and forwarding steps are required to be completed as per law.');
      paragraphs.add('Suggested: Prepare forwarding report before the Ld. Court and consider PC/JC prayer as per the facts and requirement of investigation.');
    }
    if (_seizureInvolved) {
      paragraphs.add('Seizure/evidence related action was taken. Ensure seizure list, witnesses, malkhana/FSL and chain of custody compliance are completed wherever applicable.');
    }
    if (_sopResponse.text.trim().isNotEmpty) {
      paragraphs.add('SOP compliance note: ${_sopResponse.text.trim()}');
    }
    return paragraphs.where((e) => e.trim().isNotEmpty).toList();
  }

  Future<void> _saveAction() async {
    if (_isFieldAction && (_departureTime.text.trim().isEmpty || _arrivalTime.text.trim().isEmpty)) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Mandatory CD Step Missing'),
          content: const Text('থানার বাইরে কাজ হলে Departure time এবং Arrival/action time দিতে হবে। এগুলো ছাড়া CD-II onward entry proper হবে না।'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    final entry = InvestigationActionEntry.create(
      caseId: widget.caseFile.id,
      actionDate: _date.text.trim(),
      actionType: _actionType,
      outsidePs: _isFieldAction,
      departureTime: _departureTime.text.trim(),
      actionArrivalTime: _arrivalTime.text.trim(),
      returnTime: _returnTime.text.trim(),
      place: _place.text.trim(),
      accompaniedBy: _accompaniedBy.text.trim(),
      sopResponse: _sopResponse.text.trim(),
      details: _details.text.trim(),
      arrestInvolved: _arrestInvolved,
      seizureInvolved: _seizureInvolved,
      courtForwardingSuggested: _courtForwardingSuggested,
      pcPrayerSuggested: _pcPrayerSuggested,
    );
    await _store.saveInvestigationAction(entry);

    final paragraphs = _buildCdParagraphs();
    for (var i = 0; i < paragraphs.length; i++) {
      final action = PendingCdAction.create(
        caseId: widget.caseFile.id,
        sourceType: 'Investigation',
        sourceId: '${entry.id}_$i',
        title: i == 0 ? 'Investigation: $_actionType' : 'Investigation follow-up: $_actionType',
        actionDate: entry.actionDate,
        paragraph: paragraphs[i],
      );
      await _store.savePendingCdAction(action);
    }

    if (_arrestInvolved) {
      await _showArrestSuggestions();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Investigation saved and pending CD entries created')));
    }
    _clearForm(keepDate: true);
    await _loadHistory();
  }

  Future<void> _showArrestSuggestions() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Procedure Suggested'),
        content: const Text('Raid/Arrest entry পাওয়া গেছে। Forwarding report, accused medical, arrest formalities, relative intimation এবং প্রয়োজন হলে PC/JC prayer তৈরি করুন। এই notes CD pending entry-তেও যোগ হয়েছে।'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _clearForm({bool keepDate = false}) {
    if (!keepDate) _date.text = DateTime.now().toIso8601String().split('T').first;
    _departureTime.clear();
    _arrivalTime.clear();
    _returnTime.clear();
    _details.clear();
    _sopResponse.clear();
    setState(() {
      _arrestInvolved = false;
      _seizureInvolved = false;
      _courtForwardingSuggested = false;
      _pcPrayerSuggested = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sopRules = _sop.buildRules(widget.caseFile);
    return Scaffold(
      appBar: AppBar(title: const Text('SOP Investigation')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saveAction,
            icon: const Icon(Icons.save),
            label: const Text('Save Investigation + Add to CD'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Sections: ${widget.caseFile.sections}'),
                const SizedBox(height: 8),
                const Text('এই module থেকে IO যে কাজ feed করবেন, তা date-wise CD-II onwards pending entry হিসেবে যাবে। থানার বাইরে কাজ হলে Departure + Arrival mandatory।'),
              ]),
            ),
          ),
          AppSectionCard(
            title: 'Daily Investigation Entry',
            child: Column(children: [
              FormHelpers.textField(controller: _date, label: 'Date', maxLines: 1),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _actionType,
                decoration: const InputDecoration(labelText: 'Action Type', border: OutlineInputBorder()),
                items: _actions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() {
                  _actionType = v ?? _actionType;
                  final lower = _actionType.toLowerCase();
                  _outsidePs = lower.contains('po') || lower.contains('raid') || lower.contains('search') || lower.contains('hospital') || lower.contains('court') || lower.contains('notice');
                  _arrestInvolved = lower.contains('arrest') || lower.contains('raid');
                }),
              ),
              FormHelpers.yesNoTile(title: 'Outside PS work? Departure/Arrival mandatory', value: _outsidePs, onChanged: (v) => setState(() => _outsidePs = v)),
              if (_isFieldAction) ...[
                FormHelpers.textField(controller: _departureTime, label: 'Departure time from PS', maxLines: 1),
                FormHelpers.textField(controller: _arrivalTime, label: 'Arrival/action time at place', maxLines: 1),
                FormHelpers.textField(controller: _returnTime, label: 'Return time to PS, if returned', maxLines: 1),
                FormHelpers.textField(controller: _place, label: 'Place visited / raid / PO / hospital / court', maxLines: 2),
                FormHelpers.textField(controller: _accompaniedBy, label: 'Accompanied by / force details', maxLines: 2),
              ],
              FormHelpers.textField(controller: _details, label: 'Investigation details / secure structured response', maxLines: 5),
              FormHelpers.textField(controller: _sopResponse, label: 'SOP response / compliance note', maxLines: 4),
              FormHelpers.yesNoTile(title: 'Arrest / apprehension involved?', value: _arrestInvolved, onChanged: (v) => setState(() {
                _arrestInvolved = v;
                if (v) {
                  _courtForwardingSuggested = true;
                  _pcPrayerSuggested = true;
                }
              })),
              FormHelpers.yesNoTile(title: 'Seizure/evidence involved?', value: _seizureInvolved, onChanged: (v) => setState(() => _seizureInvolved = v)),
              if (_arrestInvolved)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('App will suggest: Court forwarding, medical, arrest formalities, relative intimation and PC/JC prayer where required.', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
            ]),
          ),
          AppSectionCard(
            title: 'SOP Prompts for this Case',
            child: Column(
              children: sopRules.take(8).map((r) => ListTile(
                dense: true,
                leading: Icon(r.mandatory ? Icons.warning_amber_rounded : Icons.info_outline),
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${r.detail}\n${r.sectionRef}'),
              )).toList(),
            ),
          ),
          AppSectionCard(
            title: 'Recent Investigation Entries',
            child: _history.isEmpty
                ? const Text('No investigation entry saved yet.')
                : Column(children: _history.take(10).map((e) => ListTile(
                      title: Text('${e.actionDate} • ${e.actionType}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${e.place}\n${e.details}', maxLines: 3),
                    )).toList()),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
