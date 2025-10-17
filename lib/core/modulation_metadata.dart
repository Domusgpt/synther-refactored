import 'parameter_registry.dart';

/// Describes a modulation source that can be routed within the matrix.
class ModulationSourceDescriptor {
  const ModulationSourceDescriptor({
    required this.id,
    required this.label,
    required this.category,
    this.description = '',
    this.aliases = const <String>[],
  });

  /// Canonical identifier used by the audio engine.
  final String id;

  /// Human readable label shown in the UI.
  final String label;

  /// Grouping used to hint at the origin of the modulation signal.
  final String category;

  /// Short blurb describing how the source behaves.
  final String description;

  /// Additional identifiers that map to this descriptor.
  final List<String> aliases;

  /// Returns true when the descriptor matches the provided identifier.
  bool matches(String other) {
    if (other == id) {
      return true;
    }
    return aliases.contains(other);
  }
}

/// Describes a modulation destination exposed to users.
class ModulationDestinationDescriptor {
  const ModulationDestinationDescriptor({
    required this.id,
    required this.label,
    required this.category,
    this.description = '',
  });

  /// Canonical parameter name recognised by the registry.
  final String id;

  /// Human readable label shown in the UI.
  final String label;

  /// Grouping used to hint at the type of parameter.
  final String category;

  /// Short blurb describing how the parameter reacts to modulation.
  final String description;
}

/// Curated metadata describing which modulation routes the UI should expose.
class ModulationRoutingMetadata {
  ModulationRoutingMetadata._();

  static const List<ModulationSourceDescriptor> _sourceDescriptors =
      <ModulationSourceDescriptor>[
    ModulationSourceDescriptor(
      id: 'lfo1',
      label: 'LFO 1',
      category: 'Modulators',
      description: 'Primary low-frequency oscillator for cyclical sweeps.',
    ),
    ModulationSourceDescriptor(
      id: 'lfo2',
      label: 'LFO 2',
      category: 'Modulators',
      description: 'Secondary LFO for layered motion or cross modulation.',
    ),
    ModulationSourceDescriptor(
      id: 'modWheel',
      label: 'Mod Wheel',
      category: 'Performance',
      description: 'MIDI CC 1 – expressive controller on most keyboards.',
      aliases: <String>['modulationWheel'],
    ),
    ModulationSourceDescriptor(
      id: 'channelAftertouch',
      label: 'Channel Aftertouch',
      category: 'Performance',
      description: 'Average pressure across the keyboard for dynamic control.',
      aliases: <String>['aftertouch', 'channelPressure', 'pressure'],
    ),
    ModulationSourceDescriptor(
      id: 'expression',
      label: 'Expression Pedal',
      category: 'Performance',
      description: 'MIDI CC 11 – foot controller for swells and dynamics.',
    ),
    ModulationSourceDescriptor(
      id: 'sustainPedal',
      label: 'Sustain Pedal',
      category: 'Performance',
      description: 'MIDI CC 64 – sustain hold useful for macro triggers.',
      aliases: <String>['sustain'],
    ),
    ModulationSourceDescriptor(
      id: 'velocity',
      label: 'Velocity',
      category: 'Key Tracking',
      description: 'Per-note strike intensity captured at note on.',
    ),
    ModulationSourceDescriptor(
      id: 'note',
      label: 'Note Pitch',
      category: 'Key Tracking',
      description: 'Tracks the played pitch for keyboard tracking effects.',
      aliases: <String>['notePitch', 'keytracking'],
    ),
    ModulationSourceDescriptor(
      id: 'random',
      label: 'Random',
      category: 'Utility',
      description: 'Sample-and-hold random value per voice for organic drift.',
      aliases: <String>['sampleHold', 'sampleAndHold'],
    ),
    ModulationSourceDescriptor(
      id: 'envelope1',
      label: 'Envelope 1',
      category: 'Envelopes',
      description: 'Primary envelope output (amp).',
      aliases: <String>['env1'],
    ),
    ModulationSourceDescriptor(
      id: 'envelope2',
      label: 'Envelope 2',
      category: 'Envelopes',
      description: 'Secondary envelope output (auxiliary/mod).',
      aliases: <String>['env2'],
    ),
  ];

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

