import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/cd_entry.dart';

void main() {
  test('new CD draft preserves an explicitly selected historical diary date', () {
    final cd = CdEntry.newDraft(
      caseId: 'case-date-test',
      cdNumber: 1,
      body: 'Investigation proceedings',
      placeOfEntry: 'Police Station',
      diaryDate: '2026-08-10',
    );

    expect(cd.cdDate, '2026-08-10');
    expect(cd.createdAt, isA<DateTime>());
  });

  test('CD builder exposes and propagates the selected diary date', () {
    final source =
        File('lib/screens/cd_builder_screen.dart').readAsStringSync();

    expect(source, contains('সিডির তারিখ / Case Diary Date'));
    expect(source, contains('onTap: _pickCdDate'));
    expect(source, contains('diaryDate: _selectedCdDate'));
    expect(source, contains('date: _selectedCdDate'));
    expect(source, contains('lastDate: today'));
  });

  test('CD editor uses a date picker instead of free-typing the diary date', () {
    final source =
        File('lib/screens/cd_editor_screen.dart').readAsStringSync();

    expect(source, contains('readOnly: true'));
    expect(source, contains('onTap: _pickCdDate'));
    expect(source, contains('lastDate: today'));
  });
}
