import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/core/parameter_bridge.dart';
import 'package:synther_holographic_pro/core/parameter_definitions.dart';
import 'package:synther_holographic_pro/core/synth_preset.dart';
import 'package:synther_holographic_pro/core/voice_allocator.dart';
import 'package:synther_holographic_pro/utils/audio_ui_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioUISyncManager.instance.resetForTesting();
    ParameterBridge.instance.resetForTesting();
  });

  tearDown(() {
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

    test('enforces max polyphony with velocity-aware voice stealing', () async {
      final backend = BasicAudioBackend();
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 2, clock: clock.tick);
      final engine = AudioEngine(backend: backend, voiceAllocator: allocator);

      expect(await engine.initialize(), isTrue);

      engine.noteOn(60, 0.8);
      engine.noteOn(64, 0.35);
      engine.noteOn(67, 0.9);

      expect(engine.activeVoiceCount, 2);
      expect(engine.activeNotes, containsAll(<int>[60, 67]));
      expect(engine.activeNotes, isNot(contains(64)));
      expect(backend.releasedVoiceCount, 1);

      engine.dispose();
      backend.dispose();
    });

    test('setMaxPolyphony reduces voices immediately and notifies listeners',
        () async {
      final backend = BasicAudioBackend();
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 4, clock: clock.tick);
      final engine = AudioEngine(backend: backend, voiceAllocator: allocator);

      expect(await engine.initialize(), isTrue);

      final notifications = <int>[];
      engine.addListener(() => notifications.add(engine.activeVoiceCount));

      engine.noteOn(60, 0.8);
      engine.noteOn(62, 0.5);
      engine.noteOn(64, 0.7);
      engine.noteOn(65, 0.6);

      final before = notifications.length;

      engine.setMaxPolyphony(2);

      expect(engine.maxPolyphony, 2);
      expect(engine.activeVoiceCount, 2);
      expect(engine.activeNotes, containsAll(<int>[60, 64]));
      expect(engine.activeNotes.length, 2);
      expect(backend.releasedVoiceCount, 2);
      expect(notifications.length, greaterThan(before));

      engine.dispose();
      backend.dispose();
    });

    test('voice stealing falls back to oldest voice when velocities match',
        () async {
      final backend = BasicAudioBackend();
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 1, clock: clock.tick);
      final engine = AudioEngine(backend: backend, voiceAllocator: allocator);

      expect(await engine.initialize(), isTrue);

      engine.noteOn(60, 0.5);
      engine.noteOn(62, 0.5);

      expect(engine.activeVoiceCount, 1);
      expect(engine.activeNotes, contains(62));
      expect(engine.activeNotes, isNot(contains(60)));
      expect(backend.releasedVoiceCount, 1);

      engine.dispose();
      backend.dispose();
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

    test('max polyphony syncs bidirectionally through the bridge', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final clock = _FakeClock();
      final allocator = VoiceAllocator(maxVoices: 8, clock: clock.tick);
      final engine = AudioEngine(
        backend: backend,
        parameterBridge: bridge,
        voiceAllocator: allocator,
      );

      expect(await engine.initialize(), isTrue);

      bridge.updateParameter('polyphony', 12, ParameterBridge.UpdateSource.ui);
      await pumpEventQueue();

      expect(engine.maxPolyphony, 12);
      expect(bridge.getParameter('maxPolyphony'), closeTo(12, 1e-9));

      engine.setMaxPolyphony(6);
      await pumpEventQueue();

      expect(engine.maxPolyphony, 6);
      expect(bridge.getParameter('polyphony'), closeTo(6, 1e-9));

      engine.dispose();
      backend.dispose();
    });
  });

  group('Preset management', () {
    test('capturePreset snapshots current state and aliases', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      await engine.setMasterVolume(0.42);
      await engine.setFilterCutoff(2300);
      await engine.setReverbMix(0.58);

      final preset = engine.capturePreset(includeAliases: true);

      expect(preset.parameters['masterVolume'], closeTo(0.42, 1e-9));
      expect(preset.parameters['volume'], closeTo(0.42, 1e-9));
      expect(preset.parameters['filterCutoff'], closeTo(2300, 1e-9));
      expect(preset.parameters['reverb'], closeTo(0.58, 1e-9));
      expect(
        preset.parameters['polyphony'],
        closeTo(engine.maxPolyphony.toDouble(), 1e-9),
      );
      expect(preset.metadata.isFactory, isFalse);

      engine.dispose();
      backend.dispose();
    });

    test('applyPreset updates backend, bridge and active preset snapshot', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      final preset = SynthPreset(
        metadata: SynthPresetMetadata(
          id: 'custom-test',
          name: 'Custom Test',
          description: 'integration test preset',
          category: SynthPresetCategory.performance,
        ),
        parameters: const <String, double>{
          'masterVolume': 0.33,
          'filterCutoff': 4200,
          'attackTime': 0.45,
          'delayFeedback': 0.52,
        },
      );

      await engine.applyPreset(preset);

      expect(engine.masterVolume, closeTo(0.33, 1e-9));
      expect(backend.getParameter(SynthParameterId.masterVolume), closeTo(0.33, 1e-9));
      expect(bridge.getParameter('volume'), closeTo(0.33, 1e-9));
      expect(engine.activePreset?.metadata.id, 'custom-test');
      expect(engine.activePreset?.parameters['delayFeedback'], closeTo(0.52, 1e-9));

      engine.dispose();
      backend.dispose();
    });

    test('loadPreset parses nested alias-heavy preset data', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      final presetData = <String, dynamic>{
        'name': 'LLM Ambient',
        'category': 'ambient',
        'volume': 0.58,
        'filter': {
          'cutoff_hz': 28000,
          'res': 0.72,
        },
        'envelope': {
          'attack_time': 0.35,
          'decay': 0.4,
          'sustain': 0.6,
          'release_time': 1.4,
        },
        'effects': {
          'reverb': 0.7,
          'delay': {
            'time': 0.55,
            'feedback': 0.45,
          },
        },
        'voices': 10,
      };

      await engine.loadPreset(presetData);

      expect(engine.masterVolume, closeTo(0.58, 1e-9));
      expect(engine.filterCutoff, closeTo(20000, 1e-9));
      expect(engine.filterResonance, closeTo(0.72, 1e-9));
      expect(engine.attackTime, closeTo(0.35, 1e-9));
      expect(engine.releaseTime, closeTo(1.4, 1e-9));
      expect(engine.reverbMix, closeTo(0.7, 1e-9));
      expect(engine.delayTime, closeTo(0.55, 1e-9));
      expect(engine.delayFeedback, closeTo(0.45, 1e-9));
      expect(engine.maxPolyphony, 10);
      expect(engine.activePreset?.metadata.name, 'LLM Ambient');
      expect(engine.activePreset?.metadata.category, SynthPresetCategory.ambient);
      expect(engine.activePreset?.parameters['volume'], closeTo(0.58, 1e-9));
      expect(engine.activePreset?.parameters['polyphony'], closeTo(10, 1e-9));

      engine.dispose();
      backend.dispose();
    });

    test('loadPresetById retrieves built-in presets', () async {
      final bridge = ParameterBridge.instance;
      final backend = BasicAudioBackend();
      final engine = AudioEngine(backend: backend, parameterBridge: bridge);

      expect(await engine.initialize(), isTrue);

      final success = await engine.loadPresetById('factory-glow-pad');
      expect(success, isTrue);
      expect(engine.activePreset?.metadata.id, 'factory-glow-pad');
      expect(
        engine.availablePresets.map((preset) => preset.metadata.id),
        contains('factory-glow-pad'),
      );

      engine.dispose();
      backend.dispose();
    });
  });
}

class _FakeClock {
  int _milliseconds = 0;

  DateTime tick() {
    _milliseconds += 1;
    return DateTime.fromMillisecondsSinceEpoch(_milliseconds);
  }
}
