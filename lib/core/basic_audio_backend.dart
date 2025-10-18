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
    SynthParameterId.lfoRate: 2.0,
    SynthParameterId.lfoDepth: 0.5,
    SynthParameterId.oscillatorBlend: 0.5,
    SynthParameterId.oscillatorDetune: 0.0,
    SynthParameterId.oscillatorSpread: 0.35,
    SynthParameterId.distortionDrive: 0.25,
    SynthParameterId.chorusRate: 1.2,
    SynthParameterId.chorusDepth: 0.35,
    SynthParameterId.glideTime: 0.08,
    SynthParameterId.pitchBendRange: 2.0,
    SynthParameterId.modWheel: 0.0,
    SynthParameterId.channelAftertouch: 0.0,
    SynthParameterId.expression: 1.0,
    SynthParameterId.sustainPedal: 0.0,
    SynthParameterId.granularActive: 0.0,
    SynthParameterId.granularGrainRate: 10.0,
    SynthParameterId.granularGrainDuration: 0.05,
    SynthParameterId.granularPosition: 0.2,
    SynthParameterId.granularPitch: 1.0,
    SynthParameterId.granularAmplitude: 0.8,
    SynthParameterId.granularPositionVariation: 0.25,
    SynthParameterId.granularPitchVariation: 0.15,
    SynthParameterId.granularDurationVariation: 0.12,
    SynthParameterId.granularPan: 0.0,
    SynthParameterId.granularPanVariation: 0.1,
    SynthParameterId.granularWindowType: GrainWindowType.hann.index.toDouble(),
    SynthParameterId.wavetablePosition: 0.3,
    SynthParameterId.microphoneVolume: 0.0,
    SynthParameterId.arpeggiatorEnabled: 0.0,
    SynthParameterId.arpeggiatorRate: 8.0,
    SynthParameterId.arpeggiatorGate: 0.6,
    SynthParameterId.arpeggiatorOctaves: 1.0,
    SynthParameterId.arpeggiatorMode: ArpeggiatorMode.up.value.toDouble(),
    SynthParameterId.arpeggiatorPattern:
        ArpeggiatorPattern.asPlayed.value.toDouble(),
    SynthParameterId.arpeggiatorSwing: 0.0,
    SynthParameterId.arpeggiatorLatch: 0.0,
    SynthParameterId.arpeggiatorTempoSync: 0.0,
    SynthParameterId.arpeggiatorDivision:
        ArpeggiatorDivision.eighth.value.toDouble(),
    SynthParameterId.transportTempo: 120.0,
    SynthParameterId.transportRunning: 1.0,
    SynthParameterId.transportTimeSignatureNumerator: 4.0,
    SynthParameterId.transportTimeSignatureDenominator: 4.0,
  };

  final Map<int, _VoiceState> _activeVoices = {};
  final Set<int> _heldArpeggiatorNotes = <int>{};

  bool _initialized = false;
  String? _lastError;
  Timer? _cleanupTimer;
  double _lfoPhase = 0.0;
  DateTime? _lastLfoSample;
  double _chorusPhase = 0.0;
  DateTime? _lastChorusSample;
  double? _glideStartFrequency;
  double? _glideTargetFrequency;
  double? _glideCurrentFrequency;
  DateTime? _glideStartTime;
  double _portamentoProgress = 1.0;
  double _arpeggiatorPhase = 0.0;
  DateTime? _lastArpeggiatorSample;
  int _arpeggiatorStep = 0;
  double _arpeggiatorEffectiveRate = 0.0;
  double _transportBeatPosition = 0.0;
  DateTime? _lastTransportSample;

  @visibleForTesting
  int get activeVoiceCount => _activeVoices.length;

  @visibleForTesting
  int get releasedVoiceCount =>
      _activeVoices.values.where((voice) => voice.released).length;

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
    _heldArpeggiatorNotes.clear();
    _initialized = false;
    _lastLfoSample = null;
    _lfoPhase = 0.0;
    _lastChorusSample = null;
    _chorusPhase = 0.0;
    _glideStartFrequency = null;
    _glideTargetFrequency = null;
    _glideCurrentFrequency = null;
    _glideStartTime = null;
    _portamentoProgress = 1.0;
    _arpeggiatorPhase = 0.0;
    _lastArpeggiatorSample = null;
    _arpeggiatorStep = 0;
    _arpeggiatorEffectiveRate = 0.0;
    _transportBeatPosition = 0.0;
    _lastTransportSample = null;
  }

  @override
  void noteOn(int voiceId, int note, double velocity) {
    final clampedVelocity = clampValue(velocity, 0, 1);
    final frequency = _midiToFrequency(note);
    final now = DateTime.now();
    final glideSeconds = clampValue<double>(
      _parameters[SynthParameterId.glideTime] ?? 0.0,
      0.0,
      5.0,
    );

    if (_glideCurrentFrequency == null) {
      _glideStartFrequency = frequency;
      _glideTargetFrequency = frequency;
      _glideCurrentFrequency = frequency;
      _glideStartTime = now;
      _portamentoProgress = 1.0;
    } else {
      _glideStartFrequency = _glideCurrentFrequency ?? frequency;
      _glideTargetFrequency = frequency;
      _glideStartTime = now;

      if (glideSeconds <= 0.0001) {
        _glideCurrentFrequency = frequency;
        _portamentoProgress = 1.0;
      } else {
        _portamentoProgress = 0.0;
      }
    }

    _activeVoices[voiceId] = _VoiceState(
      note: note,
      velocity: clampedVelocity,
      started: now,
      released: false,
    );

    if ((_parameters[SynthParameterId.arpeggiatorEnabled] ?? 0.0) >= 0.5) {
      _heldArpeggiatorNotes.add(note);
    }
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

    final latchActive =
        (_parameters[SynthParameterId.arpeggiatorLatch] ?? 0.0) >= 0.5;
    if (!latchActive && voice != null) {
      _heldArpeggiatorNotes.remove(voice.note);
    }
  }

  @override
  void setParameter(int parameterId, double value) {
    _parameters[parameterId] = value;

    if (parameterId == SynthParameterId.arpeggiatorLatch && value < 0.5) {
      _heldArpeggiatorNotes.clear();
    }

    if (parameterId == SynthParameterId.arpeggiatorEnabled && value < 0.5) {
      _heldArpeggiatorNotes.clear();
    }
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
      final progress = clampValue(
        elapsed.inMilliseconds / 1000.0 / releaseSeconds,
        0.0,
        1.0,
      );
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
    final lfoRate = clampValue(
      _parameters[SynthParameterId.lfoRate] ?? 2.0,
      0.05,
      30.0,
    );
    final lfoDepth = clampValue(
      _parameters[SynthParameterId.lfoDepth] ?? 0.5,
      0.0,
      1.0,
    );
    final oscillatorBlend = clampValue(
      _parameters[SynthParameterId.oscillatorBlend] ?? 0.5,
      0.0,
      1.0,
    );
    final oscillatorDetune = clampValue(
      _parameters[SynthParameterId.oscillatorDetune] ?? 0.0,
      -12.0,
      12.0,
    );
    final oscillatorSpread = clampValue(
      _parameters[SynthParameterId.oscillatorSpread] ?? 0.35,
      0.0,
      1.0,
    );
    final distortionDrive = clampValue(
      _parameters[SynthParameterId.distortionDrive] ?? 0.25,
      0.0,
      1.0,
    );
    final chorusRate = clampValue(
      _parameters[SynthParameterId.chorusRate] ?? 1.2,
      0.05,
      12.0,
    );
    final chorusDepth = clampValue(
      _parameters[SynthParameterId.chorusDepth] ?? 0.35,
      0.0,
      1.0,
    );
    final glideSeconds = clampValue<double>(
      _parameters[SynthParameterId.glideTime] ?? 0.0,
      0.0,
      5.0,
    );
    final pitchBendRange = clampValue<double>(
      _parameters[SynthParameterId.pitchBendRange] ?? 2.0,
      1.0,
      24.0,
    );
    final granularActive = clampValue<double>(
      _parameters[SynthParameterId.granularActive] ?? 0.0,
      0.0,
      1.0,
    );
    final modWheel = clampValue<double>(
      _parameters[SynthParameterId.modWheel] ?? 0.0,
      0.0,
      1.0,
    );
    final aftertouch = clampValue<double>(
      _parameters[SynthParameterId.channelAftertouch] ?? 0.0,
      0.0,
      1.0,
    );
    final expression = clampValue<double>(
      _parameters[SynthParameterId.expression] ?? 1.0,
      0.0,
      1.0,
    );
    final sustainPedal = clampValue<double>(
      _parameters[SynthParameterId.sustainPedal] ?? 0.0,
      0.0,
      1.0,
    );
    final granularGrainRate = clampValue<double>(
      _parameters[SynthParameterId.granularGrainRate] ?? 10.0,
      0.1,
      100.0,
    );
    final granularDuration = clampValue<double>(
      _parameters[SynthParameterId.granularGrainDuration] ?? 0.05,
      0.005,
      1.0,
    );
    final granularPosition = clampValue<double>(
      _parameters[SynthParameterId.granularPosition] ?? 0.2,
      0.0,
      1.0,
    );
    final granularPitch = clampValue<double>(
      _parameters[SynthParameterId.granularPitch] ?? 1.0,
      0.25,
      4.0,
    );
    final granularAmplitude = clampValue<double>(
      _parameters[SynthParameterId.granularAmplitude] ?? 0.8,
      0.0,
      1.0,
    );
    final granularPositionVariation = clampValue<double>(
      _parameters[SynthParameterId.granularPositionVariation] ?? 0.25,
      0.0,
      1.0,
    );
    final granularPitchVariation = clampValue<double>(
      _parameters[SynthParameterId.granularPitchVariation] ?? 0.15,
      0.0,
      2.0,
    );
    final granularDurationVariation = clampValue<double>(
      _parameters[SynthParameterId.granularDurationVariation] ?? 0.12,
      0.0,
      1.0,
    );
    final granularPan = clampValue<double>(
      _parameters[SynthParameterId.granularPan] ?? 0.0,
      -1.0,
      1.0,
    );
    final granularPanVariation = clampValue<double>(
      _parameters[SynthParameterId.granularPanVariation] ?? 0.1,
      0.0,
      1.0,
    );
    final granularWindow = clampValue<double>(
      _parameters[SynthParameterId.granularWindowType] ??
          GrainWindowType.hann.index.toDouble(),
      0.0,
      (GrainWindowType.values.length - 1).toDouble(),
    );
    final wavetablePosition = clampValue<double>(
      _parameters[SynthParameterId.wavetablePosition] ?? 0.3,
      0.0,
      1.0,
    );
    final microphoneVolume = clampValue<double>(
      _parameters[SynthParameterId.microphoneVolume] ?? 0.0,
      0.0,
      1.0,
    );
    final arpeggiatorEnabled = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorEnabled] ?? 0.0,
      0.0,
      1.0,
    );
    final arpeggiatorRate = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorRate] ?? 8.0,
      0.5,
      32.0,
    );
    final arpeggiatorGate = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorGate] ?? 0.6,
      0.05,
      1.0,
    );
    final arpeggiatorOctaves = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorOctaves] ?? 1.0,
      1.0,
      4.0,
    );
    final arpeggiatorMode = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorMode] ??
          ArpeggiatorMode.up.value.toDouble(),
      0.0,
      (ArpeggiatorMode.values.length - 1).toDouble(),
    );
    final arpeggiatorPattern = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorPattern] ??
          ArpeggiatorPattern.asPlayed.value.toDouble(),
      0.0,
      (ArpeggiatorPattern.values.length - 1).toDouble(),
    );
    final arpeggiatorSwing = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorSwing] ?? 0.0,
      0.0,
      1.0,
    );
    final arpeggiatorLatch = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorLatch] ?? 0.0,
      0.0,
      1.0,
    );
    final arpeggiatorTempoSync = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorTempoSync] ?? 0.0,
      0.0,
      1.0,
    );
    final arpeggiatorDivisionValue = clampValue<double>(
      _parameters[SynthParameterId.arpeggiatorDivision] ??
          ArpeggiatorDivision.eighth.value.toDouble(),
      0.0,
      (ArpeggiatorDivision.values.length - 1).toDouble(),
    );
    final arpeggiatorDivisionIndex = arpeggiatorDivisionValue
        .round()
        .clamp(0, ArpeggiatorDivision.values.length - 1);
    final arpeggiatorDivision =
        ArpeggiatorDivision.values[arpeggiatorDivisionIndex];
    final transportTempo = clampValue<double>(
      _parameters[SynthParameterId.transportTempo] ?? 120.0,
      20.0,
      240.0,
    );
    final transportRunning = clampValue<double>(
      _parameters[SynthParameterId.transportRunning] ?? 1.0,
      0.0,
      1.0,
    );
    final transportNumerator = clampValue<double>(
      _parameters[SynthParameterId.transportTimeSignatureNumerator] ?? 4.0,
      1.0,
      12.0,
    );
    final transportDenominator = clampValue<double>(
      _parameters[SynthParameterId.transportTimeSignatureDenominator] ?? 4.0,
      1.0,
      16.0,
    );
    final tempoSyncEnabled = arpeggiatorTempoSync >= 0.5;
    final transportRunningBool = transportRunning >= 0.5;

    _advanceLfo(now, lfoRate);
    final lfoValue = (math.sin(_lfoPhase) + 1) * 0.5;
    _advanceChorus(now, chorusRate);
    final chorusValue = (math.sin(_chorusPhase) + 1) * 0.5;
    _advanceTransport(now, transportTempo, transportRunningBool);
    _advanceArpeggiator(
      now,
      arpeggiatorRate,
      arpeggiatorEnabled >= 0.5,
      arpeggiatorSwing,
      tempoSyncEnabled,
      arpeggiatorDivision,
      transportTempo,
      transportRunningBool,
    );

    final averageFrequency = frequencySum == 0
        ? 440.0
        : frequencySum / math.max(1, _activeVoices.length);

    if (_activeVoices.isEmpty) {
      _glideTargetFrequency = _glideTargetFrequency ?? _glideCurrentFrequency;
    } else if (_glideTargetFrequency == null) {
      _glideTargetFrequency = averageFrequency;
    }

    _updatePortamento(now);

    final currentFrequency = _glideCurrentFrequency ?? averageFrequency;
    final targetFrequency = _glideTargetFrequency ?? averageFrequency;
    final glideDelta = targetFrequency - currentFrequency;
    final pitchDriftCents = currentFrequency <= 0
        ? 0.0
        : 1200.0 *
            (math.log(targetFrequency / currentFrequency) / math.log(2));

    final detuneRatio = math.pow(2, oscillatorDetune / 12.0).toDouble();
    final detunedFrequency = clampValue(
      averageFrequency * detuneRatio,
      20.0,
      20000.0,
    );
    final ensembleWidth = clampValue(
      oscillatorSpread * (_activeVoices.isEmpty ? 1 : _activeVoices.length),
      0.0,
      16.0,
    );

    final normalisedAmplitude = clampValue(
      (amplitude / activeVoiceCount) * masterVolume,
      0.0,
      1.0,
    );

    final baseCutoff = _parameters[SynthParameterId.filterCutoff] ?? 1200.0;

    final modulatedCutoff = clampValue(
      baseCutoff * (1 + ((lfoValue - 0.5) * 2 * lfoDepth)),
      20.0,
      20000.0,
    );

    final performanceEnergy = (modWheel + aftertouch + expression) / 3.0;
    final sustainActive = sustainPedal >= 0.5 ? 1.0 : 0.0;

    return {
      'amplitude': normalisedAmplitude,
      'frequency': averageFrequency,
      'filterCutoff': baseCutoff,
      'filterCutoffModulated': modulatedCutoff,
      'filterResonance': _parameters[SynthParameterId.filterResonance] ?? 0.35,
      'masterVolume': masterVolume,
      'activeVoices': _activeVoices.length.toDouble(),
      'reverbMix': _parameters[SynthParameterId.reverbMix] ?? 0.25,
      'delayTime': _parameters[SynthParameterId.delayTime] ?? 0.25,
      'lfoRate': lfoRate,
      'lfoDepth': lfoDepth,
      'lfoValue': lfoValue,
      'oscillatorBlend': oscillatorBlend,
      'oscillatorDetune': oscillatorDetune,
      'detunedFrequency': detunedFrequency,
      'oscillatorSpread': oscillatorSpread,
      'ensembleWidth': ensembleWidth,
      'distortionDrive': distortionDrive,
      'chorusRate': chorusRate,
      'chorusDepth': chorusDepth,
      'chorusValue': chorusValue,
      'glideTime': glideSeconds,
      'portamentoProgress': _portamentoProgress,
      'glideCurrentFrequency': currentFrequency,
      'glideTargetFrequency': targetFrequency,
      'glideDelta': glideDelta,
      'pitchDriftCents': pitchDriftCents,
      'pitchBendRange': pitchBendRange,
      'modWheel': modWheel,
      'channelAftertouch': aftertouch,
      'expression': expression,
      'sustainPedal': sustainPedal,
      'performanceEnergy': performanceEnergy,
      'sustainActive': sustainActive,
      'granularActive': granularActive,
      'granularGrainRate': granularActive > 0.5 ? granularGrainRate : 0.0,
      'granularGrainDuration': granularDuration,
      'granularPosition': granularPosition,
      'granularPitch': granularPitch,
      'granularAmplitude': granularAmplitude * normalisedAmplitude,
      'granularMotion':
          (granularPositionVariation + granularPitchVariation + granularDurationVariation) /
              3.0,
      'granularPositionVariation': granularPositionVariation,
      'granularPitchVariation': granularPitchVariation,
      'granularDurationVariation': granularDurationVariation,
      'granularPan': granularPan,
      'granularPanVariation': granularPanVariation,
      'granularWindowType': granularWindow,
      'wavetablePosition': wavetablePosition,
      'microphoneVolume': microphoneVolume,
      'arpeggiatorEnabled': arpeggiatorEnabled,
      'arpeggiatorRate': arpeggiatorRate,
      'arpeggiatorGate': arpeggiatorGate,
      'arpeggiatorOctaves': arpeggiatorOctaves,
      'arpeggiatorMode': arpeggiatorMode,
      'arpeggiatorPattern': arpeggiatorPattern,
      'arpeggiatorSwing': arpeggiatorSwing,
      'arpeggiatorLatch': arpeggiatorLatch,
      'arpeggiatorTempoSync': arpeggiatorTempoSync,
      'arpeggiatorDivision': arpeggiatorDivision.value.toDouble(),
      'arpeggiatorEffectiveRate': _arpeggiatorEffectiveRate,
      'arpeggiatorPhase': _arpeggiatorPhase,
      'arpeggiatorStep': _arpeggiatorStep.toDouble(),
      'arpeggiatorGateOpen':
          _arpeggiatorPhase <= arpeggiatorGate ? 1.0 : 0.0,
      'arpeggiatorHeldNotes': _heldArpeggiatorNotes.length.toDouble(),
      'transportTempo': transportTempo,
      'transportRunning': transportRunning,
      'transportBeats': _transportBeatPosition,
      'transportTimeSignatureNumerator': transportNumerator,
      'transportTimeSignatureDenominator': transportDenominator,
    };
  }

  void _advanceLfo(DateTime now, double rate) {
    final lastSample = _lastLfoSample;
    _lastLfoSample = now;

    if (lastSample == null) {
      _lfoPhase = 0.0;
      return;
    }

    final deltaSeconds = now.difference(lastSample).inMicroseconds / 1000000.0;
    if (deltaSeconds <= 0) {
      return;
    }

    final phaseAdvance = 2 * math.pi * rate * deltaSeconds;
    _lfoPhase = (_lfoPhase + phaseAdvance) % (2 * math.pi);
  }

  void _advanceChorus(DateTime now, double rate) {
    final lastSample = _lastChorusSample;
    _lastChorusSample = now;

    if (lastSample == null) {
      _chorusPhase = math.pi / 2; // start in motion for smoother metrics
      return;
    }

    final deltaSeconds = now.difference(lastSample).inMicroseconds / 1000000.0;
    if (deltaSeconds <= 0) {
      return;
    }

    final phaseAdvance = 2 * math.pi * rate * deltaSeconds;
    _chorusPhase = (_chorusPhase + phaseAdvance) % (2 * math.pi);
  }

  void _advanceTransport(DateTime now, double tempo, bool running) {
    final lastSample = _lastTransportSample;
    _lastTransportSample = now;

    if (!running || lastSample == null) {
      return;
    }

    final deltaSeconds = now.difference(lastSample).inMicroseconds / 1000000.0;
    if (deltaSeconds <= 0) {
      return;
    }

    final bpm = clampValue<double>(tempo, 20.0, 240.0);
    final beatsPerSecond = bpm / 60.0;
    _transportBeatPosition =
        (_transportBeatPosition + (beatsPerSecond * deltaSeconds)) % 1000000.0;
  }

  void _advanceArpeggiator(
      DateTime now,
      double rate,
      bool enabled,
      double swing,
      bool tempoSync,
      ArpeggiatorDivision division,
      double tempo,
      bool transportRunning) {
    final lastSample = _lastArpeggiatorSample;
    _lastArpeggiatorSample = now;

    if (!enabled) {
      _arpeggiatorPhase = 0.0;
      _arpeggiatorStep = 0;
      _arpeggiatorEffectiveRate = 0.0;
      return;
    }

    if (lastSample == null) {
      _arpeggiatorPhase = 0.0;
      _arpeggiatorEffectiveRate = 0.0;
      return;
    }

    final deltaSeconds = now.difference(lastSample).inMicroseconds / 1000000.0;
    if (deltaSeconds <= 0) {
      return;
    }

    double baseRate;
    if (tempoSync) {
      if (!transportRunning) {
        _arpeggiatorEffectiveRate = 0.0;
        return;
      }
      final bpm = clampValue<double>(tempo, 20.0, 240.0);
      final beatsPerStep = division.beatsPerStep.clamp(0.0001, 16.0);
      baseRate = (bpm / 60.0) / beatsPerStep;
    } else {
      baseRate = rate.clamp(0.5, 32.0);
    }

    final swingAmount = swing.clamp(0.0, 1.0);
    final swingModifier =
        1.0 + (swingAmount * (_arpeggiatorStep.isEven ? 0.5 : -0.5));
    final adjustedRate = (baseRate * swingModifier).clamp(0.05, 64.0);
    _arpeggiatorEffectiveRate = adjustedRate;
    final phaseAdvance = deltaSeconds * adjustedRate;
    _arpeggiatorPhase += phaseAdvance;

    while (_arpeggiatorPhase >= 1.0) {
      _arpeggiatorPhase -= 1.0;
      _arpeggiatorStep = (_arpeggiatorStep + 1) % 1024;
    }
  }

  void _updatePortamento(DateTime now) {
    final target = _glideTargetFrequency;
    final start = _glideStartFrequency;

    if (target == null || start == null) {
      if (_activeVoices.isEmpty) {
        _glideCurrentFrequency = null;
        _portamentoProgress = 1.0;
      }
      return;
    }

    final glideSeconds = clampValue<double>(
      _parameters[SynthParameterId.glideTime] ?? 0.0,
      0.0,
      5.0,
    );

    if (glideSeconds <= 0.0001) {
      _glideCurrentFrequency = target;
      _glideStartFrequency = target;
      _portamentoProgress = 1.0;
      _glideStartTime = now;
      return;
    }

    final startTime = _glideStartTime ?? now;
    final elapsed = now.difference(startTime).inMicroseconds / 1000000.0;
    final progress = clampValue<double>(elapsed / glideSeconds, 0.0, 1.0);
    _portamentoProgress = progress;

    final eased = _smoothStep(progress);
    _glideCurrentFrequency = start + (target - start) * eased;

    if (progress >= 0.999) {
      _glideStartFrequency = target;
      _glideCurrentFrequency = target;
      _portamentoProgress = 1.0;
      _glideStartTime = now;
    }
  }

  double _smoothStep(double t) {
    final clamped = clampValue<double>(t, 0.0, 1.0);
    return clamped * clamped * (3 - 2 * clamped);
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
