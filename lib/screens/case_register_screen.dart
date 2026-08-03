import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';

class CaseRegisterScreen extends StatefulWidget {
  final OfficerProfile profile;

  const CaseRegisterScreen({super.key, required this.profile});

  @override
  State<CaseRegisterScreen> createState() => _CaseRegisterScreenState();
}

class _CaseRegisterScreenState extends State<CaseRegisterScreen> {
  final LocalStoreService _store = LocalStoreService();
  List<CaseFile> _cases = <CaseFile>[];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final cases = await _store.loadCases();
      if (!mounted) return;
      setState(() {
        _cases = cases;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Case register load failed: $error')),
      );
    }
  }

  List<CaseFile> get _visibleCases {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _cases;
    return _cases.where((file) {
      final searchable = <String>[
        file.psCaseNo,
        file.caseDate,
        file.sections,
        file.crimeHead,
        file.complainantName,
        file.victimName,
        file.accusedName,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _createCase() async {
    final createdId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CaseFormScreen(profile: widget.profile),
      ),
    );
    await _load();
    if (!mounted || createdId == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.t('নতুন মামলা সংরক্ষিত হয়েছে', 'New case saved')),
      ),
    );
  }

  Future<void> _editCase(CaseFile file) async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CaseFormScreen(
          profile: widget.profile,
          existing: file,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openCase(CaseFile file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDetailScreen(
          profile: widget.profile,
          caseFile: file,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCases = _visibleCases;
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.t('মামলা রেজিস্টার', 'Case Register')),
        actions: <Widget>[
          IconButton(
            tooltip: L10n.t('নতুন মামলা', 'New Case'),
            onPressed: _createCase,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCase,
        icon: const Icon(Icons.add),
        label: Text(L10n.t('নতুন মামলা', 'New Case')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: L10n.t(
                  'কেস নম্বর, ধারা, অভিযোগকারী বা অভিযুক্ত খুঁজুন',
                  'Search case no., sections, complainant or accused',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: <Widget>[
                Text(
                  L10n.t(
                    'মোট মামলা: ${_cases.length}',
                    'Total cases: ${_cases.length}',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_query.trim().isNotEmpty)
                  Text(
                    L10n.t(
                      'ফলাফল: ${visibleCases.length}',
                      'Results: ${visibleCases.length}',
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: visibleCases.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              const SizedBox(height: 100),
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  _cases.isEmpty
                                      ? L10n.t(
                                          'এখনও কোনো মামলা নেই',
                                          'No case has been created yet',
                                        )
                                      : L10n.t(
                                          'কোনো মিল পাওয়া যায়নি',
                                          'No matching case found',
                                        ),
                                ),
                              ),
                              if (_cases.isEmpty) ...<Widget>[
                                const SizedBox(height: 16),
                                Center(
                                  child: FilledButton.icon(
                                    onPressed: _createCase,
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      L10n.t(
                                        'প্রথম মামলা তৈরি করুন',
                                        'Create first case',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                            itemCount: visibleCases.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final file = visibleCases[index];
                              return Card(
                                child: ListTile(
                                  onTap: () => _openCase(file),
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(
                                    file.displayTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (file.caseDate.trim().isNotEmpty)
                                          Text(
                                            '${L10n.t('তারিখ', 'Date')}: ${file.caseDate}',
                                          ),
                                        if (file.sections.trim().isNotEmpty)
                                          Text(
                                            '${L10n.t('ধারা', 'Sections')}: ${file.sections}',
                                          ),
                                        if (file.complainantName.trim().isNotEmpty)
                                          Text(
                                            '${L10n.t('অভিযোগকারী', 'Complainant')}: ${file.complainantName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'open') {
                                        _openCase(file);
                                      } else if (value == 'edit') {
                                        _editCase(file);
                                      }
                                    },
                                    itemBuilder: (_) => <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'open',
                                        child: Text(L10n.t('খুলুন', 'Open')),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text(L10n.t('সম্পাদনা', 'Edit')),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
