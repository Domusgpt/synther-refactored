import 'package:flutter/material.dart';
import 'tokens.dart';

/// Professional typography system for Synther
/// Implements vaporwave aesthetic with neon glow effects
class SyntherTypography {
  // Font families
  static const String displayFont = 'Roboto';
  static const String uiFont = 'Roboto';
  static const String monoFont = 'Courier';
  
  // Display styles - for headers and hero text
  static TextStyle displayLarge = TextStyle(
    fontFamily: displayFont,
    fontSize: 57,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.25,
    height: 1.12,
    color: DesignTokens.textPrimary,
    shadows: [
      Shadow(
        color: DesignTokens.neonCyan.withOpacity(0.8),
        blurRadius: 20,
      ),
      Shadow(
        color: DesignTokens.neonCyan.withOpacity(0.4),
        blurRadius: 40,
      ),
    ],
  );
  
  static TextStyle displayMedium = TextStyle(
    fontFamily: displayFont,
    fontSize: 45,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.16,
    color: DesignTokens.textPrimary,
    shadows: [
      Shadow(
        color: DesignTokens.neonPurple.withOpacity(0.6),
        blurRadius: 16,
      ),
    ],
  );
  
  static TextStyle displaySmall = TextStyle(
    fontFamily: displayFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
    color: DesignTokens.textPrimary,
    shadows: [
      Shadow(
        color: DesignTokens.neonPink.withOpacity(0.5),
        blurRadius: 12,
      ),
    ],
  );
  
  // Headline styles - for section headers
  static TextStyle headlineLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle headlineMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle headlineSmall = TextStyle(
    fontFamily: uiFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: DesignTokens.textPrimary,
  );
  
  // Title styles - for component headers
  static TextStyle titleLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle titleMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle titleSmall = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    color: DesignTokens.textPrimary,
  );
  
  // Body styles - for general content
  static TextStyle bodyLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: DesignTokens.textSecondary,
  );
  
  static TextStyle bodyMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: DesignTokens.textSecondary,
  );
  
  static TextStyle bodySmall = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: DesignTokens.textSecondary,
  );
  
  // Label styles - for buttons and controls
  static TextStyle labelLarge = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle labelMedium = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle labelSmall = TextStyle(
    fontFamily: uiFont,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
    color: DesignTokens.textPrimary,
  );
  
  // Monospace styles - for values and technical text
  static TextStyle monoLarge = TextStyle(
    fontFamily: monoFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.5,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle monoMedium = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.43,
    color: DesignTokens.textPrimary,
  );
  
  static TextStyle monoSmall = TextStyle(
    fontFamily: monoFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.33,
    color: DesignTokens.textPrimary,
  );
  
  // Special effect styles
  static TextStyle glowText({
    required Color glowColor,
    double glowIntensity = 1.0,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: displayFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: Colors.white,
      shadows: [
        Shadow(
          color: glowColor.withOpacity(0.8 * glowIntensity),
          blurRadius: 8,
        ),
        Shadow(
          color: glowColor.withOpacity(0.6 * glowIntensity),
          blurRadius: 16,
        ),
        Shadow(
          color: glowColor.withOpacity(0.4 * glowIntensity),
          blurRadius: 24,
        ),
      ],
    );
  }
  
  static TextStyle outlineText({
    required Color outlineColor,
    double outlineWidth = 2.0,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: displayFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: Colors.transparent,
      shadows: [
        for (double i = 0; i < 360; i += 45)
          Shadow(
            color: outlineColor,
            offset: Offset(
              outlineWidth * Math.cos(i * Math.pi / 180),
              outlineWidth * Math.sin(i * Math.pi / 180),
            ),
          ),
      ],
    );
  }
  
  static TextStyle gradientText({
    required List<Color> colors,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: displayFont,
      fontSize: fontSize,
      fontWeight: fontWeight,
      foreground: Paint()
        ..shader = LinearGradient(
          colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
    );
  }
  
  // Theme extension for easy access
  static ThemeData applyToTheme(ThemeData base) {
    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
    );
  }
}

// Convenience widget for animated text effects
class GlowingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;
  final Duration animationDuration;
  final bool animate;
  
  const GlowingText({
    Key? key,
    required this.text,
    this.style,
    this.glowColor = DesignTokens.neonCyan,
    this.animationDuration = const Duration(seconds: 2),
    this.animate = true,
  }) : super(key: key);
  
  @override
  State<GlowingText> createState() => _GlowingTextState();
}

class _GlowingTextState extends State<GlowingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(
        widget.text,
        style: SyntherTypography.glowText(
          glowColor: widget.glowColor,
          fontSize: widget.style?.fontSize ?? 16,
          fontWeight: widget.style?.fontWeight ?? FontWeight.w600,
        ).merge(widget.style),
      );
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: SyntherTypography.glowText(
            glowColor: widget.glowColor,
            glowIntensity: _animation.value,
            fontSize: widget.style?.fontSize ?? 16,
            fontWeight: widget.style?.fontWeight ?? FontWeight.w600,
          ).merge(widget.style),
        );
      },
    );
  }
}

// Math import for trigonometric functions
import 'dart:math' as Math;