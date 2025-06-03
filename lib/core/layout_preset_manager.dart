import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parameter_visualizer_bridge.dart';
import '../design_system/design_system.dart';

/// Comprehensive layout preset manager for Morph-UI system
/// Handles saving/loading of UI layouts, parameter bindings, and user preferences
class LayoutPresetManager extends ChangeNotifier {
  static final LayoutPresetManager _instance = LayoutPresetManager._internal();
  factory LayoutPresetManager() => _instance;
  LayoutPresetManager._internal();

  /// Current active preset
  LayoutPreset? _activePreset;
  LayoutPreset? get activePreset => _activePreset;

  /// All available presets
  final Map<String, LayoutPreset> _presets = {};
  Map<String, LayoutPreset> get presets => Map.unmodifiable(_presets);

  /// Preset categories for organization
  final Map<PresetCategory, List<String>> _categorizedPresets = {
    PresetCategory.system: [],
    PresetCategory.user: [],
    PresetCategory.performance: [],
    PresetCategory.soundDesign: [],
    PresetCategory.live: [],
  };

  /// Initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Auto-save settings
  bool _autoSaveEnabled = true;
  bool get autoSaveEnabled => _autoSaveEnabled;

  /// Initialize the preset manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadPresetsFromStorage();
      await _createSystemPresets();
      
      // Load last active preset
      final prefs = await SharedPreferences.getInstance();
      final lastActiveId = prefs.getString('last_active_preset');
      if (lastActiveId != null && _presets.containsKey(lastActiveId)) {
        _activePreset = _presets[lastActiveId];
      } else {
        _activePreset = _presets['default'];
      }

      _isInitialized = true;
      notifyListeners();
      
