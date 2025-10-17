import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/parameter_bridge.dart';
import 'package:synther_holographic_pro/core/parameter_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParameterMapping', () {
    test('exponential mappings round-trip to the original value', () {
      final mapping = ParameterBridge.mappings['filterCutoff']!;
      const value = 5400.0;

      final normalized = mapping.normalize(value);
      final restored = mapping.denormalize(normalized);

      expect(restored, closeTo(value, value * 1e-6));
    });

    test('logarithmic mappings clamp normalized input to bounds', () {
      const mapping = ParameterMapping(
        range: ParameterRange(
          min: 0.01,
          max: 1.0,
          defaultValue: 0.01,
          curve: ParameterCurve.logarithmic,
        ),
        visualizerParam: 'test',
      );

      expect(mapping.denormalize(-1), closeTo(mapping.min, 1e-9));
      expect(mapping.denormalize(0), closeTo(mapping.min, 1e-9));
      expect(mapping.denormalize(1.5), closeTo(mapping.max, 1e-9));
    });
  });
}
