import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/audio_ui_sync.dart';
import 'audio_backend.dart';
import 'arpeggiator.dart';
import 'audio_preset_library.dart';
import 'parameter_definitions.dart';
import 'parameter_models.dart';
import 'parameter_registry.dart';
import 'modulation_matrix.dart';
import 'modulation_metadata.dart';
import 'platform_audio_backend.dart';
import 'parameter_bridge.dart';
import 'synth_preset.dart';
import 'voice_allocator.dart';
import 'tempo_transport.dart';

/// High level controller that exposes the synthesiser behaviour to the UI.
///
/// The legacy project expected a complex native audio engine.  The new
/// implementation wraps the lightweight [AudioBackend] so the rest of the app
/// can continue to interact with something that looks and feels like the
/// original engine while remaining completely in Dart.
class AudioEngine extends ChangeNotifier {
  AudioEngine({
    AudioBackend? backend,
    ParameterBridge? parameterBridge,
    VoiceAllocator? voiceAllocator,
  })  : _backend = backend ?? createAudioBackend(),
        _parameterBridge = parameterBridge ?? ParameterBridge.instance,
        _voiceAllocator = voiceAllocator ?? VoiceAllocator() {
    _instanceCount++;
    _liveEngines.add(this);

    _parameterSetters =
        <String, Future<void> Function(double, {bool notify})>{
      'masterVolume': (value, {notify = true}) =>
          setMasterVolume(value, notify: notify),
      'filterCutoff': (value, {notify = true}) =>
          setFilterCutoff(value, notify: notify),
      'filterResonance': (value, {notify = true}) =>
          setFilterResonance(value, notify: notify),
      'attackTime': (value, {notify = true}) =>
          setAttackTime(value, notify: notify),
      'decayTime': (value, {notify = true}) =>
          setDecayTime(value, notify: notify),
      'sustainLevel': (value, {notify = true}) =>
          setSustainLevel(value, notify: notify),
      'releaseTime': (value, {notify = true}) =>
          setReleaseTime(value, notify: notify),
      'reverbMix': (value, {notify = true}) =>
          setReverbMix(value, notify: notify),
      'delayTime': (value, {notify = true}) =>
          setDelayTime(value, notify: notify),
      'delayFeedback': (value, {notify = true}) =>
          setDelayFeedback(value, notify: notify),
      'lfoRate': (value, {notify = true}) =>
          setLfoRate(value, notify: notify),
      'lfoDepth': (value, {notify = true}) =>
          setLfoDepth(value, notify: notify),
      'oscillatorBlend': (value, {notify = true}) =>
          setOscillatorBlend(value, notify: notify),
      'oscillatorDetune': (value, {notify = true}) =>
          setOscillatorDetune(value, notify: notify),
      'oscillatorSpread': (value, {notify = true}) =>
          setOscillatorSpread(value, notify: notify),
      'distortionDrive': (value, {notify = true}) =>
          setDistortionDrive(value, notify: notify),
      'chorusRate': (value, {notify = true}) =>
          setChorusRate(value, notify: notify),
      'chorusDepth': (value, {notify = true}) =>
          setChorusDepth(value, notify: notify),
      'glideTime': (value, {notify = true}) =>
          setGlideTime(value, notify: notify),
      'pitchBendRange': (value, {notify = true}) =>
          setPitchBendRange(value, notify: notify),
      'modWheel': (value, {notify = true}) =>
          setModWheel(value, notify: notify),
      'channelAftertouch': (value, {notify = true}) =>
          setChannelAftertouch(value, notify: notify),
      'expression': (value, {notify = true}) =>
          setExpression(value, notify: notify),
      'sustainPedal': (value, {notify = true}) =>
          setSustainPedal(value, notify: notify),
      'granularActive': (value, {notify = true}) =>
          setGranularActive(value, notify: notify),
      'granularGrainRate': (value, {notify = true}) =>
          setGranularGrainRate(value, notify: notify),
      'granularGrainDuration': (value, {notify = true}) =>
          setGranularGrainDuration(value, notify: notify),
      'granularPosition': (value, {notify = true}) =>
          setGranularPosition(value, notify: notify),
      'granularPitch': (value, {notify = true}) =>
          setGranularPitch(value, notify: notify),
      'granularAmplitude': (value, {notify = true}) =>
          setGranularAmplitude(value, notify: notify),
      'granularPositionVariation': (value, {notify = true}) =>
          setGranularPositionVariation(value, notify: notify),
      'granularPitchVariation': (value, {notify = true}) =>
          setGranularPitchVariation(value, notify: notify),
      'granularDurationVariation': (value, {notify = true}) =>
          setGranularDurationVariation(value, notify: notify),
      'granularPan': (value, {notify = true}) =>
          setGranularPan(value, notify: notify),
      'granularPanVariation': (value, {notify = true}) =>
          setGranularPanVariation(value, notify: notify),
      'granularWindowType': (value, {notify = true}) =>
          setGranularWindowType(value, notify: notify),
      'wavetablePosition': (value, {notify = true}) =>
          setWavetablePosition(value, notify: notify),
      'microphoneVolume': (value, {notify = true}) =>
          setMicrophoneVolume(value, notify: notify),
      'arpeggiatorEnabled': (value, {notify = true}) =>
          setArpeggiatorEnabled(value, notify: notify),
      'arpeggiatorRate': (value, {notify = true}) =>
          setArpeggiatorRate(value, notify: notify),
      'arpeggiatorGate': (value, {notify = true}) =>
          setArpeggiatorGate(value, notify: notify),
      'arpeggiatorOctaves': (value, {notify = true}) =>
          setArpeggiatorOctaves(value, notify: notify),
      'arpeggiatorMode': (value, {notify = true}) =>
          setArpeggiatorMode(value, notify: notify),
      'arpeggiatorPattern': (value, {notify = true}) =>
          setArpeggiatorPattern(value, notify: notify),
      'arpeggiatorSwing': (value, {notify = true}) =>
          setArpeggiatorSwing(value, notify: notify),
      'arpeggiatorLatch': (value, {notify = true}) =>
          setArpeggiatorLatch(value, notify: notify),
      'arpeggiatorTempoSync': (value, {notify = true}) =>
          setArpeggiatorTempoSync(value, notify: notify),
      'arpeggiatorDivision': (value, {notify = true}) =>
          setArpeggiatorDivision(value, notify: notify),
      'transportTempo': (value, {notify = true}) =>
          setTransportTempo(value, notify: notify),
      'transportRunning': (value, {notify = true}) =>
          setTransportRunning(value, notify: notify),
      'transportTimeSignatureNumerator': (value, {notify = true}) =>
          setTransportTimeSignatureNumerator(value, notify: notify),
      'transportTimeSignatureDenominator': (value, {notify = true}) =>
          setTransportTimeSignatureDenominator(value, notify: notify),
      'maxPolyphony': (value, {notify = true}) async {
        setMaxPolyphony(value.round(), notify: notify);
      },
    };

    _maybeClaimParameterBridge();
  }

  static final AudioUISyncManager _syncManager = AudioUISyncManager.instance;

  static Future<void>? _pendingInitialization;
  static int _instanceCount = 0;
  static final LinkedHashSet<AudioEngine> _liveEngines =
      LinkedHashSet<AudioEngine>.identity();
  static AudioEngine? _bridgeOwner;
  static final ParameterRegistry _parameterRegistry = ParameterRegistry.instance;

  final AudioBackend _backend;
  final ParameterBridge? _parameterBridge;

  late final Map<String, Future<void> Function(double, {bool notify})>
      _parameterSetters;
  void Function(String, double)? _parameterBridgeHandler;

  bool _isInitialized = false;
  String? _lastError;

  final VoiceAllocator _voiceAllocator;
  final ModulationMatrix _modulationMatrix = ModulationMatrix();