      debugPrint('LayoutPresetManager initialized with ${_presets.length} presets');
    } catch (error) {
      debugPrint('Error initializing LayoutPresetManager: $error');
    }
  }

  /// Create system-provided presets
  Future<void> _createSystemPresets() async {
    // Default balanced layout
    final defaultPreset = LayoutPreset(
      id: 'default',
      name: 'Default',
      description: 'Balanced layout for general use',
      category: PresetCategory.system,
      isSystemPreset: true,
      layoutConfig: LayoutConfig(
        paneRatios: [0.45, 0.30, 0.25],
        activePanes: {
          PanePosition.top: PaneType.xyPad,
          PanePosition.middle: PaneType.controls,
          PanePosition.bottom: PaneType.drumPads,
        },
        collapsedPanes: {},
        bezelTabs: {
          BezelPosition.left: ['parameter-vault', 'effects'],
          BezelPosition.right: ['presets', 'settings'],
          BezelPosition.top: ['layouts'],
          BezelPosition.bottom: ['performance-mode'],
        },
      ),
      parameterBindings: _getDefaultParameterBindings(),
      visualizerConfig: VisualizerConfig.defaultConfig(),
      uiTheme: UIThemeConfig.defaultTheme(),
    );

    // Performance-focused layout
    final performancePreset = LayoutPreset(
      id: 'performance',
      name: 'Performance',
      description: 'Optimized for live performance',
      category: PresetCategory.performance,
      isSystemPreset: true,
      layoutConfig: LayoutConfig(
        paneRatios: [0.6, 0.15, 0.25],
        activePanes: {
          PanePosition.top: PaneType.xyPad,
          PanePosition.middle: PaneType.miniControls,
          PanePosition.bottom: PaneType.drumPads,
        },
        collapsedPanes: {},
        bezelTabs: {
          BezelPosition.left: ['effects', 'quick-presets'],
          BezelPosition.right: ['performance-monitor'],
          BezelPosition.top: ['layouts'],
          BezelPosition.bottom: [],
        },
      ),
      parameterBindings: _getPerformanceParameterBindings(),
      visualizerConfig: VisualizerConfig(
        preset: 'performance',
        opacity: 0.8,
        effectsEnabled: true,
        reactiveSensitivity: 1.5,
      ),
      uiTheme: UIThemeConfig(
        primaryColor: DesignTokens.neonPink,
        accentColor: DesignTokens.neonCyan,
        backgroundOpacity: 0.3,
        glowIntensity: 1.2,
      ),
    );

    // Sound design focused layout
    final soundDesignPreset = LayoutPreset(
      id: 'sound_design',
      name: 'Sound Design',
      description: 'Detailed controls for sound design',
      category: PresetCategory.soundDesign,
      isSystemPreset: true,
      layoutConfig: LayoutConfig(
        paneRatios: [0.3, 0.5, 0.2],
        activePanes: {
          PanePosition.top: PaneType.xyPad,
          PanePosition.middle: PaneType.detailedControls,
          PanePosition.bottom: PaneType.piano,
        },
        collapsedPanes: {},
        bezelTabs: {
          BezelPosition.left: ['parameter-vault', 'modulation'],
          BezelPosition.right: ['analyzer', 'effects'],
          BezelPosition.top: ['layouts', 'presets'],
          BezelPosition.bottom: ['export', 'settings'],
        },
      ),
      parameterBindings: _getSoundDesignParameterBindings(),
      visualizerConfig: VisualizerConfig(
        preset: 'minimal',
        opacity: 0.4,
        effectsEnabled: false,
        reactiveSensitivity: 0.8,
      ),
      uiTheme: UIThemeConfig(
        primaryColor: DesignTokens.neonOrange,
        accentColor: DesignTokens.neonGreen,
        backgroundOpacity: 0.1,
        glowIntensity: 0.6,
      ),
    );

    // Touch-optimized layout
    final touchPreset = LayoutPreset(
      id: 'touch_grid',
      name: 'Touch Grid',
      description: 'Optimized for touch interaction',
      category: PresetCategory.live,
      isSystemPreset: true,
      layoutConfig: LayoutConfig(
        paneRatios: [0.25, 0.25, 0.5],
        activePanes: {
          PanePosition.top: PaneType.miniXY,
          PanePosition.middle: PaneType.essentialControls,
          PanePosition.bottom: PaneType.touchGrid,
        },
        collapsedPanes: {},
        bezelTabs: {
          BezelPosition.left: ['quick-effects'],
          BezelPosition.right: ['volume'],
          BezelPosition.top: ['layouts'],
          BezelPosition.bottom: ['record'],
        },
      ),
      parameterBindings: _getTouchParameterBindings(),
      visualizerConfig: VisualizerConfig(
        preset: 'performance',
        opacity: 0.9,
        effectsEnabled: true,
        reactiveSensitivity: 2.0,
      ),
      uiTheme: UIThemeConfig(
        primaryColor: DesignTokens.neonCyan,
        accentColor: DesignTokens.neonPurple,
        backgroundOpacity: 0.4,
        glowIntensity: 1.0,
      ),
    );

    _presets['default'] = defaultPreset;
    _presets['performance'] = performancePreset;
    _presets['sound_design'] = soundDesignPreset;
    _presets['touch_grid'] = touchPreset;

    _categorizedPresets[PresetCategory.system]!.addAll([
      'default', 'performance', 'sound_design', 'touch_grid'
    ]);
  }

  /// Save a new preset
  Future<bool> savePreset(LayoutPreset preset) async {
    try {
      // Validate preset
      if (preset.id.isEmpty || preset.name.isEmpty) {
        throw ArgumentError('Preset must have valid id and name');
      }

      // Add timestamp if new preset
      if (!_presets.containsKey(preset.id)) {
        preset = preset.copyWith(
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
      } else {
        preset = preset.copyWith(
          modifiedAt: DateTime.now(),
        );
      }

      // Save to memory
      _presets[preset.id] = preset;
      
      // Update categories
      _updatePresetCategories(preset);

      // Save to persistent storage
      await _savePresetsToStorage();

      notifyListeners();
      debugPrint('Preset saved: ${preset.name} (${preset.id})');
      return true;
    } catch (error) {
      debugPrint('Error saving preset: $error');
      return false;
    }
  }

  /// Load a preset and make it active
  Future<bool> loadPreset(String presetId) async {
    try {
      final preset = _presets[presetId];
      if (preset == null) {
        debugPrint('Preset not found: $presetId');
        return false;
      }

      _activePreset = preset;
      
      // Save as last active
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_active_preset', presetId);

      notifyListeners();
      debugPrint('Preset loaded: ${preset.name}');
      return true;
    } catch (error) {
      debugPrint('Error loading preset: $error');
      return false;
    }
  }

  /// Delete a preset
  Future<bool> deletePreset(String presetId) async {
    try {
      final preset = _presets[presetId];
      if (preset == null) {
        return false;
      }

      // Cannot delete system presets
      if (preset.isSystemPreset) {
        debugPrint('Cannot delete system preset: $presetId');
        return false;
      }

      // Cannot delete active preset
      if (_activePreset?.id == presetId) {
        debugPrint('Cannot delete active preset: $presetId');
        return false;
      }

      _presets.remove(presetId);
      _removeFromCategories(presetId);
      
      await _savePresetsToStorage();
      notifyListeners();
      
      debugPrint('Preset deleted: $presetId');
      return true;
    } catch (error) {
      debugPrint('Error deleting preset: $error');
      return false;
    }
  }

  /// Duplicate a preset
  Future<String?> duplicatePreset(String sourceId, {String? newName}) async {
    try {
      final sourcePreset = _presets[sourceId];
      if (sourcePreset == null) return null;

      final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final duplicatedName = newName ?? '${sourcePreset.name} Copy';

      final newPreset = sourcePreset.copyWith(
        id: newId,
        name: duplicatedName,
        description: 'Copy of ${sourcePreset.name}',
        category: PresetCategory.user,
        isSystemPreset: false,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      final success = await savePreset(newPreset);
      return success ? newId : null;
    } catch (error) {
      debugPrint('Error duplicating preset: $error');
      return null;
    }
  }

  /// Export preset to JSON
  String exportPreset(String presetId) {
    final preset = _presets[presetId];
    if (preset == null) {
      throw ArgumentError('Preset not found: $presetId');
    }

    return jsonEncode(preset.toJson());
  }

  /// Import preset from JSON
  Future<String?> importPreset(String jsonData, {String? newName}) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      var preset = LayoutPreset.fromJson(data);

      // Generate new ID for imported preset
      final newId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
      preset = preset.copyWith(
        id: newId,
        name: newName ?? '${preset.name} (Imported)',
        category: PresetCategory.user,
        isSystemPreset: false,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      final success = await savePreset(preset);
      return success ? newId : null;
    } catch (error) {
      debugPrint('Error importing preset: $error');
      return null;
    }
  }

  /// Get presets by category
  List<LayoutPreset> getPresetsByCategory(PresetCategory category) {
    final presetIds = _categorizedPresets[category] ?? [];
    return presetIds
        .map((id) => _presets[id])
        .where((preset) => preset != null)
        .cast<LayoutPreset>()
        .toList();
  }

  /// Search presets
  List<LayoutPreset> searchPresets(String query) {
    if (query.isEmpty) return _presets.values.toList();

    final lowercaseQuery = query.toLowerCase();
    return _presets.values.where((preset) {
      return preset.name.toLowerCase().contains(lowercaseQuery) ||
             preset.description.toLowerCase().contains(lowercaseQuery) ||
             preset.category.displayName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Auto-save current state as temp preset
  Future<void> autoSaveCurrentState() async {
    if (!_autoSaveEnabled) return;

    try {
      // Create auto-save preset
      final autoSavePreset = LayoutPreset(
        id: 'auto_save',
        name: 'Auto Save',
        description: 'Automatically saved current state',
        category: PresetCategory.user,
        isSystemPreset: false,
        layoutConfig: _getCurrentLayoutConfig(),
        parameterBindings: _getCurrentParameterBindings(),
        visualizerConfig: _getCurrentVisualizerConfig(),
        uiTheme: _getCurrentUITheme(),
      );

      _presets['auto_save'] = autoSavePreset;
      await _savePresetsToStorage();
    } catch (error) {
      debugPrint('Error auto-saving: $error');
    }
  }

  /// Enable/disable auto-save
  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled = enabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_save_enabled', enabled);
    
    notifyListeners();
  }

  /// Load presets from persistent storage
  Future<void> _loadPresetsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString('layout_presets');
      
      if (presetsJson != null) {
        final data = jsonDecode(presetsJson) as Map<String, dynamic>;
        
        for (final entry in data.entries) {
          try {
            final preset = LayoutPreset.fromJson(entry.value);
            _presets[entry.key] = preset;
            _updatePresetCategories(preset);
          } catch (error) {
            debugPrint('Error loading preset ${entry.key}: $error');
          }
        }
      }

      // Load auto-save setting
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;
      
      debugPrint('Loaded ${_presets.length} presets from storage');
    } catch (error) {
      debugPrint('Error loading presets from storage: $error');
    }
  }

  /// Save presets to persistent storage
  Future<void> _savePresetsToStorage() async {
    try {
      final data = <String, dynamic>{};
      
      for (final entry in _presets.entries) {
        data[entry.key] = entry.value.toJson();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('layout_presets', jsonEncode(data));
    } catch (error) {
      debugPrint('Error saving presets to storage: $error');
    }
  }

  /// Update preset categories
  void _updatePresetCategories(LayoutPreset preset) {
    // Remove from all categories first
    _removeFromCategories(preset.id);
    
    // Add to appropriate category
    _categorizedPresets[preset.category]?.add(preset.id);
  }

  /// Remove preset from all categories
  void _removeFromCategories(String presetId) {
    for (final categoryList in _categorizedPresets.values) {
      categoryList.remove(presetId);
    }
  }

  /// Get current layout configuration
  LayoutConfig _getCurrentLayoutConfig() {
    // This would be implemented to get current UI state
    // For now, return default config
    return LayoutConfig.defaultConfig();
  }

  /// Get current parameter bindings
  Map<String, dynamic> _getCurrentParameterBindings() {
    final bridge = ParameterVisualizerBridge();
    return bridge.exportBindings();
  }

  /// Get current visualizer configuration
  VisualizerConfig _getCurrentVisualizerConfig() {
    return VisualizerConfig.defaultConfig();
  }

  /// Get current UI theme
  UIThemeConfig _getCurrentUITheme() {
    return UIThemeConfig.defaultTheme();
  }

  /// Default parameter bindings
  Map<String, dynamic> _getDefaultParameterBindings() {
    final bridge = ParameterVisualizerBridge();
    bridge.initialize(visualizerUpdateCallback: (_, __) {});
    return bridge.exportBindings();
  }

  /// Performance-optimized parameter bindings
  Map<String, dynamic> _getPerformanceParameterBindings() {
    // High-intensity bindings for live performance
    return {
      'bindings': {
        'xyPadX': {
          'visualizerParameter': 'rotationX',
          'type': 0, // Direct
          'scale': 360.0,
          'offset': 0.0,
        },
        'xyPadY': {
          'visualizerParameter': 'rotationY',
          'type': 0,
          'scale': 360.0,
          'offset': 0.0,
        },
        'masterVolume': {
          'visualizerParameter': 'patternIntensity',
          'type': 1, // Exponential
          'scale': 3.0,
          'offset': 0.0,
        },
      },
    };
  }

  /// Sound design focused parameter bindings
  Map<String, dynamic> _getSoundDesignParameterBindings() {
    return {
      'bindings': {
        'filterCutoff': {
          'visualizerParameter': 'lineThickness',
          'type': 4, // Logarithmic
          'scale': 0.095,
          'offset': 0.005,
        },
        'filterResonance': {
          'visualizerParameter': 'glitchIntensity',
          'type': 3, // Exponential
          'scale': 0.15,
          'offset': 0.0,
        },
      },
    };
  }

  /// Touch-optimized parameter bindings
  Map<String, dynamic> _getTouchParameterBindings() {
    return {
      'bindings': {
        'touchPad1': {
          'visualizerParameter': 'dimension',
          'type': 2, // Curved
          'scale': 2.0,
          'offset': 3.0,
        },
        'touchPad2': {
          'visualizerParameter': 'morphFactor',
          'type': 0, // Direct
          'scale': 1.5,
          'offset': 0.0,
        },
      },
    };
  }

  @override
  void dispose() {
    _presets.clear();
    _categorizedPresets.clear();
    super.dispose();
  }
}

/// Layout preset data model
class LayoutPreset {
  final String id;
  final String name;
  final String description;
  final PresetCategory category;
  final bool isSystemPreset;
  final LayoutConfig layoutConfig;
  final Map<String, dynamic> parameterBindings;
  final VisualizerConfig visualizerConfig;
  final UIThemeConfig uiTheme;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const LayoutPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isSystemPreset = false,
    required this.layoutConfig,
    required this.parameterBindings,
    required this.visualizerConfig,
    required this.uiTheme,
    this.createdAt,
    this.modifiedAt,
  });

  LayoutPreset copyWith({
    String? id,
    String? name,
    String? description,
    PresetCategory? category,
    bool? isSystemPreset,
    LayoutConfig? layoutConfig,
    Map<String, dynamic>? parameterBindings,
    VisualizerConfig? visualizerConfig,
    UIThemeConfig? uiTheme,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return LayoutPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isSystemPreset: isSystemPreset ?? this.isSystemPreset,
      layoutConfig: layoutConfig ?? this.layoutConfig,
      parameterBindings: parameterBindings ?? this.parameterBindings,
      visualizerConfig: visualizerConfig ?? this.visualizerConfig,
      uiTheme: uiTheme ?? this.uiTheme,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'isSystemPreset': isSystemPreset,
      'layoutConfig': layoutConfig.toJson(),
      'parameterBindings': parameterBindings,
      'visualizerConfig': visualizerConfig.toJson(),
      'uiTheme': uiTheme.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory LayoutPreset.fromJson(Map<String, dynamic> json) {
    return LayoutPreset(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: PresetCategory.values[json['category'] ?? 0],
      isSystemPreset: json['isSystemPreset'] ?? false,
      layoutConfig: LayoutConfig.fromJson(json['layoutConfig']),
      parameterBindings: Map<String, dynamic>.from(json['parameterBindings']),
      visualizerConfig: VisualizerConfig.fromJson(json['visualizerConfig']),
      uiTheme: UIThemeConfig.fromJson(json['uiTheme']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt']) : null,
    );
  }
}

/// Layout configuration data
class LayoutConfig {
  final List<double> paneRatios;
  final Map<PanePosition, PaneType> activePanes;
  final Set<PanePosition> collapsedPanes;
  final Map<BezelPosition, List<String>> bezelTabs;

  const LayoutConfig({
    required this.paneRatios,
    required this.activePanes,
    required this.collapsedPanes,
    required this.bezelTabs,
  });

  factory LayoutConfig.defaultConfig() {
    return LayoutConfig(
      paneRatios: [0.45, 0.30, 0.25],
      activePanes: {
        PanePosition.top: PaneType.xyPad,
        PanePosition.middle: PaneType.controls,
        PanePosition.bottom: PaneType.drumPads,
      },
      collapsedPanes: {},
      bezelTabs: {
        BezelPosition.left: ['parameter-vault'],
        BezelPosition.right: ['presets'],
        BezelPosition.top: ['layouts'],
        BezelPosition.bottom: [],
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paneRatios': paneRatios,
      'activePanes': activePanes.map((k, v) => MapEntry(k.index, v.index)),
      'collapsedPanes': collapsedPanes.map((p) => p.index).toList(),
      'bezelTabs': bezelTabs.map((k, v) => MapEntry(k.index, v)),
    };
  }

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      paneRatios: List<double>.from(json['paneRatios']),
      activePanes: Map.fromEntries(
        (json['activePanes'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            PanePosition.values[int.parse(e.key)],
            PaneType.values[e.value],
          ),
        ),
      ),
      collapsedPanes: Set.from(
        (json['collapsedPanes'] as List).map((i) => PanePosition.values[i]),
      ),
      bezelTabs: Map.fromEntries(
        (json['bezelTabs'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            BezelPosition.values[int.parse(e.key)],
            List<String>.from(e.value),
          ),
        ),
      ),
    );
  }
}

/// Visualizer configuration data
class VisualizerConfig {
  final String preset;
  final double opacity;
  final bool effectsEnabled;
  final double reactiveSensitivity;

  const VisualizerConfig({
    required this.preset,
    required this.opacity,
    required this.effectsEnabled,
    required this.reactiveSensitivity,
  });

  factory VisualizerConfig.defaultConfig() {
    return const VisualizerConfig(
      preset: 'default',
      opacity: 0.6,
      effectsEnabled: true,
      reactiveSensitivity: 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset,
      'opacity': opacity,
      'effectsEnabled': effectsEnabled,
      'reactiveSensitivity': reactiveSensitivity,
    };
  }

  factory VisualizerConfig.fromJson(Map<String, dynamic> json) {
    return VisualizerConfig(
      preset: json['preset'] ?? 'default',
      opacity: json['opacity']?.toDouble() ?? 0.6,
      effectsEnabled: json['effectsEnabled'] ?? true,
      reactiveSensitivity: json['reactiveSensitivity']?.toDouble() ?? 1.0,
    );
  }
}

/// UI theme configuration
class UIThemeConfig {
  final Color primaryColor;
  final Color accentColor;
  final double backgroundOpacity;
  final double glowIntensity;

  const UIThemeConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundOpacity,
    required this.glowIntensity,
  });

  factory UIThemeConfig.defaultTheme() {
    return UIThemeConfig(
      primaryColor: DesignTokens.neonCyan,
      accentColor: DesignTokens.neonPurple,
      backgroundOpacity: 0.2,
      glowIntensity: 0.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor.value,
      'accentColor': accentColor.value,
      'backgroundOpacity': backgroundOpacity,
      'glowIntensity': glowIntensity,
    };
  }

  factory UIThemeConfig.fromJson(Map<String, dynamic> json) {
    return UIThemeConfig(
      primaryColor: Color(json['primaryColor'] ?? DesignTokens.neonCyan.value),
      accentColor: Color(json['accentColor'] ?? DesignTokens.neonPurple.value),
      backgroundOpacity: json['backgroundOpacity']?.toDouble() ?? 0.2,
      glowIntensity: json['glowIntensity']?.toDouble() ?? 0.8,
    );
  }
}

/// Preset categories for organization
enum PresetCategory {
  system,
  user,
  performance,
  soundDesign,
  live,
}

extension PresetCategoryExtension on PresetCategory {
  String get displayName {
    switch (this) {
      case PresetCategory.system:
        return 'System';
      case PresetCategory.user:
        return 'User';
      case PresetCategory.performance:
        return 'Performance';
      case PresetCategory.soundDesign:
        return 'Sound Design';
      case PresetCategory.live:
        return 'Live';
    }
  }

  Color get color {
    switch (this) {
      case PresetCategory.system:
        return DesignTokens.neonBlue;
      case PresetCategory.user:
        return DesignTokens.neonCyan;
      case PresetCategory.performance:
        return DesignTokens.neonPink;
      case PresetCategory.soundDesign:
        return DesignTokens.neonOrange;
      case PresetCategory.live:
        return DesignTokens.neonGreen;
    }
  }
}

/// UI pane positions
enum PanePosition { top, middle, bottom }

/// UI pane types
enum PaneType {
  xyPad,
  miniXY,
  controls,
  miniControls,
  detailedControls,
  essentialControls,
  drumPads,
  touchGrid,
  piano,
}

/// Bezel positions
enum BezelPosition { left, right, top, bottom }