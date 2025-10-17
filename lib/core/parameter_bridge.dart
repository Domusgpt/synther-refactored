import 'dart:async';
import 'package:flutter/foundation.dart';

import 'parameter_models.dart';
import 'parameter_registry.dart';

/// Central parameter bridge for 3-way synchronization between UI, Audio, and Visualizer
class ParameterBridge {
  static ParameterBridge? _instance;
  static ParameterBridge get instance => _instance ??= ParameterBridge._();
  
  ParameterBridge._();
  
  // Parameter update streams
  final _parameterController = StreamController<ParameterUpdate>.broadcast();
  Stream<ParameterUpdate> get parameterStream => _parameterController.stream;
  
  // Current parameter values
  final Map<String, double> _parameters = {};
  
  // Update sources
  enum UpdateSource { ui, audio, visualizer }
  
  // Registered handlers for each system
  void Function(String, double)? _audioHandler;
  void Function(String, double)? _visualizerHandler;
  void Function(String, double)? _uiHandler;
  
  // Register handlers
  void registerAudioHandler(void Function(String, double) handler) {
    _audioHandler = handler;
  }

  void unregisterAudioHandler(void Function(String, double) handler) {
    if (identical(_audioHandler, handler)) {
      _audioHandler = null;
    }
  }

  void registerVisualizerHandler(void Function(String, double) handler) {
    _visualizerHandler = handler;
  }
  
  void registerUIHandler(void Function(String, double) handler) {
    _uiHandler = handler;
  }
  
  // Update parameter from any source
  void updateParameter(String name, double value, UpdateSource source) {
    // Store current value
    _parameters[name] = value;
    
    // Create update event
    final update = ParameterUpdate(
      name: name,
      value: value,
      source: source,
      timestamp: DateTime.now(),
    );
    
    // Broadcast to stream
    _parameterController.add(update);
    
    // Propagate to other systems
    _propagateUpdate(name, value, source);
  }
  
  void _propagateUpdate(String name, double value, UpdateSource source) {
    // Don't send update back to source
    if (source != UpdateSource.audio && _audioHandler != null) {
      _audioHandler!(name, value);
    }
    
    if (source != UpdateSource.visualizer && _visualizerHandler != null) {
      _visualizerHandler!(name, value);
    }
    
    if (source != UpdateSource.ui && _uiHandler != null) {
      _uiHandler!(name, value);
    }
  }
  
  // Get current parameter value
  double? getParameter(String name) => _parameters[name];
  
  // Get all parameters
  Map<String, double> getAllParameters() => Map.from(_parameters);
  
  // Batch update parameters
  void batchUpdate(Map<String, double> parameters, UpdateSource source) {
    parameters.forEach((name, value) {
      updateParameter(name, value, source);
    });
  }
  
  // Parameter mapping definitions
  static final Map<String, ParameterMapping> mappings = _buildMappings();

  static Map<String, ParameterMapping> _buildMappings() {
    final registry = ParameterRegistry.instance;
    final map = <String, ParameterMapping>{};

    void registerMapping(String key, ParameterDescriptor descriptor) {
      map[key] = ParameterMapping(
        range: descriptor.range,
        visualizerParam: descriptor.visualizerTarget,
      );
    }

    for (final entry in registry.descriptors.entries) {
      registerMapping(entry.key, entry.value);
      for (final alias in entry.value.allKeys.skip(1)) {
        registerMapping(alias, entry.value);
      }
    }

    // Preserve XY pad mappings that are not part of the audio registry yet.
    map.putIfAbsent(
      'xyPadX',
      () => ParameterMapping(
        range: const ParameterRange(min: 0, max: 1, defaultValue: 0.5),
        visualizerParam: 'rotation4D_XY',
      ),
    );
    map.putIfAbsent(
      'xyPadY',
      () => ParameterMapping(
        range: const ParameterRange(min: 0, max: 1, defaultValue: 0.5),
        visualizerParam: 'rotation4D_ZW',
      ),
    );

    return map;
  }

  @visibleForTesting
  void resetForTesting() {
    _parameters.clear();
    _audioHandler = null;
    _visualizerHandler = null;
    _uiHandler = null;
  }
  
  void dispose() {
    _parameterController.close();
  }
}

/// Represents a parameter update event
class ParameterUpdate {
  final String name;
  final double value;
  final ParameterBridge.UpdateSource source;
  final DateTime timestamp;
  
  ParameterUpdate({
    required this.name,
    required this.value,
    required this.source,
    required this.timestamp,
  });
}

/// Parameter mapping configuration
class ParameterMapping {
  final ParameterRange range;
  final String visualizerParam;

  const ParameterMapping({
    required this.range,
    required this.visualizerParam,
  });

  double get min => range.min;
  double get max => range.max;
  ParameterCurve get curve => range.curve;

  // Map value to normalized range
  double normalize(double value) => range.normalize(value);

  // Map normalized value back to real range
  double denormalize(double normalized) => range.denormalize(normalized);
}

/// Mixin for widgets that need parameter bridge integration
mixin ParameterBridgeMixin<T extends StatefulWidget> on State<T> {
  final _bridge = ParameterBridge.instance;
  StreamSubscription<ParameterUpdate>? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = _bridge.parameterStream.listen(_onParameterUpdate);
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  
  // Override to handle parameter updates
  void onParameterUpdate(String name, double value, ParameterBridge.UpdateSource source) {}
  
  void _onParameterUpdate(ParameterUpdate update) {
    if (mounted) {
      onParameterUpdate(update.name, update.value, update.source);
    }
  }
  
  // Helper to update parameter from this widget
  void updateParameter(String name, double value) {
    _bridge.updateParameter(name, value, ParameterBridge.UpdateSource.ui);
  }
}