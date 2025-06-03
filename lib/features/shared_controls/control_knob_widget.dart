import 'dart:math';
import 'package:flutter/material.dart';

/// A rotary knob control for adjusting parameters.
class ControlKnob extends StatefulWidget {
  const ControlKnob({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions = 100,
    this.logarithmic = false,
    required this.label,
    this.valueFormat,
    required this.onChanged,
    this.knobColor,
    this.trackColor,
    this.activeTrackColor,
    this.size = 80,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool logarithmic;
  final String label;
  final String Function(double)? valueFormat;
  final ValueChanged<double> onChanged;
  final Color? knobColor;
  final Color? trackColor;
  final Color? activeTrackColor;
  final double size;

  @override
  State<ControlKnob> createState() => _ControlKnobState();
}

class _ControlKnobState extends State<ControlKnob> with SingleTickerProviderStateMixin {
  late double _startDragY;
  late double _startValue;
  late double _normalizedValue;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;
  
  @override
  void initState() {
    super.initState();
    _updateNormalizedValue();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutBack,
    ));
  }
  
  @override
  void didUpdateWidget(ControlKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.logarithmic != widget.logarithmic) {
      _updateNormalizedValue();
    }
  }
  
  void _updateNormalizedValue() {
    if (widget.logarithmic) {
      // Logarithmic scale normalization
      final logMin = log(widget.min);
      final logMax = log(widget.max);
      final logValue = log(widget.value);
      _normalizedValue = (logValue - logMin) / (logMax - logMin);
    } else {
      // Linear scale normalization
      _normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);
    }
    
    // Clamp to 0.0-1.0 range
    _normalizedValue = _normalizedValue.clamp(0.0, 1.0);
  }
  
  double _normalizedToRealValue(double normalized) {
    final clampedNormalized = normalized.clamp(0.0, 1.0);
    
    if (widget.logarithmic) {
      // Logarithmic scale denormalization
      final logMin = log(widget.min);
      final logMax = log(widget.max);
      final logValue = logMin + clampedNormalized * (logMax - logMin);
      return exp(logValue);
    } else {
      // Linear scale denormalization
      return widget.min + clampedNormalized * (widget.max - widget.min);
    }
  }
  
  void _handleDragStart(DragStartDetails details) {
    _startDragY = details.localPosition.dy;
    _startValue = _normalizedValue;
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    // Calculate vertical drag distance and convert to value change
    final dragDistance = _startDragY - details.localPosition.dy;
    final sensitivity = 0.005; // Adjust sensitivity as needed
    
    // Update normalized value based on drag distance
    final newNormalized = (_startValue + dragDistance * sensitivity).clamp(0.0, 1.0);
    
    if (newNormalized != _normalizedValue) {
      setState(() {
        _normalizedValue = newNormalized;
      });
      
      // Trigger haptic feedback at boundaries
      if ((newNormalized == 0.0 || newNormalized == 1.0) && 
          (_normalizedValue > 0.0 && _normalizedValue < 1.0)) {
        _feedbackController.forward().then((_) {
          _feedbackController.reverse();
        });
      }
      
      // Convert normalized value to real value and call onChanged
      final realValue = _normalizedToRealValue(_normalizedValue);
      widget.onChanged(realValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final knobColor = widget.knobColor ?? theme.colorScheme.primary;
    final trackColor = widget.trackColor ?? Colors.grey.shade300;
    final activeTrackColor = widget.activeTrackColor ?? theme.colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Knob label
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium,
        ),
        
        const SizedBox(height: 4),
        
        // Knob control
        GestureDetector(
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          child: AnimatedBuilder(
            animation: _feedbackAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _feedbackAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    painter: KnobPainter(
                      value: _normalizedValue,
                      knobColor: knobColor,
                      trackColor: trackColor,
                      activeTrackColor: activeTrackColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Value display
        Text(
          widget.valueFormat != null
              ? widget.valueFormat!(widget.value)
              : widget.value.toStringAsFixed(2),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}

class KnobPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color knobColor;
  final Color trackColor;
  final Color activeTrackColor;
  
  KnobPainter({
    required this.value,
    required this.knobColor,
    required this.trackColor,
    required this.activeTrackColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final trackRadius = radius * 0.8;
    final knobRadius = radius * 0.7;
    
    // Draw track background
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      -pi * 0.8, // Start at -145 degrees
      pi * 1.6, // End at 145 degrees (290 degree arc)
      false,
      trackPaint,
    );
    
    // Draw active track
    final activeTrackPaint = Paint()
      ..color = activeTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      -pi * 0.8, // Start at -145 degrees
      pi * 1.6 * value, // Partial arc based on value
      false,
      activeTrackPaint,
    );
    
    // Draw knob
    final knobPaint = Paint()
      ..color = knobColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, knobRadius, knobPaint);
    
    // Draw knob highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final highlightCenter = Offset(
      center.dx - knobRadius * 0.25,
      center.dy - knobRadius * 0.25,
    );
    
    canvas.drawCircle(highlightCenter, knobRadius * 0.4, highlightPaint);
    
    // Draw knob indicator line
    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Calculate indicator angle
    final angle = -pi * 0.8 + pi * 1.6 * value;
    final indicatorStart = Offset(
      center.dx + (knobRadius * 0.4) * cos(angle),
      center.dy + (knobRadius * 0.4) * sin(angle),
    );
    
    final indicatorEnd = Offset(
      center.dx + (knobRadius * 0.9) * cos(angle),
      center.dy + (knobRadius * 0.9) * sin(angle),
    );
    
    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);
  }
  
  @override
  bool shouldRepaint(covariant KnobPainter oldDelegate) {
    return value != oldDelegate.value ||
           knobColor != oldDelegate.knobColor ||
           trackColor != oldDelegate.trackColor ||
           activeTrackColor != oldDelegate.activeTrackColor;
  }
}