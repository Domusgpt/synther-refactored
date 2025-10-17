import 'parameter_registry.dart';

/// Curated metadata describing which modulation routes the UI should expose.
class ModulationRoutingMetadata {
  ModulationRoutingMetadata._();

  /// Preferred modulation sources presented to users.
  static const List<String> _preferredSources = <String>[
    'lfo1',
    'lfo2',
    'modWheel',
    'channelAftertouch',
    'expression',
    'sustainPedal',
    'velocity',
    'note',
    'random',
    'envelope1',
    'envelope2',
  ];

  /// Preferred modulation destinations that are guaranteed to exist.
  static const List<String> _preferredDestinations = <String>[
    'filterCutoff',
    'filterResonance',
    'lfoDepth',
    'lfoRate',
    'oscillatorBlend',
    'oscillatorDetune',
    'oscillatorSpread',
    'chorusDepth',
    'chorusRate',
    'distortionDrive',
    'wavetablePosition',
    'granularActive',
    'granularGrainRate',
    'granularGrainDuration',
    'granularPosition',
    'granularPitch',
    'reverbMix',
    'delayTime',
    'delayFeedback',
    'masterVolume',
  ];

  /// Exposes a read-only list of modulation sources in display order.
  static List<String> get availableSources =>
      List<String>.unmodifiable(_preferredSources);

  /// Returns canonical destination parameter names recognised by the registry.
  static List<String> get availableDestinations {
    final registry = ParameterRegistry.instance;
    final seen = <String>{};
    final resolved = <String>[];
    for (final candidate in _preferredDestinations) {
      final canonical = registry.canonicalName(candidate) ?? candidate;
      final descriptor = registry.descriptorFor(canonical);
      if (descriptor == null) {
        continue;
      }
      if (seen.add(descriptor.name)) {
        resolved.add(descriptor.name);
      }
    }
    return List<String>.unmodifiable(resolved);
  }
}
