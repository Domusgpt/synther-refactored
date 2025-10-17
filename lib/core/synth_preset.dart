import 'dart:collection';

import 'modulation_matrix.dart';
import 'macro_controls.dart';

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
    List<ModulationRoute>? modulationRoutes,
    List<MacroSnapshot>? macros,
  })  : metadata = metadata,
        parameters = UnmodifiableMapView(Map<String, double>.from(parameters)),
        modulation = modulation == null
            ? const UnmodifiableMapView(<String, double>{})
            : UnmodifiableMapView(Map<String, double>.from(modulation)),
        modulationRoutes = UnmodifiableListView(
          List<ModulationRoute>.from(modulationRoutes ?? const <ModulationRoute>[]),
        ),
        macros = UnmodifiableListView(
          List<MacroSnapshot>.from(macros ?? const <MacroSnapshot>[]),
        );

  /// Metadata that describes the preset.
  final SynthPresetMetadata metadata;

  /// Canonical parameter values stored by parameter name.
  final UnmodifiableMapView<String, double> parameters;

  /// Optional modulation depths or auxiliary parameters stored alongside.
  final UnmodifiableMapView<String, double> modulation;

  /// Optional modulation matrix routes stored with the preset.
  final UnmodifiableListView<ModulationRoute> modulationRoutes;

  /// Optional macro program captured with the preset.
  final UnmodifiableListView<MacroSnapshot> macros;

  /// Create a mutable copy of the preset with overridden values.
  SynthPreset copyWith({
    SynthPresetMetadata? metadata,
    Map<String, double>? parameters,
    Map<String, double>? modulation,
    List<ModulationRoute>? modulationRoutes,
    List<MacroSnapshot>? macros,
  }) {
    return SynthPreset(
      metadata: metadata ?? this.metadata,
      parameters: parameters ?? this.parameters,
      modulation: modulation ?? this.modulation,
      modulationRoutes: modulationRoutes ?? this.modulationRoutes,
      macros: macros ?? this.macros,
    );
  }

  /// Merge another preset into this one, overriding parameter values when they
  /// exist in [other].
  SynthPreset merge(SynthPreset other) {
    final mergedParameters = Map<String, double>.from(parameters);
    mergedParameters.addAll(other.parameters);

    final mergedModulation = Map<String, double>.from(modulation);
    mergedModulation.addAll(other.modulation);

    final mergedRoutes = <String, ModulationRoute>{
      for (final route in modulationRoutes) route.key: route,
    };
    for (final route in other.modulationRoutes) {
      mergedRoutes[route.key] = route;
    }

    final mergedMacros = <String, MacroSnapshot>{
      for (final macro in macros) macro.definition.id: macro,
    };
    for (final macro in other.macros) {
      mergedMacros[macro.definition.id] = macro;
    }

    return SynthPreset(
      metadata: other.metadata,
      parameters: mergedParameters,
      modulation: mergedModulation,
      modulationRoutes: mergedRoutes.values.toList(),
      macros: mergedMacros.values.toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metadata': metadata.toJson(),
      'parameters': parameters,
      'modulation': modulation,
      'modulationRoutes': modulationRoutes.map((route) => route.toJson()).toList(),
      'macros': macros.map((macro) => macro.toJson()).toList(),
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

    final routesRaw = json['modulationRoutes'] as List<dynamic>?;
    final routes = routesRaw == null
        ? const <ModulationRoute>[]
        : routesRaw
            .whereType<Map<String, dynamic>>()
            .map(ModulationRoute.fromJson)
            .toList();

    final macrosRaw = json['macros'] as List<dynamic>?;
    final macros = macrosRaw == null
        ? const <MacroSnapshot>[]
        : macrosRaw
            .whereType<Map<String, dynamic>>()
            .map(MacroSnapshot.fromJson)
            .toList();

    return SynthPreset(
      metadata: metadata,
      parameters: parameters,
      modulation: modulation,
      modulationRoutes: routes,
      macros: macros,
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
