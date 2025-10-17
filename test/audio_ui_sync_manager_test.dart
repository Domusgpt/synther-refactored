import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/audio_backend.dart';
import 'package:synther_holographic_pro/utils/audio_ui_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioUISyncManager', () {
    late AudioUISyncManager manager;
    late _FakeBackend backend;

    setUp(() {
      manager = AudioUISyncManager.instance;
      backend = _FakeBackend();
      manager.resetForTesting();
    });

    tearDown(() {
      manager.resetForTesting();
    });

    test('tracks backend initialization and forwards queued parameters', () async {
      manager.initialize(backend);

      expect(manager.engineStatus, AudioEngineStatus.initializing);
      expect(manager.isAudioInitialized, isFalse);

      backend.markInitialized(true);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(manager.isAudioInitialized, isTrue);
      expect(manager.engineStatus, AudioEngineStatus.running);

      manager.queueParameterUpdate(42, 0.5);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(backend.parameters[42], 0.5);

      manager.setError('boom');
      expect(manager.engineStatus, AudioEngineStatus.error);

      manager.clearError();
      expect(manager.engineStatus, AudioEngineStatus.running);

      manager.detach(backend);
      expect(manager.engineStatus, AudioEngineStatus.uninitialized);
    });
  });
}

class _FakeBackend implements AudioBackend {
  final Map<int, double> parameters = {};
  bool _isInitialized = false;

  void markInitialized(bool value) {
    _isInitialized = value;
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? get lastError => null;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  void dispose() {}

  @override
  void noteOn(int voiceId, int note, double velocity) {}

  @override
  void noteOff(int voiceId) {}

  @override
  void setParameter(int parameterId, double value) {
    parameters[parameterId] = value;
  }

  @override
  double getParameter(int parameterId) {
    return parameters[parameterId] ?? 0;
  }

  @override
  Map<String, double> getVisualizerData() {
    return const {};
  }
}
