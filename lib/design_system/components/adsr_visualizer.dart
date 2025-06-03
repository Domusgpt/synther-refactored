import 'dart:math' as math;
import '../design_system.dart';

/// Professional ADSR envelope visualizer
/// Shows real-time envelope curve with animation and interaction
class AdsrVisualizer extends StatefulWidget {
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGrid;
  final bool showLabels;
  final bool enabled;
  final bool isPlaying;
  final double? currentLevel;
  final ValueChanged<AdsrParameter>? onParameterChanged;
  final bool interactive;
  
  const AdsrVisualizer({
    Key? key,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    this.width = 300,
    this.height = 150,
    this.primaryColor = DesignTokens.neonCyan,
    this.secondaryColor = DesignTokens.neonPurple,
    this.showGrid = true,
    this.showLabels = true,
    this.enabled = true,
    this.isPlaying = false,
    this.currentLevel,
    this.onParameterChanged,
    this.interactive = false,
  }) : super(key: key);
  
  @override
  State<AdsrVisualizer> createState() => _AdsrVisualizerState();
}

class _AdsrVisualizerState extends State<AdsrVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _playbackController;
  late AnimationController _glowController;
  late Animation<double> _playbackAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isDragging = false;
  AdsrParameter? _dragParameter;
  Offset? _dragStart;
  double? _parameterAtDragStart;
  
  @override
  void initState() {
    super.initState();
    
    // Playback animation for real-time envelope display
    _playbackController = AnimationController(
      duration: _calculateTotalDuration(),
      vsync: this,
    );
    
    // Glow animation for visual feedback
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _playbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_playbackController);
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enabled) {
      _glowController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(AdsrVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update playback duration if ADSR parameters changed
    if (oldWidget.attack != widget.attack ||
        oldWidget.decay != widget.decay ||
        oldWidget.release != widget.release) {
      _playbackController.duration = _calculateTotalDuration();
    }
    
    // Handle playback state
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _playbackController.forward(from: 0);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _playbackController.stop();
    }
    
    // Handle enabled state
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _playbackController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  Duration _calculateTotalDuration() {
    final totalSeconds = widget.attack + widget.decay + widget.release + 1.0; // +1 for sustain display
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }
  
  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled || !widget.interactive || widget.onParameterChanged == null) return;
    
    final localPosition = details.localPosition;
    final parameter = _hitTestParameter(localPosition);
    
    if (parameter != null) {
      setState(() {
        _isDragging = true;
        _dragParameter = parameter;
        _dragStart = localPosition;
        _parameterAtDragStart = _getParameterValue(parameter);
      });
    }
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragParameter == null || _dragStart == null) return;
    
    final delta = details.localPosition - _dragStart!;
    final sensitivity = 0.01;
    
    double newValue;
    switch (_dragParameter!) {
      case AdsrParameter.attack:
      case AdsrParameter.decay:
      case AdsrParameter.release:
        // Time parameters: horizontal drag
        final change = delta.dx * sensitivity;
        newValue = (_parameterAtDragStart! + change).clamp(0.01, 5.0);
        break;
      case AdsrParameter.sustain:
        // Level parameter: vertical drag (inverted)
        final change = -delta.dy * sensitivity;
        newValue = (_parameterAtDragStart! + change).clamp(0.0, 1.0);
        break;
    }
    
    widget.onParameterChanged!(_dragParameter!, newValue);
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragParameter = null;
      _dragStart = null;
      _parameterAtDragStart = null;
    });
  }
  
  AdsrParameter? _hitTestParameter(Offset localPosition) {
    final envelope = _calculateEnvelopePoints();
    const hitRadius = 20.0;
    
    // Check each control point
    for (final point in envelope.controlPoints.entries) {
      final distance = (localPosition - point.value).distance;
      if (distance <= hitRadius) {
        return point.key;
      }
    }
    
    return null;
  }
  
  double _getParameterValue(AdsrParameter parameter) {
    switch (parameter) {
      case AdsrParameter.attack:
        return widget.attack;
      case AdsrParameter.decay:
        return widget.decay;
      case AdsrParameter.sustain:
        return widget.sustain;
      case AdsrParameter.release:
        return widget.release;
    }
  }
  
  EnvelopeData _calculateEnvelopePoints() {
    final padding = 20.0;
    final plotWidth = widget.width - (padding * 2);
    final plotHeight = widget.height - (padding * 2);
    
    // Calculate time segments
    final totalTime = widget.attack + widget.decay + widget.release + 1.0;
    final attackRatio = widget.attack / totalTime;
    final decayRatio = widget.decay / totalTime;
    final sustainRatio = 1.0 / totalTime;
    final releaseRatio = widget.release / totalTime;
    
    // Calculate x positions
    final startX = padding;
    final attackX = startX + (plotWidth * attackRatio);
    final decayX = attackX + (plotWidth * decayRatio);
    final sustainX = decayX + (plotWidth * sustainRatio);
    final releaseX = sustainX + (plotWidth * releaseRatio);
    
    // Calculate y positions (inverted for screen coordinates)
    final bottomY = widget.height - padding;
    final topY = padding;
    final sustainY = bottomY - (plotHeight * widget.sustain);
    
    final points = [
      Offset(startX, bottomY),         // Start
      Offset(attackX, topY),           // Attack peak
      Offset(decayX, sustainY),        // Decay to sustain
      Offset(sustainX, sustainY),      // Sustain hold
      Offset(releaseX, bottomY),       // Release to zero
    ];
    
    final controlPoints = {
      AdsrParameter.attack: Offset(attackX, topY),
      AdsrParameter.decay: Offset(decayX, sustainY),
      AdsrParameter.sustain: Offset(sustainX, sustainY),
      AdsrParameter.release: Offset(releaseX, bottomY),
    };
    
    return EnvelopeData(
      points: points,
      controlPoints: controlPoints,
      attackX: attackX,
      decayX: decayX,
      sustainX: sustainX,
      releaseX: releaseX,
      sustainY: sustainY,
      plotWidth: plotWidth,
      plotHeight: plotHeight,
      padding: padding,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: DesignTokens.backgroundSecondary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: DesignTokens.borderSecondary,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: MouseRegion(
            cursor: widget.interactive && widget.enabled
              ? SystemMouseCursors.grab
              : MouseCursor.defer,
            child: AnimatedBuilder(
              animation: Listenable.merge([_playbackAnimation, _glowAnimation]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _AdsrPainter(
                    envelope: _calculateEnvelopePoints(),
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    glowIntensity: _glowAnimation.value,
                    showGrid: widget.showGrid,
                    showLabels: widget.showLabels,
                    enabled: widget.enabled,
                    isPlaying: widget.isPlaying,
                    playbackProgress: _playbackAnimation.value,
                    currentLevel: widget.currentLevel,
                    dragParameter: _dragParameter,
                    interactive: widget.interactive,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum AdsrParameter {
  attack,
  decay,
  sustain,
  release,
}

class EnvelopeData {
  final List<Offset> points;
  final Map<AdsrParameter, Offset> controlPoints;
  final double attackX;
  final double decayX;
  final double sustainX;
  final double releaseX;
  final double sustainY;
  final double plotWidth;
  final double plotHeight;
  final double padding;
  
  EnvelopeData({
    required this.points,
    required this.controlPoints,
    required this.attackX,
    required this.decayX,
    required this.sustainX,
    required this.releaseX,
    required this.sustainY,
    required this.plotWidth,
    required this.plotHeight,
    required this.padding,
  });
}

class _AdsrPainter extends CustomPainter {
  final EnvelopeData envelope;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final bool showGrid;
  final bool showLabels;
  final bool enabled;
  final bool isPlaying;
  final double playbackProgress;
  final double? currentLevel;
  final AdsrParameter? dragParameter;
  final bool interactive;
  
  _AdsrPainter({
    required this.envelope,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.showGrid,
    required this.showLabels,
    required this.enabled,
    required this.isPlaying,
    required this.playbackProgress,
    this.currentLevel,
    this.dragParameter,
    required this.interactive,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) {
      _paintDisabled(canvas, size);
      return;
    }
    
    // Draw grid
    if (showGrid) {
      _paintGrid(canvas, size);
    }
    
    // Draw envelope curve
    _paintEnvelope(canvas, size);
    
    // Draw control points
    if (interactive) {
      _paintControlPoints(canvas, size);
    }
    
    // Draw playback indicator
    if (isPlaying) {
      _paintPlaybackIndicator(canvas, size);
    }
    
    // Draw current level indicator
    if (currentLevel != null) {
      _paintCurrentLevel(canvas, size);
    }
    
    // Draw labels
    if (showLabels) {
      _paintLabels(canvas, size);
    }
  }
  
  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = DesignTokens.borderSecondary.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Horizontal lines (levels)
    for (int i = 0; i <= 4; i++) {
      final y = envelope.padding + (envelope.plotHeight * i / 4);
      canvas.drawLine(
        Offset(envelope.padding, y),
        Offset(size.width - envelope.padding, y),
        gridPaint,
      );
    }
    
    // Vertical lines (time segments)
    final timePoints = [envelope.attackX, envelope.decayX, envelope.sustainX, envelope.releaseX];
    for (final x in timePoints) {
      canvas.drawLine(
        Offset(x, envelope.padding),
        Offset(x, size.height - envelope.padding),
        gridPaint,
      );
    }
  }
  
  void _paintEnvelope(Canvas canvas, Size size) {
    final path = Path();
    
    // Create smooth curve through envelope points
    path.moveTo(envelope.points[0].dx, envelope.points[0].dy);
    
    // Attack phase - exponential curve
    _addCurveSegment(path, envelope.points[0], envelope.points[1], SyntherAnimations.adsrAttack);
    
    // Decay phase - exponential decay
    _addCurveSegment(path, envelope.points[1], envelope.points[2], SyntherAnimations.adsrDecay);
    
    // Sustain phase - straight line
    path.lineTo(envelope.points[3].dx, envelope.points[3].dy);
    
    // Release phase - exponential decay
    _addCurveSegment(path, envelope.points[3], envelope.points[4], SyntherAnimations.adsrRelease);
    
    // Draw glow effect
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path, glowPaint);
    
    // Draw main curve
    final curvePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(path, curvePaint);
    
    // Fill under curve with gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(envelope.points[4].dx, size.height - envelope.padding);
    fillPath.lineTo(envelope.points[0].dx, size.height - envelope.padding);
    fillPath.close();
    
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.3),
        primaryColor.withOpacity(0.1),
        Colors.transparent,
      ],
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(fillPath, fillPaint);
  }
  
  void _addCurveSegment(Path path, Offset start, Offset end, Curve curve) {
    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final curveValue = curve.transform(t);
      
      final x = start.dx + (end.dx - start.dx) * t;
      final y = start.dy + (end.dy - start.dy) * curveValue;
      
      if (i == 1) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
  }
  
  void _paintControlPoints(Canvas canvas, Size size) {
    for (final entry in envelope.controlPoints.entries) {
      final parameter = entry.key;
      final point = entry.value;
      final isActive = dragParameter == parameter;
      
      // Control point glow
      if (isActive) {
        final glowPaint = Paint()
          ..color = secondaryColor.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawCircle(point, 12, glowPaint);
      }
      
      // Control point base
      final pointPaint = Paint()
        ..color = isActive ? secondaryColor : primaryColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(point, 6, pointPaint);
      
      // Control point border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(point, 6, borderPaint);
    }
  }
  
  void _paintPlaybackIndicator(Canvas canvas, Size size) {
    final totalWidth = envelope.plotWidth;
    final x = envelope.padding + (totalWidth * playbackProgress);
    
    final indicatorPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(x, envelope.padding),
      Offset(x, size.height - envelope.padding),
      indicatorPaint,
    );
    
    // Playback head
    final headPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, envelope.padding), 4, headPaint);
  }
  
  void _paintCurrentLevel(Canvas canvas, Size size) {
    final y = size.height - envelope.padding - (envelope.plotHeight * currentLevel!);
    
    final levelPaint = Paint()
      ..color = secondaryColor.withOpacity(0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(envelope.padding, y),
      Offset(size.width - envelope.padding, y),
      levelPaint,
    );
  }
  
  void _paintLabels(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: DesignTokens.textSecondary,
      fontSize: 10,
      fontFamily: SyntherTypography.monoFont,
    );
    
    final labels = ['A', 'D', 'S', 'R'];
    final positions = [envelope.attackX, envelope.decayX, envelope.sustainX, envelope.releaseX];
    
    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(positions[i] - 4, size.height - envelope.padding + 5),
      );
    }
  }
  
  void _paintDisabled(Canvas canvas, Size size) {
    final disabledPaint = Paint()
      ..color = DesignTokens.textDisabled.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw simple envelope shape
    final path = Path();
    path.moveTo(envelope.padding, size.height - envelope.padding);
    path.lineTo(envelope.padding + envelope.plotWidth * 0.2, envelope.padding);
    path.lineTo(envelope.padding + envelope.plotWidth * 0.4, envelope.padding + envelope.plotHeight * 0.3);
    path.lineTo(envelope.padding + envelope.plotWidth * 0.7, envelope.padding + envelope.plotHeight * 0.3);
    path.lineTo(envelope.padding + envelope.plotWidth, size.height - envelope.padding);
    
    canvas.drawPath(path, disabledPaint);
  }
  
  @override
  bool shouldRepaint(covariant _AdsrPainter oldDelegate) {
    return oldDelegate.envelope != envelope ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.isPlaying != isPlaying ||
           oldDelegate.playbackProgress != playbackProgress ||
           oldDelegate.currentLevel != currentLevel ||
           oldDelegate.dragParameter != dragParameter ||
           oldDelegate.enabled != enabled;
  }
}