  static const Map<String, String> _destinationDescriptions =
      <String, String>{
    'filterCutoff':
        'Sweeps the main filter frequency for tonal brightness moves.',
    'filterResonance':
        'Boosts frequencies around the cutoff for sharper peaks.',
    'lfoDepth': 'Amount of modulation depth applied by the global LFO.',
    'lfoRate': 'Controls the speed of the global LFO for rhythmic effects.',
    'oscillatorBlend':
        'Balances oscillator layers for shifting harmonic focus.',
    'oscillatorDetune':
        'Spreads oscillator tuning for chorusing and movement.',
    'oscillatorSpread':
        'Adjusts unison stereo width for spacious textures.',
    'chorusDepth': 'Chorus modulation depth for shimmering pads.',
    'chorusRate': 'Chorus modulation speed for lush or rapid motion.',
    'distortionDrive': 'Amount of drive entering the distortion stage.',
    'wavetablePosition':
        'Sweeps the wavetable index for evolving timbres.',
    'granularActive': 'Enables or disables granular processing per voice.',
    'granularGrainRate': 'How frequently new grains are spawned.',
    'granularGrainDuration': 'Length of each grain for texture smoothing.',
    'granularPosition': 'Playback position within the granular buffer.',
    'granularPitch': 'Pitch shift applied to granular playback.',
    'reverbMix': 'Wet/dry mix for the ambient reverb.',
    'delayTime': 'Delay time used by the echo unit.',
    'delayFeedback': 'Amount of signal fed back into the delay.',
    'masterVolume': 'Overall output level after processing.',
  };

  static const Map<String, String> _destinationCategories =
      <String, String>{
    'filterCutoff': 'Filter',
    'filterResonance': 'Filter',
    'lfoDepth': 'Modulation',
    'lfoRate': 'Modulation',
    'oscillatorBlend': 'Oscillators',
    'oscillatorDetune': 'Oscillators',
    'oscillatorSpread': 'Oscillators',
    'chorusDepth': 'Effects',
    'chorusRate': 'Effects',
    'distortionDrive': 'Effects',
    'wavetablePosition': 'Oscillators',
    'granularActive': 'Granular',
    'granularGrainRate': 'Granular',
    'granularGrainDuration': 'Granular',
    'granularPosition': 'Granular',
    'granularPitch': 'Granular',
    'reverbMix': 'Effects',
    'delayTime': 'Effects',
    'delayFeedback': 'Effects',
    'masterVolume': 'Output',
  };

  static List<ModulationSourceDescriptor> get sourceDescriptors =>
      List<ModulationSourceDescriptor>.unmodifiable(_sourceDescriptors);

  static List<ModulationDestinationDescriptor>? _cachedDestinations;

  static List<ModulationDestinationDescriptor> get destinationDescriptors {
    _cachedDestinations ??= _buildDestinationDescriptors();
    return List<ModulationDestinationDescriptor>.unmodifiable(
      _cachedDestinations!,
    );
  }

  static List<String> get availableSources =>
      _sourceDescriptors.map((descriptor) => descriptor.id).toList(growable: false);

  static List<String> get availableDestinations => destinationDescriptors
      .map((descriptor) => descriptor.id)
      .toList(growable: false);

  static ModulationSourceDescriptor? descriptorForSource(String id) {
    final normalised = id.trim();
    for (final descriptor in _sourceDescriptors) {
      if (descriptor.matches(normalised)) {
        return descriptor;
      }
    }
    return null;
  }

  static ModulationDestinationDescriptor? descriptorForDestination(String id) {
    final registry = ParameterRegistry.instance;
    final canonical = registry.canonicalName(id) ?? id;
    for (final descriptor in destinationDescriptors) {
      if (descriptor.id == canonical) {
        return descriptor;
      }
    }
    final registryDescriptor = registry.descriptorFor(canonical);
    if (registryDescriptor == null) {
      return null;
    }
    return ModulationDestinationDescriptor(
      id: registryDescriptor.name,
      label: humanizeKey(registryDescriptor.name),
      category: _destinationCategories[registryDescriptor.name] ?? 'General',
      description: _destinationDescriptions[registryDescriptor.name] ?? '',
    );
  }

  static String labelForSource(String id) =>
      descriptorForSource(id)?.label ?? humanizeKey(id);

