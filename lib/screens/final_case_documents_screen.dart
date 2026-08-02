import 'package:flutter/material.dart';

import '../data/domain/case_investigation_store.dart';
import '../models/case_file.dart';
import '../models/final_case_documents.dart';
import '../models/officer_profile.dart';
import '../models/regular_case_document_data.dart';
import '../services/final_case_document_service.dart';
import 'final_case_document_editor_screen.dart';

class FinalCaseDocumentsScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const FinalCaseDocumentsScreen({
    super.key,
    required this.profile,
    required this.caseFile,
  });

  @override
  State<FinalCaseDocumentsScreen> createState() => _FinalCaseDocumentsScreenState();
}

class _FinalCaseDocumentsScreenState extends State<FinalCaseDocumentsScreen> {
  final _store = CaseInvestigationStore();
  final _service = const FinalCaseDocumentService();
  bool _loading = true;
  List<String> _issues = const [];
  FinalCdDraft? _finalCd;
  ChargeSheetDraft? _chargeSheet;
  If5Draft? _if5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cds = await _store.loadCds(widget.caseFile.id);
    final statements = await _store.loadStatements(widget.caseFile.id);
    final source = RegularCaseDocumentData(
      caseFile: widget.caseFile,
      caseDiaries: cds,
      witnessStatements: statements,
      investigationSummary: cds
          .expand((e) => e.tableLines)
          .map((e) => e.proceedings.trim())
          .where((e) => e.isNotEmpty)
          .join('\n\n'),
      accusedStatusSummary: widget.caseFile.accusedName,
      reliedDocumentsSummary: '',
      resultCommunication: '',
    );
    final generated = _service.buildDrafts(source);
    final savedFinalCd = await _store.loadFinalCdDraft(widget.caseFile.id);
    final savedCs = await _store.loadChargeSheetDraft(widget.caseFile.id);
    final savedIf5 = await _store.loadIf5Draft(widget.caseFile.id);
    if (!mounted) return;
    setState(() {
      _issues = _service.validateForClosure(source);
      _finalCd = savedFinalCd ?? generated.finalCd;
      _chargeSheet = savedCs ?? generated.chargeSheet;
      _if5 = savedIf5 ?? generated.if5;
      _loading = false;
    });
  }

  Future<void> _open(FinalCaseDocumentKind kind) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalCaseDocumentEditorScreen(
          profile: widget.profile,
          caseFile: widget.caseFile,
          kind: kind,
          finalCd: _finalCd,
          chargeSheet: _chargeSheet,
          if5: _if5,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Final Case Documents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_issues.isNotEmpty)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Closure readiness warnings', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ..._issues.map((e) => Text('• $e')),
                        ],
                      ),
                    ),
                  ),
                _tile(
                  title: 'Final CD',
                  subtitle: 'Daily CD থেকে আলাদা final investigation narrative',
                  approved: _finalCd?.approved ?? false,
                  onTap: () => _open(FinalCaseDocumentKind.finalCd),
                ),
                _tile(
                  title: 'Charge Sheet',
                  subtitle: 'Accused, witness, documents এবং brief facts',
                  approved: _chargeSheet?.approved ?? false,
                  onTap: () => _open(FinalCaseDocumentKind.chargeSheet),
                ),
                _tile(
                  title: 'IF-5 / Final Form',
                  subtitle: 'W.B.P. Form No. 39 structured final form',
                  approved: _if5?.approved ?? false,
                  onTap: () => _open(FinalCaseDocumentKind.if5),
                ),
                const SizedBox(height: 10),
                const Text(
                  'তিনটি document একই Regular Case data source ব্যবহার করে, কিন্তু আলাদা draft, save, approval, PDF ও DOC থাকবে।',
                ),
              ],
            ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required bool approved,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(approved ? Icons.verified : Icons.edit_document),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$subtitle\nStatus: ${approved ? 'Approved' : 'Draft'}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
