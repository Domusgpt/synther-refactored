import 'dart:collection';

/// Describes a modulation routing from a source (LFO, controller, envelope)
/// to a destination parameter inside the synth engine.
class ModulationRoute {
  const ModulationRoute({
    required this.source,
    required this.destination,
    required this.amount,
  });

  /// Identifier of the modulation source (for example `lfo1` or `modWheel`).
  final String source;

  /// Identifier of the destination parameter (for example `filterCutoff`).
  final String destination;

  /// Bipolar modulation amount in the range -1..1.
  final double amount;

  /// Stable key that uniquely identifies this route inside the matrix.
  String get key => '${source.trim().toLowerCase()}->${destination.trim().toLowerCase()}';

  ModulationRoute copyWith({
    String? source,
    String? destination,
    double? amount,
  }) {
    return ModulationRoute(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source,
      'destination': destination,
      'amount': amount,
    };
  }

  factory ModulationRoute.fromJson(Map<String, dynamic> json) {
    return ModulationRoute(
      source: (json['source'] as String).trim(),
      destination: (json['destination'] as String).trim(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'ModulationRoute(source: $source, destination: $destination, amount: $amount)';

  @override
  int get hashCode => Object.hash(source.toLowerCase(), destination.toLowerCase(), amount);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ModulationRoute) return false;
    return source.toLowerCase() == other.source.toLowerCase() &&
        destination.toLowerCase() == other.destination.toLowerCase() &&
        (amount - other.amount).abs() < ModulationMatrix.epsilon;
  }
}

/// Mutable modulation routing matrix with deterministic ordering.
class ModulationMatrix {
  ModulationMatrix([Iterable<ModulationRoute>? routes]) {
    if (routes != null) {
      replaceAll(routes);
    }
  }

  static const double epsilon = 1e-6;

  final LinkedHashMap<String, ModulationRoute> _routes =
      LinkedHashMap<String, ModulationRoute>();

  /// Returns an immutable snapshot of all active modulation routes.
  List<ModulationRoute> get routes =>
      List<ModulationRoute>.unmodifiable(_routes.values);

  /// Number of active modulation routes.
  int get routeCount => _routes.length;

  /// Total absolute modulation depth for every destination.
  Map<String, double> aggregateDepthByDestination() {
    final totals = <String, double>{};
    for (final route in _routes.values) {
      final destinationKey = route.destination.trim().toLowerCase();
      totals[destinationKey] = (totals[destinationKey] ?? 0.0) + route.amount.abs();
    }
    return totals;
  }

  /// Total absolute modulation depth for every source.
  Map<String, double> aggregateDepthBySource() {
    final totals = <String, double>{};
    for (final route in _routes.values) {
      final sourceKey = route.source.trim().toLowerCase();
      totals[sourceKey] = (totals[sourceKey] ?? 0.0) + route.amount.abs();
    }
    return totals;
  }

  /// Add or update a modulation route. Passing a value close to zero removes the
  /// route from the matrix.
  bool setRoute(ModulationRoute route) {
    final key = route.key;
    if (route.amount.abs() < epsilon) {
      return _routes.remove(key) != null;
    }

    final existing = _routes[key];
    if (existing != null && (existing.amount - route.amount).abs() < epsilon) {
      return false;
    }

    _routes[key] = route;
    return true;
  }

  /// Remove a modulation route. Returns true when the route existed.
  bool removeRoute(String source, String destination) {
    final key = '${source.trim().toLowerCase()}->${destination.trim().toLowerCase()}';
    return _routes.remove(key) != null;
  }

  /// Replace the entire modulation matrix. Returns true when the set changed.
  bool replaceAll(Iterable<ModulationRoute> routes) {
    final previous = Map<String, ModulationRoute>.from(_routes);
    _routes
      ..clear()
      ..addEntries(routes.map((route) => MapEntry(route.key, route)));

    if (previous.length != _routes.length) {
      return true;
    }

    for (final entry in _routes.entries) {
      final oldRoute = previous[entry.key];
      final newRoute = entry.value;
      if (oldRoute == null) {
        return true;
      }
      if ((oldRoute.amount - newRoute.amount).abs() >= epsilon ||
          oldRoute.source.toLowerCase() != newRoute.source.toLowerCase() ||
          oldRoute.destination.toLowerCase() != newRoute.destination.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Remove all modulation routes.
  bool clear() {
    if (_routes.isEmpty) {
      return false;
    }
    _routes.clear();
    return true;
  }
}

/// Utilities to convert between bridge keys and modulation routes.
class ModulationMatrixCodec {
  static const String bridgePrefix = 'modMatrix.';

  static String encodeBridgeKey(String source, String destination) {
    return '$bridgePrefix${source.trim().toLowerCase()}->${destination.trim().toLowerCase()}';
  }

  static ModulationRoute? decodeBridgeKey(String key, double amount) {
    if (!key.startsWith(bridgePrefix)) {
      return null;
    }

    final routeSpec = key.substring(bridgePrefix.length);
    final parts = routeSpec.split('->');
    if (parts.length != 2) {
      return null;
    }

    return ModulationRoute(
      source: parts[0].trim(),
      destination: parts[1].trim(),
      amount: amount,
    );
  }
}
