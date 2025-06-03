import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';
import '../../core/parameter_visualizer_bridge.dart';
import '../../design_system/design_system.dart';

/// Advanced visualizer bridge for Morph-UI integration
/// This component creates the seamless connection between Flutter UI and 4D visualizer
class MorphUIVisualizerBridge extends StatefulWidget {
  final Widget? child;
  final bool enableBackground;
  final double backgroundOpacity;
  final bool enableTinting;
  final Function(String, Color, double)? onParameterTint;
  
  const MorphUIVisualizerBridge({
    Key? key,
    this.child,
    this.enableBackground = true,
    this.backgroundOpacity = 0.6,
    this.enableTinting = true,
    this.onParameterTint,
  }) : super(key: key);
  
  @override
  State<MorphUIVisualizerBridge> createState() => _MorphUIVisualizerBridgeState();
}

class _MorphUIVisualizerBridgeState extends State<MorphUIVisualizerBridge> 
    with TickerProviderStateMixin {
  late html.IFrameElement _iFrameElement;
  final String _viewType = 'morph-ui-visualizer';
  bool _isVisualizerReady = false;
  bool _isBridgeInitialized = false;
  
  late AnimationController _connectionController;
  late AnimationController _tintController;
  late Animation<double> _connectionAnimation;
  late Animation<double> _tintAnimation;
  
  final ParameterVisualizerBridge _parameterBridge = ParameterVisualizerBridge();
  final Map<String, Color> _activeTints = {};
  
  @override
  void initState() {
    super.initState();
    
    _connectionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _tintController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _connectionAnimation = CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeInOut,
    );
    
    _tintAnimation = CurvedAnimation(
      parent: _tintController,
      curve: Curves.easeInOut,
    );
    
    _setupVisualizer();
    _initializeParameterBridge();
  }
  
  void _setupVisualizer() {
    _iFrameElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = widget.child != null ? 'none' : 'auto'
      ..src = 'assets/visualizer/index-flutter.html'
      ..onLoad.listen((_) {
        _handleVisualizerLoaded();
      });
    
    // Register with Flutter's platform view system
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iFrameElement,
    );
  }
  
  void _handleVisualizerLoaded() {
    setState(() {
      _isVisualizerReady = true;
    });
    
    // Set up bidirectional communication
    _setupMessageHandling();
    
    // Start connection animation
    _connectionController.forward();
    
    // Initialize visualizer with default parameters
    _initializeVisualizerDefaults();
    
    debugPrint('MorphUI Visualizer loaded and ready');
  }
  
  void _setupMessageHandling() {
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;
      
      if (data is Map) {
        switch (data['type']) {
          case 'visualizer_ready':
            _handleVisualizerReady();
            break;
          case 'parameter_feedback':
            _handleParameterFeedback(data);
            break;
          case 'performance_stats':
            _handlePerformanceStats(data);
            break;
        }
      }
    });
  }
  
  void _handleVisualizerReady() {
    setState(() {
      _isBridgeInitialized = true;
    });
    
    debugPrint('Visualizer bridge fully initialized');
  }
  
  void _handleParameterFeedback(Map data) {
    // Handle feedback from visualizer (e.g., automatic parameter adjustments)
    final parameter = data['parameter'] as String?;
    final value = data['value'] as double?;
    
    if (parameter != null && value != null) {
      // Update UI to reflect visualizer feedback
      debugPrint('Visualizer feedback: $parameter = $value');
    }
  }
  
  void _handlePerformanceStats(Map data) {
    // Monitor visualizer performance
    final fps = data['fps'] as double?;
    final drawCalls = data['drawCalls'] as int?;
    
    if (fps != null && fps < 30) {
      debugPrint('Warning: Visualizer FPS low ($fps)');
    }
  }
  
  void _initializeParameterBridge() {
    _parameterBridge.initialize(
      visualizerUpdateCallback: _updateVisualizerParameter,
      uiTintCallback: widget.enableTinting ? _handleUITinting : null,
    );
    
    debugPrint('Parameter bridge initialized with ${_parameterBridge.bindings.length} bindings');
  }
  
  void _updateVisualizerParameter(String parameter, double value) {
    if (!_isVisualizerReady || !_isBridgeInitialized) return;
    
    try {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'updateParameter',
        'parameter': parameter,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
    } catch (e) {
      debugPrint('Error updating visualizer parameter: $e');
    }
  }
  
  void _handleUITinting(String parameter, Color color, double intensity) {
    setState(() {
      if (intensity > 0.1) {
        _activeTints[parameter] = color.withOpacity(intensity * 0.3);
      } else {
        _activeTints.remove(parameter);
      }
    });
    
    // Trigger tint animation
    _tintController.forward().then((_) {
      _tintController.reverse();
    });
    
    // Notify parent widget
    widget.onParameterTint?.call(parameter, color, intensity);
  }
  
  void _initializeVisualizerDefaults() {
    // Send initial configuration to visualizer
    _iFrameElement.contentWindow?.postMessage({
      'type': 'configure',
      'config': {
        'enablePerformanceMonitoring': true,
        'targetFPS': 60,
        'adaptiveQuality': true,
        'enableFeedback': true,
      }
    }, '*');
    
    // Apply default parameter values
    final defaultParams = {
      'dimension': 4.0,
      'morphFactor': 0.7,
      'rotationSpeed': 0.5,
      'gridDensity': 8.0,
      'lineThickness': 0.03,
      'patternIntensity': 1.3,
      'universeModifier': 1.0,
      'colorShift': 0.0,
      'glitchIntensity': 0.02,
    };
    
    for (final entry in defaultParams.entries) {
      _updateVisualizerParameter(entry.key, entry.value);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _parameterBridge,
      child: Consumer<SynthParametersModel>(
        builder: (context, synthModel, child) {
          // Update parameter bridge with latest values
          _syncParametersFromSynth(synthModel);
          
          return Stack(
            children: [
              // Visualizer background (always visible in Morph-UI)
              if (widget.enableBackground) _buildVisualizerBackground(),
              
              // UI content overlay
              if (widget.child != null) _buildUIOverlay(),
              
              // Connection status indicator
              if (!_isBridgeInitialized) _buildConnectionIndicator(),
              
              // Parameter tinting overlay
              if (widget.enableTinting && _activeTints.isNotEmpty)
                _buildTintingOverlay(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildVisualizerBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _connectionAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: widget.backgroundOpacity * _connectionAnimation.value,
            child: HtmlElementView(
              viewType: _viewType,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUIOverlay() {
    return Positioned.fill(
      child: widget.child!,
    );
  }
  
  Widget _buildConnectionIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _connectionAnimation,
        builder: (context, child) {
          return GlassmorphicPane(
            width: 120,
            height: 32,
            tintColor: _isVisualizerReady ? DesignTokens.neonGreen : DesignTokens.neonOrange,
            opacity: 0.8,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      _isVisualizerReady ? DesignTokens.neonGreen : DesignTokens.neonOrange
                    ),
                    value: _isVisualizerReady ? 1.0 : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isVisualizerReady ? 'Connected' : 'Connecting...',
                  style: SyntherTypography.caption.copyWith(
                    color: _isVisualizerReady ? DesignTokens.neonGreen : DesignTokens.neonOrange,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTintingOverlay() {
    return AnimatedBuilder(
      animation: _tintAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ..._activeTints.values,
                  Colors.transparent,
                ].take(4).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _syncParametersFromSynth(SynthParametersModel synthModel) {
    if (!_parameterBridge.isConnected) return;
    
    // Update all parameters through the bridge
    _parameterBridge.updateParameter('xyPadX', synthModel.xyPadX);
    _parameterBridge.updateParameter('xyPadY', synthModel.xyPadY);
    _parameterBridge.updateParameter('filterCutoff', synthModel.filterCutoff / 20000);
    _parameterBridge.updateParameter('filterResonance', synthModel.filterResonance);
    _parameterBridge.updateParameter('attackTime', synthModel.attackTime / 2.0);
    _parameterBridge.updateParameter('releaseTime', synthModel.releaseTime / 2.0);
    _parameterBridge.updateParameter('masterVolume', synthModel.masterVolume);
    _parameterBridge.updateParameter('reverbMix', synthModel.reverbMix);
    _parameterBridge.updateParameter('delayMix', synthModel.delayMix);
    
    // Update oscillator parameters
    if (synthModel.oscillators.isNotEmpty) {
      final osc = synthModel.oscillators[0];
      _parameterBridge.updateParameter('oscillatorDetune', osc.detune / 100.0);
    }
  }
  
  /// Manually trigger a parameter update (for external control)
  void updateParameter(String parameter, double value) {
    _parameterBridge.updateParameter(parameter, value);
  }
  
  /// Get the parameter bridge instance for external configuration
  ParameterVisualizerBridge get parameterBridge => _parameterBridge;
  
  /// Force refresh the visualizer
  void refreshVisualizer() {
    if (_isVisualizerReady) {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'refresh',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
    }
  }
  
  /// Toggle visualizer effects
  void toggleEffect(String effectName) {
    if (_isVisualizerReady) {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'toggleEffect',
        'effect': effectName,
      }, '*');
    }
  }
  
  /// Reset visualizer to default state
  void resetVisualizer() {
    if (_isVisualizerReady) {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'reset',
      }, '*');
      
      _initializeVisualizerDefaults();
    }
  }
  
  @override
  void dispose() {
    _connectionController.dispose();
    _tintController.dispose();
    _parameterBridge.dispose();
    super.dispose();
  }
}

/// Simplified wrapper for using visualizer as background only
class VisualizerBackground extends StatelessWidget {
  final double opacity;
  final bool enableTinting;
  
  const VisualizerBackground({
    Key? key,
    this.opacity = 0.3,
    this.enableTinting = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MorphUIVisualizerBridge(
      enableBackground: true,
      backgroundOpacity: opacity,
      enableTinting: enableTinting,
    );
  }
}

/// Widget for overlay mode where visualizer is behind UI content
class VisualizerOverlayWrapper extends StatelessWidget {
  final Widget child;
  final double visualizerOpacity;
  final bool enableTinting;
  final Function(String, Color, double)? onParameterTint;
  
  const VisualizerOverlayWrapper({
    Key? key,
    required this.child,
    this.visualizerOpacity = 0.4,
    this.enableTinting = true,
    this.onParameterTint,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MorphUIVisualizerBridge(
      child: child,
      enableBackground: true,
      backgroundOpacity: visualizerOpacity,
      enableTinting: enableTinting,
      onParameterTint: onParameterTint,
    );
  }
}

/// Performance monitoring widget for visualizer debugging
class VisualizerPerformanceMonitor extends StatefulWidget {
  final MorphUIVisualizerBridge bridge;
  
  const VisualizerPerformanceMonitor({
    Key? key,
    required this.bridge,
  }) : super(key: key);
  
  @override
  State<VisualizerPerformanceMonitor> createState() => _VisualizerPerformanceMonitorState();
}

class _VisualizerPerformanceMonitorState extends State<VisualizerPerformanceMonitor> {
  double _fps = 60.0;
  int _drawCalls = 0;
  bool _isVisible = false;
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return GestureDetector(
        onLongPress: () => setState(() => _isVisible = true),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.analytics,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
        ),
      );
    }
    
    return GlassmorphicPane(
      width: 160,
      height: 80,
      tintColor: DesignTokens.neonGreen,
      opacity: 0.1,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Performance',
                style: SyntherTypography.caption.copyWith(
                  color: DesignTokens.neonGreen,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _isVisible = false),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: DesignTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'FPS: ${_fps.toStringAsFixed(1)}',
            style: SyntherTypography.caption.copyWith(
              color: _fps > 50 ? DesignTokens.neonGreen : DesignTokens.neonOrange,
            ),
          ),
          Text(
            'Draw Calls: $_drawCalls',
            style: SyntherTypography.caption.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}