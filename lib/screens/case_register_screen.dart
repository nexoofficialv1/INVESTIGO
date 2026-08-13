import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/investigo_ui.dart';
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
  final TextEditingController _search = TextEditingController();
  List<CaseFile> _cases = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cases = await _store.loadCases();
    if (!mounted) return;
    setState(() {
      _cases = cases;
      _loading = false;
    });
  }

  Future<void> _newCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseFormScreen(profile: widget.profile)),
    );
    await _load();
  }

  Future<void> _open(CaseFile file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDetailScreen(profile: widget.profile, caseFile: file),
      ),
    );
    await _load();
  }

  List<CaseFile> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    return _cases.where((file) {
      if (_filter == 'recent' && now.difference(file.createdAt).inDays > 7) {
        return false;
      }
      if (_filter == 'accused' && file.accusedName.trim().isEmpty) {
        return false;
      }
      if (_filter == 'no_accused' && file.accusedName.trim().isNotEmpty) {
        return false;
      }
      if (q.isEmpty) return true;
      final hay = <String>[
        file.psCaseNo,
        file.sections,
        file.crimeHead,
        file.complainantName,
        file.victimName,
        file.accusedName,
        file.placeOfOccurrence,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: Text(L10n.t('কেস তালিকা', 'Case List')),
        actions: [
          IconButton(onPressed: _newCase, icon: const Icon(Icons.add_rounded)),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: L10n.t(
                        'কেস নম্বর / ধারা / নাম লিখুন',
                        'Search case no. / section / name',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('all', L10n.t('সব', 'All')),
                        _chip('recent', L10n.t('সাম্প্রতিক', 'Recent')),
                        _chip('accused', L10n.t('অভিযুক্ত আছে', 'Accused named')),
                        _chip('no_accused', L10n.t('অভিযুক্ত নেই', 'No accused name')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InvestigoPageTitle(
                    title: L10n.t('${_filtered.length}টি মামলা', '${_filtered.length} cases'),
                    subtitle: L10n.t(
                      'কার্ডে চাপলেই মামলার সব কাজ খুলবে',
                      'Tap a card to open all case work',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_filtered.isEmpty)
                    Container(
                      decoration: InvestigoUi.cardDecoration(),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 40, color: InvestigoUi.muted),
                          const SizedBox(height: 10),
                          Text(
                            L10n.t('কোনো মামলা পাওয়া যায়নি', 'No matching case found'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filtered.map(_caseCard),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCase,
        backgroundColor: InvestigoUi.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(L10n.t('নতুন মামলা', 'New Case')),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: InvestigoUi.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : InvestigoUi.text,
          fontWeight: FontWeight.w800,
        ),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _caseCard(CaseFile file) {
    final complainant = file.complainantName.trim().isEmpty
        ? L10n.t('নাম দেওয়া নেই', 'Not entered')
        : file.complainantName.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(file),
          borderRadius: BorderRadius.circular(InvestigoUi.radius),
          child: Ink(
            decoration: InvestigoUi.cardDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: InvestigoUi.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.folder_copy_outlined, color: InvestigoUi.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.displayTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: InvestigoUi.text,
                              ),
                            ),
                          ),
                          const InvestigoStatusChip(label: 'Case'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        file.sections.trim().isEmpty
                            ? L10n.t('ধারা দেওয়া নেই', 'Sections not entered')
                            : 'U/S ${file.sections}',
                        style: const TextStyle(
                          color: InvestigoUi.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${L10n.t('অভিযোগকারী', 'Complainant')}: $complainant',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: InvestigoUi.muted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${L10n.t('তারিখ', 'Date')}: ${file.caseDate}',
                        style: const TextStyle(color: InvestigoUi.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 13),
                  child: Icon(Icons.chevron_right_rounded, color: InvestigoUi.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
