import 'package:flutter/material.dart';
import '../design_system.dart';
import '../../core/parameter_visualizer_bridge.dart';

/// Visual interface for managing parameter-to-visualizer bindings
/// This component provides the drag-and-drop interface shown in the design mockups
class ParameterBindingManager extends StatefulWidget {
  final ParameterVisualizerBridge bridge;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  
  const ParameterBindingManager({
    Key? key,
    required this.bridge,
    this.isExpanded = false,
    this.onToggleExpanded,
  }) : super(key: key);
  
  @override
  State<ParameterBindingManager> createState() => _ParameterBindingManagerState();
}

class _ParameterBindingManagerState extends State<ParameterBindingManager>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _glowController;
  late Animation<double> _expandAnimation;
  late Animation<double> _glowAnimation;
  
  String? _draggedParameter;
  String? _hoveredTarget;
  
  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
    
    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(ParameterBindingManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return GlassmorphicPane(
          width: 280,
          height: 60 + (_expandAnimation.value * 400),
          tintColor: DesignTokens.neonPurple,
          opacity: 0.08,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              
              if (_expandAnimation.value > 0.1) ...[
                SizedBox(height: 16 * _expandAnimation.value),
                Expanded(
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: _buildBindingInterface(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: DesignTokens.neonPurple,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Parameter Bindings',
          style: SyntherTypography.labelMedium.copyWith(
            color: DesignTokens.neonPurple,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onToggleExpanded,
          child: Icon(
            widget.isExpanded ? Icons.expand_less : Icons.expand_more,
            color: DesignTokens.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBindingInterface() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source parameters (left side)\n        Expanded(
          flex: 2,
          child: _buildSourceParameters(),
        ),
        
        SizedBox(width: 16),
        
        // Binding arrows and controls (center)
        SizedBox(
          width: 60,
          child: _buildBindingControls(),
        ),
        
        SizedBox(width: 16),
        
        // Target visualizer parameters (right side)
        Expanded(
          flex: 2,
          child: _buildTargetParameters(),
        ),
      ],
    );
  }
  
  Widget _buildSourceParameters() {
    const sourceParams = [
      'xyPadX', 'xyPadY', 'filterCutoff', 'filterResonance',
      'attackTime', 'releaseTime', 'masterVolume', 'reverbMix',
      'delayMix', 'oscillatorDetune', 'lfaRate', 'lfaAmount',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Parameters',
          style: SyntherTypography.labelSmall.copyWith(
            color: DesignTokens.neonCyan,
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: sourceParams.map((param) => 
                _buildDraggableParameter(param)
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTargetParameters() {
    final categories = VisualizerCategory.values;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visualizer Parameters',
          style: SyntherTypography.labelSmall.copyWith(
            color: DesignTokens.neonPink,
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: categories.map((category) => 
                _buildParameterCategory(category)
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildParameterCategory(VisualizerCategory category) {
    final categoryParams = ParameterVisualizerBridge.availableVisualizerParams.values
        .where((param) => param.category == category)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.displayName,
          style: SyntherTypography.caption.copyWith(
            color: category.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        
        ...categoryParams.map((param) => 
          _buildDropTarget(param)
        ).toList(),
        
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildDraggableParameter(String paramName) {
    final isConnected = widget.bridge.hasBinding(paramName);
    final binding = widget.bridge.getBinding(paramName);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<String>(
        data: paramName,
        onDragStarted: () {
          setState(() {
            _draggedParameter = paramName;
          });
        },
        onDragEnd: (_) {
          setState(() {
            _draggedParameter = null;
            _hoveredTarget = null;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: _buildParameterChip(
            paramName,
            isConnected ? binding!.color : DesignTokens.neonCyan,
            isDragging: true,
          ),
        ),
        child: _buildParameterChip(
          paramName,
          isConnected ? binding!.color : DesignTokens.neonCyan,
          isConnected: isConnected,
        ),
      ),
    );
  }
  
  Widget _buildParameterChip(
    String paramName,
    Color color, {
    bool isConnected = false,
    bool isDragging = false,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(isConnected ? 0.3 : 0.15),
                color.withOpacity(isConnected ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: isConnected ? 2 : 1,
              color: color.withOpacity(
                isConnected 
                  ? _glowAnimation.value 
                  : (isDragging ? 0.8 : 0.3)
              ),
            ),
            boxShadow: isConnected ? [
              BoxShadow(
                color: color.withOpacity(0.3 * _glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConnected) ...[
                Icon(
                  Icons.link,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  _formatParameterName(paramName),
                  style: SyntherTypography.caption.copyWith(
                    color: color,
                    fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDropTarget(VisualizerParameter param) {
    final isHovered = _hoveredTarget == param.id;
    final existingBinding = widget.bridge.bindings.values
        .where((binding) => binding.visualizerParameter == param.id)
        .firstOrNull;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DragTarget<String>(
        onWillAccept: (data) {
          setState(() {
            _hoveredTarget = param.id;
          });
          return data != null;
        },
        onLeave: (_) {
          setState(() {
            _hoveredTarget = null;
          });
        },
        onAccept: (flutterParam) {
          _createBinding(flutterParam, param.id);
          setState(() {
            _hoveredTarget = null;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty || isHovered;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  param.color.withOpacity(isActive ? 0.3 : 0.1),
                  param.color.withOpacity(isActive ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: isActive ? 2 : 1,
                color: param.color.withOpacity(isActive ? 0.8 : 0.3),
              ),
            ),
            child: Row(
              children: [
                if (existingBinding != null) ...[
                  Icon(
                    Icons.link,
                    size: 10,
                    color: param.color,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    param.name,
                    style: SyntherTypography.caption.copyWith(
                      color: param.color,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (existingBinding != null)
                  GestureDetector(
                    onTap: () => _removeBinding(existingBinding.flutterParameter),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: param.color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBindingControls() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Visual connection lines
        if (_draggedParameter != null)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(60, 200),
                painter: _BindingLinePainter(
                  glowIntensity: _glowAnimation.value,
                  color: DesignTokens.neonPurple,
                ),
              );
            },
          ),
        
        // Reset button
        const Spacer(),
        GestureDetector(
          onTap: () {
            widget.bridge.resetToDefaults();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonOrange.withOpacity(0.2),
                  DesignTokens.neonOrange.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.neonOrange.withOpacity(0.5),
              ),
            ),
            child: Icon(
              Icons.refresh,
              color: DesignTokens.neonOrange,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
  
  void _createBinding(String flutterParam, String visualizerParam) {
    // Smart binding type selection based on parameter types
    BindingType bindingType = BindingType.direct;
    double scale = 1.0;
    double offset = 0.0;
    
    final visualizerParamInfo = ParameterVisualizerBridge.availableVisualizerParams[visualizerParam];
    if (visualizerParamInfo != null) {
      // Adjust scale based on parameter range
      final range = visualizerParamInfo.max - visualizerParamInfo.min;
      scale = range;
      offset = visualizerParamInfo.min;
      
      // Use logarithmic scaling for filter cutoff
      if (flutterParam.contains('filterCutoff')) {
        bindingType = BindingType.logarithmic;
      }
      // Use exponential for resonance/emphasis
      else if (flutterParam.contains('resonance') || flutterParam.contains('drive')) {
        bindingType = BindingType.exponential;
      }
      // Use curved for envelope parameters
      else if (flutterParam.contains('attack') || flutterParam.contains('release')) {
        bindingType = BindingType.curved;
      }
    }
    
    widget.bridge.createBinding(
      flutterParam: flutterParam,
      visualizerParam: visualizerParam,
      type: bindingType,
      scale: scale,
      offset: offset,
    );
  }
  
  void _removeBinding(String flutterParam) {
    widget.bridge.removeBinding(flutterParam);
  }
  
  String _formatParameterName(String paramName) {
    // Convert camelCase to readable names
    return paramName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceFirst(RegExp(r'^xy'), 'XY ')
        .trim();
  }
}

/// Custom painter for drawing connection lines between parameters
class _BindingLinePainter extends CustomPainter {
  final double glowIntensity;
  final Color color;
  
  _BindingLinePainter({
    required this.glowIntensity,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * glowIntensity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.5,
      size.width, size.height * 0.7,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw arrow
    final arrowPaint = Paint()
      ..color = color.withOpacity(0.8 * glowIntensity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final arrowPath = Path();
    arrowPath.moveTo(size.width - 8, size.height * 0.7 - 4);
    arrowPath.lineTo(size.width, size.height * 0.7);
    arrowPath.lineTo(size.width - 8, size.height * 0.7 + 4);
    
    canvas.drawPath(arrowPath, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant _BindingLinePainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity;
  }
}