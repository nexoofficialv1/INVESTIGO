import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/ncr_report.dart';
import '../models/officer_profile.dart';
import '../services/doc_export_service.dart';
import '../data/domain/ncr_store.dart';
import '../services/pdf_service.dart';

class NcrScreen extends StatefulWidget {
  final OfficerProfile profile;
  const NcrScreen({super.key, required this.profile});

  @override
  State<NcrScreen> createState() => _NcrScreenState();
}

class _NcrScreenState extends State<NcrScreen> {
  final _store = NcrStore();
  final _pdf = PdfService();
  final _doc = DocExportService();
  final Map<String, TextEditingController> _c = {};
  List<NcrReport> _saved = [];
  late NcrReport _report;

  final List<_Field> _fields = const [
    _Field('formNo', 'পশ্চিমবঙ্গ ফর্ম নং', 'West Bengal Form No.'),
    _Field('reportYear', 'সাল', 'Year'),
    _Field('reference', 'রেফারেন্স', 'Reference', lines: 2),
    _Field('district', 'জেলা', 'District'),
    _Field('policeStation', 'থানা', 'Police Station'),
    _Field('ncrNo', 'NCR নম্বর ও তারিখ', 'NCR Number & Date', lines: 2),
    _Field('caseSections', 'আইনের ধারা', 'Sections of Law'),
    _Field('complainantInformation', 'অভিযোগকারী অথবা তথ্য', 'Complainant Or Information', lines: 3),
    _Field('accusedDetails', 'অভিযুক্তের নাম ও ঠিকানা', 'Name and Address of Accused', lines: 5),
    _Field('arrestDate', 'গ্রেপ্তারের তারিখ/অবস্থা', 'Date/Status of Arrest', lines: 2),
    _Field('hearingDate', 'শুনানির তারিখ/আদেশ', 'Date of Hearing/Order', lines: 2),
    _Field('offenceBrief', 'অপরাধের সংক্ষিপ্ত বিবরণ', 'Brief Description of Offence', lines: 8),
    _Field('witnessDetails', 'সাক্ষীর নাম ও ঠিকানা', 'Name and Address of Witness', lines: 5),
    _Field('trialResult', 'বিচারের ফলাফল', 'Result of Trial', lines: 4),
    _Field('remarks', 'মন্তব্য', 'Remarks', lines: 3),
    _Field('submittedBy', 'পেশকারী অফিসার', 'Submitted By'),
  ];

  @override
  void initState() {
    super.initState();
    _report = NcrReport.empty(
      ps: widget.profile.policeStation,
      district: widget.profile.district,
      submittedBy: '${widget.profile.rank} ${widget.profile.name}',
    );
    _initControllers();
    _loadSaved();
  }

  void _initControllers() {
    final map = _report.toJson();
    for (final f in _fields) {
      _c[f.key] = TextEditingController(text: (map[f.key] ?? '').toString());
    }
  }

  Future<void> _loadSaved() async {
    final list = await _store.loadNcrReports();
    if (!mounted) return;
    setState(() => _saved = list);
  }

  NcrReport _collect() => _report.copyWith({
        for (final f in _fields) f.key: _c[f.key]!.text.trim(),
        'policeStation': widget.profile.policeStation,
        'district': widget.profile.district,
        'submittedBy': '${widget.profile.rank} ${widget.profile.name}',
      });

  Future<void> _save() async {
    _report = _collect();
    await _store.saveNcrReport(_report);
    await _loadSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.t('NCR খসড়া সংরক্ষিত হয়েছে', 'NCR draft saved'))));
  }

  Future<void> _preview() async {
    _report = _collect();
    final bytes = await _pdf.buildNcrPdf(officer: widget.profile, report: _report);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf() async {
    _report = _collect();
    await _pdf.shareNcrPdf(officer: widget.profile, report: _report);
  }

  Future<void> _shareDoc() async {
    _report = _collect();
    final bytes = await _doc.buildNcrDoc(officer: widget.profile, report: _report);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/NCR_${_safeName(_report.ncrNo)}.doc');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: L10n.t('NCR DOC ফাইল', 'NCR DOC file'));
  }

  String _safeName(String value) => value.trim().isEmpty ? 'draft' : value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  void _newReport() {
    setState(() {
      _report = NcrReport.empty(
        ps: widget.profile.policeStation,
        district: widget.profile.district,
        submittedBy: '${widget.profile.rank} ${widget.profile.name}',
      );
      final map = _report.toJson();
      for (final f in _fields) {
        if (f.key == 'policeStation') {
          _c[f.key]!.text = widget.profile.policeStation;
        } else if (f.key == 'district') {
          _c[f.key]!.text = widget.profile.district;
        } else if (f.key == 'submittedBy') {
          _c[f.key]!.text = '${widget.profile.rank} ${widget.profile.name}';
        } else {
          _c[f.key]!.text = (map[f.key] ?? '').toString();
        }
      }
    });
  }

  void _loadReport(NcrReport report) {
    setState(() {
      _report = report;
      final map = report.toJson();
      for (final f in _fields) {
        if (f.key == 'policeStation') {
          _c[f.key]!.text = widget.profile.policeStation;
        } else if (f.key == 'district') {
          _c[f.key]!.text = widget.profile.district;
        } else if (f.key == 'submittedBy') {
          _c[f.key]!.text = '${widget.profile.rank} ${widget.profile.name}';
        } else {
          _c[f.key]!.text = (map[f.key] ?? '').toString();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(L10n.t('NCR তৈরি', 'Create NCR')),
        actions: [IconButton(onPressed: _newReport, icon: const Icon(Icons.add), tooltip: L10n.t('নতুন NCR', 'New NCR'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_saved.isNotEmpty) ...[
            Text(L10n.t('সংরক্ষিত NCR', 'Saved NCR'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _saved.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = _saved[i];
                  return SizedBox(
                    width: 230,
                    child: Card(
                      child: ListTile(
                        title: Text(item.ncrNo.isEmpty ? L10n.t('খসড়া NCR', 'Draft NCR') : item.ncrNo, maxLines: 1),
                        subtitle: Text(item.reference, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _loadReport(item),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    L10n.t('PRB Form No. 41 / West Bengal Form No. 5358', 'PRB Form No. 41 / West Bengal Form No. 5358'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ..._fields.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: _c[f.key],
                          readOnly: f.key == 'policeStation' ||
                              f.key == 'district' ||
                              f.key == 'submittedBy',
                          minLines: f.lines,
                          maxLines: f.lines,
                          decoration: InputDecoration(
                            labelText: L10n.t(f.bn, f.en),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: f.lines > 1,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(L10n.t('সংরক্ষণ', 'Save'))),
              OutlinedButton.icon(onPressed: _preview, icon: const Icon(Icons.preview), label: Text(L10n.t('প্রিভিউ', 'Preview'))),
              OutlinedButton.icon(onPressed: _sharePdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
              OutlinedButton.icon(onPressed: _shareDoc, icon: const Icon(Icons.description), label: const Text('DOC')),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Field {
  final String key;
  final String bn;
  final String en;
  final int lines;
  const _Field(this.key, this.bn, this.en, {this.lines = 1});
}
