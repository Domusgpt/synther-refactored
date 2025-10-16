import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../utils/audio_ui_sync.dart';
import 'audio_backend.dart';
import 'audio_preset_library.dart';
import 'parameter_definitions.dart';
import 'parameter_models.dart';
import 'parameter_registry.dart';
import 'platform_audio_backend.dart';
import 'parameter_bridge.dart';
import 'synth_preset.dart';
import 'voice_allocator.dart';

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
    data['activeVoices'] = _voiceAllocator.activeVoiceCount.toDouble();
    data['maxPolyphony'] = _voiceAllocator.maxVoices.toDouble();
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
    final snapshot = _collectState(includeAliases: true);
    _activePreset = preset.copyWith(parameters: snapshot);

    if (notify && (changed || previousPresetId != preset.metadata.id)) {
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
    if (extractedValues.isEmpty) {
      return;
    }

    final changed = await _applyPresetValues(extractedValues);
    if (!changed) {
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

      final numericValue = _coerceToDouble(value);
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

  static double? _coerceToDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
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

  void _pushStateToBridge() {
    final state = _collectState(includeAliases: false);
    state.forEach(_emitParameterToBridge);
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
