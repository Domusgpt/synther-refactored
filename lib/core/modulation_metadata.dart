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

/// Describes a curated modulation route that can be suggested to users.
class ModulationRouteSuggestion {
  const ModulationRouteSuggestion({
    required this.id,
    required this.sourceId,
    required this.sourceLabel,
    required this.sourceCategory,
    required this.destinationId,
    required this.destinationLabel,
    required this.destinationCategory,
    required this.defaultAmount,
    this.description = '',
    this.tags = const <String>[],
  });

  /// Canonical source identifier for the suggestion.
  final String sourceId;

  /// Human readable label for the source descriptor.
  final String sourceLabel;

  /// Category associated with the source descriptor.
  final String sourceCategory;

  /// Canonical destination identifier for the suggestion.
  final String destinationId;

  /// Human readable label for the destination descriptor.
  final String destinationLabel;

  /// Category associated with the destination descriptor.
  final String destinationCategory;

  /// Recommended modulation amount for the suggestion.
  final double defaultAmount;

  /// Short rationale for why the route is useful.
  final String description;

  /// Labels describing the vibe or workflow context for the suggestion.
  final List<String> tags;

  /// Unique identifier that can be used for persistence and lookups.
  final String id;

  /// Convenience identifier that combines the source and destination ids.
  String get routeKey => '$sourceId->$destinationId';
}

/// Groups a curated set of suggestions into a themed workflow.
class ModulationSuggestionBundle {
  const ModulationSuggestionBundle({
    required this.id,
    required this.title,
    required this.description,
    this.focusTags = const <String>[],
    this.suggestionIds = const <String>[],
  });

  /// Canonical identifier for referencing the bundle.
  final String id;

  /// Human-friendly name describing the workflow focus.
  final String title;

  /// High level description of what the bundle unlocks.
  final String description;

  /// Tags that hint at the sonic territory the bundle explores.
  final List<String> focusTags;

  /// Ordered list of suggestion identifiers that make up the bundle.
  final List<String> suggestionIds;

  /// Number of concrete routes that will be applied when running the bundle.
  int get routeCount => suggestionIds.length;

  /// Returns true when the bundle does not contain any curated routes.
  bool get isEmpty => suggestionIds.isEmpty;
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

  /// Returns the distinct categories represented by [descriptors] in
  /// presentation order.
  static List<String> categoriesForSources([
    Iterable<ModulationSourceDescriptor>? descriptors,
  ]) {
    final iterable = descriptors ?? sourceDescriptors;
    final seen = <String>{};
    final categories = <String>[];
    for (final descriptor in iterable) {
      final category = descriptor.category;
      if (category.isEmpty) {
        continue;
      }
      if (seen.add(category)) {
        categories.add(category);
      }
    }
    return List<String>.unmodifiable(categories);
  }

