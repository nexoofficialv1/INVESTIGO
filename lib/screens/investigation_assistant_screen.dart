import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/case_file.dart';
import '../models/investigation_action.dart';
import '../models/pending_cd_action.dart';
import '../services/investigation_narration_service.dart';
import '../services/local_store_service.dart';
import '../services/smart_case_service.dart';

class InvestigationAssistantScreen extends StatefulWidget {
  final CaseFile caseFile;

  const InvestigationAssistantScreen({
    super.key,
    required this.caseFile,
  });

  @override
  State<InvestigationAssistantScreen> createState() =>
      _InvestigationAssistantScreenState();
}

class _InvestigationAssistantScreenState
    extends State<InvestigationAssistantScreen> {
  final _store = LocalStoreService();
  final _parser = InvestigationNarrationService();
  final _smart = SmartCaseService();
  final _speech = stt.SpeechToText();
  final _narration = TextEditingController();
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final _place = TextEditingController();
  final _departureTime = TextEditingController();
  final _arrivalTime = TextEditingController();
  final _returnTime = TextEditingController();

  NarrationAnalysisResult? _result;
  final Set<int> _selected = {};
  final Map<int, String> _editedParagraphs = {};
  bool _listening = false;
  bool _saving = false;

  @override
  void dispose() {
    _speech.stop();
    _narration.dispose();
    _date.dispose();
    _place.dispose();
    _departureTime.dispose();
    _arrivalTime.dispose();
    _returnTime.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ready = await _speech.initialize();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input চালু করা যায়নি। Microphone permission যাচাই করুন।')),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'bn_IN',
      listenMode: stt.ListenMode.dictation,
      onResult: (result) {
        _narration.text = result.recognizedWords;
        _narration.selection = TextSelection.collapsed(
          offset: _narration.text.length,
        );
        if (result.finalResult && mounted) {
          setState(() => _listening = false);
        }
      },
    );
  }

  void _analyse() {
    final result = _parser.analyse(_narration.text);
    setState(() {
      _result = result;
      _selected
        ..clear()
        ..addAll(List<int>.generate(result.suggestions.length, (i) => i));
      _editedParagraphs
        ..clear()
        ..addEntries(List.generate(result.suggestions.length, (i) => MapEntry(i, result.suggestions[i].paragraph)));
    });
  }

  Future<String?> _askReason(String message) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('পুনরাবৃত্ত কাজ যাচাই'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'পুনরায় করার কারণ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাদ দিন'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('কারণসহ অনুমোদন'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }


  Future<void> _editSuggestion(int index) async {
    final current = _editedParagraphs[index] ??
        _result?.suggestions[index].paragraph ??
        '';
    final controller = TextEditingController(text: current);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CD Draft সম্পাদনা'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 14,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'অফিসার প্রয়োজনমতো ভাষা সংশোধন করবেন',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Draft রাখুন'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated != null && updated.isNotEmpty && mounted) {
      setState(() => _editedParagraphs[index] = updated);
    }
  }

  Future<void> _saveSelected() async {
    final result = _result;
    if (result == null || _selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final existing = await _store.loadInvestigationActions(widget.caseFile.id);
      var saved = 0;
      var skipped = 0;
      var sketchSuggested = false;
      var indexSuggested = false;

      for (final index in _selected.toList()..sort()) {
        final suggestion = result.suggestions[index];
        var details = _editedParagraphs[index] ?? suggestion.paragraph;
        var action = InvestigationActionEntry.create(
          caseId: widget.caseFile.id,
          actionDate: _date.text.trim(),
          actionType: suggestion.actionType,
          outsidePs: suggestion.outsidePs,
          departureTime: _departureTime.text.trim(),
          actionArrivalTime: _arrivalTime.text.trim(),
          returnTime: _returnTime.text.trim(),
          place: _place.text.trim(),
          accompaniedBy: '',
          sopResponse: '',
          details: details,
          arrestInvolved: suggestion.arrestInvolved,
          seizureInvolved: suggestion.seizureInvolved,
          courtForwardingSuggested:
              suggestion.actionType == 'Court Forwarding',
          pcPrayerSuggested: false,
        );

        final decision = _smart.assessBeforeSave(
          proposed: action,
          existing: [...existing],
        );
        if (decision.needsReason) {
          final reason = await _askReason(decision.message);
          if (reason == null) {
            skipped++;
            continue;
          }
          details = '$details\nReason for repeat action: $reason';
          action = InvestigationActionEntry.create(
            caseId: widget.caseFile.id,
            actionDate: _date.text.trim(),
            actionType: suggestion.actionType,
            outsidePs: suggestion.outsidePs,
            departureTime: _departureTime.text.trim(),
            actionArrivalTime: _arrivalTime.text.trim(),
            returnTime: _returnTime.text.trim(),
            place: _place.text.trim(),
            accompaniedBy: '',
            sopResponse: '',
            details: details,
            arrestInvolved: suggestion.arrestInvolved,
            seizureInvolved: suggestion.seizureInvolved,
            courtForwardingSuggested:
                suggestion.actionType == 'Court Forwarding',
            pcPrayerSuggested: false,
          );
        }

        await _store.saveInvestigationAction(action);
        existing.add(action);
        await _store.savePendingCdAction(
          PendingCdAction.create(
            caseId: widget.caseFile.id,
            sourceType: 'Investigation Assistant',
            sourceId: action.id,
            title: suggestion.synopsis,
            actionDate: action.actionDate,
            paragraph: details,
          ),
        );
        saved++;
        sketchSuggested = sketchSuggested || suggestion.suggestsSketchMap;
        indexSuggested = indexSuggested || suggestion.suggestsIndex;
      }

      if (!mounted) return;
      final followUp = [
        if (sketchSuggested) 'Sketch Map',
        if (indexSuggested) 'Index',
      ];
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Draft সংরক্ষিত'),
          content: Text(
            '$savedটি investigation action এবং pending CD entry তৈরি হয়েছে.'
            '${skipped > 0 ? '\n$skippedটি action বাদ গেছে।' : ''}'
            '${followUp.isNotEmpty ? '\n\n${followUp.join(' ও ')} এখন তৈরি/লিংক করবেন কি না Case screen থেকে যাচাই করুন।' : ''}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
      setState(() {
        _result = null;
        _selected.clear();
        _editedParagraphs.clear();
        _narration.clear();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Investigation Assistant')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _saving || result == null || _selected.isEmpty
                ? null
                : _saveSelected,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('নির্বাচিত Draft অনুমোদন করে CD-তে পাঠান'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.caseFile.displayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'অফিসার নিজের ভাষায় বলবেন/লিখবেন। অ্যাপ শুধু editable draft তৈরি করবে; অনুমোদন ছাড়া কোনো CD final হবে না।',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phonelink_lock),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Offline Smart Draft: এই বিশ্লেষণ সম্পূর্ণ ফোনের ভিতরে হয়। কোনো মামলা, নাম, মোবাইল নম্বর বা ঠিকানা ইন্টারনেটে পাঠানো হয় না।',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _date,
            decoration: const InputDecoration(
              labelText: 'তারিখ (YYYY-MM-DD)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _place,
            decoration: const InputDecoration(
              labelText: 'স্থান',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _departureTime,
                  decoration: const InputDecoration(
                    labelText: 'Departure time',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _arrivalTime,
                  decoration: const InputDecoration(
                    labelText: 'Action/arrival time',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _returnTime,
                  decoration: const InputDecoration(
                    labelText: 'Return time',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _narration,
            minLines: 7,
            maxLines: 14,
            decoration: InputDecoration(
              labelText: 'আজ কী তদন্ত করেছেন—নিজের ভাষায় লিখুন বা বলুন',
              hintText:
                  'উদাহরণ: আজ ১০:৩০ ঘটিকায় ফোর্সসহ ঘটনাস্থলে গিয়ে অভিযোগকারী ও দুইজন সাক্ষীকে পরীক্ষা করলাম এবং rough sketch map with index প্রস্তুত করলাম।',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _toggleListening,
                icon: Icon(_listening ? Icons.stop_circle : Icons.mic),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _analyse,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Draft বিশ্লেষণ করুন'),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            if (!result.context.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Narration থেকে শনাক্ত তথ্য',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (result.context.times.isNotEmpty)
                        Text('সময়: ${result.context.times.join(', ')}'),
                      if (result.context.places.isNotEmpty)
                        Text('স্থান: ${result.context.places.join(', ')}'),
                      if (result.context.witnessCount != null)
                        Text('সাক্ষীর সংখ্যা: ${result.context.witnessCount}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (result.warnings.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'যাচাই প্রয়োজন',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ...result.warnings.map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $warning'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'চিহ্নিত Investigation Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            ...List.generate(result.suggestions.length, (index) {
              final suggestion = result.suggestions[index];
              return Card(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _selected.contains(index),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(index);
                        } else {
                          _selected.remove(index);
                        }
                      }),
                      title: Text(suggestion.actionType),
                      subtitle: Text(suggestion.synopsis),
                      secondary: Icon(
                        suggestion.outsidePs ? Icons.location_on : Icons.notes,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _editedParagraphs[index] ?? suggestion.paragraph,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Draft edit',
                            onPressed: () => _editSuggestion(index),
                            icon: const Icon(Icons.edit_note),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}
