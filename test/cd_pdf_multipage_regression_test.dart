import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/cd_entry.dart';
import 'package:investigo/services/pdf_service.dart';

String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  test('multi-page CD planner preserves all proceedings after page one', () {
    final sentence =
        'Visited the place of occurrence, examined available witnesses, '
        'verified the relevant facts and recorded the investigation step. ';
    final body = List<String>.filled(90, sentence).join();

    final now = DateTime(2026, 8, 13, 21, 0);
    final cd = CdEntry(
      id: 'cd-multipage-regression',
      caseId: 'case-regression',
      cdNumber: 1,
      cdDate: '2026-08-13',
      startTime: '20.00 hrs.',
      endTime: '21.00 hrs.',
      placeOfEntry: 'Police Station',
      body: body,
      tableLines: [
        CdTableLine(
          noAndHour: 'I\n20.00 hrs.',
          placeOfEntry: 'Police Station',
          synopsis: 'Received copy of FIR\n+\nGist',
          proceedings: body,
        ),
      ],
      isFinal: false,
      createdAt: now,
      updatedAt: now,
    );

    final pages = PdfService().splitCdIntoPageChunksForTest(cd);

    expect(pages.length, greaterThan(1));
    expect(
      pages.skip(1).every(
            (page) =>
                page.tableLines.isNotEmpty &&
                page.tableLines.any((line) => line.proceedings.trim().isNotEmpty),
          ),
      isTrue,
    );

    final rebuilt = pages
        .expand((page) => page.tableLines)
        .map((line) => line.proceedings)
        .join(' ');

    expect(_normalize(rebuilt), _normalize(body));

    for (final page in pages) {
      for (final line in page.tableLines) {
        expect(
          line.proceedings.length,
          lessThanOrEqualTo(1000),
          reason: 'A fixed-page CD row must remain small enough to render.',
        );
      }
    }
  });
}
