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
        'lfofreq': 0.01,
        'mod_depth': 1.5,
        'blend': -1,
        'detune': 24,
        'unisonWidth': 2,
        'drive': 3,
        'chorus_speed': 24,
        'portamento': 3.2,
        'pitch_bend_range': 36,
        'unknown': 123,
      });

      expect(canonical.length, 12);
      expect(canonical['masterVolume'], closeTo(0.4, 1e-9));
      expect(canonical['filterCutoff'], closeTo(20000, 1e-9));
      expect(canonical['releaseTime'], closeTo(1.8, 1e-9));
      expect(canonical['lfoRate'], closeTo(0.05, 1e-9));
      expect(canonical['lfoDepth'], closeTo(1.0, 1e-9));
      expect(canonical['oscillatorBlend'], closeTo(0.0, 1e-9));
      expect(canonical['oscillatorDetune'], closeTo(12, 1e-9));
      expect(canonical['oscillatorSpread'], closeTo(1.0, 1e-9));
      expect(canonical['distortionDrive'], closeTo(1.0, 1e-9));
      expect(canonical['chorusRate'], closeTo(12, 1e-9));
      expect(canonical['glideTime'], closeTo(3.2, 1e-9));
      expect(canonical['pitchBendRange'], closeTo(24, 1e-9));
      expect(canonical.containsKey('unknown'), isFalse);
    });

    test('expandWithAliases mirrors canonical values to bridge aliases', () {
      final expanded = registry.expandWithAliases(<String, double>{
        'masterVolume': 0.3,
        'maxPolyphony': 12,
        'lfoRate': 4.5,
        'lfoDepth': 0.65,
        'oscillatorBlend': 0.4,
        'chorusDepth': 0.3,
        'glideTime': 0.45,
        'pitchBendRange': 6,
      });

      expect(expanded['masterVolume'], closeTo(0.3, 1e-9));
      expect(expanded['volume'], closeTo(0.3, 1e-9));
      expect(expanded['maxPolyphony'], closeTo(12, 1e-9));
      expect(expanded['polyphony'], closeTo(12, 1e-9));
      expect(expanded['voices'], closeTo(12, 1e-9));
      expect(expanded['lfoRate'], closeTo(4.5, 1e-9));
      expect(expanded['lfoFrequency'], closeTo(4.5, 1e-9));
      expect(expanded['lfoDepth'], closeTo(0.65, 1e-9));
      expect(expanded['lfoAmount'], closeTo(0.65, 1e-9));
      expect(expanded['oscillatorBlend'], closeTo(0.4, 1e-9));
      expect(expanded['blend'], closeTo(0.4, 1e-9));
      expect(expanded['chorusDepth'], closeTo(0.3, 1e-9));
      expect(expanded['chorusMix'], closeTo(0.3, 1e-9));
      expect(expanded['glideTime'], closeTo(0.45, 1e-9));
      expect(expanded['portamento'], closeTo(0.45, 1e-9));
      expect(expanded['pitchBendRange'], closeTo(6, 1e-9));
      expect(expanded['pitchBend'], closeTo(6, 1e-9));
    });

    test('defaultValue exposes descriptor defaults', () {
      expect(registry.defaultValue('masterVolume'), closeTo(0.75, 1e-9));
      expect(registry.defaultValue('delayFeedback'), closeTo(0.2, 1e-9));
      expect(registry.defaultValue('lfoRate'), closeTo(2.0, 1e-9));
      expect(registry.defaultValue('oscillatorDetune'), closeTo(0.0, 1e-9));
      expect(registry.defaultValue('chorusDepth'), closeTo(0.35, 1e-9));
      expect(registry.defaultValue('glideTime'), closeTo(0.08, 1e-9));
      expect(registry.defaultValue('pitchBendRange'), closeTo(2.0, 1e-9));
      expect(registry.defaultValue('doesNotExist'), isNull);
    });
  });
}
