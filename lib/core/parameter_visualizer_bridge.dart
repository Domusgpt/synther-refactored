import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'synth_parameters.dart';
import '../design_system/design_system.dart';

/// Advanced parameter-to-visualizer binding engine for Morph-UI
/// This engine creates the unified experience where UI controls directly affect the 4D visualizer
class ParameterVisualizerBridge extends ChangeNotifier {
  static final ParameterVisualizerBridge _instance = ParameterVisualizerBridge._internal();
  factory ParameterVisualizerBridge() => _instance;
  ParameterVisualizerBridge._internal();

  /// Active parameter bindings: Flutter parameter -> Visualizer parameter
  final Map<String, VisualizerBinding> _bindings = {};
  
  /// Real-time parameter values cache for smooth updates
  final Map<String, double> _parameterCache = {};
  
  /// Visual feedback colors for each parameter
  final Map<String, Color> _parameterColors = {};
  
  /// Update callback for visualizer
  Function(String, double)? _visualizerUpdateCallback;
  
  /// Tinting callback for UI elements
  Function(String, Color, double)? _uiTintCallback;
  
  /// Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  /// Available visualizer parameters that can be controlled
  static const Map<String, VisualizerParameter> availableVisualizerParams = {
    // 4D Geometry Control
    'dimension': VisualizerParameter(
      id: 'dimension',
      name: '4D Dimension',
      description: 'Controls 4D to 3D projection dimension',
      min: 3.0,
      max: 5.0,
      defaultValue: 4.0,
      category: VisualizerCategory.geometry,
      color: DesignTokens.neonCyan,
    ),
    'morphFactor': VisualizerParameter(
      id: 'morphFactor',
      name: 'Morph Factor',
      description: 'Shape morphing intensity',
      min: 0.0,
      max: 2.0,
      defaultValue: 0.7,
      category: VisualizerCategory.geometry,
      color: DesignTokens.neonPurple,
    ),
    
    // Rotation and Movement
    'rotationX': VisualizerParameter(
      id: 'rotationX',
      name: 'X Rotation',
      description: '4D rotation around X axis',
      min: 0.0,
      max: 360.0,
      defaultValue: 0.0,
      category: VisualizerCategory.rotation,
      color: DesignTokens.neonCyan,
    ),
    'rotationY': VisualizerParameter(
      id: 'rotationY',
      name: 'Y Rotation',
      description: '4D rotation around Y axis',
      min: 0.0,
      max: 360.0,
      defaultValue: 0.0,
      category: VisualizerCategory.rotation,
      color: DesignTokens.neonPink,
    ),
    'rotationSpeed': VisualizerParameter(
      id: 'rotationSpeed',
      name: 'Rotation Speed',
      description: 'Automatic rotation speed',
      min: 0.0,
      max: 3.0,
      defaultValue: 0.5,
      category: VisualizerCategory.rotation,
      color: DesignTokens.neonGreen,
    ),
    
    // Visual Properties
    'lineThickness': VisualizerParameter(
      id: 'lineThickness',
      name: 'Line Thickness',
      description: 'Wireframe line thickness',
      min: 0.005,
      max: 0.1,
      defaultValue: 0.03,
      category: VisualizerCategory.appearance,
      color: DesignTokens.neonOrange,
    ),
    'gridDensity': VisualizerParameter(
      id: 'gridDensity',
      name: 'Grid Density',
      description: 'Tesseract grid density',
      min: 2.0,
      max: 20.0,
      defaultValue: 8.0,
      category: VisualizerCategory.appearance,
      color: DesignTokens.neonBlue,
    ),
    'patternIntensity': VisualizerParameter(
      id: 'patternIntensity',
      name: 'Pattern Intensity',
      description: 'Visual pattern complexity',
      min: 0.1,
      max: 3.0,
      defaultValue: 1.3,
      category: VisualizerCategory.appearance,
      color: DesignTokens.neonPurple,
    ),
    
    // Color and Effects
    'colorShift': VisualizerParameter(
      id: 'colorShift',
      name: 'Color Shift',
      description: 'Hue shift animation',
      min: 0.0,
      max: 1.0,
      defaultValue: 0.0,
      category: VisualizerCategory.color,
      color: DesignTokens.neonRainbow,
    ),
    'glitchIntensity': VisualizerParameter(
      id: 'glitchIntensity',
      name: 'Glitch Intensity',
      description: 'Digital glitch effects',
      min: 0.0,
      max: 0.2,
      defaultValue: 0.02,
      category: VisualizerCategory.effects,
      color: DesignTokens.neonPink,
    ),
    'universeModifier': VisualizerParameter(
      id: 'universeModifier',
      name: 'Universe Modifier',
      description: 'Overall visual scale',
      min: 0.1,
      max: 3.0,
      defaultValue: 1.0,
      category: VisualizerCategory.effects,
      color: DesignTokens.neonCyan,
    ),
  };
  
