import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'audio_backend.dart';
import 'parameter_definitions.dart';

/// A lightweight, pure Dart implementation of [AudioBackend].
///
/// It does not generate real audio but it mimics the behaviour of a synthesiser
/// well enough for the UI, preset system and visualiser to function.  The goal
/// is to provide deterministic behaviour across every platform without
/// depending on native bindings.
class BasicAudioBackend implements AudioBackend {
  BasicAudioBackend();

  final Map<int, double> _parameters = {
    SynthParameterId.masterVolume: 0.75,
    SynthParameterId.filterCutoff: 1200,
    SynthParameterId.filterResonance: 0.35,
    SynthParameterId.attackTime: 0.02,
    SynthParameterId.decayTime: 0.2,
    SynthParameterId.sustainLevel: 0.7,
    SynthParameterId.releaseTime: 0.4,
    SynthParameterId.reverbMix: 0.25,
    SynthParameterId.delayTime: 0.25,
    SynthParameterId.delayFeedback: 0.2,
  };

  final Map<int, _VoiceState> _activeVoices = {};

  bool _initialized = false;
  String? _lastError;
  Timer? _cleanupTimer;

  @override
  bool get isInitialized => _initialized;

  @override
  String? get lastError => _lastError;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Simulate asynchronous setup work.  Keeping a slight delay here makes
      // the initial loading animation visible which improves perceived polish.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      _initialized = true;

      _cleanupTimer ??=
          Timer.periodic(const Duration(milliseconds: 250), _pruneVoices);
    } catch (error, stackTrace) {
      _initialized = false;
      _lastError = 'Audio initialisation failed: $error';
      debugPrintStack(label: _lastError, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _activeVoices.clear();
    _initialized = false;
  }

  @override
  void noteOn(int voiceId, int note, double velocity) {
    final clampedVelocity = clampValue(velocity, 0, 1);
    _activeVoices[voiceId] = _VoiceState(
      note: note,
      velocity: clampedVelocity,
      started: DateTime.now(),
      released: false,
    );
  }

  @override
  void noteOff(int voiceId) {
    final voice = _activeVoices[voiceId];
    if (voice != null) {
      _activeVoices[voiceId] = voice.copyWith(
        released: true,
        releasedAt: DateTime.now(),
      );
    }
  }

  @override
  void setParameter(int parameterId, double value) {
    _parameters[parameterId] = value;
  }

  @override
  double getParameter(int parameterId) {
    return _parameters[parameterId] ?? 0.0;
  }

  @override
  Map<String, double> getVisualizerData() {
    final now = DateTime.now();

    double amplitude = 0;
    double frequencySum = 0;

    _activeVoices.removeWhere((_, voice) {
      if (!voice.released) {
        amplitude += voice.velocity;
        frequencySum += _midiToFrequency(voice.note);
        return false;
      }

      final releaseTime = _parameters[SynthParameterId.releaseTime] ?? 0.4;
      final elapsed = now.difference(voice.releasedAt ?? voice.started);
      final releaseSeconds = releaseTime.clamp(0.05, 5.0);
      final progress = clampValue(elapsed.inMilliseconds / 1000.0 / releaseSeconds, 0.0, 1.0);
      final level = (1 - progress) * voice.velocity;

      if (level <= 0.001) {
        return true;
      }

      amplitude += level;
      frequencySum += _midiToFrequency(voice.note);
      return false;
    });

    final activeVoiceCount = _activeVoices.isEmpty ? 1 : _activeVoices.length;
    final masterVolume = _parameters[SynthParameterId.masterVolume] ?? 0.75;
    final normalisedAmplitude = clampValue(
      (amplitude / activeVoiceCount) * masterVolume,
      0.0,
      1.0,
    );

    final averageFrequency = frequencySum == 0
        ? 440.0
        : frequencySum / math.max(1, _activeVoices.length);

    return {
      'amplitude': normalisedAmplitude,
      'frequency': averageFrequency,
      'filterCutoff': _parameters[SynthParameterId.filterCutoff] ?? 1200.0,
      'filterResonance': _parameters[SynthParameterId.filterResonance] ?? 0.35,
      'masterVolume': masterVolume,
      'activeVoices': _activeVoices.length.toDouble(),
      'reverbMix': _parameters[SynthParameterId.reverbMix] ?? 0.25,
      'delayTime': _parameters[SynthParameterId.delayTime] ?? 0.25,
    };
  }

  void _pruneVoices(Timer timer) {
    if (_activeVoices.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final releaseSeconds = (_parameters[SynthParameterId.releaseTime] ?? 0.4)
        .clamp(0.05, 5.0);

    _activeVoices.removeWhere((_, voice) {
      if (!voice.released) {
        return false;
      }

      final elapsed = now.difference(voice.releasedAt ?? voice.started);
      return elapsed.inMilliseconds / 1000.0 > releaseSeconds + 0.2;
    });
  }

  double _midiToFrequency(int note) {
    return 440.0 * math.pow(2, (note - 69) / 12.0);
  }
}

class _VoiceState {
  const _VoiceState({
    required this.note,
    required this.velocity,
    required this.started,
    required this.released,
    this.releasedAt,
  });

  final int note;
  final double velocity;
  final DateTime started;
  final bool released;
  final DateTime? releasedAt;

  _VoiceState copyWith({
    int? note,
    double? velocity,
    DateTime? started,
    bool? released,
    DateTime? releasedAt,
  }) {
    return _VoiceState(
      note: note ?? this.note,
      velocity: velocity ?? this.velocity,
      started: started ?? this.started,
      released: released ?? this.released,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }
}
