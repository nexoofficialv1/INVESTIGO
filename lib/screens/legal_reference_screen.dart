import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../models/legal_reference.dart';
import '../services/bilingual_translation_service.dart';
import '../services/legal_reference_service.dart';

class LegalReferenceScreen extends StatefulWidget {
  final String initialQuery;
  final LegalCode? initialCode;

  const LegalReferenceScreen({
    super.key,
    this.initialQuery = '',
    this.initialCode,
  });

  @override
  State<LegalReferenceScreen> createState() => _LegalReferenceScreenState();
}

class _LegalReferenceScreenState extends State<LegalReferenceScreen> {
  final _service = LegalReferenceService();
  late final TextEditingController _search;
  LegalCode? _code;
  List<LegalSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
    _code = widget.initialCode ?? LegalReferenceService.inferCode(widget.initialQuery);
    _runSearch();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _runSearch() {
    setState(() {
      _results = _service.search(_search.text, code: _code);
    });
  }

  Future<void> _showDetail(LegalSearchResult result) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LegalReferenceDetail(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BNS / BNSS Law Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => _runSearch(),
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          _runSearch();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                labelText: 'Section / keyword / old IPC-CrPC section',
                hintText: '281, rash driving, BNSS 180, IPC 279…',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _code == null,
                  onSelected: (_) {
                    setState(() => _code = null);
                    _runSearch();
                  },
                ),
                for (final c in LegalCode.values)
                  ChoiceChip(
                    label: Text(c.shortName),
                    selected: _code == c,
                    onSelected: (_) {
                      setState(() => _code = c);
                      _runSearch();
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Offline index: BNS + BNSS • Verified official text badge where bundled',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No matching BNS/BNSS section found.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final e = r.index;
                      return Card(
                        child: ListTile(
                          onTap: () => _showDetail(r),
                          leading: CircleAvatar(
                            child: Text(e.code.shortName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                          title: Text('Section ${e.section} — ${e.titleEn}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text([
                            if (e.oldSection.isNotEmpty) '${e.code.oldCodeName}: ${e.oldSection}',
                            r.hasVerifiedOfficialText ? '✓ Official text verified' : 'Comparison/index reference',
                          ].join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegalReferenceDetail extends StatefulWidget {
  final LegalSearchResult result;
  const _LegalReferenceDetail({required this.result});

  @override
  State<_LegalReferenceDetail> createState() => _LegalReferenceDetailState();
}

class _LegalReferenceDetailState extends State<_LegalReferenceDetail> {
  bool _translating = false;
  String? _translatedTitle;
  String? _translatedText;

  Future<void> _translateToBengali() async {
    final r = widget.result;
    final verified = r.verified;
    final source = verified?.officialTextEn ??
        [r.index.titleEn, if (r.index.comparisonNote.isNotEmpty) r.index.comparisonNote].join('. ');
    setState(() => _translating = true);
    try {
      final translator = BilingualTranslationService.instance;
      try {
        await translator.prepareForTexts([r.index.titleEn, source], targetLanguage: AppLanguage.bengali);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('বাংলা translation model প্রস্তুত হয়নি: $e')),
        );
        return;
      }
      final title = await translator.translate(r.index.titleEn, targetLanguage: AppLanguage.bengali);
      final text = await translator.translate(source, targetLanguage: AppLanguage.bengali);
      if (!mounted) return;
      setState(() {
        _translatedTitle = title;
        _translatedText = text;
      });
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final e = r.index;
    final v = r.verified;
    return Scaffold(
      appBar: AppBar(title: Text('${e.code.shortName} ${e.section}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(e.code.fullName, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text('Section ${e.section}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(e.titleEn, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('${e.code.shortName} Act ${e.code.actNumber}')),
            if (e.oldSection.isNotEmpty) Chip(label: Text('${e.code.oldCodeName} ${e.oldSection}')),
            Chip(
              avatar: Icon(v != null ? Icons.verified : Icons.info_outline, size: 18),
              label: Text(v != null ? 'Official verified text' : 'Comparison/index source'),
            ),
          ]),
          const Divider(height: 28),
          if (v != null) ...[
            const Text('Official / verified English', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            SelectableText(v.officialTextEn, textAlign: TextAlign.justify),
            const SizedBox(height: 10),
            Text(v.isFullSectionText ? 'Full section text bundled.' : 'Verified statutory extract / operational summary; consult the source for the complete provision.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            const Text('বাংলা সহায়ক ব্যাখ্যা', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            SelectableText(v.bengaliGuide, textAlign: TextAlign.justify),
            const SizedBox(height: 14),
            Text('Source: ${v.sourceLabel}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ] else ...[
            const Text('Offline section index', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            SelectableText(e.titleEn),
            if (e.comparisonNote.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Comparison note', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              SelectableText(e.comparisonNote, textAlign: TextAlign.justify),
            ],
            const SizedBox(height: 10),
            const Text('Note: v204 does not label this comparison/index text as the authoritative statutory text. Verify the complete provision against the official Act when legal wording is material.', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _translating ? null : _translateToBengali,
            icon: _translating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.translate),
            label: const Text('বাংলায় দেখুন (সহায়ক অনুবাদ)'),
          ),
          if (_translatedText != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_translatedTitle ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  SelectableText(_translatedText!),
                  const SizedBox(height: 8),
                  const Text('⚠ সহায়ক machine translation; official statutory Bengali text নয়।', style: TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