  /// Initialize the bridge with callbacks
  void initialize({
    required Function(String, double) visualizerUpdateCallback,
    Function(String, Color, double)? uiTintCallback,
  }) {
    _visualizerUpdateCallback = visualizerUpdateCallback;
    _uiTintCallback = uiTintCallback;
    _isConnected = true;
    
    // Set up default bindings
    _setupDefaultBindings();
    
    debugPrint('ParameterVisualizerBridge initialized with ${_bindings.length} bindings');
    notifyListeners();
  }
  
  /// Create a binding between a Flutter parameter and visualizer parameter
  void createBinding({
    required String flutterParam,
    required String visualizerParam,
    BindingType type = BindingType.direct,
    double scale = 1.0,
    double offset = 0.0,
    Curve curve = Curves.linear,
    bool enableTinting = true,
  }) {
    final binding = VisualizerBinding(
      flutterParameter: flutterParam,
      visualizerParameter: visualizerParam,
      type: type,
      scale: scale,
      offset: offset,
      curve: curve,
      enableTinting: enableTinting,
      color: availableVisualizerParams[visualizerParam]?.color ?? DesignTokens.neonCyan,
    );
    
    _bindings[flutterParam] = binding;
    _parameterColors[flutterParam] = binding.color;
    
    debugPrint('Created binding: $flutterParam -> $visualizerParam');
    notifyListeners();
  }
  
  /// Remove a parameter binding
  void removeBinding(String flutterParam) {
    _bindings.remove(flutterParam);
    _parameterColors.remove(flutterParam);
    notifyListeners();
  }
  
  /// Update a parameter value and sync to visualizer
  void updateParameter(String parameterName, double value) {
    _parameterCache[parameterName] = value;
    
    final binding = _bindings[parameterName];
    if (binding != null && _visualizerUpdateCallback != null) {
      // Apply transformation
      double transformedValue = value;
      
      switch (binding.type) {
        case BindingType.direct:
          transformedValue = value * binding.scale + binding.offset;
          break;
        case BindingType.inverse:
          transformedValue = (1.0 - value) * binding.scale + binding.offset;
          break;
        case BindingType.curved:
          transformedValue = binding.curve.transform(value) * binding.scale + binding.offset;
          break;
        case BindingType.exponential:
          transformedValue = (value * value) * binding.scale + binding.offset;
          break;
        case BindingType.logarithmic:
          transformedValue = (value > 0 ? (value * 10).log() / 10.log() : 0) * binding.scale + binding.offset;
          break;
      }
      
      // Clamp to visualizer parameter range
      final visualizerParam = availableVisualizerParams[binding.visualizerParameter];
      if (visualizerParam != null) {
        transformedValue = transformedValue.clamp(visualizerParam.min, visualizerParam.max);
      }
      
      // Update visualizer
      _visualizerUpdateCallback!(binding.visualizerParameter, transformedValue);
      
      // Apply UI tinting if enabled
      if (binding.enableTinting && _uiTintCallback != null) {
        _uiTintCallback!(parameterName, binding.color, value);
      }
    }
  }
  
  /// Get the color associated with a parameter
  Color? getParameterColor(String parameterName) {
    return _parameterColors[parameterName];
  }
  
