import 'dart:math' as math;
import 'dart:typed_data';
import '../design_system.dart';

/// Professional spectrum analyzer component
/// Displays real-time frequency analysis with neon glow effects
class SpectrumAnalyzer extends StatefulWidget {
  final List<double>? frequencyData;
  final double width;
  final double height;
  final int barCount;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGrid;
  final bool showLabels;
  final double barSpacing;
  final double minDb;
  final double maxDb;
  final bool enabled;
  final SpectrumStyle style;
  
  const SpectrumAnalyzer({
    Key? key,
    this.frequencyData,
    this.width = 300,
    this.height = 120,
    this.barCount = 32,
    this.primaryColor = DesignTokens.neonCyan,
    this.secondaryColor = DesignTokens.neonPurple,
    this.showGrid = true,
    this.showLabels = false,
    this.barSpacing = 2,
    this.minDb = -60,
    this.maxDb = 0,
    this.enabled = true,
    this.style = SpectrumStyle.bars,
  }) : super(key: key);
  
  @override
  State<SpectrumAnalyzer> createState() => _SpectrumAnalyzerState();
}

class _SpectrumAnalyzerState extends State<SpectrumAnalyzer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  
  List<double> _displayData = [];
  List<double> _peakHolds = [];
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enabled) {
      _animationController.repeat(reverse: true);
    }
    
    _initializeData();
  }
  
  @override
  void didUpdateWidget(SpectrumAnalyzer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.barCount != widget.barCount) {
      _initializeData();
    }
    
    if (widget.frequencyData != null) {
      _updateDisplayData(widget.frequencyData!);
    }
    
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _initializeData() {
    _displayData = List.filled(widget.barCount, 0.0);
    _peakHolds = List.filled(widget.barCount, 0.0);
  }
  
  void _updateDisplayData(List<double> newData) {
    if (!mounted) return;
    
    setState(() {
      // Resample data to match bar count
      for (int i = 0; i < widget.barCount; i++) {
        final index = (i * newData.length / widget.barCount).floor();
        if (index < newData.length) {
          final dbValue = 20 * math.log(math.max(newData[index], 0.001)) / math.ln10;
          final normalizedValue = ((dbValue - widget.minDb) / (widget.maxDb - widget.minDb))
              .clamp(0.0, 1.0);
          
          // Smooth decay for display
          _displayData[i] = math.max(normalizedValue, _displayData[i] * 0.8);
          
          // Peak hold
          if (normalizedValue > _peakHolds[i]) {
            _peakHolds[i] = normalizedValue;
          } else {
            _peakHolds[i] *= 0.95; // Slow decay for peaks
          }
        }
      }
    });
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
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _SpectrumPainter(
                displayData: _displayData,
                peakHolds: _peakHolds,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
                glowIntensity: _glowAnimation.value,
                showGrid: widget.showGrid,
                showLabels: widget.showLabels,
                barSpacing: widget.barSpacing,
                style: widget.style,
                enabled: widget.enabled,
              ),
            );
          },
        ),
      ),
    );
  }
}

enum SpectrumStyle {
  bars,
  line,
  filled,
}

class _SpectrumPainter extends CustomPainter {
  final List<double> displayData;
  final List<double> peakHolds;
  final Color primaryColor;
  final Color secondaryColor;
  final double glowIntensity;
  final bool showGrid;
  final bool showLabels;
  final double barSpacing;
  final SpectrumStyle style;
  final bool enabled;
  
