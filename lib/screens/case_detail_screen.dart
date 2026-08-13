import 'package:flutter/material.dart';

import '../data/domain/case_investigation_store.dart';
import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../widgets/investigo_ui.dart';
import 'case_form_screen.dart';
import 'cd_builder_screen.dart';
import 'cd_editor_screen.dart';
import 'compliance_screen.dart';
import 'evidence_screen.dart';
import 'final_case_documents_screen.dart';
import 'forms_screen.dart';
import 'investigation_assistant_screen.dart';
import 'investigation_screen.dart';
import 'legal_reference_screen.dart';
import 'report_screen.dart';
import 'sketch_map_screen.dart';
import 'statement_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CaseDetailScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final CaseInvestigationStore _store = CaseInvestigationStore();
  late CaseFile _caseFile;
  List<CdEntry> _cds = [];

  @override
  void initState() {
    super.initState();
    _caseFile = widget.caseFile;
    _load();
  }

  Future<void> _load() async {
    final cds = await _store.loadCds(_caseFile.id);
    final allCases = await _store.loadCases();
    CaseFile? refreshed;
    for (final item in allCases) {
      if (item.id == _caseFile.id) {
        refreshed = item;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _cds = cds;
      if (refreshed != null) _caseFile = refreshed!;
    });
  }

  Future<void> _editCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseFormScreen(
          profile: widget.profile,
          existing: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _newCd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CdBuilderScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openCd(CdEntry cd) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CdEditorScreen(
          profile: widget.profile,
          caseFile: _caseFile,
          cd: cd,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openStatements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatementScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
  }

  Future<void> _openForms() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormsScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
  }

  Future<void> _openSketchMap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SketchMapScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openInvestigation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestigationScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openSmartNarration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestigationAssistantScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openEvidence() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenceScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openFinalCaseDocuments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalCaseDocumentsScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openCompliance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplianceScreen(caseFile: _caseFile)),
    );
  }


  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          profile: widget.profile,
          caseFile: _caseFile,
        ),
      ),
    );
  }

  Future<void> _openLegalReference() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalReferenceScreen(initialQuery: _caseFile.sections),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: Text(_caseFile.displayTitle),
        actions: [
          IconButton(
            tooltip: 'Edit case',
            onPressed: _editCase,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _caseSummary(),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: InvestigoUi.primaryButtonStyle(),
              onPressed: _newCd,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _cds.isEmpty
                    ? 'CD-I তৈরি করুন / Create CD-I'
                    : 'পরবর্তী CD তৈরি করুন / Create Next CD',
              ),
            ),
            const SizedBox(height: 20),
            const InvestigoPageTitle(
              title: 'এই মামলার কাজ',
              subtitle: 'যে কাজটি করবেন সেটিতে চাপুন',
            ),
            const SizedBox(height: 12),
            _moduleGrid(),
            const SizedBox(height: 22),
            InvestigoPageTitle(
              title: 'Case Diaries',
              subtitle: _cds.isEmpty
                  ? 'এখনও কোনো CD তৈরি হয়নি'
                  : '${_cds.length}টি CD পাওয়া গেছে',
            ),
            const SizedBox(height: 10),
            if (_cds.isEmpty)
              Container(
                decoration: InvestigoUi.cardDecoration(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 40, color: InvestigoUi.muted),
                    const SizedBox(height: 9),
                    const Text(
                      'প্রথম CD তৈরি করতে উপরের বড় বাটনে চাপুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, color: InvestigoUi.muted),
                    ),
                  ],
                ),
              )
            else
              ..._cds.map(_cdCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newCd,
        backgroundColor: InvestigoUi.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _caseSummary() {
    return Container(
      decoration: InvestigoUi.cardDecoration(),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _caseFile.displayTitle,
                  style: const TextStyle(
                    color: InvestigoUi.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const InvestigoStatusChip(label: 'Active'),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'U/S ${_caseFile.sections}',
            style: const TextStyle(
              color: InvestigoUi.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          _infoLine(Icons.calendar_today_outlined, 'Case Date', _caseFile.caseDate),
          _infoLine(Icons.person_outline, 'Complainant', _caseFile.complainantName),
          if (_caseFile.placeOfOccurrence.trim().isNotEmpty)
            _infoLine(Icons.location_on_outlined, 'P.O.', _caseFile.placeOfOccurrence),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: _openLegalReference,
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('ধারার অর্থ দেখুন / View Law'),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) {
    final shown = value.trim().isEmpty ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: InvestigoUi.muted),
          const SizedBox(width: 7),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: InvestigoUi.muted)),
          Expanded(child: Text(shown, style: const TextStyle(color: InvestigoUi.text))),
        ],
      ),
    );
  }

  Widget _moduleGrid() {
    final items = <_CaseTool>[
      _CaseTool(Icons.manage_search_outlined, 'তদন্ত', 'Investigation', _openInvestigation),
      _CaseTool(Icons.auto_awesome_outlined, 'Smart Narration', 'Narration → CD', _openSmartNarration),
      _CaseTool(Icons.groups_outlined, 'সাক্ষী', 'Statements', _openStatements),
      _CaseTool(Icons.description_outlined, 'ফর্ম ও নোটিশ', 'Forms', _openForms),
      _CaseTool(Icons.inventory_2_outlined, 'প্রমাণ', 'Evidence', _openEvidence),
      _CaseTool(Icons.map_outlined, 'স্কেচ ম্যাপ', 'Sketch Map', _openSketchMap),
      _CaseTool(Icons.checklist_outlined, 'কমপ্লায়েন্স', 'Compliance', _openCompliance),
      _CaseTool(Icons.fact_check_outlined, 'Final CD / CS', 'Final Documents', _openFinalCaseDocuments),
      _CaseTool(Icons.summarize_outlined, 'রিপোর্ট', 'Case Report', _openReport),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return InvestigoActionCard(
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          onTap: item.onTap,
        );
      },
    );
  }

  Widget _cdCard(CdEntry cd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(InvestigoUi.radius),
          onTap: () => _openCd(cd),
          child: Ink(
            decoration: InvestigoUi.cardDecoration(),
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InvestigoUi.primary.withOpacity(.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${cd.cdNumber}',
                      style: const TextStyle(
                        color: InvestigoUi.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CD-${cd.cdNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text('${cd.cdDate} • ${cd.isFinal ? 'Final' : 'Draft'}', style: const TextStyle(color: InvestigoUi.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: InvestigoUi.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseTool {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CaseTool(this.icon, this.title, this.subtitle, this.onTap);
}