  /// Get all active bindings
  Map<String, VisualizerBinding> get bindings => Map.unmodifiable(_bindings);
  
  /// Check if a parameter has a binding
  bool hasBinding(String parameterName) {
    return _bindings.containsKey(parameterName);
  }
  
  /// Get binding info for parameter
  VisualizerBinding? getBinding(String parameterName) {
    return _bindings[parameterName];
  }
  
  /// Export bindings to JSON for preset storage
  Map<String, dynamic> exportBindings() {
    return {
      'bindings': _bindings.map((key, binding) => MapEntry(key, binding.toJson())),
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Import bindings from JSON
  void importBindings(Map<String, dynamic> data) {
    if (data['bindings'] != null) {
      _bindings.clear();
      _parameterColors.clear();
      
      final bindingsData = data['bindings'] as Map<String, dynamic>;
      for (final entry in bindingsData.entries) {
        final binding = VisualizerBinding.fromJson(entry.value);
        _bindings[entry.key] = binding;
        _parameterColors[entry.key] = binding.color;
      }
      
      debugPrint('Imported ${_bindings.length} parameter bindings');
      notifyListeners();
    }
  }
  
  /// Set up default parameter bindings for immediate functionality
  void _setupDefaultBindings() {
    // XY Pad -> Rotation
    createBinding(
      flutterParam: 'xyPadX',
      visualizerParam: 'rotationX',
      type: BindingType.direct,
      scale: 360.0,
    );
    
    createBinding(
      flutterParam: 'xyPadY',
      visualizerParam: 'rotationY',
      type: BindingType.direct,
      scale: 360.0,
    );
    
    // Filter -> Visual Properties
    createBinding(
      flutterParam: 'filterCutoff',
      visualizerParam: 'lineThickness',
      type: BindingType.logarithmic,
      scale: 0.095,
      offset: 0.005,
    );
    
    createBinding(
      flutterParam: 'filterResonance',
      visualizerParam: 'glitchIntensity',
      type: BindingType.exponential,
      scale: 0.15,
    );
    
    // Envelope -> Morphing
    createBinding(
      flutterParam: 'attackTime',
      visualizerParam: 'morphFactor',
      type: BindingType.curved,
      curve: Curves.easeInOut,
      scale: 1.5,
    );
    
    // Master Volume -> Pattern Intensity
    createBinding(
      flutterParam: 'masterVolume',
      visualizerParam: 'patternIntensity',
      type: BindingType.direct,
      scale: 2.0,
      offset: 0.1,
    );
    
    // Reverb -> Grid Density
    createBinding(
      flutterParam: 'reverbMix',
      visualizerParam: 'gridDensity',
      type: BindingType.inverse,
      scale: 15.0,
      offset: 5.0,
    );
    
    // Oscillator Detune -> Color Shift
    createBinding(
      flutterParam: 'oscillatorDetune',
      visualizerParam: 'colorShift',
      type: BindingType.direct,
      scale: 1.0,
    );
    
    // Delay Mix -> Universe Modifier
    createBinding(
      flutterParam: 'delayMix',
      visualizerParam: 'universeModifier',
      type: BindingType.direct,
      scale: 2.0,
      offset: 0.2,
    );
  }
  
  /// Create a performance-optimized binding for real-time control
  void createRealtimeBinding({
    required String flutterParam,
    required String visualizerParam,
    required Function(double) smoothingFunction,
  }) {
    createBinding(
      flutterParam: flutterParam,
      visualizerParam: visualizerParam,
      type: BindingType.direct,
    );
    
    // TODO: Implement smoothing and performance optimization
  }
  
  /// Get suggestions for parameter bindings based on parameter type
  List<String> getSuggestedBindings(String flutterParam) {
    // Smart suggestions based on parameter semantics
    final suggestions = <String>[];
    
    if (flutterParam.toLowerCase().contains('xy')) {
      suggestions.addAll(['rotationX', 'rotationY', 'morphFactor']);
    } else if (flutterParam.toLowerCase().contains('filter')) {
      suggestions.addAll(['lineThickness', 'glitchIntensity', 'gridDensity']);
    } else if (flutterParam.toLowerCase().contains('envelope') || flutterParam.toLowerCase().contains('attack')) {
      suggestions.addAll(['morphFactor', 'patternIntensity', 'universeModifier']);
    } else if (flutterParam.toLowerCase().contains('volume')) {
      suggestions.addAll(['patternIntensity', 'universeModifier', 'gridDensity']);
    } else if (flutterParam.toLowerCase().contains('reverb') || flutterParam.toLowerCase().contains('delay')) {
      suggestions.addAll(['glitchIntensity', 'colorShift', 'gridDensity']);
    }
    
    return suggestions;
  }
  
  /// Reset all bindings to defaults
  void resetToDefaults() {
    _bindings.clear();
    _parameterColors.clear();
    _parameterCache.clear();
    _setupDefaultBindings();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _isConnected = false;
    _bindings.clear();
    _parameterColors.clear();
    _parameterCache.clear();
    super.dispose();
  }
}

/// Represents a binding between a Flutter parameter and visualizer parameter
class VisualizerBinding {
  final String flutterParameter;
  final String visualizerParameter;
  final BindingType type;
  final double scale;
  final double offset;
  final Curve curve;
  final bool enableTinting;
  final Color color;
  
  const VisualizerBinding({
    required this.flutterParameter,
    required this.visualizerParameter,
    this.type = BindingType.direct,
    this.scale = 1.0,
    this.offset = 0.0,
    this.curve = Curves.linear,
    this.enableTinting = true,
    this.color = DesignTokens.neonCyan,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'flutterParameter': flutterParameter,
      'visualizerParameter': visualizerParameter,
      'type': type.index,
      'scale': scale,
      'offset': offset,
      'enableTinting': enableTinting,
      'color': color.value,
    };
  }
  
  factory VisualizerBinding.fromJson(Map<String, dynamic> json) {
    return VisualizerBinding(
      flutterParameter: json['flutterParameter'],
      visualizerParameter: json['visualizerParameter'],
      type: BindingType.values[json['type'] ?? 0],
      scale: json['scale']?.toDouble() ?? 1.0,
      offset: json['offset']?.toDouble() ?? 0.0,
      enableTinting: json['enableTinting'] ?? true,
      color: Color(json['color'] ?? DesignTokens.neonCyan.value),
    );
  }
}

/// Types of parameter binding transformations
enum BindingType {
  direct,      // Linear mapping
  inverse,     // Inverted linear mapping
  curved,      // Custom curve transformation
  exponential, // Quadratic response
  logarithmic, // Logarithmic response
}

/// Visualizer parameter definition
class VisualizerParameter {
  final String id;
  final String name;
  final String description;
  final double min;
  final double max;
  final double defaultValue;
  final VisualizerCategory category;
  final Color color;
  
  const VisualizerParameter({
    required this.id,
    required this.name,
    required this.description,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.category,
    required this.color,
  });
}

/// Categories for organizing visualizer parameters
enum VisualizerCategory {
  geometry,    // 4D shape and morphing
  rotation,    // Rotation and movement
  appearance,  // Visual properties
  color,       // Color and hue
  effects,     // Special effects
}

/// Extension for visualizer category display names
extension VisualizerCategoryExtension on VisualizerCategory {
  String get displayName {
    switch (this) {
      case VisualizerCategory.geometry:
        return 'Geometry';
      case VisualizerCategory.rotation:
        return 'Rotation';
      case VisualizerCategory.appearance:
        return 'Appearance';
      case VisualizerCategory.color:
        return 'Color';
      case VisualizerCategory.effects:
        return 'Effects';
    }
  }
  
  Color get color {
    switch (this) {
      case VisualizerCategory.geometry:
        return DesignTokens.neonCyan;
      case VisualizerCategory.rotation:
        return DesignTokens.neonPurple;
      case VisualizerCategory.appearance:
        return DesignTokens.neonOrange;
      case VisualizerCategory.color:
        return DesignTokens.neonPink;
      case VisualizerCategory.effects:
        return DesignTokens.neonGreen;
    }
  }
}