  _SpectrumPainter({
    required this.displayData,
    required this.peakHolds,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowIntensity,
    required this.showGrid,
    required this.showLabels,
    required this.barSpacing,
    required this.style,
    required this.enabled,
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
    
    // Draw spectrum based on style
    switch (style) {
      case SpectrumStyle.bars:
        _paintBars(canvas, size);
        break;
      case SpectrumStyle.line:
        _paintLine(canvas, size);
        break;
      case SpectrumStyle.filled:
        _paintFilled(canvas, size);
        break;
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
    
    // Horizontal lines (dB levels)
    for (int i = 0; i <= 4; i++) {
      final y = (size.height * i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Vertical lines (frequency bands)
    final barWidth = (size.width - (barSpacing * (displayData.length - 1))) / displayData.length;
    for (int i = 0; i < displayData.length; i += 4) {
      final x = i * (barWidth + barSpacing);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }
  
  void _paintBars(Canvas canvas, Size size) {
    final barWidth = (size.width - (barSpacing * (displayData.length - 1))) / displayData.length;
    
    for (int i = 0; i < displayData.length; i++) {
      final x = i * (barWidth + barSpacing);
      final barHeight = displayData[i] * size.height;
      final y = size.height - barHeight;
      
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      
      // Create gradient based on bar height
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor,
          secondaryColor,
        ],
        stops: const [0.0, 1.0],
      );
      
      final barPaint = Paint()
        ..shader = gradient.createShader(rect);
      
      // Glow effect
      if (displayData[i] > 0.1) {
        final glowPaint = Paint()
          ..color = primaryColor.withOpacity(0.4 * glowIntensity * displayData[i])
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            2 + (displayData[i] * 4),
          );
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(1),
            const Radius.circular(1),
          ),
          glowPaint,
        );
      }
      
      // Main bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(1),
        ),
        barPaint,
      );
      
      // Peak hold indicator
      if (peakHolds[i] > 0.05) {
        final peakY = size.height - (peakHolds[i] * size.height);
        final peakPaint = Paint()
          ..color = secondaryColor.withOpacity(0.8)
          ..strokeWidth = 2;
        
        canvas.drawLine(
          Offset(x, peakY),
          Offset(x + barWidth, peakY),
          peakPaint,
        );
      }
    }
  }
  
  void _paintLine(Canvas canvas, Size size) {
    if (displayData.isEmpty) return;
    
    final path = Path();
    final barWidth = size.width / displayData.length;
    
    path.moveTo(0, size.height - (displayData[0] * size.height));
    
    for (int i = 1; i < displayData.length; i++) {
      final x = i * barWidth;
      final y = size.height - (displayData[i] * size.height);
      path.lineTo(x, y);
    }
    
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Glow effect
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }
  
  void _paintFilled(Canvas canvas, Size size) {
    if (displayData.isEmpty) return;
    
    final path = Path();
    final barWidth = size.width / displayData.length;
    
    path.moveTo(0, size.height);
    path.lineTo(0, size.height - (displayData[0] * size.height));
    
    for (int i = 1; i < displayData.length; i++) {
      final x = i * barWidth;
      final y = size.height - (displayData[i] * size.height);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        primaryColor.withOpacity(0.8),
        secondaryColor.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, fillPaint);
  }
  
  void _paintLabels(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: DesignTokens.textSecondary,
      fontSize: 10,
      fontFamily: SyntherTypography.monoFont,
    );
    
    // Frequency labels
    final frequencies = ['60', '250', '1K', '4K', '16K'];
    for (int i = 0; i < frequencies.length; i++) {
      final x = (size.width * i / (frequencies.length - 1)) - 10;
      final textPainter = TextPainter(
        text: TextSpan(text: frequencies[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, size.height - 15));
    }
  }
  
  void _paintDisabled(Canvas canvas, Size size) {
    final disabledPaint = Paint()
      ..color = DesignTokens.textDisabled.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw static bars to indicate disabled state
    final barWidth = (size.width - (barSpacing * 7)) / 8;
    for (int i = 0; i < 8; i++) {
      final x = i * (barWidth + barSpacing);
      final height = size.height * 0.2;
      final y = size.height - height;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(1),
        ),
        disabledPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.displayData != displayData ||
           oldDelegate.peakHolds != peakHolds ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.enabled != enabled;
  }
}