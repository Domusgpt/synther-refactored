import 'dart:math' as math;
import '../design_system.dart';

/// Professional synthesizer knob component
/// Implements neo-skeuomorphic design with vaporwave aesthetics
class SyntherKnob extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? label;
  final String? unit;
  final bool showValue;
  final double size;
  final Color? glowColor;
  final bool enabled;
  final int divisions;
  final bool snap;
  final double sensitivity;
  final String? tooltip;
  
  const SyntherKnob({
    Key? key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.label,
    this.unit,
    this.showValue = true,
    this.size = DesignTokens.knobSizeMedium,
    this.glowColor,
    this.enabled = true,
    this.divisions = 0,
    this.snap = false,
    this.sensitivity = 1.0,
    this.tooltip,
  }) : super(key: key);
  
  @override
  State<SyntherKnob> createState() => _SyntherKnobState();
}

class _SyntherKnobState extends State<SyntherKnob>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  bool _isDragging = false;
  bool _isHovered = false;
  Offset? _dragStart;
  double? _valueAtDragStart;
  
  // Knob parameters
  static const double _startAngle = -2.356; // -135 degrees
  static const double _endAngle = 2.356;    // 135 degrees
  static const double _totalAngle = _endAngle - _startAngle;
  
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
  double get _angle => _startAngle + (_normalizedValue * _totalAngle);
  
  Color get _effectiveGlowColor => widget.glowColor ?? DesignTokens.neonCyan;
  
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled || widget.onChanged == null) return;
    
    setState(() {
      _isDragging = true;
      _dragStart = details.localPosition;
      _valueAtDragStart = widget.value;
    });
    
    _animationController.forward();
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.onChanged == null || _dragStart == null) return;
    
    final delta = _dragStart! - details.localPosition;
    final sensitivity = widget.sensitivity * 0.01;
    final change = delta.dy * sensitivity * (widget.max - widget.min);
    
    double newValue = (_valueAtDragStart! - change).clamp(widget.min, widget.max);
    
    if (widget.snap && widget.divisions > 0) {
      final step = (widget.max - widget.min) / widget.divisions;
      newValue = (newValue / step).round() * step;
    }
    
    widget.onChanged!(newValue);
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStart = null;
      _valueAtDragStart = null;
    });
    
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
    final knobWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Knob control
        SizedBox(
          width: widget.size,
          height: widget.size,
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
                    size: Size(widget.size, widget.size),
                    painter: _KnobPainter(
                      value: _normalizedValue,
                      angle: _angle,
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
        
        // Label and value
        if (widget.label != null || widget.showValue) ..[
          SizedBox(height: DesignTokens.spacing1),
          
          if (widget.label != null)
            Text(
              widget.label!,
              style: SyntherTypography.labelSmall.copyWith(
                color: widget.enabled 
                  ? DesignTokens.textSecondary 
                  : DesignTokens.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
            
          if (widget.showValue) ..[
            SizedBox(height: DesignTokens.spacing0_5),
            Text(
              '${_getDisplayValue()}${widget.unit ?? ''}',
              style: SyntherTypography.monoSmall.copyWith(
                color: widget.enabled 
                  ? DesignTokens.textPrimary 
                  : DesignTokens.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
    
    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: knobWidget,
      );
    }
    
    return knobWidget;
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final double angle;
  final double glowIntensity;
  final Color glowColor;
  final bool isDragging;
  final bool isHovered;
  final bool enabled;
  
  _KnobPainter({
    required this.value,
    required this.angle,
    required this.glowIntensity,
    required this.glowColor,
    required this.isDragging,
    required this.isHovered,
    required this.enabled,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final knobRadius = radius * 0.85;
    
    // Outer shadow/glow
    if (enabled && glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(0.3 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(center, knobRadius + 4, glowPaint);
    }
    
    // Base knob - neumorphic shadow
    final shadowLight = Paint()
      ..color = DesignTokens.shadowLight
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final shadowDark = Paint()
      ..color = DesignTokens.shadowDark
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    if (!isDragging) {
      canvas.drawCircle(center + const Offset(-3, -3), knobRadius, shadowLight);
      canvas.drawCircle(center + const Offset(3, 3), knobRadius, shadowDark);
    }
    
    // Knob base
    final basePaint = Paint()
      ..color = enabled ? DesignTokens.surface : DesignTokens.surfaceDisabled
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, knobRadius, basePaint);
    
    // Inner shadow for pressed state
    if (isDragging) {
      final innerShadowLight = Paint()
        ..color = DesignTokens.shadowLight.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      final innerShadowDark = Paint()
        ..color = DesignTokens.shadowDark
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(center + const Offset(2, 2), knobRadius - 4, innerShadowDark);
      canvas.drawCircle(center + const Offset(-2, -2), knobRadius - 4, innerShadowLight);
    }
    
    // Track background
    final trackRadius = knobRadius * 0.9;
    final trackPaint = Paint()
      ..color = DesignTokens.surfaceDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -2.356; // -135 degrees
    const sweepAngle = 4.712;   // 270 degrees
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );
    
    // Active track
    if (value > 0 && enabled) {
      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            glowColor,
            glowColor.withOpacity(0.7),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: trackRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        startAngle,
        sweepAngle * value,
        false,
        activePaint,
      );
    }
    
    // Pointer/indicator
    final pointerLength = knobRadius * 0.6;
    final pointerStart = center + Offset(
      math.cos(angle) * (knobRadius * 0.2),
      math.sin(angle) * (knobRadius * 0.2),
    );
    final pointerEnd = center + Offset(
      math.cos(angle) * pointerLength,
      math.sin(angle) * pointerLength,
    );
    
    final pointerPaint = Paint()
      ..color = enabled ? DesignTokens.textPrimary : DesignTokens.textDisabled
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(pointerStart, pointerEnd, pointerPaint);
    
    // Center dot
    final centerDotPaint = Paint()
      ..color = enabled 
        ? (glowIntensity > 0 ? glowColor : DesignTokens.textPrimary)
        : DesignTokens.textDisabled;
    
    canvas.drawCircle(center, 3, centerDotPaint);
    
    // Outer ring highlight
    if (enabled && (isHovered || isDragging)) {
      final ringPaint = Paint()
        ..color = glowColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawCircle(center, knobRadius, ringPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.isHovered != isHovered ||
           oldDelegate.enabled != enabled;
  }
}