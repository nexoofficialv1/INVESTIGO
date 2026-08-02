import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String title;
  final String filename;
  final Future<Uint8List> Function() buildPdf;
  final String? docFilename;
  final Future<Uint8List> Function()? buildDoc;
  final Future<void> Function()? onFinalSave;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.filename,
    required this.buildPdf,
    this.docFilename,
    this.buildDoc,
    this.onFinalSave,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late Future<Uint8List> _pdfFuture;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _pdfFuture = Future<Uint8List>.sync(widget.buildPdf);
  }

  void _retryPreview() {
    setState(() {
      _pdfFuture = Future<Uint8List>.sync(widget.buildPdf);
    });
  }

  void _showError(String action, Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action ব্যর্থ হয়েছে: $error'),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      if (widget.onFinalSave != null) await widget.onFinalSave!();
      final bytes = await _pdfFuture;
      await Printing.sharePdf(bytes: bytes, filename: widget.filename);
    } catch (error) {
      _showError('PDF export/share', error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportDoc() async {
    final docBuilder = widget.buildDoc;
    if (docBuilder == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      if (widget.onFinalSave != null) await widget.onFinalSave!();
      final bytes = await docBuilder();
      final dir = await getTemporaryDirectory();
      final safeName = widget.docFilename ??
          widget.filename.replaceAll(
            RegExp(r'\.pdf$', caseSensitive: false),
            '.doc',
          );
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: widget.title);
    } catch (error) {
      _showError('DOC export/share', error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _previewBody() {
    return FutureBuilder<Uint8List>(
      future: _pdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Preview তৈরি হচ্ছে...'),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Preview তৈরি করা যায়নি',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${snapshot.error ?? 'Unknown PDF generation error'}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retryPreview,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final bytes = snapshot.data!;
        return PdfPreview(
          build: (_) async => bytes,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: false,
          pdfFileName: widget.filename,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: _exporting ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  onPressed: _exporting ? null : _exportPdf,
                ),
              ),
              if (widget.buildDoc != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('DOC'),
                    onPressed: _exporting ? null : _exportDoc,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: Colors.amber.shade100,
            child: const Text(
              'Preview দেখে নাম, তারিখ, section, লেখা, page break ও official format ঠিক আছে কিনা verify করুন। ভুল থাকলে Edit চাপুন। ঠিক থাকলে PDF বা DOC export করুন।',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: _previewBody()),
        ],
      ),
    );
  }
}