  static String descriptionForSource(String id) =>
      descriptorForSource(id)?.description ?? '';

  static String labelForDestination(String id) =>
      descriptorForDestination(id)?.label ?? humanizeKey(id);

  static String descriptionForDestination(String id) =>
      descriptorForDestination(id)?.description ?? '';

  /// Returns sources whose metadata matches the provided [query].
  ///
  /// Matching is case-insensitive and token based – every token in the query
  /// must be present within any field (id, label, category, description or
  /// alias) for a descriptor to be included in the results.
  static List<ModulationSourceDescriptor> searchSources(String query) {
    final tokens = _tokeniseQuery(query);
    if (tokens.isEmpty) {
      return sourceDescriptors;
    }

    return _sourceDescriptors
        .where((descriptor) => _matchesSource(descriptor, tokens))
        .toList(growable: false);
  }

  /// Returns curated destination descriptors that match the [query].
  ///
  /// The search spans canonical ids, labels, descriptions, categories and any
  /// aliases registered in the [ParameterRegistry].
  static List<ModulationDestinationDescriptor> searchDestinations(
    String query,
  ) {
    final tokens = _tokeniseQuery(query);
    if (tokens.isEmpty) {
      return destinationDescriptors;
    }

    final registry = ParameterRegistry.instance;
    return destinationDescriptors
        .where(
          (descriptor) =>
              _matchesDestination(descriptor, tokens, registry),
        )
        .toList(growable: false);
  }

  /// Formats a raw key into a title cased human readable label.
  static String humanizeKey(String raw) {
    if (raw.isEmpty) {
      return raw;
    }

    final buffer = StringBuffer();
    final cleaned = raw
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])(\d)'),
          (match) => '${match[1]} ${match[2]}',
        );

    final parts = cleaned.split(RegExp(r'\s+'));
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(part[0].toUpperCase());
      if (part.length > 1) {
        buffer.write(part.substring(1).toLowerCase());
      }
    }

    return buffer.toString();
  }

  static List<ModulationDestinationDescriptor> _buildDestinationDescriptors() {
    final registry = ParameterRegistry.instance;
    final seen = <String>{};
    final resolved = <ModulationDestinationDescriptor>[];

    for (final candidate in _preferredDestinations) {
      final canonical = registry.canonicalName(candidate) ?? candidate;
      final descriptor = registry.descriptorFor(canonical);
      if (descriptor == null) {
        continue;
      }
      if (!seen.add(descriptor.name)) {
        continue;
      }
      resolved.add(
        ModulationDestinationDescriptor(
          id: descriptor.name,
          label: humanizeKey(descriptor.name),
          category: _destinationCategories[descriptor.name] ?? 'General',
          description: _destinationDescriptions[descriptor.name] ?? '',
        ),
      );
    }

    return resolved;
  }

  static bool _matchesSource(
    ModulationSourceDescriptor descriptor,
    List<String> tokens,
  ) {
    final haystacks = <String>{
      descriptor.id,
      descriptor.label,
      descriptor.category,
      descriptor.description,
      ...descriptor.aliases,
    }.map((value) => value.toLowerCase()).toList(growable: false);

    return _tokensMatch(tokens, haystacks);
  }

  static bool _matchesDestination(
    ModulationDestinationDescriptor descriptor,
    List<String> tokens,
    ParameterRegistry registry,
  ) {
    final haystacks = <String>{
      descriptor.id,
      descriptor.label,
      descriptor.category,
      descriptor.description,
    };

    final registryDescriptor = registry.descriptorFor(descriptor.id);
    if (registryDescriptor != null) {
      haystacks.addAll(registryDescriptor.allKeys);
    }

    final lowercased = haystacks
        .map((value) => value.toLowerCase())
        .toList(growable: false);

    return _tokensMatch(tokens, lowercased);
  }

  static bool _tokensMatch(List<String> tokens, List<String> haystacks) {
    if (tokens.isEmpty) {
      return true;
    }

    for (final token in tokens) {
      final matchesToken = haystacks.any((value) => value.contains(token));
      if (!matchesToken) {
        return false;
      }
    }
    return true;
  }

  static List<String> _tokeniseQuery(String query) {
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }
}