  /// Returns the distinct destination categories surfaced by [descriptors] in
  /// curated order.
  static List<String> categoriesForDestinations([
    Iterable<ModulationDestinationDescriptor>? descriptors,
  ]) {
    final iterable = descriptors ?? destinationDescriptors;
    final seen = <String>{};
    final categories = <String>[];
    for (final descriptor in iterable) {
      final category = descriptor.category;
      if (category.isEmpty) {
        continue;
      }
      if (seen.add(category)) {
        categories.add(category);
      }
    }
    return List<String>.unmodifiable(categories);
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

  static const List<_RawModulationRouteSuggestion> _suggestedRouteSeeds =
      <_RawModulationRouteSuggestion>[
    _RawModulationRouteSuggestion(
      id: 'lfo1_filter_cutoff_classic',
      sourceId: 'lfo1',
      destinationId: 'filterCutoff',
      defaultAmount: 0.45,
      description: 'Classic filter sweeps driven by a slow LFO.',
      tags: <String>['Filter', 'Movement', 'Rhythmic'],
    ),
    _RawModulationRouteSuggestion(
      id: 'env2_lfo_depth_dynamics',
      sourceId: 'envelope2',
      destinationId: 'lfoDepth',
      defaultAmount: 0.6,
      description: 'Shape LFO intensity with an auxiliary envelope.',
      tags: <String>['Dynamic', 'Modulation'],
    ),
    _RawModulationRouteSuggestion(
      id: 'mod_wheel_wavetable_performance',
      sourceId: 'modWheel',
      destinationId: 'wavetablePosition',
      defaultAmount: 0.5,
      description: 'Manual sweeps across the wavetable for performance.',
      tags: <String>['Performance', 'Texture'],
    ),
    _RawModulationRouteSuggestion(
      id: 'random_oscillator_detune_drift',
      sourceId: 'random',
      destinationId: 'oscillatorDetune',
      defaultAmount: 0.25,
      description: 'Organic drift by subtly detuning oscillators.',
      tags: <String>['Analog', 'Texture', 'Variation'],
    ),
    _RawModulationRouteSuggestion(
      id: 'note_granular_pitch_track',
      sourceId: 'note',
      destinationId: 'granularPitch',
      defaultAmount: 0.35,
      description: 'Key tracking to keep granular pitch stable per note.',
      tags: <String>['Granular', 'Pitch Tracking'],
    ),
    _RawModulationRouteSuggestion(
      id: 'env1_filter_resonance_peaks',
      sourceId: 'envelope1',
      destinationId: 'filterResonance',
      defaultAmount: 0.4,
      description: 'Accentuate harmonic peaks with the main envelope.',
      tags: <String>['Dynamic', 'Filter'],
    ),
    _RawModulationRouteSuggestion(
      id: 'velocity_oscillator_blend_expressive',
      sourceId: 'velocity',
      destinationId: 'oscillatorBlend',
      defaultAmount: 0.3,
      description: 'Blend harmonics per note intensity for expressiveness.',
      tags: <String>['Expressive', 'Harmonics'],
    ),
    _RawModulationRouteSuggestion(
      id: 'expression_chorus_depth_swells',
      sourceId: 'expression',
      destinationId: 'chorusDepth',
      defaultAmount: 0.55,
      description: 'Foot pedal widens chorus depth during swells.',
      tags: <String>['Effects', 'Performance', 'Spatial'],
    ),
    _RawModulationRouteSuggestion(
      id: 'sustain_granular_active_trigger',
      sourceId: 'sustainPedal',
      destinationId: 'granularActive',
      defaultAmount: 1.0,
      description: 'Hold the sustain pedal to trigger granular textures.',
      tags: <String>['Granular', 'Performance', 'Trigger'],
    ),
    _RawModulationRouteSuggestion(
      id: 'env2_distortion_drive_bite',
      sourceId: 'envelope2',
      destinationId: 'distortionDrive',
      defaultAmount: 0.45,
      description: 'Add bite on envelope peaks by driving the distortion.',
      tags: <String>['Aggressive', 'Dynamic', 'Effects'],
    ),
    _RawModulationRouteSuggestion(
      id: 'lfo2_granular_position_orbit',
      sourceId: 'lfo2',
      destinationId: 'granularPosition',
      defaultAmount: 0.52,
      description: 'Slow orbital scans through the granular buffer.',
      tags: <String>['Granular', 'Movement', 'Texture'],
    ),
    _RawModulationRouteSuggestion(
      id: 'aftertouch_filter_cutoff_performance',
      sourceId: 'channelAftertouch',
      destinationId: 'filterCutoff',
      defaultAmount: 0.32,
      description: 'Press harder to bloom harmonic brightness on leads.',
      tags: <String>['Performance', 'Filter', 'Expressive'],
    ),
    _RawModulationRouteSuggestion(
      id: 'mod_wheel_filter_resonance_sculpt',
      sourceId: 'modWheel',
      destinationId: 'filterResonance',
      defaultAmount: 0.45,
      description: 'Ride filter resonance for acid sweeps with the wheel.',
      tags: <String>['Performance', 'Filter', 'Dynamic'],
    ),
    _RawModulationRouteSuggestion(
      id: 'random_reverb_mix_space',
      sourceId: 'random',
      destinationId: 'reverbMix',
      defaultAmount: 0.18,
      description: 'Organic space wash with subtle reverb randomisation.',
      tags: <String>['Effects', 'Space', 'Texture'],
    ),
    _RawModulationRouteSuggestion(
      id: 'expression_delay_feedback_echo',
      sourceId: 'expression',
      destinationId: 'delayFeedback',
      defaultAmount: 0.42,
      description: 'Swell delay trails with the expression pedal.',
      tags: <String>['Effects', 'Performance', 'Rhythmic'],
    ),
    _RawModulationRouteSuggestion(
      id: 'velocity_distortion_drive_grit',
      sourceId: 'velocity',
      destinationId: 'distortionDrive',
      defaultAmount: 0.35,
      description: 'Digging in hits the distortion harder for aggressive phrasing.',
      tags: <String>['Aggressive', 'Dynamic', 'Effects'],
    ),
    _RawModulationRouteSuggestion(
      id: 'note_filter_cutoff_tracking',
      sourceId: 'note',
      destinationId: 'filterCutoff',
      defaultAmount: 0.25,
      description: 'Keyboard tracking keeps filter brightness consistent.',
      tags: <String>['Filter', 'Key Tracking'],
    ),
    _RawModulationRouteSuggestion(
      id: 'sustain_reverb_mix_clouds',
      sourceId: 'sustainPedal',
      destinationId: 'reverbMix',
      defaultAmount: 0.6,
      description: 'Hold sustain to bloom ambient reverb swells.',
      tags: <String>['Effects', 'Performance', 'Ambient'],
    ),
    _RawModulationRouteSuggestion(
      id: 'env1_chorus_depth_motion',
      sourceId: 'envelope1',
      destinationId: 'chorusDepth',
      defaultAmount: 0.38,
      description: 'Dynamic chorus widening on each articulation.',
      tags: <String>['Effects', 'Dynamic', 'Spatial'],
    ),
    _RawModulationRouteSuggestion(
      id: 'lfo1_oscillator_spread_widen',
      sourceId: 'lfo1',
      destinationId: 'oscillatorSpread',
      defaultAmount: 0.48,
      description: 'Stereo width undulates with the main LFO.',
      tags: <String>['Oscillators', 'Movement', 'Spatial'],
    ),
    _RawModulationRouteSuggestion(
      id: 'aftertouch_oscillator_blend_morph',
      sourceId: 'channelAftertouch',
      destinationId: 'oscillatorBlend',
      defaultAmount: 0.28,
      description: 'Lean into the keybed to morph between oscillator layers.',
      tags: <String>['Performance', 'Oscillators', 'Expressive'],
    ),
    _RawModulationRouteSuggestion(
      id: 'expression_granular_grain_rate_shimmer',
      sourceId: 'expression',
      destinationId: 'granularGrainRate',
      defaultAmount: 0.5,
      description: 'Pedal-controlled grain density for evolving shimmer.',
      tags: <String>['Granular', 'Performance', 'Texture'],
    ),
    _RawModulationRouteSuggestion(
      id: 'mod_wheel_delay_time_swell',
      sourceId: 'modWheel',
      destinationId: 'delayTime',
      defaultAmount: 0.36,
      description: 'Gesture echo time sweeps for live build-ups.',
      tags: <String>['Effects', 'Performance', 'Rhythmic'],
    ),
    _RawModulationRouteSuggestion(
      id: 'random_wavetable_position_wander',
      sourceId: 'random',
      destinationId: 'wavetablePosition',
      defaultAmount: 0.2,
      description: 'Subtle random wavetable scanning for evolving timbre.',
      tags: <String>['Oscillators', 'Texture', 'Variation'],
    ),
    _RawModulationRouteSuggestion(
      id: 'velocity_chorus_depth_glow',
      sourceId: 'velocity',
      destinationId: 'chorusDepth',
      defaultAmount: 0.27,
      description: 'Harder playing widens the chorus halo.',
      tags: <String>['Effects', 'Expressive', 'Spatial'],
    ),
    _RawModulationRouteSuggestion(
      id: 'lfo2_delay_feedback_pulses',
      sourceId: 'lfo2',
      destinationId: 'delayFeedback',
      defaultAmount: 0.28,
      description: 'Tempo-synced echoes that breathe with LFO pulses.',
      tags: <String>['Effects', 'Rhythmic', 'Movement'],
    ),
    _RawModulationRouteSuggestion(
      id: 'velocity_reverb_mix_dynamics',
      sourceId: 'velocity',
      destinationId: 'reverbMix',
      defaultAmount: 0.32,
      description: 'Dig in to bloom lush reverb tails on expressive notes.',
      tags: <String>['Effects', 'Dynamic', 'Ambient'],
    ),
    _RawModulationRouteSuggestion(
      id: 'mod_wheel_master_volume_macro',
      sourceId: 'modWheel',
      destinationId: 'masterVolume',
      defaultAmount: 0.22,
      description: 'Use the wheel as a macro to lift entire patches.',
      tags: <String>['Performance', 'Output', 'Macro'],
    ),
    _RawModulationRouteSuggestion(
      id: 'expression_lfo_rate_lift',
      sourceId: 'expression',
      destinationId: 'lfoRate',
      defaultAmount: 0.4,
      description: 'Pedal-controlled LFO rate ramps for performance swells.',
      tags: <String>['Performance', 'Movement', 'Rhythmic'],
    ),
    _RawModulationRouteSuggestion(
      id: 'random_chorus_rate_glimmer',
      sourceId: 'random',
      destinationId: 'chorusRate',
      defaultAmount: 0.3,
      description: 'Micro-variations in chorus speed for shimmering pads.',
      tags: <String>['Effects', 'Texture', 'Movement'],
    ),
  ];

  static const List<ModulationSuggestionBundle> _suggestionBundles =
      <ModulationSuggestionBundle>[
    ModulationSuggestionBundle(
      id: 'performance_expressives',
      title: 'Performance Expressives',
      description: 'Leverage wheels, pedals, and pressure for live nuance.',
      focusTags: <String>['Performance', 'Expressive'],
      suggestionIds: <String>[
        'mod_wheel_wavetable_performance',
        'mod_wheel_filter_resonance_sculpt',
        'aftertouch_filter_cutoff_performance',
        'aftertouch_oscillator_blend_morph',
        'expression_chorus_depth_swells',
        'expression_delay_feedback_echo',
      ],
    ),
    ModulationSuggestionBundle(
      id: 'granular_motion_suite',
      title: 'Granular Motion Suite',
      description:
          'Curated modulation for animated granular pads and textures.',
      focusTags: <String>['Granular', 'Texture'],
      suggestionIds: <String>[
        'lfo2_granular_position_orbit',
        'expression_granular_grain_rate_shimmer',
        'sustain_granular_active_trigger',
        'note_granular_pitch_track',
        'random_wavetable_position_wander',
      ],
    ),
    ModulationSuggestionBundle(
      id: 'filter_motion_toolkit',
      title: 'Filter Motion Toolkit',
      description:
          'Blend LFOs, tracking, and performance gestures for lively filters.',
      focusTags: <String>['Filter', 'Movement'],
      suggestionIds: <String>[
        'lfo1_filter_cutoff_classic',
        'mod_wheel_filter_resonance_sculpt',
        'aftertouch_filter_cutoff_performance',
        'note_filter_cutoff_tracking',
        'env1_filter_resonance_peaks',
      ],
    ),
    ModulationSuggestionBundle(
      id: 'ambient_space_wash',
      title: 'Ambient Space Wash',
      description: 'Layer evolving ambience with time-based modulation plays.',
      focusTags: <String>['Ambient', 'Effects', 'Spatial'],
      suggestionIds: <String>[
        'random_reverb_mix_space',
        'sustain_reverb_mix_clouds',
        'mod_wheel_delay_time_swell',
        'velocity_chorus_depth_glow',
        'env1_chorus_depth_motion',
      ],
    ),
    ModulationSuggestionBundle(
      id: 'live_macro_lifters',
      title: 'Live Macro Lifters',
      description:
          'Wheel and pedal driven macros that lift entire performances.',
      focusTags: <String>['Performance', 'Macro'],
      suggestionIds: <String>[
        'mod_wheel_master_volume_macro',
        'mod_wheel_wavetable_performance',
        'expression_lfo_rate_lift',
        'expression_delay_feedback_echo',
      ],
    ),
    ModulationSuggestionBundle(
      id: 'ambient_motion_enhancers',
      title: 'Ambient Motion Enhancers',
      description:
          'Reverb, chorus, and delay moves that keep atmospheres evolving.',
      focusTags: <String>['Ambient', 'Effects', 'Movement'],
      suggestionIds: <String>[
        'velocity_reverb_mix_dynamics',
        'random_chorus_rate_glimmer',
        'lfo2_delay_feedback_pulses',
        'sustain_reverb_mix_clouds',
      ],
    ),
  ];

  /// Returns curated modulation suggestions filtered by category, tags or query.
  static List<ModulationRouteSuggestion> suggestedRoutes({
    String? sourceCategory,
    String? destinationCategory,
    Iterable<String>? requiredTags,
    String? query,
  }) {
    final suggestions = <ModulationRouteSuggestion>[];
    final activeTags = requiredTags
        ?.where((tag) => tag.trim().isNotEmpty)
        .map((tag) => tag.trim().toLowerCase())
        .toSet();
    final tokens = query == null || query.trim().isEmpty
        ? const <String>[]
        : _tokeniseQuery(query);

    for (final raw in _suggestedRouteSeeds) {
      final suggestion = _buildSuggestionFromSeed(raw);
      if (suggestion == null) {
        continue;
      }

      if (sourceCategory != null &&
          suggestion.sourceCategory != sourceCategory) {
        continue;
      }

      if (destinationCategory != null &&
          suggestion.destinationCategory != destinationCategory) {
        continue;
      }

      if (activeTags != null && activeTags.isNotEmpty) {
        final lowercased = suggestion.tags
            .map((tag) => tag.toLowerCase())
            .toSet(growable: false);
        final matchesAllTags = activeTags.every(lowercased.contains);
        if (!matchesAllTags) {
          continue;
        }
      }

      suggestions.add(suggestion);
    }

    if (tokens.isEmpty) {
      return List<ModulationRouteSuggestion>.unmodifiable(suggestions);
    }

    final filtered = suggestions.where((suggestion) {
      final haystacks = <String>{
        suggestion.sourceId,
        suggestion.sourceLabel,
        suggestion.sourceCategory,
        suggestion.destinationId,
        suggestion.destinationLabel,
        suggestion.destinationCategory,
        suggestion.description,
        ...suggestion.tags,
      }.map((value) => value.toLowerCase()).toList(growable: false);

      return _tokensMatch(tokens, haystacks);
    }).toList(growable: false);

    return List<ModulationRouteSuggestion>.unmodifiable(filtered);
  }

  /// Returns the curated list of suggestion tags sorted alphabetically.
  static List<String> suggestionTags() {
    final tags = <String>{};
    for (final raw in _suggestedRouteSeeds) {
      tags.addAll(raw.tags);
    }

    final sorted = tags.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List<String>.unmodifiable(sorted);
  }

  /// Returns the curated suggestion for [id] if one exists.
  static ModulationRouteSuggestion? suggestionById(String id) {
    final raw = _seedForId(id);
    if (raw == null) {
      return null;
    }
    return _buildSuggestionFromSeed(raw);
  }

  /// Resolves the ordered list of suggestions matching [ids].
  static List<ModulationRouteSuggestion> suggestionsForIds(
    Iterable<String> ids,
  ) {
    final results = <ModulationRouteSuggestion>[];
    for (final id in ids) {
      final suggestion = suggestionById(id);
      if (suggestion != null) {
        results.add(suggestion);
      }
    }
    return List<ModulationRouteSuggestion>.unmodifiable(results);
  }

  /// Returns the curated bundle catalogue in presentation order.
  static List<ModulationSuggestionBundle> suggestionBundles() =>
      List<ModulationSuggestionBundle>.unmodifiable(_suggestionBundles);

  /// Returns the suggestions associated with the bundle [bundleId].
  static List<ModulationRouteSuggestion> routesForBundle(String bundleId) {
    for (final bundle in _suggestionBundles) {
      if (bundle.id == bundleId) {
        return suggestionsForIds(bundle.suggestionIds);
      }
    }
    return const <ModulationRouteSuggestion>[];
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

  static ModulationRouteSuggestion? _buildSuggestionFromSeed(
    _RawModulationRouteSuggestion raw,
  ) {
    final source = descriptorForSource(raw.sourceId);
    final destination = descriptorForDestination(raw.destinationId);
    if (source == null || destination == null) {
      return null;
    }

    return ModulationRouteSuggestion(
      id: raw.id,
      sourceId: source.id,
      sourceLabel: source.label,
      sourceCategory: source.category,
      destinationId: destination.id,
      destinationLabel: destination.label,
      destinationCategory: destination.category,
      defaultAmount: raw.defaultAmount,
      description: raw.description,
      tags: raw.tags,
    );
  }

  static _RawModulationRouteSuggestion? _seedForId(String id) {
    for (final raw in _suggestedRouteSeeds) {
      if (raw.id == id) {
        return raw;
      }
    }
    return null;
  }
}

class _RawModulationRouteSuggestion {
  const _RawModulationRouteSuggestion({
    required this.id,
    required this.sourceId,
    required this.destinationId,
    this.defaultAmount = 0.5,
    this.description = '',
    this.tags = const <String>[],
  });

  final String id;
  final String sourceId;
  final String destinationId;
  final double defaultAmount;
  final String description;
  final List<String> tags;
}
