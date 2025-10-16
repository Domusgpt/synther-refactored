import 'modulation_matrix.dart';
import 'parameter_registry.dart';
import 'parameter_definitions.dart';
import 'synth_preset.dart';

/// Registry that stores synthesiser presets available to the application.
class AudioPresetLibrary {
  AudioPresetLibrary._();

  static final AudioPresetLibrary instance = AudioPresetLibrary._();

  final Map<String, SynthPreset> _presets = <String, SynthPreset>{};

  bool _initialised = false;

  /// Lazily register the built-in factory presets on first access.
  void ensureBuiltInPresets() {
    if (_initialised) {
      return;
    }

    final now = DateTime.now();
    void registerPreset({
      required String id,
      required String name,
      required SynthPresetCategory category,
      required Map<String, double> parameters,
      String description = '',
      List<String> tags = const <String>[],
      List<ModulationRoute> modulationRoutes = const <ModulationRoute>[],
    }) {
      final metadata = SynthPresetMetadata(
        id: id,
        name: name,
        description: description,
        category: category,
        createdAt: now,
        tags: tags,
        isFactory: true,
      );

      register(
        metadata: metadata,
        parameters: parameters,
        modulationRoutes: modulationRoutes,
        replaceExisting: true,
      );
    }

    registerPreset(
      id: 'factory-glow-pad',
      name: 'Glow Pad',
      category: SynthPresetCategory.ambient,
      description: 'Wide shimmering pad with a slow attack and evolving tail.',
      tags: const <String>['ambient', 'pad', 'wide'],
      parameters: const <String, double>{
        'masterVolume': 0.68,
        'filterCutoff': 1450.0,
        'filterResonance': 0.28,
        'attackTime': 0.85,
        'decayTime': 0.9,
        'sustainLevel': 0.82,
        'releaseTime': 2.4,
        'reverbMix': 0.62,
        'delayTime': 0.48,
        'delayFeedback': 0.38,
        'lfoRate': 0.35,
        'lfoDepth': 0.7,
        'oscillatorBlend': 0.6,
        'oscillatorDetune': 4.0,
        'oscillatorSpread': 0.72,
        'distortionDrive': 0.18,
        'chorusRate': 0.38,
        'chorusDepth': 0.68,
        'glideTime': 0.65,
        'pitchBendRange': 4.0,
        'modWheel': 0.62,
        'channelAftertouch': 0.28,
        'expression': 0.84,
        'sustainPedal': 0.95,
        'arpeggiatorEnabled': 1.0,
        'arpeggiatorRate': 6.0,
        'arpeggiatorGate': 0.55,
        'arpeggiatorOctaves': 2.0,
        'arpeggiatorMode': 2.0,
        'arpeggiatorPattern': 0.0,
        'arpeggiatorSwing': 0.25,
        'arpeggiatorLatch': 0.0,
        'arpeggiatorTempoSync': 1.0,
        'arpeggiatorDivision': ArpeggiatorDivision.eighth.value.toDouble(),
        'transportTempo': 110.0,
        'transportRunning': 1.0,
        'transportTimeSignatureNumerator': 4.0,
        'transportTimeSignatureDenominator': 4.0,
      },
      modulationRoutes: const <ModulationRoute>[
        ModulationRoute(source: 'lfo1', destination: 'filterCutoff', amount: 0.42),
        ModulationRoute(source: 'lfo1', destination: 'oscillatorDetune', amount: 0.18),
      ],
    );

    registerPreset(
      id: 'factory-laser-pluck',
      name: 'Laser Pluck',
      category: SynthPresetCategory.performance,
      description: 'Snappy plucked lead with bright harmonics and tempo delay.',
      tags: const <String>['lead', 'pluck', 'tempo'],
      parameters: const <String, double>{
        'masterVolume': 0.74,
        'filterCutoff': 5200.0,
        'filterResonance': 0.42,
        'attackTime': 0.012,
        'decayTime': 0.22,
        'sustainLevel': 0.3,
        'releaseTime': 0.18,
        'reverbMix': 0.25,
        'delayTime': 0.31,
        'delayFeedback': 0.46,
        'lfoRate': 8.0,
        'lfoDepth': 0.24,
        'oscillatorBlend': 0.28,
        'oscillatorDetune': -2.0,
        'oscillatorSpread': 0.26,
        'distortionDrive': 0.42,
        'chorusRate': 1.8,
        'chorusDepth': 0.24,
        'glideTime': 0.02,
        'pitchBendRange': 12.0,
        'modWheel': 0.58,
        'channelAftertouch': 0.18,
        'expression': 0.7,
        'sustainPedal': 0.25,
        'arpeggiatorEnabled': 1.0,
        'arpeggiatorRate': 12.0,
        'arpeggiatorGate': 0.38,
        'arpeggiatorOctaves': 1.0,
        'arpeggiatorMode': 0.0,
        'arpeggiatorPattern': 3.0,
        'arpeggiatorSwing': 0.1,
        'arpeggiatorLatch': 0.0,
        'arpeggiatorTempoSync': 1.0,
        'arpeggiatorDivision': ArpeggiatorDivision.sixteenth.value.toDouble(),
        'transportTempo': 128.0,
        'transportRunning': 1.0,
        'transportTimeSignatureNumerator': 4.0,
        'transportTimeSignatureDenominator': 4.0,
      },
      modulationRoutes: const <ModulationRoute>[
        ModulationRoute(source: 'modWheel', destination: 'filterCutoff', amount: 0.65),
      ],
    );

    registerPreset(
      id: 'factory-submerged-bass',
      name: 'Submerged Bass',
      category: SynthPresetCategory.bass,
      description: 'Focused low-end patch with tight decay and mild resonance.',
      tags: const <String>['bass', 'tight', 'low-end'],
      parameters: const <String, double>{
        'masterVolume': 0.63,
        'filterCutoff': 420.0,
        'filterResonance': 0.55,
        'attackTime': 0.025,
        'decayTime': 0.19,
        'sustainLevel': 0.58,
        'releaseTime': 0.24,
        'reverbMix': 0.18,
        'delayTime': 0.16,
        'delayFeedback': 0.21,
        'lfoRate': 2.4,
        'lfoDepth': 0.4,
        'oscillatorBlend': 0.45,
        'oscillatorDetune': -7.0,
        'oscillatorSpread': 0.18,
        'distortionDrive': 0.55,
        'chorusRate': 0.6,
        'chorusDepth': 0.18,
        'glideTime': 0.18,
        'pitchBendRange': 5.0,
        'modWheel': 0.34,
        'channelAftertouch': 0.42,
        'expression': 0.68,
        'sustainPedal': 0.12,
        'arpeggiatorEnabled': 0.0,
        'arpeggiatorRate': 8.0,
        'arpeggiatorGate': 0.5,
        'arpeggiatorOctaves': 1.0,
        'arpeggiatorMode': 4.0,
        'arpeggiatorPattern': 2.0,
        'arpeggiatorSwing': 0.0,
        'arpeggiatorLatch': 0.0,
        'arpeggiatorTempoSync': 0.0,
        'arpeggiatorDivision': ArpeggiatorDivision.quarter.value.toDouble(),
        'transportTempo': 100.0,
        'transportRunning': 1.0,
        'transportTimeSignatureNumerator': 4.0,
        'transportTimeSignatureDenominator': 4.0,
      },
      modulationRoutes: const <ModulationRoute>[
        ModulationRoute(source: 'expression', destination: 'distortionDrive', amount: 0.4),
      ],
    );

    registerPreset(
      id: 'factory-crystal-keys',
      name: 'Crystal Keys',
      category: SynthPresetCategory.keys,
      description: 'Bell-like keys with long shimmering release tails.',
      tags: const <String>['keys', 'bell', 'sparkle'],
      parameters: const <String, double>{
        'masterVolume': 0.7,
        'filterCutoff': 2800.0,
        'filterResonance': 0.33,
        'attackTime': 0.045,
        'decayTime': 0.65,
        'sustainLevel': 0.54,
        'releaseTime': 1.8,
        'reverbMix': 0.58,
        'delayTime': 0.42,
        'delayFeedback': 0.36,
        'lfoRate': 1.6,
        'lfoDepth': 0.58,
        'oscillatorBlend': 0.52,
        'oscillatorDetune': 6.0,
        'oscillatorSpread': 0.58,
        'distortionDrive': 0.22,
        'chorusRate': 1.1,
        'chorusDepth': 0.48,
        'glideTime': 0.12,
        'pitchBendRange': 7.0,
        'modWheel': 0.76,
        'channelAftertouch': 0.48,
        'expression': 0.88,
        'sustainPedal': 0.9,
        'arpeggiatorEnabled': 1.0,
        'arpeggiatorRate': 5.5,
        'arpeggiatorGate': 0.72,
        'arpeggiatorOctaves': 2.0,
        'arpeggiatorMode': 2.0,
        'arpeggiatorPattern': 1.0,
        'arpeggiatorSwing': 0.18,
        'arpeggiatorLatch': 0.0,
        'arpeggiatorTempoSync': 1.0,
        'arpeggiatorDivision':
            ArpeggiatorDivision.eighthTriplet.value.toDouble(),
        'transportTempo': 95.0,
        'transportRunning': 1.0,
        'transportTimeSignatureNumerator': 3.0,
        'transportTimeSignatureDenominator': 4.0,
      },
      modulationRoutes: const <ModulationRoute>[
        ModulationRoute(source: 'aftertouch', destination: 'lfoDepth', amount: 0.5),
        ModulationRoute(source: 'sustainPedal', destination: 'reverbMix', amount: 0.35),
      ],
    );

    _initialised = true;
  }

