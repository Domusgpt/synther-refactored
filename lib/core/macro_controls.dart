import 'dart:collection';

import 'parameter_registry.dart';

/// Describes a single parameter mapping that should respond to a macro value.
class MacroAssignment {
  MacroAssignment({
    required this.parameterId,
    double minNormalized = 0.0,
    double maxNormalized = 1.0,
  })  : minNormalized = minNormalized.clamp(0.0, 1.0),
        maxNormalized = maxNormalized.clamp(0.0, 1.0);

  /// Canonical parameter identifier targeted by the assignment.
  final String parameterId;

  /// Minimum normalized value applied when the macro is at 0.
  final double minNormalized;

  /// Maximum normalized value applied when the macro is at 1.
  final double maxNormalized;

  /// Calculates the concrete parameter value for [macroValue].
  double resolve(ParameterRegistry registry, double macroValue) {
    final descriptor = registry.descriptorFor(parameterId);
    if (descriptor == null) {
      return macroValue;
    }

    final normalized = _lerp(minNormalized, maxNormalized, macroValue);
    return descriptor.range.denormalize(normalized);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parameterId': parameterId,
      'min': minNormalized,
      'max': maxNormalized,
    };
  }

  factory MacroAssignment.fromJson(Map<String, dynamic> json) {
    return MacroAssignment(
      parameterId: json['parameterId'] as String,
      minNormalized: (json['min'] as num?)?.toDouble() ?? 0.0,
      maxNormalized: (json['max'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static double _lerp(double a, double b, double t) {
    final clampedT = t.clamp(0.0, 1.0).toDouble();
    return a + (b - a) * clampedT;
  }
}

/// Defines a macro control surface containing one or more assignments.
class MacroDefinition {
  MacroDefinition({
    required this.id,
    required this.name,
    this.description = '',
    List<MacroAssignment> assignments = const <MacroAssignment>[],
    double defaultValue = 0.0,
  })  : assignments = UnmodifiableListView(
            List<MacroAssignment>.from(assignments),
          ),
        defaultValue = defaultValue.clamp(0.0, 1.0);

  /// Stable identifier for the macro.
  final String id;

  /// Human readable name for UI surfaces.
  final String name;

  /// Optional description shown in tooltips or docs.
  final String description;

  /// Macro targets that should respond when the macro value changes.
  final UnmodifiableListView<MacroAssignment> assignments;

  /// Default macro position used for preset capture or resets.
  final double defaultValue;

  /// Clamp [value] to the macro range.
  double clamp(double value) => value.clamp(0.0, 1.0).toDouble();

  /// Resolves [value] into concrete parameter updates.
  Map<String, double> resolve(ParameterRegistry registry, double value) {
    if (assignments.isEmpty) {
      return const <String, double>{};
    }

    final updates = <String, double>{};
    final clamped = clamp(value);
    for (final assignment in assignments) {
      updates[assignment.parameterId] =
          assignment.resolve(registry, clamped);
    }
    return updates;
  }

  MacroDefinition copyWith({
    String? id,
    String? name,
    String? description,
    List<MacroAssignment>? assignments,
    double? defaultValue,
  }) {
    return MacroDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      assignments: assignments ?? this.assignments,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'defaultValue': defaultValue,
      'assignments': assignments.map((assignment) => assignment.toJson()).toList(),
    };
  }

  factory MacroDefinition.fromJson(Map<String, dynamic> json) {
    final assignmentsRaw = json['assignments'] as List<dynamic>?;
    return MacroDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      defaultValue: (json['defaultValue'] as num?)?.toDouble() ?? 0.0,
      assignments: assignmentsRaw == null
          ? const <MacroAssignment>[]
          : assignmentsRaw
              .whereType<Map<String, dynamic>>()
              .map(MacroAssignment.fromJson)
              .toList(),
    );
  }
}

/// Snapshot containing both the macro definition and its active value.
class MacroSnapshot {
  const MacroSnapshot({
    required this.definition,
    required this.value,
  });

  final MacroDefinition definition;
  final double value;

  MacroSnapshot copyWith({
    MacroDefinition? definition,
    double? value,
  }) {
    return MacroSnapshot(
      definition: definition ?? this.definition,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'definition': definition.toJson(),
      'value': value,
    };
  }

  factory MacroSnapshot.fromJson(Map<String, dynamic> json) {
    return MacroSnapshot(
      definition: MacroDefinition.fromJson(
        json['definition'] as Map<String, dynamic>,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Runtime manager that tracks macro definitions and resolves parameter updates.
class MacroController {
  MacroController({ParameterRegistry? parameterRegistry})
      : _parameterRegistry = parameterRegistry ?? ParameterRegistry.instance;

  final ParameterRegistry _parameterRegistry;
  final LinkedHashMap<String, MacroDefinition> _definitions =
      LinkedHashMap<String, MacroDefinition>();
  final Map<String, double> _values = <String, double>{};

  UnmodifiableListView<MacroDefinition> get definitions =>
      UnmodifiableListView(_definitions.values.toList());

  bool get isEmpty => _definitions.isEmpty;

  bool contains(String id) => _definitions.containsKey(id);

  double valueFor(String id) {
    final definition = _definitions[id];
    if (definition == null) {
      return 0.0;
    }
    return _values[id] ?? definition.defaultValue;
  }

  /// Registers [definition], optionally overriding an existing macro.
  bool register(MacroDefinition definition, {bool overwrite = true}) {
    if (!overwrite && _definitions.containsKey(definition.id)) {
      return false;
    }

    _definitions[definition.id] = definition;
    _values.putIfAbsent(definition.id, () => definition.defaultValue);
    return true;
  }

  /// Registers multiple macros.
  bool registerAll(Iterable<MacroDefinition> macros, {bool overwrite = true}) {
    var changed = false;
    for (final macro in macros) {
      changed = register(macro, overwrite: overwrite) || changed;
    }
    return changed;
  }

  /// Applies [value] to the macro, returning resolved parameter updates.
  Map<String, double> setValue(String id, double value) {
    final definition = _definitions[id];
    if (definition == null) {
      return const <String, double>{};
    }

    final clamped = definition.clamp(value);
    _values[id] = clamped;
    return definition.resolve(_parameterRegistry, clamped);
  }

  /// Reset all macros and load [snapshots], returning the resolved updates.
  Map<String, double> replaceWithSnapshots(List<MacroSnapshot> snapshots) {
    clear();
    if (snapshots.isEmpty) {
      return const <String, double>{};
    }

    final updates = <String, double>{};
    for (final snapshot in snapshots) {
      _definitions[snapshot.definition.id] = snapshot.definition;
      final clamped = snapshot.definition.clamp(snapshot.value);
      _values[snapshot.definition.id] = clamped;
      final resolved = snapshot.definition.resolve(_parameterRegistry, clamped);
      updates.addAll(resolved);
    }
    return updates;
  }

  /// Clear all macros and values.
  bool clear() {
    if (_definitions.isEmpty && _values.isEmpty) {
      return false;
    }
    _definitions.clear();
    _values.clear();
    return true;
  }

  /// Capture a snapshot of the current macro program.
  List<MacroSnapshot> snapshot() {
    if (_definitions.isEmpty) {
      return const <MacroSnapshot>[];
    }

    final snapshots = <MacroSnapshot>[];
    for (final entry in _definitions.entries) {
      final definition = entry.value;
      final value = _values[entry.key] ?? definition.defaultValue;
      snapshots.add(
        MacroSnapshot(definition: definition, value: definition.clamp(value)),
      );
    }
    return List<MacroSnapshot>.unmodifiable(snapshots);
  }
}