  double _masterVolume =
      _parameterRegistry.defaultValue('masterVolume') ?? 0.75;
  double _filterCutoff =
      _parameterRegistry.defaultValue('filterCutoff') ?? 1200;
  double _filterResonance =
      _parameterRegistry.defaultValue('filterResonance') ?? 0.35;
  double _attackTime =
      _parameterRegistry.defaultValue('attackTime') ?? 0.02;
  double _decayTime = _parameterRegistry.defaultValue('decayTime') ?? 0.2;
  double _sustainLevel =
      _parameterRegistry.defaultValue('sustainLevel') ?? 0.7;
  double _releaseTime =
      _parameterRegistry.defaultValue('releaseTime') ?? 0.4;
  double _reverbMix = _parameterRegistry.defaultValue('reverbMix') ?? 0.25;
  double _delayTime = _parameterRegistry.defaultValue('delayTime') ?? 0.25;
  double _delayFeedback =
      _parameterRegistry.defaultValue('delayFeedback') ?? 0.2;
  double _lfoRate = _parameterRegistry.defaultValue('lfoRate') ?? 2.0;
  double _lfoDepth = _parameterRegistry.defaultValue('lfoDepth') ?? 0.5;
  double _oscillatorBlend =
      _parameterRegistry.defaultValue('oscillatorBlend') ?? 0.5;
  double _oscillatorDetune =
      _parameterRegistry.defaultValue('oscillatorDetune') ?? 0.0;
  double _oscillatorSpread =
      _parameterRegistry.defaultValue('oscillatorSpread') ?? 0.35;
  double _distortionDrive =
      _parameterRegistry.defaultValue('distortionDrive') ?? 0.25;
  double _chorusRate =
      _parameterRegistry.defaultValue('chorusRate') ?? 1.2;
  double _chorusDepth =
      _parameterRegistry.defaultValue('chorusDepth') ?? 0.35;
  double _glideTime = _parameterRegistry.defaultValue('glideTime') ?? 0.08;
  double _pitchBendRange =
      _parameterRegistry.defaultValue('pitchBendRange') ?? 2.0;
  double _modWheel = _parameterRegistry.defaultValue('modWheel') ?? 0.0;
  double _channelAftertouch =
      _parameterRegistry.defaultValue('channelAftertouch') ?? 0.0;
  double _expression =
      _parameterRegistry.defaultValue('expression') ?? 1.0;
  double _sustainPedal =
      _parameterRegistry.defaultValue('sustainPedal') ?? 0.0;
  double _granularActive =
      _parameterRegistry.defaultValue('granularActive') ?? 0.0;
  double _granularGrainRate =
      _parameterRegistry.defaultValue('granularGrainRate') ?? 10.0;
  double _granularGrainDuration =
      _parameterRegistry.defaultValue('granularGrainDuration') ?? 0.05;
  double _granularPosition =
      _parameterRegistry.defaultValue('granularPosition') ?? 0.2;
  double _granularPitch =
      _parameterRegistry.defaultValue('granularPitch') ?? 1.0;
  double _granularAmplitude =
      _parameterRegistry.defaultValue('granularAmplitude') ?? 0.8;
  double _granularPositionVariation =
      _parameterRegistry.defaultValue('granularPositionVariation') ?? 0.25;
  double _granularPitchVariation =
      _parameterRegistry.defaultValue('granularPitchVariation') ?? 0.15;
  double _granularDurationVariation =
      _parameterRegistry.defaultValue('granularDurationVariation') ?? 0.12;
  double _granularPan =
      _parameterRegistry.defaultValue('granularPan') ?? 0.0;
  double _granularPanVariation =
      _parameterRegistry.defaultValue('granularPanVariation') ?? 0.1;
  double _granularWindowType =
      _parameterRegistry.defaultValue('granularWindowType') ?? 1.0;
  double _wavetablePosition =
      _parameterRegistry.defaultValue('wavetablePosition') ?? 0.3;
  double _microphoneVolume =
      _parameterRegistry.defaultValue('microphoneVolume') ?? 0.0;
  double _arpeggiatorEnabled =
      _parameterRegistry.defaultValue('arpeggiatorEnabled') ?? 0.0;
  double _arpeggiatorRate =
      _parameterRegistry.defaultValue('arpeggiatorRate') ?? 8.0;
  double _arpeggiatorGate =
      _parameterRegistry.defaultValue('arpeggiatorGate') ?? 0.6;
  double _arpeggiatorOctaves =
      _parameterRegistry.defaultValue('arpeggiatorOctaves') ?? 1.0;
  double _arpeggiatorMode =
      _parameterRegistry.defaultValue('arpeggiatorMode') ??
          ArpeggiatorMode.up.value.toDouble();
  double _arpeggiatorPattern =
      _parameterRegistry.defaultValue('arpeggiatorPattern') ??
          ArpeggiatorPattern.asPlayed.value.toDouble();
  double _arpeggiatorSwing =
      _parameterRegistry.defaultValue('arpeggiatorSwing') ?? 0.0;
  double _arpeggiatorLatch =
      _parameterRegistry.defaultValue('arpeggiatorLatch') ?? 0.0;
  double _arpeggiatorTempoSync =
      _parameterRegistry.defaultValue('arpeggiatorTempoSync') ?? 0.0;
  double _arpeggiatorDivision =
      _parameterRegistry.defaultValue('arpeggiatorDivision') ??
          ArpeggiatorDivision.eighth.value.toDouble();
  double _transportTempo =
      _parameterRegistry.defaultValue('transportTempo') ?? 120.0;
  double _transportRunning =
      _parameterRegistry.defaultValue('transportRunning') ?? 1.0;
  double _transportTimeSignatureNumerator =
      _parameterRegistry.defaultValue('transportTimeSignatureNumerator') ?? 4.0;
  double _transportTimeSignatureDenominator =
      _parameterRegistry.defaultValue('transportTimeSignatureDenominator') ?? 4.0;
  double _transportPositionBeats = 0.0;
  SynthPreset? _activePreset;

  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  double get masterVolume => _masterVolume;
  double get filterCutoff => _filterCutoff;
  double get cutoff => _filterCutoff;
  double get filterResonance => _filterResonance;
  double get resonance => _filterResonance;
  double get attackTime => _attackTime;
  double get attack => _attackTime;
  double get decayTime => _decayTime;
  double get decay => _decayTime;
  double get sustainLevel => _sustainLevel;
  double get releaseTime => _releaseTime;
  double get reverbMix => _reverbMix;
  double get delayTime => _delayTime;
  double get delayFeedback => _delayFeedback;
  double get lfoRate => _lfoRate;
  double get lfoDepth => _lfoDepth;
  double get oscillatorBlend => _oscillatorBlend;
  double get oscillatorDetune => _oscillatorDetune;
  double get oscillatorSpread => _oscillatorSpread;
  double get distortionDrive => _distortionDrive;
  double get chorusRate => _chorusRate;
  double get chorusDepth => _chorusDepth;
  double get glideTime => _glideTime;
  double get pitchBendRange => _pitchBendRange;
  double get modWheel => _modWheel;
  double get channelAftertouch => _channelAftertouch;
  double get expression => _expression;
  double get sustainPedal => _sustainPedal;
  bool get sustainEngaged => _sustainPedal >= 0.5;
  double get granularActive => _granularActive;
  bool get granularEnabled => _granularActive >= 0.5;
  double get granularGrainRate => _granularGrainRate;
  double get granularGrainDuration => _granularGrainDuration;
  double get granularPosition => _granularPosition;
  double get granularPitch => _granularPitch;
  double get granularAmplitude => _granularAmplitude;
  double get granularPositionVariation => _granularPositionVariation;
  double get granularPitchVariation => _granularPitchVariation;
  double get granularDurationVariation => _granularDurationVariation;
  double get granularPan => _granularPan;
  double get granularPanVariation => _granularPanVariation;
  double get granularWindowType => _granularWindowType;
  double get wavetablePosition => _wavetablePosition;
  double get microphoneVolume => _microphoneVolume;
  bool get arpeggiatorEnabled => _arpeggiatorEnabled >= 0.5;
  double get arpeggiatorRate => _arpeggiatorRate;
  double get arpeggiatorGate => _arpeggiatorGate;
  int get arpeggiatorOctaves =>
      _arpeggiatorOctaves.round().clamp(1, 4).toInt();
  ArpeggiatorMode get arpeggiatorMode =>
      ArpeggiatorMode.values[_arpeggiatorMode.clamp(0, ArpeggiatorMode.values.length - 1).toInt()];
  ArpeggiatorPattern get arpeggiatorPattern =>
      ArpeggiatorPattern.values[_arpeggiatorPattern
          .clamp(0, ArpeggiatorPattern.values.length - 1)
          .toInt()];
  double get arpeggiatorSwing => _arpeggiatorSwing;
  bool get arpeggiatorLatch => _arpeggiatorLatch >= 0.5;
  bool get arpeggiatorTempoSync => _arpeggiatorTempoSync >= 0.5;
  ArpeggiatorDivision get arpeggiatorDivision =>
      ArpeggiatorDivision.values[_arpeggiatorDivision
          .clamp(0, ArpeggiatorDivision.values.length - 1)
          .toInt()];
  ArpeggiatorSettings get arpeggiatorSettings => ArpeggiatorSettings(
        enabled: arpeggiatorEnabled,
        rate: _arpeggiatorRate,
        gate: _arpeggiatorGate,
        octaveSpan: arpeggiatorOctaves,
        mode: arpeggiatorMode,
        pattern: arpeggiatorPattern,
        swing: _arpeggiatorSwing,
        latch: arpeggiatorLatch,
        tempoSync: arpeggiatorTempoSync,
        division: arpeggiatorDivision,
        heldNotes: _voiceAllocator.activeNotes.toList(),
      );
  TempoTransportSettings get tempoTransport => TempoTransportSettings(
        bpm: _transportTempo,
        running: transportRunning,
        timeSignatureNumerator: transportTimeSignatureNumerator,
        timeSignatureDenominator: transportTimeSignatureDenominator,
        positionBeats: _transportPositionBeats,
      );
  double get transportTempo => _transportTempo;
  bool get transportRunning => _transportRunning >= 0.5;
  int get transportTimeSignatureNumerator =>
      _transportTimeSignatureNumerator.round().clamp(1, 12).toInt();
  int get transportTimeSignatureDenominator =>
      _transportTimeSignatureDenominator.round().clamp(1, 16).toInt();
  double get transportPositionBeats => _transportPositionBeats;
  List<ModulationRoute> get modulationRoutes => _modulationMatrix.routes;

  /// Curated list of modulation sources the UI should expose.
  List<String> get availableModulationSources =>
      ModulationRoutingMetadata.availableSources;

