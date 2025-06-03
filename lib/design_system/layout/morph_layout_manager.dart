import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/components.dart';

/// Morph-UI adaptive tri-pane layout manager
/// Manages three resizable panes with RGB drag bars
class MorphLayoutManager extends StatefulWidget {
  final Widget? topPane;
  final Widget? middlePane;
  final Widget? bottomPane;
  final MorphLayoutPreset initialPreset;
  final ValueChanged<MorphLayoutPreset>? onLayoutChanged;
  final bool enableAnimation;
  final Duration animationDuration;
  
  const MorphLayoutManager({
    Key? key,
    this.topPane,
    this.middlePane,
    this.bottomPane,
    this.initialPreset = const MorphLayoutPreset(),
    this.onLayoutChanged,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  State<MorphLayoutManager> createState() => _MorphLayoutManagerState();
}

class _MorphLayoutManagerState extends State<MorphLayoutManager> {
  late MorphLayoutPreset _currentPreset;
  bool _isDraggingTop = false;
  bool _isDraggingBottom = false;
  
  // Minimum pane heights
  static const double _minPaneHeight = 50.0;
  static const double _dragBarHeight = 6.0;
  
  @override
  void initState() {
    super.initState();
    _currentPreset = widget.initialPreset;
  }
  
  void _handleTopDragUpdate(double delta) {
    setState(() {
      final totalHeight = MediaQuery.of(context).size.height;
      final availableHeight = totalHeight - (2 * _dragBarHeight);
      
      // Calculate new ratios
      double newTopRatio = _currentPreset.topRatio + (delta / availableHeight);
      double newMiddleRatio = _currentPreset.middleRatio - (delta / availableHeight);
      
      // Apply constraints
      final minRatio = _minPaneHeight / availableHeight;
      
      if (newTopRatio >= minRatio && newMiddleRatio >= minRatio) {
        _currentPreset = _currentPreset.copyWith(
          topRatio: newTopRatio,
          middleRatio: newMiddleRatio,
        );
        
        widget.onLayoutChanged?.call(_currentPreset);
      }
    });
  }
  
  void _handleBottomDragUpdate(double delta) {
    setState(() {
      final totalHeight = MediaQuery.of(context).size.height;
      final availableHeight = totalHeight - (2 * _dragBarHeight);
      
      // Calculate new ratios
      double newMiddleRatio = _currentPreset.middleRatio + (delta / availableHeight);
      double newBottomRatio = _currentPreset.bottomRatio - (delta / availableHeight);
      
      // Apply constraints
      final minRatio = _minPaneHeight / availableHeight;
      
      if (newMiddleRatio >= minRatio && newBottomRatio >= minRatio) {
        _currentPreset = _currentPreset.copyWith(
          middleRatio: newMiddleRatio,
          bottomRatio: newBottomRatio,
        );
        
        widget.onLayoutChanged?.call(_currentPreset);
      }
    });
  }
  
  Widget _buildPane(Widget? content, double ratio, MorphPaneType type) {
    if (content == null) return const SizedBox.shrink();
    
    final color = _getPaneColor(type);
    final isCollapsed = _isPaneCollapsed(type);
    
    return Flexible(
      flex: (ratio * 1000).round(),
      child: AnimatedContainer(
        duration: widget.enableAnimation ? widget.animationDuration : Duration.zero,
        curve: Curves.easeInOut,
        child: GlassmorphicPane(
          tintColor: color,
          opacity: 0.08,
          blurIntensity: 12.0,
          isCollapsed: isCollapsed,
          padding: const EdgeInsets.all(12),
          margin: EdgeInsets.zero,
          borderRadius: 0,
          showBorder: false,
          child: content,
        ),
      ),
    );
  }
  
  Color _getPaneColor(MorphPaneType type) {
    switch (type) {
      case MorphPaneType.top:
        return DesignTokens.neonCyan;
      case MorphPaneType.middle:
        return DesignTokens.neonPurple;
      case MorphPaneType.bottom:
        return DesignTokens.neonPink;
    }
  }
  
  bool _isPaneCollapsed(MorphPaneType type) {
    switch (type) {
      case MorphPaneType.top:
        return _currentPreset.topCollapsed;
      case MorphPaneType.middle:
        return _currentPreset.middleCollapsed;
      case MorphPaneType.bottom:
        return _currentPreset.bottomCollapsed;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top pane
        _buildPane(widget.topPane, _currentPreset.topRatio, MorphPaneType.top),
        
        // Top drag bar
        if (!_currentPreset.topCollapsed && !_currentPreset.middleCollapsed)
          SizedBox(
            height: _dragBarHeight,
            child: RGBDragBar(
              orientation: Axis.horizontal,
              onDragStart: () => setState(() => _isDraggingTop = true),
              onDragUpdate: _handleTopDragUpdate,
              onDragEnd: () => setState(() => _isDraggingTop = false),
            ),
          ),
        
        // Middle pane
        _buildPane(widget.middlePane, _currentPreset.middleRatio, MorphPaneType.middle),
        
        // Bottom drag bar
        if (!_currentPreset.middleCollapsed && !_currentPreset.bottomCollapsed)
          SizedBox(
            height: _dragBarHeight,
            child: RGBDragBar(
              orientation: Axis.horizontal,
              onDragStart: () => setState(() => _isDraggingBottom = true),
              onDragUpdate: _handleBottomDragUpdate,
              onDragEnd: () => setState(() => _isDraggingBottom = false),
            ),
          ),
        
        // Bottom pane
        _buildPane(widget.bottomPane, _currentPreset.bottomRatio, MorphPaneType.bottom),
      ],
    );
  }
}

/// Layout preset data model
class MorphLayoutPreset {
  final String id;
  final String name;
  final double topRatio;
  final double middleRatio;
  final double bottomRatio;
  final bool topCollapsed;
  final bool middleCollapsed;
  final bool bottomCollapsed;
  final Map<String, dynamic> customData;
  
