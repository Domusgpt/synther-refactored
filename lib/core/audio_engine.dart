import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/audio_ui_sync.dart';
import 'audio_backend.dart';
import 'parameter_definitions.dart';
import 'platform_audio_backend.dart';

/// High level controller that exposes the synthesiser behaviour to the UI.
///
/// The legacy project expected a complex native audio engine.  The new
/// implementation wraps the lightweight [AudioBackend] so the rest of the app
/// can continue to interact with something that looks and feels like the
/// original engine while remaining completely in Dart.
class AudioEngine extends ChangeNotifier {
  AudioEngine({AudioBackend? backend}) : _backend = backend ?? createAudioBackend() {
    _instanceCount++;
  }

  static final AudioUISyncManager _syncManager = AudioUISyncManager.instance;

  static Future<void>? _pendingInitialization;
  static bool _syncManagerHooked = false;
  static int _instanceCount = 0;

  final AudioBackend _backend;

  bool _isInitialized = false;
  String? _lastError;

  double _masterVolume = 0.75;
  double _filterCutoff = 1200;
  double _filterResonance = 0.35;
  double _attackTime = 0.02;
  double _decayTime = 0.2;
  double _sustainLevel = 0.7;
  double _releaseTime = 0.4;
  double _reverbMix = 0.25;
  double _delayTime = 0.25;
  double _delayFeedback = 0.2;
  int _nextVoiceId = 0;
  final Map<int, List<int>> _voicesByNote = <int, List<int>>{};

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

  /// Initialises the shared backend.  Multiple [AudioEngine] instances share the
  /// same backend instance so only the first call performs real work.
  Future<bool> initialize() async {
    if (_backend.isInitialized) {
      _isInitialized = true;
      return true;
    }

    _pendingInitialization ??= _backend.initialize();

    try {
      await _pendingInitialization;
      _isInitialized = _backend.isInitialized;
      _lastError = _backend.lastError;

      if (_isInitialized) {
        _pushStateToBackend();
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
      min: 0,
      max: 1,
      current: _masterVolume,
      parameterId: SynthParameterId.masterVolume,
      assign: (v) => _masterVolume = v,
      notify: notify,
    );
  }

  Future<void> setFilterCutoff(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      min: 20,
      max: 20000,
      current: _filterCutoff,
      parameterId: SynthParameterId.filterCutoff,
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
      min: 0,
      max: 1.5,
      current: _filterResonance,
      parameterId: SynthParameterId.filterResonance,
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
      min: 0.001,
      max: 5,
      current: _attackTime,
      parameterId: SynthParameterId.attackTime,
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
      min: 0.001,
      max: 5,
      current: _decayTime,
      parameterId: SynthParameterId.decayTime,
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
      min: 0,
      max: 1,
      current: _sustainLevel,
      parameterId: SynthParameterId.sustainLevel,
      assign: (v) => _sustainLevel = v,
      notify: notify,
    );
  }

