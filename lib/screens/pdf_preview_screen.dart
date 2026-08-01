import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
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

  Future<void> _exportPdf(BuildContext context) async {
    if (onFinalSave != null) await onFinalSave!();
    final bytes = await buildPdf();
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _exportDoc(BuildContext context) async {
    final docBuilder = buildDoc;
    if (docBuilder == null) return;
    if (onFinalSave != null) await onFinalSave!();
    final bytes = await docBuilder();
    final dir = await getTemporaryDirectory();
    final safeName = docFilename ?? filename.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '.doc');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  onPressed: () => _exportPdf(context),
                ),
              ),
              if (buildDoc != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('DOC'),
                    onPressed: () => _exportDoc(context),
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
          Expanded(
            child: PdfPreview(
              build: (_) => buildPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: false,
              pdfFileName: filename,
            ),
          ),
        ],
      ),
    );
  }
}
