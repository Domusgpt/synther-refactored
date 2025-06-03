import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'tokens.dart';

/// Professional animation system for Synther
/// Provides smooth 60fps animations with custom curves
class SyntherAnimations {
  // Standard durations
  static const Duration instantaneous = Duration(milliseconds: 0);
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration slowest = Duration(milliseconds: 800);
  
  // Animation curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve smooth = Curves.fastOutSlowIn;
  
  // Custom curves for synth-specific animations
  static final Curve adsrAttack = CatmullRomCurve([
    const Offset(0.0, 0.0),
    const Offset(0.2, 0.8),
    const Offset(0.4, 0.95),
    const Offset(1.0, 1.0),
  ]);
  
  static final Curve adsrDecay = CatmullRomCurve([
    const Offset(0.0, 1.0),
    const Offset(0.3, 0.7),
    const Offset(0.6, 0.5),
    const Offset(1.0, 0.0),
  ]);
  
  static final Curve adsrRelease = CatmullRomCurve([
    const Offset(0.0, 1.0),
    const Offset(0.2, 0.6),
    const Offset(0.5, 0.2),
    const Offset(1.0, 0.0),
  ]);
  
  // Stagger delays for sequential animations
  static Duration staggerDelay(int index, {Duration baseDelay = const Duration(milliseconds: 50)}) {
    return baseDelay * index;
  }
  
  // Page transitions
  static Route<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }
  
  static Route<T> slideRoute<T>(Widget page, {Offset begin = const Offset(1.0, 0.0)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: easeOut),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: normal,
    );
  }
  
  // Reusable animation controllers
  static AnimationController createController({
    required TickerProvider vsync,
    Duration duration = normal,
    bool repeat = false,
    bool reverse = false,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
    );
    
    if (repeat) {
      controller.repeat(reverse: reverse);
    }
    
    return controller;
  }
}

/// Animated value widget for smooth transitions
class AnimatedValue extends StatefulWidget {
  final double value;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext, double) builder;
  
  const AnimatedValue({
    Key? key,
    required this.value,
    this.duration = SyntherAnimations.fast,
    this.curve = SyntherAnimations.smooth,
    required this.builder,
  }) : super(key: key);
  
  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _currentValue;
  
  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: _currentValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }
  
  @override
  void didUpdateWidget(AnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.forward(from: 0).then((_) {
        _currentValue = widget.value;
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(context, _animation.value);
      },
    );
  }
}

/// Pulse animation widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool enabled;
  
  const PulseAnimation({
    Key? key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(seconds: 2),
    this.enabled = true,
  }) : super(key: key);
  
  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller.stop();
      _controller.value = 0;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer animation widget for loading states
class ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final bool enabled;
  
  const ShimmerAnimation({
    Key? key,
    required this.child,
    this.colors = const [
      Colors.transparent,
      Colors.white24,
      Colors.transparent,
    ],
    this.duration = const Duration(seconds: 2),
    this.enabled = true,
  }) : super(key: key);
  
  @override
  State<ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    
    if (widget.enabled) {
      _controller.repeat();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientTransform.slideX(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Gradient transform for shimmer effect
class GradientTransform {
  static GradientTransform slideX(double translateX) {
    return _SlideGradientTransform(translateX: translateX);
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double translateX;
  
  _SlideGradientTransform({required this.translateX});
  
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * translateX, 0.0, 0.0);
  }
}