  const MorphLayoutPreset({
    this.id = 'default',
    this.name = 'Default',
    this.topRatio = 0.45,
    this.middleRatio = 0.30,
    this.bottomRatio = 0.25,
    this.topCollapsed = false,
    this.middleCollapsed = false,
    this.bottomCollapsed = false,
    this.customData = const {},
  });
  
  MorphLayoutPreset copyWith({
    String? id,
    String? name,
    double? topRatio,
    double? middleRatio,
    double? bottomRatio,
    bool? topCollapsed,
    bool? middleCollapsed,
    bool? bottomCollapsed,
    Map<String, dynamic>? customData,
  }) {
    return MorphLayoutPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      topRatio: topRatio ?? this.topRatio,
      middleRatio: middleRatio ?? this.middleRatio,
      bottomRatio: bottomRatio ?? this.bottomRatio,
      topCollapsed: topCollapsed ?? this.topCollapsed,
      middleCollapsed: middleCollapsed ?? this.middleCollapsed,
      bottomCollapsed: bottomCollapsed ?? this.bottomCollapsed,
      customData: customData ?? this.customData,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'topRatio': topRatio,
      'middleRatio': middleRatio,
      'bottomRatio': bottomRatio,
      'topCollapsed': topCollapsed,
      'middleCollapsed': middleCollapsed,
      'bottomCollapsed': bottomCollapsed,
      'customData': customData,
    };
  }
  
  factory MorphLayoutPreset.fromJson(Map<String, dynamic> json) {
    return MorphLayoutPreset(
      id: json['id'] ?? 'default',
      name: json['name'] ?? 'Default',
      topRatio: json['topRatio']?.toDouble() ?? 0.45,
      middleRatio: json['middleRatio']?.toDouble() ?? 0.30,
      bottomRatio: json['bottomRatio']?.toDouble() ?? 0.25,
      topCollapsed: json['topCollapsed'] ?? false,
      middleCollapsed: json['middleCollapsed'] ?? false,
      bottomCollapsed: json['bottomCollapsed'] ?? false,
      customData: json['customData'] ?? {},
    );
  }
}

/// Predefined layout presets
class MorphLayoutPresets {
  static const MorphLayoutPreset defaultLayout = MorphLayoutPreset();
  
  static const MorphLayoutPreset xyFocus = MorphLayoutPreset(
    id: 'xy_focus',
    name: 'XY Focus',
    topRatio: 0.60,
    middleRatio: 0.25,
    bottomRatio: 0.15,
  );
  
  static const MorphLayoutPreset pianoFocus = MorphLayoutPreset(
    id: 'piano_focus',
    name: 'Piano Focus',
    topRatio: 0.15,
    middleRatio: 0.25,
    bottomRatio: 0.60,
    topCollapsed: true,
  );
  
  static const MorphLayoutPreset soundDesign = MorphLayoutPreset(
    id: 'sound_design',
    name: 'Sound Design',
    topRatio: 0.40,
    middleRatio: 0.45,
    bottomRatio: 0.15,
    bottomCollapsed: true,
  );
  
  static const MorphLayoutPreset performance = MorphLayoutPreset(
    id: 'performance',
    name: 'Performance',
    topRatio: 0.33,
    middleRatio: 0.33,
    bottomRatio: 0.34,
    topCollapsed: true,
    middleCollapsed: true,
    bottomCollapsed: true,
  );
  
  static const MorphLayoutPreset touchGrid = MorphLayoutPreset(
    id: 'touch_grid',
    name: 'Touch Grid',
    topRatio: 0.50,
    middleRatio: 0.20,
    bottomRatio: 0.30,
  );
}

/// Pane type enumeration
enum MorphPaneType {
  top,
  middle,
  bottom,
}

/// Animated pane transition widget
class AnimatedMorphPane extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final Curve curve;
  
  const AnimatedMorphPane({
    Key? key,
    required this.child,
    this.isVisible = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve.flipped,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isVisible
          ? KeyedSubtree(
              key: const ValueKey('visible'),
              child: child,
            )
          : const SizedBox.shrink(
              key: ValueKey('hidden'),
            ),
    );
  }
}