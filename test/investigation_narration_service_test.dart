import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/investigation_narration_service.dart';

void main() {
  final service = InvestigationNarrationService();

  test('analysis is offline and splits action-specific paragraphs', () {
    final result = service.analyse(
      'আজ সকাল ১০টায় গ্রাম কাশীপুর ঘটনাস্থল পরিদর্শন করলাম। পরে দুইজন সাক্ষীর বিবৃতি রেকর্ড করলাম।',
    );

    expect(result.processedOffline, isTrue);
    expect(result.context.witnessCount, 2);
    expect(result.context.times, isNotEmpty);
    final po = result.suggestions.firstWhere(
      (e) => e.actionType == 'PO Visit / Local Enquiry',
    );
    final witness = result.suggestions.firstWhere(
      (e) => e.actionType == 'Witness Examination / Statement Record',
    );
    expect(po.paragraph, contains('ঘটনাস্থল'));
    expect(po.paragraph, isNot(contains('সাক্ষীর বিবৃতি')));
    expect(witness.paragraph, contains('সাক্ষীর বিবৃতি'));
  });

  test('CD-1 narration identifies normal first-day work', () {
    final result = service.analyse(
      'আজ ঘটনাস্থল পরিদর্শন করে অভিযোগকারীকে পরীক্ষা করলাম। দুইজন সাক্ষীর বিবৃতি রেকর্ড করলাম। rough sketch map with index প্রস্তুত করলাম।',
    );
    final types = result.suggestions.map((e) => e.actionType).toSet();
    expect(types, contains('PO Visit / Local Enquiry'));
    expect(types, contains('Complainant Examination / Statement Record'));
    expect(types, contains('Witness Examination / Statement Record'));
    expect(types, contains('Rough Sketch Map Prepared'));
    expect(types, contains('Index Prepared'));
  });

  test('later witness work does not create PO visit', () {
    final result = service.analyse(
      'আজ আরও একজন সাক্ষীকে পরীক্ষা করে তার বিবৃতি রেকর্ড করলাম।',
    );
    expect(result.suggestions.any((e) => e.actionType.contains('Witness')), isTrue);
    expect(result.suggestions.any((e) => e.actionType.contains('PO Visit')), isFalse);
  });

  test('extracts witness names from narration', () {
    final result = service.analyse(
      'সাক্ষী নামে রমেশ দাস ও সুরেশ পালকে পরীক্ষা করে সাক্ষীদের বিবৃতি রেকর্ড করলাম।',
    );
    expect(result.context.witnessNames, contains('রমেশ দাস'));
    expect(result.context.witnessNames, contains('সুরেশ পাল'));
  });

  test('sketch map without index creates review warning', () {
    final result = service.analyse(
      'সকাল ১১:30 hrs ঘটনাস্থলের rough sketch map প্রস্তুত করলাম।',
    );
    expect(result.warnings.any((e) => e.contains('Index')), isTrue);
  });
}
