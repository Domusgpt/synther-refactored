import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/core/parameter_definitions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('portamento metrics progress towards target frequency', () async {
    final backend = BasicAudioBackend();
    await backend.initialize();

    backend.setParameter(SynthParameterId.glideTime, 0.5);

    backend.noteOn(1, 60, 1.0);
    backend.getVisualizerData();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    backend.noteOn(2, 72, 1.0);
    final start = backend.getVisualizerData()['portamentoProgress'] ?? 1.0;

    await Future<void>.delayed(const Duration(milliseconds: 220));
    final mid = backend.getVisualizerData()['portamentoProgress'] ?? 1.0;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final end = backend.getVisualizerData()['portamentoProgress'] ?? 0.0;

    expect(start, lessThan(0.25));
    expect(mid, greaterThan(start));
    expect(mid, lessThan(0.95));
    expect(end, closeTo(1.0, 0.05));

    backend.dispose();
  });

  test('granular and wavetable metrics mirror parameter state', () async {
    final backend = BasicAudioBackend();
    await backend.initialize();

    backend.setParameter(SynthParameterId.granularActive, 1.0);
    backend.setParameter(SynthParameterId.granularGrainRate, 42.0);
    backend.setParameter(SynthParameterId.granularGrainDuration, 0.25);
    backend.setParameter(SynthParameterId.granularPitch, 3.5);
    backend.setParameter(SynthParameterId.granularPanVariation, 0.8);
    backend.setParameter(SynthParameterId.wavetablePosition, 0.65);
    backend.setParameter(SynthParameterId.microphoneVolume, 0.45);
    backend.setParameter(SynthParameterId.modWheel, 0.75);
    backend.setParameter(SynthParameterId.channelAftertouch, 0.6);
    backend.setParameter(SynthParameterId.expression, 1.2);
    backend.setParameter(SynthParameterId.sustainPedal, 0.7);

    final metrics = backend.getVisualizerData();

    expect(metrics['granularActive'], closeTo(1.0, 1e-9));
    expect(metrics['granularGrainRate'], closeTo(42.0, 1e-9));
    expect(metrics['granularGrainDuration'], closeTo(0.25, 1e-9));
    expect(metrics['granularPitch'], closeTo(3.5, 1e-9));
    expect(metrics['granularPanVariation'], closeTo(0.8, 1e-9));
    expect(metrics['wavetablePosition'], closeTo(0.65, 1e-9));
    expect(metrics['microphoneVolume'], closeTo(0.45, 1e-9));
    expect(metrics['modWheel'], closeTo(0.75, 1e-9));
    expect(metrics['channelAftertouch'], closeTo(0.6, 1e-9));
    expect(metrics['expression'], closeTo(1.0, 1e-9));
    expect(metrics['sustainPedal'], closeTo(0.7, 1e-9));
    expect(metrics['performanceEnergy'], closeTo((0.75 + 0.6 + 1.0) / 3, 1e-9));
    expect(metrics['sustainActive'], closeTo(1.0, 1e-9));

    backend.dispose();
  });
}
