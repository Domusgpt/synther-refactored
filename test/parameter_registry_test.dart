import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/parameter_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParameterRegistry', () {
    final registry = ParameterRegistry.instance;

    test('canonicalize resolves aliases and ignores unknown parameters', () {
      final canonical = registry.canonicalize(<String, double>{
        'volume': 0.4,
        'cutoff_hz': 28000,
        'env_release': 1.8,
        'unknown': 123,
      });

      expect(canonical.length, 3);
      expect(canonical['masterVolume'], closeTo(0.4, 1e-9));
      expect(canonical['filterCutoff'], closeTo(20000, 1e-9));
      expect(canonical['releaseTime'], closeTo(1.8, 1e-9));
      expect(canonical.containsKey('unknown'), isFalse);
    });

    test('expandWithAliases mirrors canonical values to bridge aliases', () {
      final expanded = registry.expandWithAliases(<String, double>{
        'masterVolume': 0.3,
        'maxPolyphony': 12,
      });

      expect(expanded['masterVolume'], closeTo(0.3, 1e-9));
      expect(expanded['volume'], closeTo(0.3, 1e-9));
      expect(expanded['maxPolyphony'], closeTo(12, 1e-9));
      expect(expanded['polyphony'], closeTo(12, 1e-9));
      expect(expanded['voices'], closeTo(12, 1e-9));
    });

    test('defaultValue exposes descriptor defaults', () {
      expect(registry.defaultValue('masterVolume'), closeTo(0.75, 1e-9));
      expect(registry.defaultValue('delayFeedback'), closeTo(0.2, 1e-9));
      expect(registry.defaultValue('doesNotExist'), isNull);
    });
  });
}
