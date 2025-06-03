import 'package:flutter/material.dart';
import 'tokens.dart';

/// Professional shadow system for neumorphic design
/// Creates depth and tactile feel for vaporwave aesthetic
class SyntherShadows {
  // Base shadow configurations
  static const double _baseBlur = 12.0;
  static const double _baseSpread = 0.0;
  static const Offset _lightOffset = Offset(-6, -6);
  static const Offset _darkOffset = Offset(6, 6);
  
  // Elevation levels
  static List<BoxShadow> elevation0 = [];
  
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: DesignTokens.shadowLight,
      blurRadius: _baseBlur * 0.5,
      spreadRadius: _baseSpread,
      offset: _lightOffset * 0.5,
    ),
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur * 0.5,
      spreadRadius: _baseSpread,
      offset: _darkOffset * 0.5,
    ),
  ];
  
  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: DesignTokens.shadowLight,
      blurRadius: _baseBlur,
      spreadRadius: _baseSpread,
      offset: _lightOffset,
    ),
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur,
      spreadRadius: _baseSpread,
      offset: _darkOffset,
    ),
  ];
  
  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: DesignTokens.shadowLight,
      blurRadius: _baseBlur * 1.5,
      spreadRadius: _baseSpread,
      offset: _lightOffset * 1.5,
    ),
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur * 1.5,
      spreadRadius: _baseSpread,
      offset: _darkOffset * 1.5,
    ),
  ];
  
  static List<BoxShadow> elevation4 = [
    BoxShadow(
      color: DesignTokens.shadowLight,
      blurRadius: _baseBlur * 2,
      spreadRadius: _baseSpread,
      offset: _lightOffset * 2,
    ),
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur * 2,
      spreadRadius: _baseSpread,
      offset: _darkOffset * 2,
    ),
  ];
  
  // Inset shadows for pressed states
  static List<BoxShadow> inset1 = [
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur * 0.5,
      spreadRadius: _baseSpread,
      offset: _lightOffset * -0.5,
    ),
    BoxShadow(
      color: DesignTokens.shadowLight.withOpacity(0.7),
      blurRadius: _baseBlur * 0.5,
      spreadRadius: _baseSpread,
      offset: _darkOffset * -0.5,
    ),
  ];
  
  static List<BoxShadow> inset2 = [
    BoxShadow(
      color: DesignTokens.shadowDark,
      blurRadius: _baseBlur,
      spreadRadius: _baseSpread,
      offset: _lightOffset * -1,
    ),
    BoxShadow(
      color: DesignTokens.shadowLight.withOpacity(0.7),
      blurRadius: _baseBlur,
      spreadRadius: _baseSpread,
      offset: _darkOffset * -1,
    ),
  ];
  
  // Glow shadows for active/hover states
  static List<BoxShadow> glowCyan = [
    BoxShadow(
      color: DesignTokens.neonCyan.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: DesignTokens.neonCyan.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> glowPurple = [
    BoxShadow(
      color: DesignTokens.neonPurple.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: DesignTokens.neonPurple.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> glowPink = [
    BoxShadow(
      color: DesignTokens.neonPink.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: DesignTokens.neonPink.withOpacity(0.2),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];
  
  // Combined shadows for special effects
  static List<BoxShadow> neuomorphicRaised = [
    ...elevation2,
  ];
  
  static List<BoxShadow> neuomorphicPressed = [
    ...inset1,
  ];
  
  static List<BoxShadow> neuomorphicHover(Color glowColor) => [
    ...elevation2,
    BoxShadow(
      color: glowColor.withOpacity(0.3),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
  
  // Dynamic shadow functions
  static List<BoxShadow> customGlow({
    required Color color,
    double intensity = 1.0,
    double blur = 20,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(0.4 * intensity),
        blurRadius: blur,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: blur * 2,
        spreadRadius: 0,
      ),
    ];
  }
  
  static List<BoxShadow> customNeumorphic({
    double elevation = 2.0,
    Color? lightColor,
    Color? darkColor,
  }) {
    final light = lightColor ?? DesignTokens.shadowLight;
    final dark = darkColor ?? DesignTokens.shadowDark;
    
    return [
      BoxShadow(
        color: light,
        blurRadius: _baseBlur * elevation * 0.5,
        offset: _lightOffset * elevation * 0.5,
      ),
      BoxShadow(
        color: dark,
        blurRadius: _baseBlur * elevation * 0.5,
        offset: _darkOffset * elevation * 0.5,
      ),
    ];
  }
  
  // Animated shadow widget
  static Widget animatedShadow({
    required Widget child,
    required List<BoxShadow> shadows,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: BoxDecoration(
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

/// Container with neumorphic shadows
class NeumorphicContainer extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final bool isPressed;
  final bool showGlow;
  final Color glowColor;
  final VoidCallback? onTap;
  final Duration animationDuration;
  
  const NeumorphicContainer({
    Key? key,
    this.child,
    this.width = double.infinity,
    this.height = 60,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.shadows,
    this.isPressed = false,
    this.showGlow = false,
    this.glowColor = DesignTokens.neonCyan,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 150),
  }) : super(key: key);
  
  @override
  State<NeumorphicContainer> createState() => _NeumorphicContainerState();
}

class _NeumorphicContainerState extends State<NeumorphicContainer> {
  bool _isPressed = false;
  bool _isHovered = false;
  
  List<BoxShadow> get _shadows {
    if (widget.shadows != null) return widget.shadows!;
    
    if (_isPressed || widget.isPressed) {
      return SyntherShadows.neuomorphicPressed;
    } else if (_isHovered && widget.showGlow) {
      return SyntherShadows.neuomorphicHover(widget.glowColor);
    } else {
      return SyntherShadows.neuomorphicRaised;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? EdgeInsets.all(DesignTokens.spacing3),
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.color ?? DesignTokens.surface,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(DesignTokens.radiusMedium),
            boxShadow: _shadows,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Circular neumorphic container for knobs and buttons
class NeumorphicCircle extends StatelessWidget {
  final Widget? child;
  final double size;
  final Color? color;
  final List<BoxShadow>? shadows;
  final bool isPressed;
  final VoidCallback? onTap;
  
  const NeumorphicCircle({
    Key? key,
    this.child,
    this.size = 60,
    this.color,
    this.shadows,
    this.isPressed = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      color: color,
      shadows: shadows,
      isPressed: isPressed,
      onTap: onTap,
      child: Center(child: child),
    );
  }
}