  /// Canonical modulation destinations sourced from the parameter registry.
  List<String> get availableModulationDestinations =>
      ModulationRoutingMetadata.availableDestinations;

  /// Aggregated modulation depth per source for visual summaries.
  Map<String, double> get modulationDepthBySource =>
      Map<String, double>.unmodifiable(
        _modulationMatrix.aggregateDepthBySource(),
      );

  /// Aggregated modulation depth per destination using canonical parameter names.
  Map<String, double> get modulationDepthByDestination {
    final totals = _modulationMatrix.aggregateDepthByDestination();
    final resolved = <String, double>{};
    totals.forEach((rawKey, value) {
      final canonical =
          _parameterRegistry.canonicalName(rawKey) ?? rawKey;
      final descriptor = _parameterRegistry.descriptorFor(canonical);
      if (descriptor == null) {
        resolved[rawKey] = value;
      } else {
        resolved[descriptor.name] = value;
      }
    });
    return Map<String, double>.unmodifiable(resolved);
  }
  SynthPreset? get activePreset => _activePreset;
  List<SynthPreset> get availablePresets =>
      AudioPresetLibrary.instance.allPresets();
  int get maxPolyphony => _voiceAllocator.maxVoices;

  @visibleForTesting
  int get activeVoiceCount => _voiceAllocator.activeVoiceCount;

  @visibleForTesting
  Set<int> get activeNotes => _voiceAllocator.activeNotes;

  /// Initialises the shared backend.  Multiple [AudioEngine] instances share the
  /// same backend instance so only the first call performs real work.
  Future<bool> initialize() async {
    if (_backend.isInitialized) {
      _isInitialized = true;
      _lastError = _backend.lastError;
      _pushStateToBackend();
      _pushStateToBridge();
      _hookSyncManager();
      _syncManager.clearError();
      notifyListeners();
      return true;
    }

    _pendingInitialization ??= _backend.initialize();

    try {
      await _pendingInitialization;
      _isInitialized = _backend.isInitialized;
      _lastError = _backend.lastError;

      if (_isInitialized) {
        _pushStateToBackend();
        _pushStateToBridge();
        _hookSyncManager();
      }
    } catch (error) {
      _lastError = error.toString();
      _isInitialized = false;
      _syncManager.setError(_lastError ?? 'Unknown audio error');
      _pendingInitialization = null;
      notifyListeners();
      return false;
    }

    if (_isInitialized) {
      _syncManager.clearError();
    }

    notifyListeners();
    return _isInitialized;
  }

  static Future<void> initializeShared() async {
    final engine = AudioEngine();
    await engine.initialize();
    engine.dispose();
  }