  /// Register a new preset. Passing [replaceExisting] allows overriding factory
  /// entries during development.
  void register({
    required SynthPresetMetadata metadata,
    required Map<String, double> parameters,
    Map<String, double>? modulation,
    List<ModulationRoute> modulationRoutes = const <ModulationRoute>[],
    bool replaceExisting = false,
  }) {
    if (!replaceExisting && _presets.containsKey(metadata.id)) {
      return;
    }

    _presets[metadata.id] = SynthPreset(
      metadata: metadata,
      parameters: _sanitiseParameterMap(parameters),
      modulation: modulation,
      modulationRoutes: modulationRoutes,
    );
  }

  /// Removes a preset if it exists. Factory presets are kept unless
  /// [force] is true.
  bool unregister(String id, {bool force = false}) {
    final existing = _presets[id];
    if (existing == null) {
      return false;
    }

    if (!force && existing.metadata.isFactory) {
      return false;
    }

    return _presets.remove(id) != null;
  }

  /// Look up a preset by its identifier.
  SynthPreset? findById(String id) {
    ensureBuiltInPresets();
    return _presets[id];
  }

  /// Return all presets sorted by creation time and name for deterministic UI.
  List<SynthPreset> allPresets() {
    ensureBuiltInPresets();
    final presets = _presets.values.toList()
      ..sort((a, b) {
        final createdComparison = a.metadata.createdAt.compareTo(b.metadata.createdAt);
        if (createdComparison != 0) {
          return createdComparison;
        }
        return a.metadata.name.compareTo(b.metadata.name);
      });
    return List<SynthPreset>.unmodifiable(presets);
  }

  /// Returns presets filtered by category.
  List<SynthPreset> presetsForCategory(SynthPresetCategory category) {
    ensureBuiltInPresets();
    return allPresets().where((preset) => preset.metadata.category == category).toList();
  }

  /// Replace or insert a preset wholesale.
  void upsertPreset(SynthPreset preset) {
    _presets[preset.metadata.id] = preset.copyWith(
      parameters: _sanitiseParameterMap(preset.parameters),
      modulationRoutes: preset.modulationRoutes,
    );
  }

  /// Export all presets to a JSON serialisable structure.
  List<Map<String, dynamic>> exportPresets() {
    ensureBuiltInPresets();
    return _presets.values.map((preset) => preset.toJson()).toList(growable: false);
  }

  Map<String, double> _sanitiseParameterMap(Map<String, double> parameters) {
    final registry = ParameterRegistry.instance;
    final canonical = registry.canonicalize(parameters);
    final expanded = registry.expandWithAliases(canonical);
    final sanitised = <String, double>{}..addAll(expanded);

    parameters.forEach((key, value) {
      if (registry.canonicalName(key) == null) {
        sanitised[key] = value;
      }
    });

    return sanitised;
  }
}
