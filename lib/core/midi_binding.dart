import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'parameter_models.dart';
import 'parameter_registry.dart';

/// Describes how a MIDI controller maps onto a synthesiser parameter.
@immutable
class MidiBinding {
  const MidiBinding({
    required this.controller,
    required this.parameterId,
    this.minValue,
    this.maxValue,
    this.invert = false,
  })  : assert(controller >= 0 && controller <= 127,
            'controller must be within the MIDI 0-127 range');

  /// MIDI Control Change number.
  final int controller;

  /// Canonical or alias parameter identifier.
  final String parameterId;

  /// Optional lower bound for the mapped parameter value.
  final double? minValue;

  /// Optional upper bound for the mapped parameter value.
  final double? maxValue;

  /// When true the MIDI value is inverted before being mapped.
  final bool invert;

  /// Returns a JSON representation suitable for storing in project presets.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'controller': controller,
      'parameterId': parameterId,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (invert) 'invert': invert,
    };
  }

  /// Restores a [MidiBinding] from JSON data.
  factory MidiBinding.fromJson(Map<String, dynamic> json) {
    return MidiBinding(
      controller: json['controller'] as int,
      parameterId: json['parameterId'] as String,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      invert: json['invert'] as bool? ?? false,
    );
  }

  /// Returns the denormalised parameter value for the provided MIDI [value].
  double resolveValue(
    int value,
    ParameterDescriptor descriptor,
  ) {
    final clampedMidi = value.clamp(0, 127).toDouble();
    var normalized = clampedMidi / 127.0;
    if (invert) {
      normalized = 1.0 - normalized;
    }

    final range = descriptor.range;
    final effectiveMin = range.clamp(minValue ?? range.min);
    final effectiveMax = range.clamp(maxValue ?? range.max);

    final minNorm = range.normalize(math.min(effectiveMin, effectiveMax));
    final maxNorm = range.normalize(math.max(effectiveMin, effectiveMax));
    final lower = math.min(minNorm, maxNorm);
    final upper = math.max(minNorm, maxNorm);
    final scaled = lower + (upper - lower) * normalized;
    final denormalized = range.denormalize(scaled);

    if (effectiveMin <= effectiveMax) {
      return denormalized.clamp(effectiveMin, effectiveMax);
    }

    // When the override window is inverted we still clamp to the provided
    // bounds but respect the intended reversed response curve.
    return denormalized.clamp(effectiveMax, effectiveMin);
  }

  MidiBinding copyWith({
    int? controller,
    String? parameterId,
    double? minValue,
    double? maxValue,
    bool? invert,
  }) {
    return MidiBinding(
      controller: controller ?? this.controller,
      parameterId: parameterId ?? this.parameterId,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      invert: invert ?? this.invert,
    );
  }
}

/// Manages MIDI controller bindings and calculates parameter updates.
class MidiBindingManager extends ChangeNotifier {
  MidiBindingManager({ParameterRegistry? registry})
      : _registry = registry ?? ParameterRegistry.instance;

  final ParameterRegistry _registry;
  final Map<int, List<MidiBinding>> _bindings = <int, List<MidiBinding>>{};

  /// Global singleton used across the application.
  static final MidiBindingManager instance = MidiBindingManager();

  /// Returns an unmodifiable view of registered bindings.
  UnmodifiableMapView<int, List<MidiBinding>> get bindings =>
      UnmodifiableMapView<int, List<MidiBinding>>({
        for (final entry in _bindings.entries)
          entry.key: List<MidiBinding>.unmodifiable(entry.value),
      });

  /// Returns the bindings registered for a controller.
  List<MidiBinding> bindingsForController(int controller) {
    final list = _bindings[controller];
    if (list == null) {
      return const <MidiBinding>[];
    }
    return List<MidiBinding>.unmodifiable(list);
  }

  /// Adds a new MIDI binding.
  void registerBinding(MidiBinding binding, {bool replace = false}) {
    final canonical =
        _registry.canonicalName(binding.parameterId) ?? binding.parameterId;
    final resolved = binding.copyWith(parameterId: canonical);

    final list = _bindings.putIfAbsent(resolved.controller, () => <MidiBinding>[]);
    if (replace) {
      list
        ..clear()
        ..add(resolved);
    } else {
      final existingIndex = list.indexWhere(
        (other) => other.parameterId == resolved.parameterId,
      );
      if (existingIndex >= 0) {
        list[existingIndex] = resolved;
      } else {
        list.add(resolved);
      }
    }
    notifyListeners();
  }

  /// Removes a binding for the given [controller] and [parameterId].
  bool removeBinding(int controller, String parameterId) {
    final canonical = _registry.canonicalName(parameterId) ?? parameterId;
    final list = _bindings[controller];
    if (list == null) {
      return false;
    }

    final removed = list.removeWhere(
          (binding) => binding.parameterId == canonical,
        ) >
        0;
    if (list.isEmpty) {
      _bindings.remove(controller);
    }
    if (removed) {
      notifyListeners();
    }
    return removed;
  }

  /// Clears all registered bindings.
  void clear() {
    if (_bindings.isEmpty) {
      return;
    }
    _bindings.clear();
    notifyListeners();
  }

  /// Processes a MIDI control change and returns parameter updates.
  Map<String, double> processControlChange(int controller, int value) {
    final list = _bindings[controller];
    if (list == null || list.isEmpty) {
      return const <String, double>{};
    }

    final updates = <String, double>{};
    for (final binding in list) {
      final descriptor = _registry.descriptorFor(binding.parameterId);
      if (descriptor == null) {
        continue;
      }
      updates[descriptor.name] = binding.resolveValue(value, descriptor);
    }
    return updates;
  }

  /// Serialises the current bindings to JSON.
  Map<String, dynamic> toJson() {
    final entries = <Map<String, dynamic>>[];
    _bindings.forEach((_, bindings) {
      for (final binding in bindings) {
        entries.add(binding.toJson());
      }
    });
    return <String, dynamic>{'bindings': entries};
  }

  /// Restores bindings from JSON data.
  void loadFromJson(Map<String, dynamic> json, {bool replace = false}) {
    final rawBindings = json['bindings'];
    if (rawBindings is! List) {
      return;
    }

    if (replace) {
      _bindings.clear();
    }

    for (final entry in rawBindings) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      registerBinding(MidiBinding.fromJson(entry as Map<String, dynamic>));
    }
  }
}
