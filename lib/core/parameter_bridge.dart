import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Identifies the origin of a parameter update so changes are not echoed back
/// to the sender.
enum ParameterUpdateSource { ui, audio, visualizer }

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
  
  // Registered handlers for each system
  void Function(String, double)? _audioHandler;
  void Function(String, double)? _visualizerHandler;
  void Function(String, double)? _uiHandler;
  
  // Register handlers
  void registerAudioHandler(void Function(String, double) handler) {
    _audioHandler = handler;
  }
  
  void registerVisualizerHandler(void Function(String, double) handler) {
    _visualizerHandler = handler;
  }
  
  void registerUIHandler(void Function(String, double) handler) {
    _uiHandler = handler;
  }
  
  // Update parameter from any source
  void updateParameter(String name, double value, ParameterUpdateSource source) {
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
  
  void _propagateUpdate(String name, double value, ParameterUpdateSource source) {
    // Don't send update back to source
    if (source != ParameterUpdateSource.audio && _audioHandler != null) {
      _audioHandler!(name, value);
    }

    if (source != ParameterUpdateSource.visualizer && _visualizerHandler != null) {
      _visualizerHandler!(name, value);
    }

    if (source != ParameterUpdateSource.ui && _uiHandler != null) {
      _uiHandler!(name, value);
    }
  }
  
  // Get current parameter value
  double? getParameter(String name) => _parameters[name];
  
  // Get all parameters
  Map<String, double> getAllParameters() => Map.from(_parameters);
  
  // Batch update parameters
  void batchUpdate(Map<String, double> parameters, ParameterUpdateSource source) {
    parameters.forEach((name, value) {
      updateParameter(name, value, source);
    });
  }
  
  // Parameter mapping definitions
  static const Map<String, ParameterMapping> mappings = {
    'filterCutoff': ParameterMapping(
      min: 20,
      max: 20000,
      curve: ParameterCurve.exponential,
      visualizerParam: 'geometryComplexity',
    ),
    'filterResonance': ParameterMapping(
      min: 0,
      max: 1,
      curve: ParameterCurve.linear,
      visualizerParam: 'colorIntensity',
    ),
    'reverbMix': ParameterMapping(
      min: 0,
      max: 1,
      curve: ParameterCurve.linear,
      visualizerParam: 'spaceSize',
    ),
    'xyPadX': ParameterMapping(
      min: 0,
      max: 1,
      curve: ParameterCurve.linear,
      visualizerParam: 'rotation4D_XY',
    ),
    'xyPadY': ParameterMapping(
      min: 0,
      max: 1,
      curve: ParameterCurve.linear,
      visualizerParam: 'rotation4D_ZW',
    ),
    'masterVolume': ParameterMapping(
      min: 0,
      max: 1,
      curve: ParameterCurve.linear,
      visualizerParam: 'brightness',
    ),
  };
  
  void dispose() {
    _parameterController.close();
  }
}

/// Represents a parameter update event
class ParameterUpdate {
  final String name;
  final double value;
  final ParameterUpdateSource source;
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
  final double min;
  final double max;
  final ParameterCurve curve;
  final String visualizerParam;
  
  const ParameterMapping({
    required this.min,
    required this.max,
    required this.curve,
    required this.visualizerParam,
  });
  
  // Map value to normalized range
  double normalize(double value) {
    final clamped = value.clamp(min, max);
    final normalized = (clamped - min) / (max - min);
    
    switch (curve) {
      case ParameterCurve.linear:
        return normalized;
      case ParameterCurve.exponential:
        return normalized * normalized;
      case ParameterCurve.logarithmic:
        if (normalized <= 0) {
          return 0;
        }
        return math.log(normalized * 9 + 1) / math.log(10);
    }
  }
  
  // Map normalized value back to real range
  double denormalize(double normalized) {
    double curved;
    
    switch (curve) {
      case ParameterCurve.linear:
        curved = normalized;
        break;
      case ParameterCurve.exponential:
        curved = normalized.sign * math.sqrt(normalized.abs());
        break;
      case ParameterCurve.logarithmic:
        if (normalized <= 0) {
          curved = 0;
        } else {
          curved = (math.pow(10, normalized) - 1) / 9;
        }
        break;
    }
    
    return min + curved * (max - min);
  }
}

/// Parameter curve types
enum ParameterCurve {
  linear,
  exponential,
  logarithmic,
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
  void onParameterUpdate(String name, double value, ParameterUpdateSource source) {}
  
  void _onParameterUpdate(ParameterUpdate update) {
    if (mounted) {
      onParameterUpdate(update.name, update.value, update.source);
    }
  }
  
  // Helper to update parameter from this widget
  void updateParameter(String name, double value) {
    _bridge.updateParameter(name, value, ParameterUpdateSource.ui);
  }
}
