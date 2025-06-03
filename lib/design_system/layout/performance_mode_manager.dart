import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

/// Performance mode manager for collapsible UI system
/// Provides streamlined interface for live performance with gesture controls
class PerformanceModeManager extends ChangeNotifier {
  static final PerformanceModeManager _instance = PerformanceModeManager._internal();
  factory PerformanceModeManager() => _instance;
  PerformanceModeManager._internal();

  /// Current performance mode state
  PerformanceMode _currentMode = PerformanceMode.normal;
  PerformanceMode get currentMode => _currentMode;

  /// UI visibility states
  final Map<UIElement, bool> _elementVisibility = {
    UIElement.xyPad: true,
    UIElement.controls: true,
    UIElement.keyboard: true,
    UIElement.visualizer: true,
    UIElement.bezelTabs: true,
    UIElement.parameterVault: false,
    UIElement.presets: false,
  };

  /// Collapse animation states
  final Map<UIElement, double> _collapseProgress = {};

  /// Performance optimizations
  bool _reducedAnimations = false;
  bool get reducedAnimations => _reducedAnimations;

  bool _highContrastMode = false;
  bool get highContrastMode => _highContrastMode;

  /// Gesture shortcuts
  final Map<PerformanceGesture, VoidCallback> _gestureCallbacks = {};

  /// Initialize performance mode
  void initialize() {
    // Set default collapse progress
    for (final element in UIElement.values) {
      _collapseProgress[element] = 1.0; // 1.0 = fully expanded
    }
    
    debugPrint('PerformanceModeManager initialized');
  }

  /// Set performance mode
  void setMode(PerformanceMode mode) {
    if (_currentMode == mode) return;

    _currentMode = mode;
    _applyModeConfiguration(mode);
    
    // Haptic feedback for mode change
    HapticFeedback.mediumImpact();
    
    notifyListeners();
    debugPrint('Performance mode changed to: ${mode.name}');
  }

  /// Toggle specific UI element visibility
  void toggleElement(UIElement element) {
    _elementVisibility[element] = !(_elementVisibility[element] ?? true);
    notifyListeners();
    
    debugPrint('${element.name} visibility: ${_elementVisibility[element]}');
  }

  /// Set element visibility with animation
  void setElementVisibility(UIElement element, bool visible, {Duration? duration}) {
    _elementVisibility[element] = visible;
    
    // Animate collapse/expand
    if (duration != null) {
      _animateElementCollapse(element, visible ? 1.0 : 0.0, duration);
    } else {
      _collapseProgress[element] = visible ? 1.0 : 0.0;
    }
    
    notifyListeners();
  }

  /// Get element visibility
  bool isElementVisible(UIElement element) {
    return _elementVisibility[element] ?? true;
  }

  /// Get collapse progress for smooth animations
  double getCollapseProgress(UIElement element) {
    return _collapseProgress[element] ?? 1.0;
  }

  /// Register gesture callback
  void registerGesture(PerformanceGesture gesture, VoidCallback callback) {
    _gestureCallbacks[gesture] = callback;
    debugPrint('Registered gesture: ${gesture.name}');
  }

  /// Execute gesture callback
  void executeGesture(PerformanceGesture gesture) {
    final callback = _gestureCallbacks[gesture];
    if (callback != null) {
      callback();
      HapticFeedback.lightImpact();
    }
  }

  /// Enable/disable reduced animations
  void setReducedAnimations(bool reduced) {
    _reducedAnimations = reduced;
    notifyListeners();
  }

  /// Enable/disable high contrast mode
  void setHighContrastMode(bool enabled) {
    _highContrastMode = enabled;
    notifyListeners();
  }

  /// Quick access presets for performance modes
  void applyQuickPreset(PerformanceQuickPreset preset) {
    switch (preset) {
      case PerformanceQuickPreset.minimalXY:
        _applyMinimalXYPreset();
        break;
      case PerformanceQuickPreset.fullVisualizer:
        _applyFullVisualizerPreset();
        break;
      case PerformanceQuickPreset.touchGrid:
        _applyTouchGridPreset();
        break;
      case PerformanceQuickPreset.djMode:
        _applyDJModePreset();
        break;
    }
    
    notifyListeners();
  }