  Future<void> setReleaseTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      min: 0.01,
      max: 10,
      current: _releaseTime,
      parameterId: SynthParameterId.releaseTime,
      assign: (v) => _releaseTime = v,
      notify: notify,
    );
  }

  Future<void> setReverbMix(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      min: 0,
      max: 1,
      current: _reverbMix,
      parameterId: SynthParameterId.reverbMix,
      assign: (v) => _reverbMix = v,
      notify: notify,
    );
  }

  Future<void> setDelayTime(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      min: 0.01,
      max: 2,
      current: _delayTime,
      parameterId: SynthParameterId.delayTime,
      assign: (v) => _delayTime = v,
      notify: notify,
    );
  }

  Future<void> setDelayFeedback(double value, {bool notify = true}) async {
    await _updateParameter(
      value: value,
      min: 0,
      max: 0.95,
      current: _delayFeedback,
      parameterId: SynthParameterId.delayFeedback,
      assign: (v) => _delayFeedback = v,
      notify: notify,
    );
  }

  /// Trigger a new note using the MIDI [note] number and a 0-1 [velocity].
  void noteOn(int note, [double velocity = 1.0]) {
    if (!_backend.isInitialized) return;
    final normalisedVelocity = velocity.clamp(0.0, 1.0).toDouble();
    final voiceId = _allocateVoiceId(note);
    _backend.noteOn(voiceId, note, normalisedVelocity);
    notifyListeners();
  }

  /// Release a note that was started with [noteOn].
  void noteOff(int note) {
    if (!_backend.isInitialized) return;
    final voiceId = _releaseVoiceId(note);
    if (voiceId == null) {
      return;
    }
    _backend.noteOff(voiceId);
    notifyListeners();
  }

  Map<String, double> getVisualizerData() {
    final data = Map<String, double>.from(_backend.getVisualizerData());
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
    return data;
  }

  /// Load a preset structure.  The format is intentionally permissive so we can
  /// consume data from the various LLM services without additional transforms.
  Future<void> loadPreset(Map<String, dynamic> preset) async {
    Future<void> setFromCandidates(
      Iterable<dynamic> candidates,
      Future<void> Function(double, {bool notify}) setter,
    ) async {
      for (final candidate in candidates) {
        if (candidate is num) {
          await setter(candidate.toDouble(), notify: false);
          return;
        }
      }
    }

    final filter = preset['filter'] as Map<String, dynamic>?;
    await setFromCandidates([
      filter?['cutoff'],
      filter?['filterCutoff'],
      preset['filterCutoff'],
    ], setFilterCutoff);
    await setFromCandidates([
      filter?['resonance'],
      filter?['filterResonance'],
      preset['filterResonance'],
    ], setFilterResonance);

    final envelope = preset['envelope'] as Map<String, dynamic>?;
    await setFromCandidates([
      envelope?['attack'],
      envelope?['attackTime'],
      preset['attack'],
      preset['attackTime'],
    ], setAttackTime);
    await setFromCandidates([
      envelope?['decay'],
      envelope?['decayTime'],
      preset['decay'],
      preset['decayTime'],
    ], setDecayTime);
    await setFromCandidates([
      envelope?['sustain'],
      envelope?['sustainLevel'],
      preset['sustain'],
      preset['sustainLevel'],
    ], setSustainLevel);
    await setFromCandidates([
      envelope?['release'],
      envelope?['releaseTime'],
      preset['release'],
      preset['releaseTime'],
    ], setReleaseTime);

    final effects = preset['effects'] as Map<String, dynamic>?;
    await setFromCandidates([
      effects?['reverb'],
      effects?['reverbMix'],
      preset['reverbMix'],
    ], setReverbMix);
    await setFromCandidates([
      effects?['delayTime'],
      preset['delayTime'],
    ], setDelayTime);
    await setFromCandidates([
      effects?['delayFeedback'],
      preset['delayFeedback'],
    ], setDelayFeedback);

    await setFromCandidates([
      preset['masterVolume'],
      preset['volume'],
    ], setMasterVolume);

    notifyListeners();
  }

  Future<void> _updateParameter({
    required double value,
    required double min,
    required double max,
    required double current,
    required int parameterId,
    required void Function(double) assign,
    required bool notify,
  }) async {
    final clamped = value.clamp(min, max).toDouble();
    if ((clamped - current).abs() < 0.00001) {
      return;
    }

    assign(clamped);
    _backend.setParameter(parameterId, clamped);

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
  }

  void _hookSyncManager() {
    if (_syncManagerHooked) return;
    _syncManager.initialize(_backend);
    _syncManagerHooked = true;
  }

  @override
  void dispose() {
    _instanceCount--;
    if (_instanceCount <= 0) {
      _backend.dispose();
      _pendingInitialization = null;
      _syncManagerHooked = false;
      _isInitialized = false;
    }
    _voicesByNote.clear();
    _nextVoiceId = 0;
    super.dispose();
  }

  int _allocateVoiceId(int note) {
    final voiceId = _nextVoiceId++;
    if (_nextVoiceId == 0x7fffffff) {
      _nextVoiceId = 0;
    }
    final voices = _voicesByNote.putIfAbsent(note, () => <int>[]);
    voices.add(voiceId);
    return voiceId;
  }

  int? _releaseVoiceId(int note) {
    final voices = _voicesByNote[note];
    if (voices == null || voices.isEmpty) {
      return null;
    }
    final voiceId = voices.removeLast();
    if (voices.isEmpty) {
      _voicesByNote.remove(note);
    }
    return voiceId;
  }
}
