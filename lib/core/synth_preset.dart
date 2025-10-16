import 'dart:collection';

/// Categories used to organise synthesiser presets.
enum SynthPresetCategory {
  factory,
  performance,
  ambient,
  bass,
  keys,
  experimental,
  user,
}

/// Metadata describing a preset that can be saved, shared or recalled.
class SynthPresetMetadata {
  SynthPresetMetadata({
    required this.id,
    required this.name,
    this.description = '',
    this.author,
    this.category = SynthPresetCategory.user,
    DateTime? createdAt,
    List<String>? tags,
    this.isFactory = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = UnmodifiableListView(List<String>.from(tags ?? const <String>[]));

  /// Stable identifier used to address the preset in registries or storage.
  final String id;

  /// Human readable preset name displayed in the UI.
  final String name;

  /// Optional description giving more context about the sound or usage.
  final String description;

  /// Optional author credit.
  final String? author;

  /// Category used for filtering and browsing.
  final SynthPresetCategory category;

  /// Timestamp recorded when the preset was created.
  final DateTime createdAt;

  /// Free-form tags to help search or sort presets.
  final UnmodifiableListView<String> tags;

  /// Indicates whether the preset ships with the application.
  final bool isFactory;

  SynthPresetMetadata copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    SynthPresetCategory? category,
    DateTime? createdAt,
    List<String>? tags,
    bool? isFactory,
  }) {
    return SynthPresetMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isFactory: isFactory ?? this.isFactory,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags.toList(),
      'isFactory': isFactory,
    };
  }

  factory SynthPresetMetadata.fromJson(Map<String, dynamic> json) {
    return SynthPresetMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String?,
      category: SynthPresetCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => SynthPresetCategory.user,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      isFactory: json['isFactory'] as bool? ?? false,
    );
  }
}

/// Immutable snapshot of synthesiser parameter values.
class SynthPreset {
  SynthPreset({
    required SynthPresetMetadata metadata,
    required Map<String, double> parameters,
    Map<String, double>? modulation,
  })  : metadata = metadata,
        parameters = UnmodifiableMapView(Map<String, double>.from(parameters)),
        modulation = modulation == null
            ? const UnmodifiableMapView(<String, double>{})
            : UnmodifiableMapView(Map<String, double>.from(modulation));

  /// Metadata that describes the preset.
  final SynthPresetMetadata metadata;

  /// Canonical parameter values stored by parameter name.
  final UnmodifiableMapView<String, double> parameters;

  /// Optional modulation depths or auxiliary parameters stored alongside.
  final UnmodifiableMapView<String, double> modulation;

  /// Create a mutable copy of the preset with overridden values.
  SynthPreset copyWith({
    SynthPresetMetadata? metadata,
    Map<String, double>? parameters,
    Map<String, double>? modulation,
  }) {
    return SynthPreset(
      metadata: metadata ?? this.metadata,
      parameters: parameters ?? this.parameters,
      modulation: modulation ?? this.modulation,
    );
  }

  /// Merge another preset into this one, overriding parameter values when they
  /// exist in [other].
  SynthPreset merge(SynthPreset other) {
    final mergedParameters = Map<String, double>.from(parameters);
    mergedParameters.addAll(other.parameters);

    final mergedModulation = Map<String, double>.from(modulation);
    mergedModulation.addAll(other.modulation);

    return SynthPreset(
      metadata: other.metadata,
      parameters: mergedParameters,
      modulation: mergedModulation,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metadata': metadata.toJson(),
      'parameters': parameters,
      'modulation': modulation,
    };
  }

  factory SynthPreset.fromJson(Map<String, dynamic> json) {
    final metadata = SynthPresetMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
    final parameters = (json['parameters'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    final modulationRaw = json['modulation'] as Map<String, dynamic>?;
    final modulation = modulationRaw == null
        ? <String, double>{}
        : modulationRaw.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return SynthPreset(
      metadata: metadata,
      parameters: parameters,
      modulation: modulation,
    );
  }
}

/// Convenience helper that builds metadata for an ad-hoc preset capture.
SynthPresetMetadata buildCapturedPresetMetadata({
  String? id,
  String? name,
  String? description,
  SynthPresetCategory category = SynthPresetCategory.user,
}) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return SynthPresetMetadata(
    id: id ?? 'captured-$timestamp',
    name: name ?? 'Captured Preset',
    description: description ?? 'Snapshot captured at $timestamp',
    category: category,
    createdAt: DateTime.now(),
    isFactory: false,
  );
}
