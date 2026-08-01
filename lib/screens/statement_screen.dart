import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../models/statement_entry.dart';
import '../services/local_store_service.dart';
import '../services/doc_export_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_screen.dart';
import '../widgets/form_helpers.dart';

class StatementScreen extends StatefulWidget {
  final OfficerProfile profile;
  final CaseFile caseFile;

  const StatementScreen({super.key, required this.profile, required this.caseFile});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final LocalStoreService _store = LocalStoreService();
  List<StatementEntry> statements = [];

  final witnessName = TextEditingController();
  final witnessDetails = TextEditingController();
  final statementType = TextEditingController(text: 'Complainant / Victim / Eye witness / Local witness');
  final body = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _store.loadStatements(widget.caseFile.id);
    if (!mounted) return;
    setState(() => statements = list);
  }

  @override
  void dispose() {
    witnessName.dispose();
    witnessDetails.dispose();
    statementType.dispose();
    body.dispose();
    super.dispose();
  }

  void _generateBasicDraft() {
    body.text = 'Today I examined the witness namely ${witnessName.text.trim()} in connection with ${widget.profile.policeStation} PS Case No. ${widget.caseFile.psCaseNo} dated ${widget.caseFile.caseDate} u/s ${widget.caseFile.sections}. The witness stated about the facts and circumstances of the case. The statement was recorded u/s 180 BNSS.';
  }

  Future<void> _saveStatement() async {
    if (witnessName.text.trim().isEmpty || body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Witness name and statement body required')));
      return;
    }
    final entry = StatementEntry.create(
      caseId: widget.caseFile.id,
      witnessName: witnessName.text.trim(),
      witnessDetails: witnessDetails.text.trim(),
      statementType: statementType.text.trim(),
      body: body.text.trim(),
    );
    await _store.saveStatement(entry);
    if (!mounted) return;
    witnessName.clear();
    witnessDetails.clear();
    body.clear();
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statement saved')));
  }

  Future<void> _preview(StatementEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Preview Statement',
          filename: 'Statement_${entry.witnessName}.pdf',
          docFilename: 'Statement_${entry.witnessName}.doc',
          buildPdf: () => PdfService().buildStatementPdf(officer: widget.profile, caseFile: widget.caseFile, statement: entry),
          buildDoc: () => DocExportService().buildStatementDoc(officer: widget.profile, caseFile: widget.caseFile, statement: entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Statement', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FormHelpers.textField(controller: witnessName, label: 'Witness Name'),
                  FormHelpers.textField(controller: witnessDetails, label: 'Witness Details', maxLines: 2),
                  FormHelpers.textField(controller: statementType, label: 'Statement Type'),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: _generateBasicDraft, icon: const Icon(Icons.auto_awesome), label: const Text('Generate Basic Draft'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FormHelpers.textField(controller: body, label: 'Statement Body', maxLines: 8),
                  FilledButton.icon(onPressed: _saveStatement, icon: const Icon(Icons.save), label: const Text('Save Statement')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Saved Statements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (statements.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No statement saved yet.')))
          else
            ...statements.map((e) => Card(
                  child: ListTile(
                    title: Text(e.witnessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(e.statementType),
                    trailing: IconButton(icon: const Icon(Icons.preview), onPressed: () => _preview(e)),
                  ),
                )),
        ],
      ),
    );
  }
}
