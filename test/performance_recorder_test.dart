import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/audio_engine.dart';
import 'package:synther_holographic_pro/core/audio_engine_events.dart';
import 'package:synther_holographic_pro/core/basic_audio_backend.dart';
import 'package:synther_holographic_pro/core/performance_recorder.dart';
import 'package:synther_holographic_pro/core/synth_preset.dart';
import 'package:synther_holographic_pro/core/parameter_bridge.dart';
import 'package:synther_holographic_pro/core/preset_setlist.dart';
import 'package:synther_holographic_pro/utils/audio_ui_sync.dart';
import 'package:synther_holographic_pro/core/midi_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioUISyncManager.instance.resetForTesting();
    ParameterBridge.instance.resetForTesting();
    PresetSetlistLibrary.instance.reset();
    MidiBindingManager.instance.clear();
  });

  tearDown(() {
    AudioUISyncManager.instance.resetForTesting();
    ParameterBridge.instance.resetForTesting();
    PresetSetlistLibrary.instance.reset();
    MidiBindingManager.instance.clear();
  });

  test('captures engine events with relative timing', () async {
    final backend = BasicAudioBackend();
    final engine = AudioEngine(backend: backend);

    expect(await engine.initialize(), isTrue);

    var now = DateTime(2024, 1, 1, 12);
    DateTime clock() => now;

    final recorder = PerformanceRecorder(clock: clock);
    recorder.attach(engine);

    recorder.startRecording(label: 'take');

    now = now.add(const Duration(milliseconds: 10));
    await engine.setMasterVolume(0.42);

    now = now.add(const Duration(milliseconds: 5));
    engine.noteOn(60, 0.75);

    now = now.add(const Duration(milliseconds: 7));
    engine.noteOff(60);

    now = now.add(const Duration(milliseconds: 12));
    await engine.applyPreset(
      SynthPreset(
        metadata: buildCapturedPresetMetadata(name: 'Test'),
        parameters: const <String, double>{
          'masterVolume': 0.6,
        },
      ),
      notify: false,
    );

    final recording = recorder.stopRecording();

    expect(recorder.isRecording, isFalse);
    expect(recording.label, 'take');
    expect(recording.events, hasLength(4));

    expect(recording.events[0].position, const Duration(milliseconds: 10));
    expect(recording.events[0].event.type, AudioEngineEventType.parameterChanged);
    expect(recording.events[0].event.parameterId, 'masterVolume');

    expect(recording.events[1].position, const Duration(milliseconds: 15));
    expect(recording.events[1].event.type, AudioEngineEventType.noteOn);
    expect(recording.events[1].event.note, 60);

    expect(recording.events[2].position, const Duration(milliseconds: 22));
    expect(recording.events[2].event.type, AudioEngineEventType.noteOff);

    expect(recording.events[3].event.type, AudioEngineEventType.presetApplied);

    recorder.detach();
    engine.dispose();
    backend.dispose();
  });

  test('detaching stops capturing additional events', () async {
    final backend = BasicAudioBackend();
    final engine = AudioEngine(backend: backend);

    expect(await engine.initialize(), isTrue);

    var now = DateTime(2024, 6, 15, 9);
    DateTime clock() => now;

    final recorder = PerformanceRecorder(clock: clock);
    recorder.attach(engine);

    recorder.startRecording();

    now = now.add(const Duration(milliseconds: 8));
    await engine.setMasterVolume(0.2);

    recorder.detach();

    now = now.add(const Duration(milliseconds: 4));
    engine.noteOn(64, 0.5);
    engine.noteOff(64);

    final recording = recorder.stopRecording();

    expect(recording.events, hasLength(1));
    expect(recording.events.first.event.type, AudioEngineEventType.parameterChanged);

    engine.dispose();
    backend.dispose();
  });
}
