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

  test('arpeggiator metrics advance over time and expose configuration', () async {
    final backend = BasicAudioBackend();
    await backend.initialize();

    backend.setParameter(SynthParameterId.arpeggiatorEnabled, 1.0);
    backend.setParameter(SynthParameterId.arpeggiatorRate, 8.0);
    backend.setParameter(SynthParameterId.arpeggiatorGate, 0.45);
    backend.setParameter(SynthParameterId.arpeggiatorOctaves, 2.0);
    backend.setParameter(
        SynthParameterId.arpeggiatorMode, ArpeggiatorMode.upDown.value.toDouble());
    backend.setParameter(
        SynthParameterId.arpeggiatorPattern, ArpeggiatorPattern.octaves.value.toDouble());
    backend.setParameter(SynthParameterId.arpeggiatorSwing, 0.35);
    backend.setParameter(SynthParameterId.arpeggiatorLatch, 0.0);

    backend.noteOn(42, 64, 0.9);

    final first = backend.getVisualizerData();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final second = backend.getVisualizerData();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final third = backend.getVisualizerData();

    expect(first['arpeggiatorEnabled'], closeTo(1.0, 1e-9));
    expect(first['arpeggiatorRate'], closeTo(8.0, 1e-9));
    expect(first['arpeggiatorGate'], closeTo(0.45, 1e-9));
    expect(first['arpeggiatorOctaves'], closeTo(2.0, 1e-9));
    expect(first['arpeggiatorMode'], closeTo(ArpeggiatorMode.upDown.value.toDouble(), 1e-9));
    expect(first['arpeggiatorPattern'],
        closeTo(ArpeggiatorPattern.octaves.value.toDouble(), 1e-9));
    expect(first['arpeggiatorSwing'], closeTo(0.35, 1e-9));
    expect(first['arpeggiatorHeldNotes'], closeTo(1.0, 1e-9));

    final secondPhase = second['arpeggiatorPhase']! as double;
    final thirdPhase = third['arpeggiatorPhase']! as double;
    expect(secondPhase, isNot(closeTo(thirdPhase, 1e-9)));
    final secondStep = second['arpeggiatorStep']! as double;
    final thirdStep = third['arpeggiatorStep']! as double;
    expect(thirdStep, greaterThan(secondStep));

    backend.dispose();
  });

  test('tempo-synchronised arpeggiator follows transport tempo', () async {
    final backend = BasicAudioBackend();
    await backend.initialize();

    backend.setParameter(SynthParameterId.arpeggiatorEnabled, 1.0);
    backend.setParameter(SynthParameterId.arpeggiatorTempoSync, 1.0);
    backend.setParameter(SynthParameterId.arpeggiatorDivision,
        ArpeggiatorDivision.sixteenth.value.toDouble());
    backend.setParameter(SynthParameterId.transportTempo, 128.0);
    backend.setParameter(SynthParameterId.transportRunning, 1.0);
    backend.noteOn(1, 60, 0.8);

    final initial = backend.getVisualizerData();
    final expectedRate = (128.0 / 60.0) / ArpeggiatorDivision.sixteenth.beatsPerStep;
    expect(initial['arpeggiatorTempoSync'], closeTo(1.0, 1e-9));
    expect(initial['arpeggiatorDivision'],
        closeTo(ArpeggiatorDivision.sixteenth.value.toDouble(), 1e-9));
    expect(initial['transportTempo'], closeTo(128.0, 1e-9));

    await Future<void>.delayed(const Duration(milliseconds: 180));
    final progressed = backend.getVisualizerData();

    expect(progressed['arpeggiatorEffectiveRate'], closeTo(expectedRate, 0.05));
    expect(progressed['transportBeats'], greaterThan(initial['transportBeats'] ?? 0.0));

    backend.setParameter(SynthParameterId.transportRunning, 0.0);
    final pausedPhase = backend.getVisualizerData()['arpeggiatorPhase'] ?? 0.0;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final afterPausePhase = backend.getVisualizerData()['arpeggiatorPhase'] ?? 0.0;

    expect(afterPausePhase, closeTo(pausedPhase, 1e-3));

    backend.dispose();
  });
}
