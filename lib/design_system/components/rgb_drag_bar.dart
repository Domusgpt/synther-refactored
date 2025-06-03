import 'dart:math' as math;
import '../design_system.dart';

/// RGB drag bar for resizing panes in Morph-UI
/// Features animated rainbow gradient and elastic feedback
class RGBDragBar extends StatefulWidget {
  final Axis orientation;
  final VoidCallback? onDragStart;
  final ValueChanged<double>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final double thickness;
  final double length;
  final bool showHandles;
  final bool enableHaptic;
  final Duration animationDuration;
  
  const RGBDragBar({
    Key? key,
    this.orientation = Axis.horizontal,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.thickness = 6.0,
    this.length = double.infinity,
    this.showHandles = true,
    this.enableHaptic = true,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);
  
  @override
  State<RGBDragBar> createState() => _RGBDragBarState();
}

class _RGBDragBarState extends State<RGBDragBar>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isDragging = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    // Continuous gradient animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gradientController);
    
    _gradientController.repeat();
    
    // Pulse animation for interaction feedback
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _handleDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _pulseController.forward();
    widget.onDragStart?.call();
    
    if (widget.enableHaptic) {
      // HapticFeedback.lightImpact(); // Uncomment when adding haptic feedback
    }
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = widget.orientation == Axis.horizontal
        ? details.delta.dy
        : details.delta.dx;
    
    widget.onDragUpdate?.call(delta);
  }
  
  void _handleDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _pulseController.reverse();
    widget.onDragEnd?.call();
  }
  
  void _handlePointerEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
  }
  
  void _handlePointerExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
  }
  
  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.orientation == Axis.horizontal;
    
    return MouseRegion(
      onEnter: _handlePointerEnter,
      onExit: _handlePointerExit,
      cursor: isHorizontal
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        onVerticalDragStart: isHorizontal ? _handleDragStart : null,
        onVerticalDragUpdate: isHorizontal ? _handleDragUpdate : null,
        onVerticalDragEnd: isHorizontal ? _handleDragEnd : null,
        onHorizontalDragStart: !isHorizontal ? _handleDragStart : null,
        onHorizontalDragUpdate: !isHorizontal ? _handleDragUpdate : null,
        onHorizontalDragEnd: !isHorizontal ? _handleDragEnd : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_gradientAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Container(
              width: isHorizontal ? widget.length : widget.thickness * _pulseAnimation.value,
              height: isHorizontal ? widget.thickness * _pulseAnimation.value : widget.length,
              child: Stack(
                children: [
                  // Main gradient bar
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: isHorizontal ? Alignment.centerLeft : Alignment.topCenter,
                        end: isHorizontal ? Alignment.centerRight : Alignment.bottomCenter,
                        colors: _generateRainbowColors(_gradientAnimation.value),
                        stops: _generateRainbowStops(),
                      ),
                      borderRadius: BorderRadius.circular(widget.thickness / 2),
                      boxShadow: [
                        // Glow effect
                        BoxShadow(
                          color: _getCurrentGlowColor(_gradientAnimation.value)
                              .withOpacity(_isDragging ? 0.8 : (_isHovered ? 0.5 : 0.3)),
                          blurRadius: _isDragging ? 20 : (_isHovered ? 15 : 10),
                          spreadRadius: _isDragging ? 3 : (_isHovered ? 2 : 0),
                        ),
                        // Inner shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                  ),
                  
                  // Notch pattern overlay
                  if (widget.showHandles)
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (index) => Container(
                            width: isHorizontal ? 2 : widget.thickness,
                            height: isHorizontal ? widget.thickness : 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Animated highlight
                  if (_isDragging || _isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.white.withOpacity(0.2),
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(widget.thickness / 2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  List<Color> _generateRainbowColors(double offset) {
    // Create smooth rainbow gradient that loops
    final colors = <Color>[];
    const steps = 7;
    
    for (int i = 0; i < steps; i++) {
      final hue = (360.0 * i / (steps - 1) + offset * 360) % 360;
      colors.add(HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor());
    }
    
    return colors;
  }
  
  List<double> _generateRainbowStops() {
    const steps = 7;
    return List.generate(steps, (i) => i / (steps - 1));
  }
  
  Color _getCurrentGlowColor(double offset) {
    // Get the dominant color at the center of the gradient
    final hue = (180 + offset * 360) % 360;
    return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  }
}

/// Elastic drag indicator that appears during resize
class DragIndicator extends StatefulWidget {
  final double position;
  final Axis orientation;
  final bool isActive;
  
  const DragIndicator({
    Key? key,
    required this.position,
    required this.orientation,
    this.isActive = false,
  }) : super(key: key);
  
  @override
  State<DragIndicator> createState() => _DragIndicatorState();
}

class _DragIndicatorState extends State<DragIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isActive) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(DragIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.orientation == Axis.horizontal ? double.infinity : 2,
            height: widget.orientation == Axis.vertical ? double.infinity : 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.5),
                  Colors.transparent,
                ],
                begin: widget.orientation == Axis.horizontal
                    ? Alignment.centerLeft
                    : Alignment.topCenter,
                end: widget.orientation == Axis.horizontal
                    ? Alignment.centerRight
                    : Alignment.bottomCenter,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Preset RGB drag bar configurations
class RGBDragBarPresets {
  static RGBDragBar horizontalPaneDivider({
    ValueChanged<double>? onDragUpdate,
  }) {
    return RGBDragBar(
      orientation: Axis.horizontal,
      thickness: 6.0,
      showHandles: true,
      onDragUpdate: onDragUpdate,
    );
  }
  
  static RGBDragBar verticalPaneDivider({
    ValueChanged<double>? onDragUpdate,
  }) {
    return RGBDragBar(
      orientation: Axis.vertical,
      thickness: 6.0,
      showHandles: true,
      onDragUpdate: onDragUpdate,
    );
  }
  
  static RGBDragBar miniDivider({
    required Axis orientation,
    ValueChanged<double>? onDragUpdate,
  }) {
    return RGBDragBar(
      orientation: orientation,
      thickness: 4.0,
      showHandles: false,
      onDragUpdate: onDragUpdate,
    );
  }
}