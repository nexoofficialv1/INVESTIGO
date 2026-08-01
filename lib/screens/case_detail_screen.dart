import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/cd_entry.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import 'case_form_screen.dart';
import 'cd_builder_screen.dart';
import 'cd_editor_screen.dart';
import 'forms_screen.dart';
import 'statement_screen.dart';
import 'compliance_screen.dart';
import 'sketch_map_screen.dart';
import 'evidence_screen.dart';
import 'investigation_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const CaseDetailScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final LocalStoreService _store = LocalStoreService();
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
      if (refreshed != null) _caseFile = refreshed;
    });
  }

  Future<void> _editCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseFormScreen(profile: widget.profile, existing: _caseFile)),
    );
    await _load();
  }

  Future<void> _newCd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CdBuilderScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openCd(CdEntry cd) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CdEditorScreen(profile: widget.profile, caseFile: _caseFile, cd: cd)),
    );
    await _load();
  }

  Future<void> _openStatements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatementScreen(profile: widget.profile, caseFile: _caseFile)),
    );
  }

  Future<void> _openForms() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormsScreen(profile: widget.profile, caseFile: _caseFile)),
    );
  }


  Future<void> _openSketchMap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SketchMapScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openInvestigation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvestigationScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openEvidence() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EvidenceScreen(profile: widget.profile, caseFile: _caseFile)),
    );
    await _load();
  }

  Future<void> _openCompliance() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplianceScreen(caseFile: _caseFile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_caseFile.displayTitle),
        actions: [IconButton(onPressed: _editCase, icon: const Icon(Icons.edit))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newCd,
        icon: const Icon(Icons.add),
        label: const Text('Add CD'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Date: ${_caseFile.caseDate}'),
                    Text('Sections: ${_caseFile.sections}'),
                    if (_caseFile.complainantName.isNotEmpty) Text('Complainant: ${_caseFile.complainantName}', maxLines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _moduleCard('Investigation', Icons.manage_search, _openInvestigation),
                _moduleCard('CD Writer', Icons.note_alt, _newCd),
                _moduleCard('Statements', Icons.record_voice_over, _openStatements),
                _moduleCard('Forms', Icons.description, _openForms),
                _moduleCard('Compliance', Icons.checklist, _openCompliance),
                _moduleCard('Evidence', Icons.inventory_2, _openEvidence),
                _moduleCard('Sketch Map', Icons.map, _openSketchMap),
              ],
            ),
            const SizedBox(height: 18),
            Text('Case Diaries', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_cds.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No CD created yet. Tap Add CD.')))
            else
              ..._cds.map((cd) => Card(
                    child: ListTile(
                      title: Text('CD-${cd.cdNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${cd.cdDate} • ${cd.isFinal ? 'Final Saved' : 'Draft'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openCd(cd),
                    ),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

}
