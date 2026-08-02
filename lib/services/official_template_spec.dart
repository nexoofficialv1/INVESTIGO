/// Locked layout measurements for official forms.
/// Values are shared by renderers so Preview/PDF/DOC remain aligned.
abstract final class OfficialTemplateSpec {
  static const cdColumnRatios = <double>[0.10, 0.10, 0.13, 0.67];
  static const cdFormNo = '5363';
  static const cdBpFormNo = '38';

  static const finalCdColumnRatios = <double>[0.10, 0.10, 0.13, 0.67];

  static const if5FormNo = '39';
  static const if5PropertyColumnRatios = <double>[0.06, 0.24, 0.14, 0.16, 0.25, 0.15];
  static const if5WitnessColumnRatios = <double>[0.05, 0.17, 0.16, 0.11, 0.12, 0.24, 0.15];

  static const ncrFormNo = '5358';
  static const ncrColumnRatios = <double>[
    0.05,
    0.08,
    0.17,
    0.05,
    0.05,
    0.36,
    0.14,
    0.07,
    0.05,
  ];

  static double get ncrRatioTotal =>
      ncrColumnRatios.fold<double>(0, (total, value) => total + value);
}

