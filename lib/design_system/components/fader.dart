import '../design_system.dart';

/// Professional synthesizer fader component
/// Vertical slider with neumorphic design and glow effects
class SyntherFader extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? label;
  final String? unit;
  final bool showValue;
  final double width;
  final double height;
  final Color? glowColor;
  final bool enabled;
  final int divisions;
  final bool snap;
  final double sensitivity;
  final String? tooltip;
  
  const SyntherFader({
    Key? key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.label,
    this.unit,
    this.showValue = true,
    this.width = 40,
    this.height = 200,
    this.glowColor,
    this.enabled = true,
    this.divisions = 0,
    this.snap = false,
    this.sensitivity = 1.0,
    this.tooltip,
  }) : super(key: key);
  
  @override
  State<SyntherFader> createState() => _SyntherFaderState();
}

class _SyntherFaderState extends State<SyntherFader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  bool _isDragging = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  double get _normalizedValue => (widget.value - widget.min) / (widget.max - widget.min);
  Color get _effectiveGlowColor => widget.glowColor ?? DesignTokens.neonCyan;
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.onChanged == null) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final trackHeight = widget.height - 40; // Account for handle size
    
    double newValue = 1.0 - ((localPosition.dy - 20) / trackHeight);
    newValue = newValue.clamp(0.0, 1.0);
    newValue = widget.min + (newValue * (widget.max - widget.min));
    
    if (widget.snap && widget.divisions > 0) {
      final step = (widget.max - widget.min) / widget.divisions;
      newValue = (newValue / step).round() * step;
    }
    
    widget.onChanged!(newValue);
  }
  
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled || widget.onChanged == null) return;
    
    setState(() => _isDragging = true);
    _animationController.forward();
    _handlePanUpdate(DragUpdateDetails(
      globalPosition: details.globalPosition,
      delta: Offset.zero,
    ));
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    if (!_isHovered) {
      _animationController.reverse();
    }
  }
  
  void _handlePointerEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
    _animationController.forward();
  }
  
  void _handlePointerExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
    if (!_isDragging) {
      _animationController.reverse();
    }
  }
  
  String _getDisplayValue() {
    if (widget.divisions > 0) {
      return widget.value.toInt().toString();
    } else {
      return widget.value.toStringAsFixed(2);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final faderWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        if (widget.showValue) ..[
          SizedBox(
            width: widget.width,
            height: 20,
            child: Center(
              child: Text(
                '${_getDisplayValue()}${widget.unit ?? ''}',
                style: SyntherTypography.monoSmall.copyWith(
                  color: widget.enabled 
                    ? DesignTokens.textPrimary 
                    : DesignTokens.textDisabled,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spacing1),
        ],
        
        // Fader control
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: MouseRegion(
              onEnter: _handlePointerEnter,
              onExit: _handlePointerExit,
              cursor: widget.enabled ? SystemMouseCursors.grab : SystemMouseCursors.forbidden,
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.width, widget.height),
                    painter: _FaderPainter(
                      value: _normalizedValue,
                      glowIntensity: _glowAnimation.value,
                      glowColor: _effectiveGlowColor,
                      isDragging: _isDragging,
                      isHovered: _isHovered,
                      enabled: widget.enabled,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Label
        if (widget.label != null) ..[
          SizedBox(height: DesignTokens.spacing1),
          SizedBox(
            width: widget.width,
            child: Text(
              widget.label!,
              style: SyntherTypography.labelSmall.copyWith(
                color: widget.enabled 
                  ? DesignTokens.textSecondary 
                  : DesignTokens.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
    
    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: faderWidget,
      );
    }
    
    return faderWidget;
  }
}

class _FaderPainter extends CustomPainter {
  final double value;
  final double glowIntensity;
  final Color glowColor;
  final bool isDragging;
  final bool isHovered;
  final bool enabled;
  
  _FaderPainter({
    required this.value,
    required this.glowIntensity,
    required this.glowColor,
    required this.isDragging,
    required this.isHovered,
    required this.enabled,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final trackWidth = 8.0;
    final handleWidth = size.width - 8;
    final handleHeight = 20.0;
    final trackHeight = size.height - handleHeight;
    
    final trackRect = Rect.fromLTWH(
      (size.width - trackWidth) / 2,
      handleHeight / 2,
      trackWidth,
      trackHeight,
    );
    
    // Track background
    final trackBgPaint = Paint()
      ..color = DesignTokens.surfaceDim
      ..style = PaintingStyle.fill;
    
    final trackRadius = Radius.circular(trackWidth / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      trackBgPaint,
    );
    
    // Active track
    if (value > 0 && enabled) {
      final activeHeight = trackHeight * value;
      final activeRect = Rect.fromLTWH(
        trackRect.left,
        trackRect.bottom - activeHeight,
        trackWidth,
        activeHeight,
      );
      
      final activePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            glowColor,
            glowColor.withOpacity(0.7),
          ],
        ).createShader(activeRect)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, trackRadius),
        activePaint,
      );
    }
    
    // Handle position
    final handleY = trackRect.bottom - (trackHeight * value) - (handleHeight / 2);
    final handleRect = Rect.fromLTWH(
      4,
      handleY,
      handleWidth,
      handleHeight,
    );
    
    // Handle glow
    if (enabled && glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.4 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          handleRect.inflate(2),
          const Radius.circular(6),
        ),
        glowPaint,
      );
    }
    
    // Handle shadows
    if (!isDragging) {
      final shadowLight = Paint()
        ..color = DesignTokens.shadowLight
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      final shadowDark = Paint()
        ..color = DesignTokens.shadowDark
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          handleRect.translate(-2, -2),
          const Radius.circular(4),
        ),
        shadowLight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          handleRect.translate(2, 2),
          const Radius.circular(4),
        ),
        shadowDark,
      );
    }
    
    // Handle base
    final handlePaint = Paint()
      ..color = enabled ? DesignTokens.surface : DesignTokens.surfaceDisabled
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        handleRect,
        const Radius.circular(4),
      ),
      handlePaint,
    );
    
    // Handle inner shadow for pressed state
    if (isDragging) {
      final innerShadow = Paint()
        ..color = DesignTokens.shadowDark.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          handleRect.deflate(1),
          const Radius.circular(3),
        ),
        innerShadow,
      );
    }
    
    // Handle highlight
    if (enabled && (isHovered || isDragging)) {
      final highlightPaint = Paint()
        ..color = glowColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          handleRect,
          const Radius.circular(4),
        ),
        highlightPaint,
      );
    }
    
    // Handle grip lines
    if (enabled) {
      final gripPaint = Paint()
        ..color = DesignTokens.textSecondary.withOpacity(0.6)
        ..strokeWidth = 1;
      
      final centerX = handleRect.center.dx;
      final centerY = handleRect.center.dy;
      
      for (int i = -1; i <= 1; i++) {
        final lineY = centerY + (i * 3);
        canvas.drawLine(
          Offset(centerX - 6, lineY),
          Offset(centerX + 6, lineY),
          gripPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _FaderPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.isHovered != isHovered ||
           oldDelegate.enabled != enabled;
  }
}