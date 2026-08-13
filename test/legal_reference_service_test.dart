import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/models/legal_reference.dart';
import 'package:investigo/services/legal_reference_service.dart';

void main() {
  final service = LegalReferenceService();

  test('BNS 281 resolves to final rash driving section, not draft-bill 281', () {
    final result = service.search('BNS 281').first;
    expect(result.index.code, LegalCode.bns);
    expect(result.index.section, '281');
    expect(result.index.titleEn.toLowerCase(), contains('rash driving'));
    expect(result.index.oldSection, contains('279'));
    expect(result.verified, isNotNull);
  });

  test('Case 605 section string resolves all BNS refs', () {
    final results = service.search('281/125(b)/324(4) BNS', limit: 20);
    final sections = results.map((e) => e.index.section).toSet();
    expect(sections, containsAll(<String>['281', '125(b)', '324(4)']));
  });

  test('BNSS 180 and old CrPC 161 are searchable', () {
    final direct = service.search('BNSS 180').first;
    expect(direct.index.titleEn, contains('Examination of witnesses'));
    final old = service.search('CrPC 161').first;
    expect(old.index.code, LegalCode.bnss);
    expect(old.index.section, '180');
  });

  test('BNSS case diary section 192 is indexed and verified', () {
    final result = service.search('case diary BNSS').where((e) => e.index.section == '192').first;
    expect(result.index.titleEn.toLowerCase(), contains('diary'));
    expect(result.verified, isNotNull);
  });

  test('base section search also finds indexed subsections', () {
    final results = service.search('BNS 103', limit: 20);
    final sections = results.map((e) => e.index.section).toSet();
    expect(sections, containsAll(<String>['103(1)', '103(2)']));
  });

  test('citation parser extracts subsection references', () {
    expect(
      LegalReferenceService.extractSectionTokens('281/125(b)/324(4) BNS'),
      containsAll(<String>['281', '125(b)', '324(4)']),
    );
  });
}
