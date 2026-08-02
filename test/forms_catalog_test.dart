import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/forms_generator_service.dart';

void main() {
  test('RC form catalog contains FSL 5203 and A Form', () {
    final ids = FormsGeneratorService.templates.map((e) => e.id).toSet();
    expect(ids, contains('fsl'));
    expect(ids, contains('a_form'));
  });
}
