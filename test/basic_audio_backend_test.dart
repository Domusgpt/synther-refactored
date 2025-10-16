import 'dart:math' as math;

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

  test('pitch bend updates frequency metrics and clamps to range', () async {
    final backend = BasicAudioBackend();
    await backend.initialize();

    backend.noteOn(1, 69, 1.0);
    backend.setParameter(SynthParameterId.pitchBendRange, 12.0);
    backend.setPitchBend(6.0);

    final metrics = backend.getVisualizerData();
    expect(metrics['pitchBendSemitones'], closeTo(6.0, 1e-9));
    expect(metrics['pitchWheelValue'], closeTo(0.5, 1e-9));
    expect(metrics['frequency'], closeTo(440.0 * math.pow(2, 0.5), 1e-6));

    backend.setParameter(SynthParameterId.pitchBendRange, 3.0);
    final clamped = backend.getVisualizerData();
    expect(clamped['pitchBendSemitones'], closeTo(3.0, 1e-9));
    expect(clamped['pitchWheelValue'], closeTo(1.0, 1e-9));

    backend.dispose();
  });
}
