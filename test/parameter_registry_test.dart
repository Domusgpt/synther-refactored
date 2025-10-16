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
        'modwheel': 1.6,
        'aftertouch': 0.85,
        'expression_pedal': 1.2,
        'holdpedal': -0.4,
        'granular_active': 2,
        'grain_rate': 120,
        'granular.grain_duration': 0.0001,
        'granular.position': 1.5,
        'granular.pitch': 5.0,
        'granular.amplitude': 1.4,
        'granular.position_variation': 2.0,
        'grainPitchVariation': 3.0,
        'granular.duration_variation': 2.0,
        'granular.pan_variation': 1.5,
        'grainPan': -2.0,
        'grainWindow': 8.0,
        'wavetable_position': 1.5,
        'micvolume': -0.4,
        'unknown': 123,
      });

      expect(canonical.length, 30);
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
      expect(canonical['modWheel'], closeTo(1.0, 1e-9));
      expect(canonical['channelAftertouch'], closeTo(0.85, 1e-9));
      expect(canonical['expression'], closeTo(1.0, 1e-9));
      expect(canonical['sustainPedal'], closeTo(0.0, 1e-9));
      expect(canonical['granularActive'], closeTo(1.0, 1e-9));
      expect(canonical['granularGrainRate'], closeTo(100, 1e-9));
      expect(canonical['granularGrainDuration'], closeTo(0.005, 1e-9));
      expect(canonical['granularPosition'], closeTo(1.0, 1e-9));
      expect(canonical['granularPitch'], closeTo(4.0, 1e-9));
      expect(canonical['granularAmplitude'], closeTo(1.0, 1e-9));
      expect(canonical['granularPositionVariation'], closeTo(1.0, 1e-9));
      expect(canonical['granularPitchVariation'], closeTo(2.0, 1e-9));
      expect(canonical['granularDurationVariation'], closeTo(1.0, 1e-9));
      expect(canonical['granularPanVariation'], closeTo(1.0, 1e-9));
      expect(canonical['granularPan'], closeTo(-1.0, 1e-9));
      expect(canonical['granularWindowType'], closeTo(3.0, 1e-9));
      expect(canonical['wavetablePosition'], closeTo(1.0, 1e-9));
      expect(canonical['microphoneVolume'], closeTo(0.0, 1e-9));
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
        'modWheel': 0.7,
        'channelAftertouch': 0.4,
        'expression': 0.9,
        'sustainPedal': 1.0,
        'granularActive': 1.0,
        'granularGrainRate': 24.0,
        'granularAmplitude': 0.72,
        'granularPan': 0.35,
        'granularPanVariation': 0.6,
        'granularWindowType': 2.0,
        'wavetablePosition': 0.75,
        'microphoneVolume': 0.4,
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
      expect(expanded['modWheel'], closeTo(0.7, 1e-9));
      expect(expanded['modulationWheel'], closeTo(0.7, 1e-9));
      expect(expanded['modWheelAmount'], closeTo(0.7, 1e-9));
      expect(expanded['channelAftertouch'], closeTo(0.4, 1e-9));
      expect(expanded['aftertouch'], closeTo(0.4, 1e-9));
      expect(expanded['pressure'], closeTo(0.4, 1e-9));
      expect(expanded['expression'], closeTo(0.9, 1e-9));
      expect(expanded['expressionPedal'], closeTo(0.9, 1e-9));
      expect(expanded['expressionAmount'], closeTo(0.9, 1e-9));
      expect(expanded['sustainPedal'], closeTo(1.0, 1e-9));
      expect(expanded['sustain'], closeTo(1.0, 1e-9));
      expect(expanded['holdPedal'], closeTo(1.0, 1e-9));
      expect(expanded['granularActive'], closeTo(1.0, 1e-9));
      expect(expanded['granularEnabled'], closeTo(1.0, 1e-9));
      expect(expanded['granularGrainRate'], closeTo(24.0, 1e-9));
      expect(expanded['grainRate'], closeTo(24.0, 1e-9));
      expect(expanded['granularAmplitude'], closeTo(0.72, 1e-9));
      expect(expanded['grainLevel'], closeTo(0.72, 1e-9));
      expect(expanded['granularPan'], closeTo(0.35, 1e-9));
      expect(expanded['grainPan'], closeTo(0.35, 1e-9));
      expect(expanded['granularPanVariation'], closeTo(0.6, 1e-9));
      expect(expanded['grainPanVariation'], closeTo(0.6, 1e-9));
      expect(expanded['granularWindowType'], closeTo(2.0, 1e-9));
      expect(expanded['grainWindow'], closeTo(2.0, 1e-9));
      expect(expanded['wavetablePosition'], closeTo(0.75, 1e-9));
      expect(expanded['tablePosition'], closeTo(0.75, 1e-9));
      expect(expanded['microphoneVolume'], closeTo(0.4, 1e-9));
      expect(expanded['micVolume'], closeTo(0.4, 1e-9));
    });

    test('defaultValue exposes descriptor defaults', () {
      expect(registry.defaultValue('masterVolume'), closeTo(0.75, 1e-9));
      expect(registry.defaultValue('delayFeedback'), closeTo(0.2, 1e-9));
      expect(registry.defaultValue('lfoRate'), closeTo(2.0, 1e-9));
      expect(registry.defaultValue('oscillatorDetune'), closeTo(0.0, 1e-9));
      expect(registry.defaultValue('chorusDepth'), closeTo(0.35, 1e-9));
      expect(registry.defaultValue('glideTime'), closeTo(0.08, 1e-9));
      expect(registry.defaultValue('pitchBendRange'), closeTo(2.0, 1e-9));
      expect(registry.defaultValue('modWheel'), closeTo(0.0, 1e-9));
      expect(
          registry.defaultValue('channelAftertouch'), closeTo(0.0, 1e-9));
      expect(registry.defaultValue('expression'), closeTo(1.0, 1e-9));
      expect(registry.defaultValue('sustainPedal'), closeTo(0.0, 1e-9));
      expect(registry.defaultValue('granularGrainRate'), closeTo(10.0, 1e-9));
      expect(registry.defaultValue('granularAmplitude'), closeTo(0.8, 1e-9));
      expect(registry.defaultValue('wavetablePosition'), closeTo(0.3, 1e-9));
      expect(registry.defaultValue('microphoneVolume'), closeTo(0.0, 1e-9));
      expect(registry.defaultValue('doesNotExist'), isNull);
    });
  });
}
