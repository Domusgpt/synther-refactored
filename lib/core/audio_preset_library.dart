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

      register(metadata: metadata, parameters: parameters, replaceExisting: true);
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
      },
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
      },
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
      },
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
      },
    );

    _initialised = true;
  }

  /// Register a new preset. Passing [replaceExisting] allows overriding factory
  /// entries during development.
  void register({
    required SynthPresetMetadata metadata,
    required Map<String, double> parameters,
    Map<String, double>? modulation,
    bool replaceExisting = false,
  }) {
    if (!replaceExisting && _presets.containsKey(metadata.id)) {
      return;
    }

    _presets[metadata.id] = SynthPreset(
      metadata: metadata,
      parameters: parameters,
      modulation: modulation,
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
    _presets[preset.metadata.id] = preset;
  }

  /// Export all presets to a JSON serialisable structure.
  List<Map<String, dynamic>> exportPresets() {
    ensureBuiltInPresets();
    return _presets.values.map((preset) => preset.toJson()).toList(growable: false);
  }
}
