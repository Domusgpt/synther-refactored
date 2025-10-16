import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/core/parameter_bridge.dart';
import 'package:synther_holographic_pro/core/parameter_definitions.dart';
import 'package:synther_holographic_pro/utils/audio_ui_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioUISyncManager.instance.resetForTesting();
    ParameterBridge.instance.resetForTesting();
  });

  group('AudioEngine voice management', () {
    test('allocates unique voice ids per simultaneous note', () async {
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend);

      final success = await engine.initialize();
      expect(success, isTrue);

      engine.noteOn(60, 0.6);
      engine.noteOn(60, 0.4);
      engine.noteOn(67, 0.8);

      expect(backend.activeVoiceCount, 3);

      engine.noteOff(60);
      expect(backend.releasedVoiceCount, 1);

      engine.noteOff(60);
      expect(backend.releasedVoiceCount, 2);

      engine.noteOff(60);
      expect(backend.releasedVoiceCount, 2);

      engine.dispose();
      backend.dispose();
    });

    test('disposal resets shared initialization tracking', () async {
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend);

      expect(await engine.initialize(), isTrue);

      engine.dispose();
      backend.dispose();

      final newBackend = BasicAudioBackend();
      final newEngine = AudioEngine(backend: newBackend);

      expect(await newEngine.initialize(), isTrue);

      newEngine.dispose();
      newBackend.dispose();
    });
  });

  group('Parameter bridge integration', () {
    test('applies parameter updates from the bridge and clamps values', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      bridge.updateParameter('filterCutoff', 50000, ParameterBridge.UpdateSource.ui);
      await pumpEventQueue();

      expect(engine.filterCutoff, closeTo(20000, 1e-9));
      expect(
        backend.getParameter(SynthParameterId.filterCutoff),
        closeTo(20000, 1e-9),
      );
      expect(bridge.getParameter('filterCutoff'), closeTo(20000, 1e-9));
      expect(bridge.getParameter('cutoff'), closeTo(20000, 1e-9));

      engine.dispose();
      backend.dispose();
    });

    test('publishes engine parameter changes back to the bridge', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      final updates = <ParameterUpdate>[];
      final subscription = bridge.parameterStream.listen(updates.add);

      await engine.setMasterVolume(0.5);
      await engine.setDelayFeedback(2);
      await pumpEventQueue();

      final masterUpdate =
          updates.lastWhere((event) => event.name == 'masterVolume');
      expect(masterUpdate.source, ParameterBridge.UpdateSource.audio);
      expect(masterUpdate.value, closeTo(0.5, 1e-9));

      expect(bridge.getParameter('delayFeedback'), closeTo(0.95, 1e-9));
      expect(bridge.getParameter('volume'), closeTo(0.5, 1e-9));

      await subscription.cancel();
      engine.dispose();
      backend.dispose();
    });
  });
}
