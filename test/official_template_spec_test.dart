import 'package:flutter_test/flutter_test.dart';
import 'package:investigo/services/official_template_spec.dart';

void main() {
  test('CD locked columns total 100 percent', () {
    final total = OfficialTemplateSpec.cdColumnRatios
        .fold<double>(0, (sum, value) => sum + value);
    expect(total, closeTo(1, 0.0001));
    expect(
      OfficialTemplateSpec.cdColumnRatios,
      equals(const <double>[0.09, 0.09, 0.11, 0.71]),
    );
  });

  test('NCR locked columns total expected width', () {
    expect(OfficialTemplateSpec.ncrRatioTotal, closeTo(1.02, 0.0001));
  });
}