  /// Apply mode-specific configuration
  void _applyModeConfiguration(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.normal:
        _applyNormalMode();
        break;
      case PerformanceMode.performance:
        _applyPerformanceMode();
        break;
      case PerformanceMode.minimal:
        _applyMinimalMode();
        break;
      case PerformanceMode.visualizerOnly:
        _applyVisualizerOnlyMode();
        break;
    }
  }

  void _applyNormalMode() {
    // All elements visible
    _elementVisibility.updateAll((key, value) => true);
    _elementVisibility[UIElement.parameterVault] = false;
    _elementVisibility[UIElement.presets] = false;
    _reducedAnimations = false;
  }

  void _applyPerformanceMode() {
    // Streamlined for performance
    _elementVisibility[UIElement.xyPad] = true;
    _elementVisibility[UIElement.controls] = true;
    _elementVisibility[UIElement.keyboard] = true;
    _elementVisibility[UIElement.visualizer] = true;
    _elementVisibility[UIElement.bezelTabs] = false;
    _elementVisibility[UIElement.parameterVault] = false;
    _elementVisibility[UIElement.presets] = false;
    _reducedAnimations = true;
  }

  void _applyMinimalMode() {
    // Only essential controls
    _elementVisibility[UIElement.xyPad] = true;
    _elementVisibility[UIElement.controls] = false;
    _elementVisibility[UIElement.keyboard] = false;
    _elementVisibility[UIElement.visualizer] = true;
    _elementVisibility[UIElement.bezelTabs] = false;
    _elementVisibility[UIElement.parameterVault] = false;
    _elementVisibility[UIElement.presets] = false;
    _reducedAnimations = true;
  }

  void _applyVisualizerOnlyMode() {
    // Only visualizer visible
    _elementVisibility.updateAll((key, value) => false);
    _elementVisibility[UIElement.visualizer] = true;
    _reducedAnimations = false;
  }

  // Quick preset implementations
  void _applyMinimalXYPreset() {
    _elementVisibility.updateAll((key, value) => false);
    _elementVisibility[UIElement.xyPad] = true;
    _elementVisibility[UIElement.visualizer] = true;
  }

  void _applyFullVisualizerPreset() {
    _elementVisibility.updateAll((key, value) => false);
    _elementVisibility[UIElement.visualizer] = true;
  }

  void _applyTouchGridPreset() {
    _elementVisibility[UIElement.xyPad] = false;
    _elementVisibility[UIElement.controls] = false;
    _elementVisibility[UIElement.keyboard] = true; // As touch grid
    _elementVisibility[UIElement.visualizer] = true;
    _elementVisibility[UIElement.bezelTabs] = false;
  }

  void _applyDJModePreset() {
    _elementVisibility[UIElement.xyPad] = true;
    _elementVisibility[UIElement.controls] = true;
    _elementVisibility[UIElement.keyboard] = false;
    _elementVisibility[UIElement.visualizer] = true;
    _elementVisibility[UIElement.bezelTabs] = true;
  }

  void _animateElementCollapse(UIElement element, double target, Duration duration) {
    // In a real implementation, this would use an AnimationController
    // For now, we'll just set the value directly
    _collapseProgress[element] = target;
  }

  /// Export current configuration
  Map<String, dynamic> exportConfiguration() {
    return {
      'mode': _currentMode.index,
      'visibility': _elementVisibility.map((k, v) => MapEntry(k.index, v)),
      'reducedAnimations': _reducedAnimations,
      'highContrastMode': _highContrastMode,
    };
  }

  /// Import configuration
  void importConfiguration(Map<String, dynamic> config) {
    if (config['mode'] != null) {
      _currentMode = PerformanceMode.values[config['mode']];
    }
    
    if (config['visibility'] != null) {
      final visibilityMap = config['visibility'] as Map<String, dynamic>;
      visibilityMap.forEach((key, value) {
        final element = UIElement.values[int.parse(key.toString())];
        _elementVisibility[element] = value as bool;
      });
    }
    
    _reducedAnimations = config['reducedAnimations'] ?? false;
    _highContrastMode = config['highContrastMode'] ?? false;
    
    notifyListeners();
  }

  @override
  void dispose() {
    _gestureCallbacks.clear();
    super.dispose();
  }
}

/// Performance mode options
enum PerformanceMode {
  normal,         // All UI elements visible
  performance,    // Optimized for live performance
  minimal,        // Only essential controls
  visualizerOnly, // Full-screen visualizer
}

/// UI elements that can be toggled
enum UIElement {
  xyPad,
  controls,
  keyboard,
  visualizer,
  bezelTabs,
  parameterVault,
  presets,
}

/// Performance gesture types
enum PerformanceGesture {
  doubleTap,      // Toggle performance mode
  twoFingerTap,   // Quick preset
  swipeUp,        // Collapse bottom panel
  swipeDown,      // Expand bottom panel
  pinch,          // Toggle visualizer fullscreen
  longPress,      // Show quick menu
  shake,          // Emergency reset
}

/// Quick preset options
enum PerformanceQuickPreset {
  minimalXY,      // Just XY pad and visualizer
  fullVisualizer, // Visualizer only
  touchGrid,      // Touch grid focus
  djMode,         // DJ-style layout
}

/// Extension for display names
extension PerformanceModeExtension on PerformanceMode {
  String get displayName {
    switch (this) {
      case PerformanceMode.normal:
        return 'Normal';
      case PerformanceMode.performance:
        return 'Performance';
      case PerformanceMode.minimal:
        return 'Minimal';
      case PerformanceMode.visualizerOnly:
        return 'Visualizer';
    }
  }
  
  IconData get icon {
    switch (this) {
      case PerformanceMode.normal:
        return Icons.dashboard;
      case PerformanceMode.performance:
        return Icons.music_note;
      case PerformanceMode.minimal:
        return Icons.minimize;
      case PerformanceMode.visualizerOnly:
        return Icons.fullscreen;
    }
  }
  
  Color get color {
    switch (this) {
      case PerformanceMode.normal:
        return DesignTokens.neonCyan;
      case PerformanceMode.performance:
        return DesignTokens.neonPink;
      case PerformanceMode.minimal:
        return DesignTokens.neonOrange;
      case PerformanceMode.visualizerOnly:
        return DesignTokens.neonPurple;
    }
  }
}

extension UIElementExtension on UIElement {
  String get displayName {
    switch (this) {
      case UIElement.xyPad:
        return 'XY Pad';
      case UIElement.controls:
        return 'Controls';
      case UIElement.keyboard:
        return 'Keyboard';
      case UIElement.visualizer:
        return 'Visualizer';
      case UIElement.bezelTabs:
        return 'Tabs';
      case UIElement.parameterVault:
        return 'Vault';
      case UIElement.presets:
        return 'Presets';
    }
  }
}