  Future<void> setMasterVolume(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('masterVolume')!.range,
      current: _masterVolume,
      parameterId: SynthParameterId.masterVolume,
      bridgeParameterName: 'masterVolume',
      assign: (v) => _masterVolume = v,
      notify: notify,
    );
  }

  Future<void> setFilterCutoff(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('filterCutoff')!.range,
      current: _filterCutoff,
      parameterId: SynthParameterId.filterCutoff,
      bridgeParameterName: 'filterCutoff',
      assign: (v) => _filterCutoff = v,
      notify: notify,
    );
  }

  void setCutoff(double value) {
    unawaited(setFilterCutoff(value));
  }

  Future<void> setFilterResonance(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('filterResonance')!.range,
      current: _filterResonance,
      parameterId: SynthParameterId.filterResonance,
      bridgeParameterName: 'filterResonance',
      assign: (v) => _filterResonance = v,
      notify: notify,
    );
  }

  void setResonance(double value) {
    unawaited(setFilterResonance(value));
  }

  Future<void> setAttackTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('attackTime')!.range,
      current: _attackTime,
      parameterId: SynthParameterId.attackTime,
      bridgeParameterName: 'attackTime',
      assign: (v) => _attackTime = v,
      notify: notify,
    );
  }

  void setAttack(double value) {
    unawaited(setAttackTime(value));
  }

  Future<void> setDecayTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('decayTime')!.range,
      current: _decayTime,
      parameterId: SynthParameterId.decayTime,
      bridgeParameterName: 'decayTime',
      assign: (v) => _decayTime = v,
      notify: notify,
    );
  }

  void setDecay(double value) {
    unawaited(setDecayTime(value));
  }

  Future<void> setSustainLevel(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('sustainLevel')!.range,
      current: _sustainLevel,
      parameterId: SynthParameterId.sustainLevel,
      bridgeParameterName: 'sustainLevel',
      assign: (v) => _sustainLevel = v,
      notify: notify,
    );
  }

  Future<void> setReleaseTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('releaseTime')!.range,
      current: _releaseTime,
      parameterId: SynthParameterId.releaseTime,
      bridgeParameterName: 'releaseTime',
      assign: (v) => _releaseTime = v,
      notify: notify,
    );
  }

  Future<void> setReverbMix(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('reverbMix')!.range,
      current: _reverbMix,
      parameterId: SynthParameterId.reverbMix,
      bridgeParameterName: 'reverbMix',
      assign: (v) => _reverbMix = v,
      notify: notify,
    );
  }

  Future<void> setDelayTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('delayTime')!.range,
      current: _delayTime,
      parameterId: SynthParameterId.delayTime,
      bridgeParameterName: 'delayTime',
      assign: (v) => _delayTime = v,
      notify: notify,
    );
  }

  Future<void> setDelayFeedback(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('delayFeedback')!.range,
      current: _delayFeedback,
      parameterId: SynthParameterId.delayFeedback,
      bridgeParameterName: 'delayFeedback',
      assign: (v) => _delayFeedback = v,
      notify: notify,
    );
  }

  Future<void> setLfoRate(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('lfoRate')!.range,
      current: _lfoRate,
      parameterId: SynthParameterId.lfoRate,
      bridgeParameterName: 'lfoRate',
      assign: (v) => _lfoRate = v,
      notify: notify,
    );
  }

  Future<void> setLfoDepth(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('lfoDepth')!.range,
      current: _lfoDepth,
      parameterId: SynthParameterId.lfoDepth,
      bridgeParameterName: 'lfoDepth',
      assign: (v) => _lfoDepth = v,
      notify: notify,
    );
  }

  Future<void> setOscillatorBlend(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('oscillatorBlend')!.range,
      current: _oscillatorBlend,
      parameterId: SynthParameterId.oscillatorBlend,
      bridgeParameterName: 'oscillatorBlend',
      assign: (v) => _oscillatorBlend = v,
      notify: notify,
    );
  }

  Future<void> setOscillatorDetune(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('oscillatorDetune')!.range,
      current: _oscillatorDetune,
      parameterId: SynthParameterId.oscillatorDetune,
      bridgeParameterName: 'oscillatorDetune',
      assign: (v) => _oscillatorDetune = v,
      notify: notify,
    );
  }

  Future<void> setOscillatorSpread(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('oscillatorSpread')!.range,
      current: _oscillatorSpread,
      parameterId: SynthParameterId.oscillatorSpread,
      bridgeParameterName: 'oscillatorSpread',
      assign: (v) => _oscillatorSpread = v,
      notify: notify,
    );
  }

  Future<void> setDistortionDrive(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('distortionDrive')!.range,
      current: _distortionDrive,
      parameterId: SynthParameterId.distortionDrive,
      bridgeParameterName: 'distortionDrive',
      assign: (v) => _distortionDrive = v,
      notify: notify,
    );
  }

  Future<void> setChorusRate(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('chorusRate')!.range,
      current: _chorusRate,
      parameterId: SynthParameterId.chorusRate,
      bridgeParameterName: 'chorusRate',
      assign: (v) => _chorusRate = v,
      notify: notify,
    );
  }

  Future<void> setChorusDepth(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('chorusDepth')!.range,
      current: _chorusDepth,
      parameterId: SynthParameterId.chorusDepth,
      bridgeParameterName: 'chorusDepth',
      assign: (v) => _chorusDepth = v,
      notify: notify,
    );
  }

  Future<void> setGlideTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('glideTime')!.range,
      current: _glideTime,
      parameterId: SynthParameterId.glideTime,
      bridgeParameterName: 'glideTime',
      assign: (v) => _glideTime = v,
      notify: notify,
    );
  }

  Future<void> setPitchBendRange(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('pitchBendRange')!.range,
      current: _pitchBendRange,
      parameterId: SynthParameterId.pitchBendRange,
      bridgeParameterName: 'pitchBendRange',
      assign: (v) => _pitchBendRange = v,
      notify: notify,
    );
  }

  Future<void> setModWheel(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('modWheel')!.range,
      current: _modWheel,
      parameterId: SynthParameterId.modWheel,
      bridgeParameterName: 'modWheel',
      assign: (v) => _modWheel = v,
      notify: notify,
    );
  }

  Future<void> setChannelAftertouch(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('channelAftertouch')!.range,
      current: _channelAftertouch,
      parameterId: SynthParameterId.channelAftertouch,
      bridgeParameterName: 'channelAftertouch',
      assign: (v) => _channelAftertouch = v,
      notify: notify,
    );
  }

  Future<void> setExpression(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('expression')!.range,
      current: _expression,
      parameterId: SynthParameterId.expression,
      bridgeParameterName: 'expression',
      assign: (v) => _expression = v,
      notify: notify,
    );
  }

  Future<void> setSustainPedal(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('sustainPedal')!.range,
      current: _sustainPedal,
      parameterId: SynthParameterId.sustainPedal,
      bridgeParameterName: 'sustainPedal',
      assign: (v) => _sustainPedal = v,
      notify: notify,
    );
  }

  Future<void> setGranularActive(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularActive')!.range,
      current: _granularActive,
      parameterId: SynthParameterId.granularActive,
      bridgeParameterName: 'granularActive',
      assign: (v) => _granularActive = v,
      notify: notify,
    );
  }

  Future<void> setGranularEnabled(bool enabled, {bool notify = true}) async {
    await setGranularActive(enabled ? 1.0 : 0.0, notify: notify);
  }

  Future<void> setGranularGrainRate(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularGrainRate')!.range,
      current: _granularGrainRate,
      parameterId: SynthParameterId.granularGrainRate,
      bridgeParameterName: 'granularGrainRate',
      assign: (v) => _granularGrainRate = v,
      notify: notify,
    );
  }

  Future<void> setGranularGrainDuration(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularGrainDuration')!.range,
      current: _granularGrainDuration,
      parameterId: SynthParameterId.granularGrainDuration,
      bridgeParameterName: 'granularGrainDuration',
      assign: (v) => _granularGrainDuration = v,
      notify: notify,
    );
  }

  Future<void> setGranularPosition(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularPosition')!.range,
      current: _granularPosition,
      parameterId: SynthParameterId.granularPosition,
      bridgeParameterName: 'granularPosition',
      assign: (v) => _granularPosition = v,
      notify: notify,
    );
  }

  Future<void> setGranularPitch(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularPitch')!.range,
      current: _granularPitch,
      parameterId: SynthParameterId.granularPitch,
      bridgeParameterName: 'granularPitch',
      assign: (v) => _granularPitch = v,
      notify: notify,
    );
  }

  Future<void> setGranularAmplitude(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularAmplitude')!.range,
      current: _granularAmplitude,
      parameterId: SynthParameterId.granularAmplitude,
      bridgeParameterName: 'granularAmplitude',
      assign: (v) => _granularAmplitude = v,
      notify: notify,
    );
  }

  Future<void> setGranularPositionVariation(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range:
          _parameterRegistry.descriptorFor('granularPositionVariation')!.range,
      current: _granularPositionVariation,
      parameterId: SynthParameterId.granularPositionVariation,
      bridgeParameterName: 'granularPositionVariation',
      assign: (v) => _granularPositionVariation = v,
      notify: notify,
    );
  }

  Future<void> setGranularPitchVariation(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range:
          _parameterRegistry.descriptorFor('granularPitchVariation')!.range,
      current: _granularPitchVariation,
      parameterId: SynthParameterId.granularPitchVariation,
      bridgeParameterName: 'granularPitchVariation',
      assign: (v) => _granularPitchVariation = v,
      notify: notify,
    );
  }

  Future<void> setGranularDurationVariation(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range:
          _parameterRegistry.descriptorFor('granularDurationVariation')!.range,
      current: _granularDurationVariation,
      parameterId: SynthParameterId.granularDurationVariation,
      bridgeParameterName: 'granularDurationVariation',
      assign: (v) => _granularDurationVariation = v,
      notify: notify,
    );
  }

  Future<void> setGranularPan(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('granularPan')!.range,
      current: _granularPan,
      parameterId: SynthParameterId.granularPan,
      bridgeParameterName: 'granularPan',
      assign: (v) => _granularPan = v,
      notify: notify,
    );
  }

  Future<void> setGranularPanVariation(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range:
          _parameterRegistry.descriptorFor('granularPanVariation')!.range,
      current: _granularPanVariation,
      parameterId: SynthParameterId.granularPanVariation,
      bridgeParameterName: 'granularPanVariation',
      assign: (v) => _granularPanVariation = v,
      notify: notify,
    );
  }

  Future<void> setGranularWindowType(double value,
      {bool notify = true}) async {
    final descriptor = _parameterRegistry.descriptorFor('granularWindowType')!;
    final clamped = descriptor.range.clamp(value);
    final discrete = clamped.roundToDouble();
    if ((discrete - _granularWindowType).abs() < 0.00001) {
      return;
    }

    _granularWindowType = discrete;
    _backend.setParameter(SynthParameterId.granularWindowType, discrete);
    _emitParameterToBridge('granularWindowType', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setWavetablePosition(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('wavetablePosition')!.range,
      current: _wavetablePosition,
      parameterId: SynthParameterId.wavetablePosition,
      bridgeParameterName: 'wavetablePosition',
      assign: (v) => _wavetablePosition = v,
      notify: notify,
    );
  }

  Future<void> setMicrophoneVolume(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('microphoneVolume')!.range,
      current: _microphoneVolume,
      parameterId: SynthParameterId.microphoneVolume,
      bridgeParameterName: 'microphoneVolume',
      assign: (v) => _microphoneVolume = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorEnabled(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorEnabled')!.range,
      current: _arpeggiatorEnabled,
      parameterId: SynthParameterId.arpeggiatorEnabled,
      bridgeParameterName: 'arpeggiatorEnabled',
      assign: (v) => _arpeggiatorEnabled = v,
      notify: notify,
    );
  }

  Future<void> toggleArpeggiator(bool enabled, {bool notify = true}) {
    return setArpeggiatorEnabled(enabled ? 1.0 : 0.0, notify: notify);
  }

  Future<void> setArpeggiatorRate(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorRate')!.range,
      current: _arpeggiatorRate,
      parameterId: SynthParameterId.arpeggiatorRate,
      bridgeParameterName: 'arpeggiatorRate',
      assign: (v) => _arpeggiatorRate = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorGate(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorGate')!.range,
      current: _arpeggiatorGate,
      parameterId: SynthParameterId.arpeggiatorGate,
      bridgeParameterName: 'arpeggiatorGate',
      assign: (v) => _arpeggiatorGate = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorSwing(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorSwing')!.range,
      current: _arpeggiatorSwing,
      parameterId: SynthParameterId.arpeggiatorSwing,
      bridgeParameterName: 'arpeggiatorSwing',
      assign: (v) => _arpeggiatorSwing = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorLatch(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorLatch')!.range,
      current: _arpeggiatorLatch,
      parameterId: SynthParameterId.arpeggiatorLatch,
      bridgeParameterName: 'arpeggiatorLatch',
      assign: (v) => _arpeggiatorLatch = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorTempoSync(double value,
      {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('arpeggiatorTempoSync')!.range,
      current: _arpeggiatorTempoSync,
      parameterId: SynthParameterId.arpeggiatorTempoSync,
      bridgeParameterName: 'arpeggiatorTempoSync',
      assign: (v) => _arpeggiatorTempoSync = v,
      notify: notify,
    );
  }

  Future<void> setArpeggiatorDivision(double value,
      {bool notify = true}) async {
    final descriptor = _parameterRegistry.descriptorFor('arpeggiatorDivision')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _arpeggiatorDivision).abs() < 0.00001) {
      return;
    }

    _arpeggiatorDivision = discrete;
    _backend.setParameter(SynthParameterId.arpeggiatorDivision, discrete);
    _emitParameterToBridge('arpeggiatorDivision', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setArpeggiatorOctaves(double value, {bool notify = true}) async {
    final descriptor = _parameterRegistry.descriptorFor('arpeggiatorOctaves')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _arpeggiatorOctaves).abs() < 0.00001) {
      return;
    }

    _arpeggiatorOctaves = discrete;
    _backend.setParameter(SynthParameterId.arpeggiatorOctaves, discrete);
    _emitParameterToBridge('arpeggiatorOctaves', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setArpeggiatorMode(double value, {bool notify = true}) async {
    final descriptor = _parameterRegistry.descriptorFor('arpeggiatorMode')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _arpeggiatorMode).abs() < 0.00001) {
      return;
    }

    _arpeggiatorMode = discrete;
    _backend.setParameter(SynthParameterId.arpeggiatorMode, discrete);
    _emitParameterToBridge('arpeggiatorMode', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setArpeggiatorPattern(double value, {bool notify = true}) async {
    final descriptor = _parameterRegistry.descriptorFor('arpeggiatorPattern')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _arpeggiatorPattern).abs() < 0.00001) {
      return;
    }

    _arpeggiatorPattern = discrete;
    _backend.setParameter(SynthParameterId.arpeggiatorPattern, discrete);
    _emitParameterToBridge('arpeggiatorPattern', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> applyArpeggiatorSettings(ArpeggiatorSettings settings,
      {bool notify = true}) async {
    final previousEnabled = _arpeggiatorEnabled;
    final previousRate = _arpeggiatorRate;
    final previousGate = _arpeggiatorGate;
    final previousOctaves = _arpeggiatorOctaves;
    final previousMode = _arpeggiatorMode;
    final previousPattern = _arpeggiatorPattern;
    final previousSwing = _arpeggiatorSwing;
    final previousLatch = _arpeggiatorLatch;
    final previousSync = _arpeggiatorTempoSync;
    final previousDivision = _arpeggiatorDivision;

    await setArpeggiatorEnabled(settings.enabled ? 1.0 : 0.0, notify: false);
    await setArpeggiatorRate(settings.rate, notify: false);
    await setArpeggiatorGate(settings.gate, notify: false);
    await setArpeggiatorOctaves(settings.octaveSpan.toDouble(), notify: false);
    await setArpeggiatorMode(settings.mode.value.toDouble(), notify: false);
    await setArpeggiatorPattern(
        settings.pattern.value.toDouble(), notify: false);
    await setArpeggiatorSwing(settings.swing, notify: false);
    await setArpeggiatorLatch(settings.latch ? 1.0 : 0.0, notify: false);
    await setArpeggiatorTempoSync(settings.tempoSync ? 1.0 : 0.0, notify: false);
    await setArpeggiatorDivision(settings.division.value.toDouble(), notify: false);

    final changed = previousEnabled != _arpeggiatorEnabled ||
        previousRate != _arpeggiatorRate ||
        previousGate != _arpeggiatorGate ||
        previousOctaves != _arpeggiatorOctaves ||
        previousMode != _arpeggiatorMode ||
        previousPattern != _arpeggiatorPattern ||
        previousSwing != _arpeggiatorSwing ||
        previousLatch != _arpeggiatorLatch ||
        previousSync != _arpeggiatorTempoSync ||
        previousDivision != _arpeggiatorDivision;

    if (notify && changed) {
      notifyListeners();
    }
  }

  Future<void> setTransportTempo(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('transportTempo')!.range,
      current: _transportTempo,
      parameterId: SynthParameterId.transportTempo,
      bridgeParameterName: 'transportTempo',
      assign: (v) => _transportTempo = v,
      notify: notify,
    );
  }

  Future<void> setTransportRunning(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      range: _parameterRegistry.descriptorFor('transportRunning')!.range,
      current: _transportRunning,
      parameterId: SynthParameterId.transportRunning,
      bridgeParameterName: 'transportRunning',
      assign: (v) => _transportRunning = v,
      notify: notify,
    );
  }

  Future<void> setTransportTimeSignatureNumerator(double value,
      {bool notify = true}) async {
    final descriptor =
        _parameterRegistry.descriptorFor('transportTimeSignatureNumerator')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _transportTimeSignatureNumerator).abs() < 0.00001) {
      return;
    }

    _transportTimeSignatureNumerator = discrete;
    _backend.setParameter(
        SynthParameterId.transportTimeSignatureNumerator, discrete);
    _emitParameterToBridge('transportTimeSignatureNumerator', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setTransportTimeSignatureDenominator(double value,
      {bool notify = true}) async {
    final descriptor =
        _parameterRegistry.descriptorFor('transportTimeSignatureDenominator')!;
    final discrete = descriptor.range.clamp(value).roundToDouble();
    if ((discrete - _transportTimeSignatureDenominator).abs() < 0.00001) {
      return;
    }

    _transportTimeSignatureDenominator = discrete;
    _backend.setParameter(
        SynthParameterId.transportTimeSignatureDenominator, discrete);
    _emitParameterToBridge('transportTimeSignatureDenominator', discrete);

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> applyTempoTransport(TempoTransportSettings settings,
      {bool notify = true}) async {
    final previousTempo = _transportTempo;
    final previousRunning = _transportRunning;
    final previousNumerator = _transportTimeSignatureNumerator;
    final previousDenominator = _transportTimeSignatureDenominator;

    await setTransportTempo(settings.bpm, notify: false);
    await setTransportRunning(settings.running ? 1.0 : 0.0, notify: false);
    await setTransportTimeSignatureNumerator(
      settings.timeSignatureNumerator.toDouble(),
      notify: false,
    );
    await setTransportTimeSignatureDenominator(
      settings.timeSignatureDenominator.toDouble(),
      notify: false,
    );

    _transportPositionBeats = settings.positionBeats;

    final changed = previousTempo != _transportTempo ||
        previousRunning != _transportRunning ||
        previousNumerator != _transportTimeSignatureNumerator ||
        previousDenominator != _transportTimeSignatureDenominator;

    if (notify && changed) {
      notifyListeners();
    }
  }

  bool setModulationRoute(ModulationRoute route, {bool notify = true}) {
    final changed = _applyModulationRoute(route, emitToBridge: true);
    if (changed) {
      _activePreset = _activePreset?.copyWith(
        modulationRoutes: _modulationMatrix.routes,
      );
      if (notify) {
        notifyListeners();
      }
    }
    return changed;
  }

  bool removeModulationRoute(String source, String destination, {bool notify = true}) {
    final changed = _removeModulationRoute(source, destination, emitToBridge: true);
    if (changed) {
      _activePreset = _activePreset?.copyWith(
        modulationRoutes: _modulationMatrix.routes,
      );
      if (notify) {
        notifyListeners();
      }
    }
    return changed;
  }

  bool clearModulationRoutes({bool notify = true}) {
    if (!_modulationMatrix.clear()) {
      return false;
    }

    _emitModulationMatrixCleared();

    _activePreset = _activePreset?.copyWith(
      modulationRoutes: _modulationMatrix.routes,
    );
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  /// Trigger a new note using the MIDI [note] number and a 0-1 [velocity].
  void noteOn(int note, [double velocity = 1.0]) {
    if (!_backend.isInitialized) return;

    final normalisedVelocity = velocity.clamp(0.0, 1.0).toDouble();
    final allocation = _voiceAllocator.allocate(note, normalisedVelocity);

    if (allocation.hasStolenVoices) {
      for (final stolen in allocation.stolenVoices) {
        _backend.noteOff(stolen.voiceId);
      }
    }

    _backend.noteOn(
      allocation.voice.voiceId,
      note,
      normalisedVelocity,
    );
    notifyListeners();
  }

  /// Release a note that was started with [noteOn].
  void noteOff(int note) {
    if (!_backend.isInitialized) return;

    final voice = _voiceAllocator.release(note);
    if (voice == null) {
      return;
    }

    _backend.noteOff(voice.voiceId);
    notifyListeners();
  }

  void setMaxPolyphony(int value, {bool notify = true}) {
    final range = _parameterRegistry.descriptorFor('maxPolyphony')!.range;
    final clampedValue = range.clamp(value.toDouble()).round();
    final previousLimit = _voiceAllocator.maxVoices;
    final released = _voiceAllocator.updateMaxVoices(clampedValue);

    if (_backend.isInitialized && released.isNotEmpty) {
      for (final voice in released) {
        _backend.noteOff(voice.voiceId);
      }
    }

    final limitChanged = previousLimit != _voiceAllocator.maxVoices;
    if (limitChanged || released.isNotEmpty) {
      _emitParameterToBridge(
        'maxPolyphony',
        _voiceAllocator.maxVoices.toDouble(),
      );
    }
    if (notify && (limitChanged || released.isNotEmpty)) {
      notifyListeners();
    }
  }

  Map<String, double> getVisualizerData() {
    final data = Map<String, double>.from(_backend.getVisualizerData());
    final backendBeats = data['transportBeats'];
    if (backendBeats != null) {
      _transportPositionBeats = backendBeats;
    }
    data['filterCutoff'] = _filterCutoff;
    data['filterResonance'] = _filterResonance;
    data['attackTime'] = _attackTime;
    data['decayTime'] = _decayTime;
    data['sustainLevel'] = _sustainLevel;
    data['releaseTime'] = _releaseTime;
    data['reverbMix'] = _reverbMix;
    data['delayTime'] = _delayTime;
    data['delayFeedback'] = _delayFeedback;
    data['masterVolume'] = _masterVolume;
    data['glideTime'] = _glideTime;
    data['pitchBendRange'] = _pitchBendRange;
    data['modWheel'] = _modWheel;
    data['channelAftertouch'] = _channelAftertouch;
    data['expression'] = _expression;
    data['sustainPedal'] = _sustainPedal;
    data['performanceEnergy'] =
        (_modWheel + _channelAftertouch + _expression) / 3.0;
    data['sustainActive'] = _sustainPedal >= 0.5 ? 1.0 : 0.0;
    data['activeVoices'] = _voiceAllocator.activeVoiceCount.toDouble();
    data['maxPolyphony'] = _voiceAllocator.maxVoices.toDouble();
    data['granularActive'] = _granularActive;
    data['granularGrainRate'] =
        _granularActive >= 0.5 ? _granularGrainRate : 0.0;
    data['granularGrainDuration'] = _granularGrainDuration;
    data['granularPosition'] = _granularPosition;
    data['granularPitch'] = _granularPitch;
    data['granularAmplitude'] = _granularAmplitude;
    data['granularPositionVariation'] = _granularPositionVariation;
    data['granularPitchVariation'] = _granularPitchVariation;
    data['granularDurationVariation'] = _granularDurationVariation;
    data['granularMotion'] =
        (_granularPositionVariation + _granularPitchVariation +
                _granularDurationVariation) /
            3.0;
    data['granularPan'] = _granularPan;
    data['granularPanVariation'] = _granularPanVariation;
    data['granularWindowType'] = _granularWindowType;
    data['wavetablePosition'] = _wavetablePosition;
    data['microphoneVolume'] = _microphoneVolume;
    data['arpeggiatorEnabled'] = _arpeggiatorEnabled;
    data['arpeggiatorRate'] = _arpeggiatorRate;
    data['arpeggiatorGate'] = _arpeggiatorGate;
    data['arpeggiatorOctaves'] = _arpeggiatorOctaves;
    data['arpeggiatorMode'] = _arpeggiatorMode;
    data['arpeggiatorPattern'] = _arpeggiatorPattern;
    data['arpeggiatorSwing'] = _arpeggiatorSwing;
    data['arpeggiatorLatch'] = _arpeggiatorLatch;
    data['arpeggiatorTempoSync'] = _arpeggiatorTempoSync;
    data['arpeggiatorDivision'] = _arpeggiatorDivision;
    data['transportTempo'] = _transportTempo;
    data['transportRunning'] = _transportRunning;
    data['transportTimeSignatureNumerator'] =
        _transportTimeSignatureNumerator;
    data['transportTimeSignatureDenominator'] =
        _transportTimeSignatureDenominator;
    data['transportBeats'] = _transportPositionBeats;
    data['modulationRouteCount'] = _modulationMatrix.routeCount.toDouble();

    final sourceTotals = _modulationMatrix.aggregateDepthBySource();
    for (final entry in sourceTotals.entries) {
      data['modSource.${entry.key}'] = entry.value.clamp(0.0, 1.0).toDouble();
    }

    final destinationTotals = _modulationMatrix.aggregateDepthByDestination();
    for (final entry in destinationTotals.entries) {
      data['modDestination.${entry.key}'] = entry.value.clamp(0.0, 1.0).toDouble();
    }

    if (_modulationMatrix.routeCount > 0) {
      final averageDepth = destinationTotals.values.isEmpty
          ? 0.0
          : destinationTotals.values.reduce((a, b) => a + b) /
              destinationTotals.length;
      data['modulationEnergy'] = averageDepth.clamp(0.0, 1.0).toDouble();
    } else {
      data['modulationEnergy'] = 0.0;
    }
    return data;
  }

  SynthPreset capturePreset({
    String? id,
    String? name,
    String? description,
    SynthPresetCategory category = SynthPresetCategory.user,
    bool includeAliases = true,
    bool persist = false,
    bool overwriteExisting = false,
  }) {
    final metadata = buildCapturedPresetMetadata(
      id: id,
      name: name,
      description: description,
      category: category,
    );

    final parameters = _collectState(includeAliases: includeAliases);
    final preset = SynthPreset(
      metadata: metadata,
      parameters: parameters,
      modulationRoutes: _modulationMatrix.routes,
    );

    if (persist) {
      final library = AudioPresetLibrary.instance;
      library.ensureBuiltInPresets();
      if (overwriteExisting) {
        library.upsertPreset(preset);
      } else {
        library.register(
          metadata: metadata,
          parameters: Map<String, double>.from(preset.parameters),
          modulationRoutes: preset.modulationRoutes,
          replaceExisting: false,
        );
      }
    }

    return preset;
  }

  Future<bool> loadPresetById(String id, {bool notify = true}) async {
    final library = AudioPresetLibrary.instance;
    final preset = library.findById(id);
    if (preset == null) {
      return false;
    }

    await applyPreset(preset, notify: notify);
    return true;
  }

  Future<void> applyPreset(SynthPreset preset, {bool notify = true}) async {
    final previousPresetId = _activePreset?.metadata.id;
    final changed = await _applyPresetValues(preset.parameters);
    final matrixChanged =
        _replaceModulationMatrix(preset.modulationRoutes, emitToBridge: true);
    final snapshot = _collectState(includeAliases: true);
    _activePreset = preset.copyWith(
      parameters: snapshot,
      modulationRoutes: _modulationMatrix.routes,
    );

    if (notify && (changed || matrixChanged || previousPresetId != preset.metadata.id)) {
      notifyListeners();
    }
  }

  /// Load a preset structure.  The format is intentionally permissive so we can
  /// consume data from the various LLM services without additional transforms.
  Future<void> loadPreset(Map<String, dynamic> preset) async {
    if (preset.containsKey('metadata') && preset.containsKey('parameters')) {
      final typedPreset = SynthPreset.fromJson(preset);
      await applyPreset(typedPreset);
      return;
    }

    final extractedValues = _extractPresetValues(preset);
    final extractedRoutes = _extractModulationRoutes(preset);
    final hasRoutePayload = extractedRoutes != null;

    if (extractedValues.isEmpty && !hasRoutePayload) {
      return;
    }

    final changed = extractedValues.isEmpty
        ? false
        : await _applyPresetValues(extractedValues);
    final matrixChanged = hasRoutePayload
        ? _replaceModulationMatrix(extractedRoutes!, emitToBridge: true)
        : false;

    if (!changed && !matrixChanged) {
      return;
    }

    final metadata = buildCapturedPresetMetadata(
      id: preset['id'] as String?,
      name: preset['name'] as String?,
      description: preset['description'] as String?,
      category: _categoryFromString(preset['category'] as String?),
    );

    _activePreset = SynthPreset(
      metadata: metadata,
      parameters: _collectState(includeAliases: true),
      modulationRoutes: _modulationMatrix.routes,
    );

    notifyListeners();
  }

  Future<bool> _applyPresetValues(Map<String, double> values) async {
    if (values.isEmpty) {
      return false;
    }

    var changed = false;
    final processed = <String>{};

    for (final entry in values.entries) {
      final canonical = _canonicalParameterNameFor(entry.key);
      if (!processed.add(canonical)) {
        continue;
      }

      final setter = _parameterSetters[canonical];
      if (setter == null) {
        continue;
      }

      await setter(entry.value, notify: false);
      changed = true;
    }

    return changed;
  }

  Map<String, double> _collectState({bool includeAliases = true}) {
    final values = <String, double>{
      'masterVolume': _masterVolume,
      'filterCutoff': _filterCutoff,
      'filterResonance': _filterResonance,
      'attackTime': _attackTime,
      'decayTime': _decayTime,
      'sustainLevel': _sustainLevel,
      'releaseTime': _releaseTime,
      'reverbMix': _reverbMix,
      'delayTime': _delayTime,
      'delayFeedback': _delayFeedback,
      'lfoRate': _lfoRate,
      'lfoDepth': _lfoDepth,
      'oscillatorBlend': _oscillatorBlend,
      'oscillatorDetune': _oscillatorDetune,
      'oscillatorSpread': _oscillatorSpread,
      'distortionDrive': _distortionDrive,
      'chorusRate': _chorusRate,
      'chorusDepth': _chorusDepth,
      'glideTime': _glideTime,
      'pitchBendRange': _pitchBendRange,
      'modWheel': _modWheel,
      'channelAftertouch': _channelAftertouch,
      'expression': _expression,
      'sustainPedal': _sustainPedal,
      'granularActive': _granularActive,
      'granularGrainRate': _granularGrainRate,
      'granularGrainDuration': _granularGrainDuration,
      'granularPosition': _granularPosition,
      'granularPitch': _granularPitch,
      'granularAmplitude': _granularAmplitude,
      'granularPositionVariation': _granularPositionVariation,
      'granularPitchVariation': _granularPitchVariation,
      'granularDurationVariation': _granularDurationVariation,
      'granularPan': _granularPan,
      'granularPanVariation': _granularPanVariation,
      'granularWindowType': _granularWindowType,
      'wavetablePosition': _wavetablePosition,
      'microphoneVolume': _microphoneVolume,
      'arpeggiatorEnabled': _arpeggiatorEnabled,
      'arpeggiatorRate': _arpeggiatorRate,
      'arpeggiatorGate': _arpeggiatorGate,
      'arpeggiatorOctaves': _arpeggiatorOctaves,
      'arpeggiatorMode': _arpeggiatorMode,
      'arpeggiatorPattern': _arpeggiatorPattern,
      'arpeggiatorSwing': _arpeggiatorSwing,
      'arpeggiatorLatch': _arpeggiatorLatch,
      'arpeggiatorTempoSync': _arpeggiatorTempoSync,
      'arpeggiatorDivision': _arpeggiatorDivision,
      'transportTempo': _transportTempo,
      'transportRunning': _transportRunning,
      'transportTimeSignatureNumerator': _transportTimeSignatureNumerator,
      'transportTimeSignatureDenominator': _transportTimeSignatureDenominator,
      'maxPolyphony': _voiceAllocator.maxVoices.toDouble(),
    };

    if (!includeAliases) {
      return values;
    }

    return _parameterRegistry.expandWithAliases(values);
  }

  Map<String, double> _extractPresetValues(Map<String, dynamic> preset) {
    final flattened = _flattenPresetValues(preset);
    return _parameterRegistry.canonicalize(flattened);
  }

  List<ModulationRoute>? _extractModulationRoutes(Map<String, dynamic> preset) {
    var found = false;
    final routes = <ModulationRoute>[];

    void addRoute(String source, String destination, double? amount) {
      if (source.isEmpty || destination.isEmpty || amount == null) {
        return;
      }
      routes.add(
        ModulationRoute(
          source: source.trim(),
          destination: destination.trim(),
          amount: amount,
        ),
      );
    }

    void parseMatrixMap(Map<dynamic, dynamic> map) {
      map.forEach((dynamic rawSource, dynamic rawValue) {
        if (rawSource is! String) {
          return;
        }

        if (rawValue is Map) {
          rawValue.forEach((dynamic rawDest, dynamic rawAmount) {
            if (rawDest is! String) {
              return;
            }
            addRoute(rawSource, rawDest, _coerceToDouble(rawAmount));
          });
          return;
        }

        if (rawValue is Iterable) {
          for (final element in rawValue) {
            if (element is Map<String, dynamic>) {
              final destination = element['destination'] as String? ?? '';
              final amount = _coerceToDouble(element['amount']);
              addRoute(rawSource, destination, amount);
            }
          }
          return;
        }

        final amount = _coerceToDouble(rawValue);
        if (amount == null) {
          return;
        }

        final parts = rawSource.split('->');
        if (parts.length == 2) {
          addRoute(parts[0], parts[1], amount);
        }
      });
    }

    final rawRoutes = preset['modulationRoutes'];
    if (rawRoutes is Iterable) {
      found = true;
      for (final entry in rawRoutes) {
        if (entry is Map<String, dynamic>) {
          final source = (entry['source'] as String?)?.trim() ?? '';
          final destination = (entry['destination'] as String?)?.trim() ?? '';
          final amount = _coerceToDouble(entry['amount']);
          addRoute(source, destination, amount);
        }
      }
    }

    final mapCandidates = <Map<dynamic, dynamic>>[];
    if (preset['modulationMatrix'] is Map) {
      found = true;
      mapCandidates.add((preset['modulationMatrix'] as Map).cast<dynamic, dynamic>());
    }
    if (preset['modMatrix'] is Map) {
      found = true;
      mapCandidates.add((preset['modMatrix'] as Map).cast<dynamic, dynamic>());
    }
    if (preset['modRouting'] is Map) {
      found = true;
      mapCandidates.add((preset['modRouting'] as Map).cast<dynamic, dynamic>());
    }

    for (final candidate in mapCandidates) {
      parseMatrixMap(candidate);
    }

    return found ? routes : null;
  }

  static Map<String, double> _flattenPresetValues(
      Map<String, dynamic> preset) {
    final result = <String, double>{};

    void visit(dynamic value, String path) {
      if (value is Map<String, dynamic>) {
        value.forEach((key, child) {
          final nextPath = path.isEmpty ? key : '$path.$key';
          visit(child, nextPath);
        });
        return;
      }

      if (value is Map) {
        value.forEach((dynamic key, dynamic child) {
          if (key is! String) {
            return;
          }
          final nextPath = path.isEmpty ? key : '$path.$key';
          visit(child, nextPath);
        });
        return;
      }

      if (value is Iterable) {
        var index = 0;
        for (final element in value) {
          final nextPath = path.isEmpty ? '$index' : '$path.$index';
          visit(element, nextPath);
          index++;
        }
        return;
      }

      final numericValue = _coerceToParameterValue(path, value);
      if (numericValue == null) {
        return;
      }

      final key = ParameterRegistry.normalizeKey(path);
      if (key.isEmpty) {
        return;
      }

      result[key] = numericValue;
    }

    preset.forEach((key, value) {
      visit(value, key);
    });

    return result;
  }

  static double? _coerceToParameterValue(String path, dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final normalizedKey = ParameterRegistry.normalizeKey(path);

    if (value is bool) {
      return value ? 1.0 : 0.0;
    }

    if (value is String) {
      final numeric = double.tryParse(value);
      if (numeric != null) {
        return numeric;
      }

      final sanitizedValue = ParameterRegistry.normalizeKey(value);

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatorenabled',
        'arpeggiatoractive',
        'arpenabled',
        'arpactive',
      ])) {
        if (_matchesNormalizedKey(sanitizedValue, const <String>['true', 'on', 'yes'])) {
          return 1.0;
        }
        if (_matchesNormalizedKey(sanitizedValue, const <String>['false', 'off', 'no'])) {
          return 0.0;
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatorlatch',
        'arplatch',
        'arpeggiatorhold',
        'arphold',
      ])) {
        if (_matchesNormalizedKey(sanitizedValue, const <String>['true', 'on', 'yes'])) {
          return 1.0;
        }
        if (_matchesNormalizedKey(sanitizedValue, const <String>['false', 'off', 'no'])) {
          return 0.0;
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatortemposync',
        'arpsync',
        'arpsynced',
      ])) {
        if (_matchesNormalizedKey(sanitizedValue, const <String>['true', 'on', 'yes'])) {
          return 1.0;
        }
        if (_matchesNormalizedKey(sanitizedValue, const <String>['false', 'off', 'no'])) {
          return 0.0;
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatormode',
        'arpmode',
        'arpeggiatordirection',
        'arpdirection',
      ])) {
        for (final mode in ArpeggiatorMode.values) {
          final modeKey = ParameterRegistry.normalizeKey(mode.name);
          if (modeKey == sanitizedValue) {
            return mode.value.toDouble();
          }
        }
        if (_matchesNormalizedKey(sanitizedValue, const <String>['updown'])) {
          return ArpeggiatorMode.upDown.value.toDouble();
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatorpattern',
        'arppattern',
        'arpeggiatorshape',
      ])) {
        for (final pattern in ArpeggiatorPattern.values) {
          final patternKey = ParameterRegistry.normalizeKey(pattern.name);
          if (patternKey == sanitizedValue) {
            return pattern.value.toDouble();
          }
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'arpeggiatordivision',
        'arpratedivision',
        'arprate',
      ])) {
        for (final division in ArpeggiatorDivision.values) {
          final divisionKey = ParameterRegistry.normalizeKey(division.name);
          if (divisionKey == sanitizedValue ||
              sanitizedValue == ParameterRegistry.normalizeKey(divisionLabel(division)) ||
              sanitizedValue == '${division.value}') {
            return division.value.toDouble();
          }
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'transportrunning',
        'transportplay',
        'transportactive',
      ])) {
        if (_matchesNormalizedKey(sanitizedValue, const <String>['true', 'on', 'yes', 'play'])) {
          return 1.0;
        }
        if (_matchesNormalizedKey(sanitizedValue, const <String>['false', 'off', 'no', 'stop'])) {
          return 0.0;
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'transporttimesignaturenumerator',
        'transporttsnum',
        'transportnumerator',
      ])) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed.toDouble();
        }
      }

      if (_matchesNormalizedKey(normalizedKey, const <String>[
        'transporttimesignaturedenominator',
        'transporttsden',
        'transportdenominator',
      ])) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed.toDouble();
        }
      }
    }

    return null;
  }

  static bool _matchesNormalizedKey(String key, List<String> normalizedOptions) {
    return normalizedOptions.contains(key);
  }

  Future<void> _updateParameter({
    required double value,
    required ParameterRange range,
    required double current,
    required int parameterId,
    required String bridgeParameterName,
    required void Function(double) assign,
    required bool notify,
  }) async {
    final clamped = range.clamp(value);
    if ((clamped - current).abs() < 0.00001) {
      return;
    }

    assign(clamped);
    _backend.setParameter(parameterId, clamped);
    _emitParameterToBridge(bridgeParameterName, clamped);

    if (notify) {
      notifyListeners();
    }
  }

  void _pushStateToBackend() {
    _backend.setParameter(SynthParameterId.masterVolume, _masterVolume);
    _backend.setParameter(SynthParameterId.filterCutoff, _filterCutoff);
    _backend.setParameter(SynthParameterId.filterResonance, _filterResonance);
    _backend.setParameter(SynthParameterId.attackTime, _attackTime);
    _backend.setParameter(SynthParameterId.decayTime, _decayTime);
    _backend.setParameter(SynthParameterId.sustainLevel, _sustainLevel);
    _backend.setParameter(SynthParameterId.releaseTime, _releaseTime);
    _backend.setParameter(SynthParameterId.reverbMix, _reverbMix);
    _backend.setParameter(SynthParameterId.delayTime, _delayTime);
    _backend.setParameter(SynthParameterId.delayFeedback, _delayFeedback);
    _backend.setParameter(SynthParameterId.lfoRate, _lfoRate);
    _backend.setParameter(SynthParameterId.lfoDepth, _lfoDepth);
    _backend.setParameter(SynthParameterId.oscillatorBlend, _oscillatorBlend);
    _backend.setParameter(SynthParameterId.oscillatorDetune, _oscillatorDetune);
    _backend.setParameter(SynthParameterId.oscillatorSpread, _oscillatorSpread);
    _backend.setParameter(SynthParameterId.distortionDrive, _distortionDrive);
    _backend.setParameter(SynthParameterId.chorusRate, _chorusRate);
    _backend.setParameter(SynthParameterId.chorusDepth, _chorusDepth);
    _backend.setParameter(SynthParameterId.glideTime, _glideTime);
    _backend.setParameter(SynthParameterId.pitchBendRange, _pitchBendRange);
    _backend.setParameter(SynthParameterId.modWheel, _modWheel);
    _backend.setParameter(
        SynthParameterId.channelAftertouch, _channelAftertouch);
    _backend.setParameter(SynthParameterId.expression, _expression);
    _backend.setParameter(SynthParameterId.sustainPedal, _sustainPedal);
    _backend.setParameter(SynthParameterId.granularActive, _granularActive);
    _backend.setParameter(
        SynthParameterId.granularGrainRate, _granularGrainRate);
    _backend.setParameter(
        SynthParameterId.granularGrainDuration, _granularGrainDuration);
    _backend.setParameter(SynthParameterId.granularPosition, _granularPosition);
    _backend.setParameter(SynthParameterId.granularPitch, _granularPitch);
    _backend.setParameter(
        SynthParameterId.granularAmplitude, _granularAmplitude);
    _backend.setParameter(
        SynthParameterId.granularPositionVariation, _granularPositionVariation);
    _backend.setParameter(
        SynthParameterId.granularPitchVariation, _granularPitchVariation);
    _backend.setParameter(
        SynthParameterId.granularDurationVariation, _granularDurationVariation);
    _backend.setParameter(SynthParameterId.granularPan, _granularPan);
    _backend.setParameter(
        SynthParameterId.granularPanVariation, _granularPanVariation);
    _backend.setParameter(
        SynthParameterId.granularWindowType, _granularWindowType);
    _backend.setParameter(
        SynthParameterId.wavetablePosition, _wavetablePosition);
    _backend.setParameter(
        SynthParameterId.microphoneVolume, _microphoneVolume);
    _backend.setParameter(
        SynthParameterId.arpeggiatorEnabled, _arpeggiatorEnabled);
    _backend.setParameter(
        SynthParameterId.arpeggiatorRate, _arpeggiatorRate);
    _backend.setParameter(
        SynthParameterId.arpeggiatorGate, _arpeggiatorGate);
    _backend.setParameter(
        SynthParameterId.arpeggiatorOctaves, _arpeggiatorOctaves);
    _backend.setParameter(
        SynthParameterId.arpeggiatorMode, _arpeggiatorMode);
    _backend.setParameter(
        SynthParameterId.arpeggiatorPattern, _arpeggiatorPattern);
    _backend.setParameter(
        SynthParameterId.arpeggiatorSwing, _arpeggiatorSwing);
    _backend.setParameter(
        SynthParameterId.arpeggiatorLatch, _arpeggiatorLatch);
    _backend.setParameter(
        SynthParameterId.arpeggiatorTempoSync, _arpeggiatorTempoSync);
    _backend.setParameter(
        SynthParameterId.arpeggiatorDivision, _arpeggiatorDivision);
    _backend.setParameter(SynthParameterId.transportTempo, _transportTempo);
    _backend.setParameter(
        SynthParameterId.transportRunning, _transportRunning);
    _backend.setParameter(
        SynthParameterId.transportTimeSignatureNumerator,
        _transportTimeSignatureNumerator);
    _backend.setParameter(
        SynthParameterId.transportTimeSignatureDenominator,
        _transportTimeSignatureDenominator);
  }

  void _emitParameterToBridge(String name, double value) {
    final bridge = _parameterBridge;
    if (bridge == null) {
      return;
    }

    bridge.updateParameter(name, value, ParameterBridge.UpdateSource.audio);
    for (final alias in _parameterRegistry.bridgeAliases(name)) {
      bridge.updateParameter(alias, value, ParameterBridge.UpdateSource.audio);
    }
  }

  bool _applyModulationRoute(ModulationRoute route, {bool emitToBridge = true}) {
    final isRemoval = route.amount.abs() < ModulationMatrix.epsilon;
    final changed = _modulationMatrix.setRoute(route);
    if (!changed) {
      return false;
    }

    if (emitToBridge) {
      if (isRemoval) {
        _emitModulationRouteRemovalToBridge(route.source, route.destination);
      } else {
        _emitModulationRouteToBridge(route);
      }
    }

    return true;
  }

  bool _removeModulationRoute(String source, String destination,
      {bool emitToBridge = true}) {
    final removed = _modulationMatrix.removeRoute(source, destination);
    if (!removed) {
      return false;
    }

    if (emitToBridge) {
      _emitModulationRouteRemovalToBridge(source, destination);
    }
    return true;
  }

  bool _replaceModulationMatrix(Iterable<ModulationRoute> routes,
      {bool emitToBridge = true}) {
    final previous = {for (final route in _modulationMatrix.routes) route.key: route};
    final changed = _modulationMatrix.replaceAll(routes);

    if (!emitToBridge) {
      return changed;
    }

    final current = {for (final route in _modulationMatrix.routes) route.key: route};
    for (final route in current.values) {
      _emitModulationRouteToBridge(route);
    }

    for (final removedKey in previous.keys) {
      if (!current.containsKey(removedKey)) {
        final removedRoute = previous[removedKey]!;
        _emitModulationRouteRemovalToBridge(
          removedRoute.source,
          removedRoute.destination,
        );
      }
    }

    if (current.isEmpty) {
      _emitModulationMatrixCleared();
    }

    return changed;
  }

  void _emitModulationRouteToBridge(ModulationRoute route) {
    final bridge = _parameterBridge;
    if (bridge == null) {
      return;
    }

    final key = ModulationMatrixCodec.encodeBridgeKey(route.source, route.destination);
    bridge.updateParameter(key, route.amount, ParameterBridge.UpdateSource.audio);
  }

  void _emitModulationRouteRemovalToBridge(String source, String destination) {
    final bridge = _parameterBridge;
    if (bridge == null) {
      return;
    }

    final key = ModulationMatrixCodec.encodeBridgeKey(source, destination);
    bridge.updateParameter(key, 0.0, ParameterBridge.UpdateSource.audio);
  }

  void _emitModulationMatrixCleared() {
    final bridge = _parameterBridge;
    if (bridge == null) {
      return;
    }

    bridge.updateParameter(
      '${ModulationMatrixCodec.bridgePrefix}__cleared__',
      1.0,
      ParameterBridge.UpdateSource.audio,
    );
  }

  void _emitModulationMatrixToBridge() {
    final bridge = _parameterBridge;
    if (bridge == null) {
      return;
    }

    if (_modulationMatrix.routeCount == 0) {
      _emitModulationMatrixCleared();
      return;
    }

    for (final route in _modulationMatrix.routes) {
      _emitModulationRouteToBridge(route);
    }
  }

  void _pushStateToBridge() {
    final state = _collectState(includeAliases: false);
    state.forEach(_emitParameterToBridge);
    _emitModulationMatrixToBridge();
  }

  void _hookSyncManager() {
    _syncManager.initialize(_backend);
  }

  @override
  void dispose() {
    _liveEngines.remove(this);
    final wasBridgeOwner = identical(_bridgeOwner, this);
    final wasLastInstance = _instanceCount <= 1;
    _instanceCount = (_instanceCount - 1).clamp(0, 1 << 30).toInt();
    final releasedVoices = _voiceAllocator.reset();

    if (_backend.isInitialized) {
      for (final voice in releasedVoices) {
        _backend.noteOff(voice.voiceId);
      }
    }

    if (wasLastInstance) {
      _syncManager.detach(_backend);
      _pendingInitialization = null;
      _isInitialized = false;
    }

    if (wasBridgeOwner) {
      _releaseParameterBridge();
      _bridgeOwner = null;
      for (final candidate in _liveEngines) {
        candidate._maybeClaimParameterBridge();
        if (_bridgeOwner != null) {
          break;
        }
      }
    }

    _backend.dispose();
    super.dispose();
  }

  void _maybeClaimParameterBridge() {
    final bridge = _parameterBridge;
    if (bridge == null || _bridgeOwner != null) {
      return;
    }

    _parameterBridgeHandler ??= (String name, double value) {
      unawaited(_handleBridgeUpdate(name, value));
    };

    bridge.registerAudioHandler(_parameterBridgeHandler!);
    _bridgeOwner = this;
    _pushStateToBridge();
  }

  Future<void> _handleBridgeUpdate(String name, double value) async {
    final modulationRoute = ModulationMatrixCodec.decodeBridgeKey(name, value);
    if (modulationRoute != null) {
      final changed = _applyModulationRoute(modulationRoute, emitToBridge: false);
      if (changed) {
        _activePreset = _activePreset?.copyWith(
          modulationRoutes: _modulationMatrix.routes,
        );
        notifyListeners();
      }
      return;
    }

    if (name == '${ModulationMatrixCodec.bridgePrefix}clear') {
      final changed = _modulationMatrix.clear();
      if (changed) {
        _activePreset = _activePreset?.copyWith(
          modulationRoutes: _modulationMatrix.routes,
        );
        notifyListeners();
      }
      return;
    }

    final canonical = _canonicalParameterNameFor(name);
    final setter = _parameterSetters[canonical];
    if (setter == null) {
      return;
    }

    await setter(value, notify: true);
  }

  void _releaseParameterBridge() {
    final handler = _parameterBridgeHandler;
    final bridge = _parameterBridge;
    if (handler == null || bridge == null) {
      return;
    }

    bridge.unregisterAudioHandler(handler);
    _parameterBridgeHandler = null;
  }

  static String _canonicalParameterNameFor(String name) {
    return _parameterRegistry.canonicalName(name) ?? name;
  }

  static SynthPresetCategory _categoryFromString(String? category) {
    if (category == null || category.isEmpty) {
      return SynthPresetCategory.user;
    }

    return SynthPresetCategory.values.firstWhere(
      (value) => value.name.toLowerCase() == category.toLowerCase(),
      orElse: () => SynthPresetCategory.user,
    );
  }
}
