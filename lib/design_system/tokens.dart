import 'dart:ui';
import 'package:flutter/material.dart';

/// Synther Design System Tokens
/// Based on neo-skeuomorphic vaporwave aesthetic
class SyntherTokens {
  // Prevent instantiation
  SyntherTokens._();

  // ===== COLOR SYSTEM =====
  
  // Background colors - deep space blacks
  static const Color backgroundVoid = Color(0xFF000000);
  static const Color backgroundDeep = Color(0xFF0A0A0F);
  static const Color backgroundSurface = Color(0xFF12121A);
  static const Color backgroundElevated = Color(0xFF1A1A25);
  static const Color backgroundCard = Color(0xFF20202D);
  
  // Neon accent colors - vaporwave palette
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonPurple = Color(0xFFFF00FF);
  static const Color neonPink = Color(0xFFFF0080);
  static const Color neonBlue = Color(0xFF0080FF);
  static const Color neonGreen = Color(0xFF00FF80);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonOrange = Color(0xFFFF8000);
  
  // Text colors with hierarchy
  static const Color textPrimary = Color(0xFFE0E0FF);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color textTertiary = Color(0xFF606080);
  static const Color textDisabled = Color(0xFF404050);
  
  // Semantic colors
  static const Color success = Color(0xFF00FF80);
  static const Color warning = Color(0xFFFFAA00);
  static const Color error = Color(0xFFFF0040);
  static const Color info = Color(0xFF00AAFF);
  
  // ===== GRADIENTS =====
  
  static const LinearGradient neonGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [neonCyan, neonPurple, neonPink],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient neonGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [neonBlue, neonPurple, neonPink],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const RadialGradient glowGradient = RadialGradient(
    colors: [
      Color(0xFF00FFFF),
      Color(0x8000FFFF),
      Color(0x0000FFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // ===== SPACING SYSTEM =====
  
  static const double spacingMicro = 4.0;
  static const double spacingTiny = 8.0;
  static const double spacingSmall = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingHuge = 48.0;
  static const double spacingMassive = 64.0;
  
  // ===== BORDER RADIUS =====
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 999.0;
  
  // ===== SHADOWS & GLOWS =====
  
  static List<BoxShadow> neumorphicShadow({
    Color color = backgroundSurface,
    double elevation = 8.0,
  }) {
    return [
      // Dark shadow
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        offset: Offset(elevation * 0.5, elevation * 0.5),
        blurRadius: elevation,
        spreadRadius: 0,
      ),
      // Light shadow
      BoxShadow(
        color: Color.lerp(color, Colors.white, 0.1)!.withOpacity(0.3),
        offset: Offset(-elevation * 0.5, -elevation * 0.5),
        blurRadius: elevation,
        spreadRadius: 0,
      ),
    ];
  }
  
  static List<BoxShadow> neonGlow({
    required Color color,
    double intensity = 1.0,
    double spread = 0.0,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(0.6 * intensity),
        blurRadius: 20 * intensity,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: color.withOpacity(0.4 * intensity),
        blurRadius: 40 * intensity,
        spreadRadius: spread * 0.5,
      ),
      BoxShadow(
        color: color.withOpacity(0.2 * intensity),
        blurRadius: 80 * intensity,
        spreadRadius: spread * 0.25,
      ),
    ];
  }
  
  // ===== ANIMATION CONSTANTS =====
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationXSlow = Duration(milliseconds: 1000);
  
  static const Curve animationCurveDefault = Curves.easeInOutCubic;
  static const Curve animationCurveSpring = Curves.elasticOut;
  static const Curve animationCurveBounce = Curves.bounceOut;
  
  // ===== BLUR EFFECTS =====
  
  static const double blurLight = 5.0;
  static const double blurMedium = 10.0;
  static const double blurHeavy = 20.0;
  static const double blurExtreme = 40.0;
  
  // ===== COMPONENT SIZES =====
  
  static const double knobSizeSmall = 48.0;
  static const double knobSizeMedium = 64.0;
  static const double knobSizeLarge = 80.0;
  static const double knobSizeXLarge = 96.0;
  
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 40.0;
  static const double buttonHeightLarge = 48.0;
  
  static const double sliderTrackHeight = 4.0;
  static const double sliderThumbSize = 20.0;
  
  // ===== Z-INDEX LAYERS =====
  
  static const double zIndexBackground = 0;
  static const double zIndexContent = 10;
  static const double zIndexElevated = 20;
  static const double zIndexModal = 30;
  static const double zIndexTooltip = 40;
  static const double zIndexNotification = 50;
  
  // ===== HAPTIC FEEDBACK LEVELS =====
  
  static const HapticLevel hapticLight = HapticLevel.light;
  static const HapticLevel hapticMedium = HapticLevel.medium;
  static const HapticLevel hapticHeavy = HapticLevel.heavy;
  
  // ===== PERFORMANCE THRESHOLDS =====
  
  static const int targetFPS = 60;
  static const double maxCPUUsage = 25.0; // Percentage
  static const double maxMemoryUsage = 100.0; // MB
  static const Duration maxResponseTime = Duration(milliseconds: 100);
}

/// Haptic feedback intensity levels
enum HapticLevel {
  light,
  medium,
  heavy,
  selection,
  impact,
}