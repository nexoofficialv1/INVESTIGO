import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/ud_narration_service.dart';

void main() {
  test('Bengali UD narration populates shared document fields', () {
    final result = UdNarrationService().analyse(
      'UD No: 10/2026; GDE No: 455 dated 02.08.2026। '
      'মৃত ব্যক্তির নাম: রমেশ দাস। মৃতের বয়স: 45 বছর। '
      'মৃতের লিঙ্গ: পুরুষ। মৃতদেহ পাওয়ার স্থান: নদীর ঘাট। '
      'দেহের অবস্থান: চিৎ অবস্থায় ছিল। পোশাক: নীল শার্ট। '
      'সম্ভাব্য মৃত্যুর কারণ: জলে ডুবে মৃত্যু। সাক্ষী ১: সুমন দাস, কালনা।',
    );

    expect(result.values['udNo'], '10/2026');
    expect(result.values['deceasedName'], 'রমেশ দাস');
    expect(result.values['placeFound'], 'নদীর ঘাট');
    expect(result.values['probableCauseOfDeath'], 'জলে ডুবে মৃত্যু');
    expect(result.values['briefFacts'], isNotEmpty);
  });

  test('English UD narration remains the source of brief facts', () {
    final result = UdNarrationService().analyse(
      'UD No: 11/2026\nName of deceased: John Doe\n'
      'Place where dead body found: Canal bank\n'
      'Probable cause of death: Drowning',
    );

    expect(result.values['deceasedName'], 'John Doe');
    expect(result.values['placeFound'], 'Canal bank');
    expect(result.values['briefFacts'], contains('John Doe'));
  });
}
