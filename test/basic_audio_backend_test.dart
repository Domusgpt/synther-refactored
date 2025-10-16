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
}
