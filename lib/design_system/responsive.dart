import 'package:flutter/material.dart';
import 'tokens.dart';

/// Responsive design system for Synther
/// Handles layout adaptation across all screen sizes
class SyntherResponsive {
  // Breakpoints
  static const double mobileSmall = 320;   // Small phones
  static const double mobile = 375;        // Standard phones
  static const double mobileLarge = 425;   // Large phones
  static const double tablet = 768;        // Tablets
  static const double desktop = 1024;      // Small desktop
  static const double desktopLarge = 1440; // Standard desktop
  static const double desktopXL = 1920;    // Large desktop
  
  // Get current size category
  static ResponsiveSize getSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < tablet) return ResponsiveSize.mobile;
    if (width < desktop) return ResponsiveSize.tablet;
    if (width < desktopLarge) return ResponsiveSize.desktop;
    return ResponsiveSize.desktopLarge;
  }
  
  // Adaptive values based on screen size
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    final size = getSize(context);
    
    switch (size) {
      case ResponsiveSize.mobile:
        return mobile;
      case ResponsiveSize.tablet:
        return tablet ?? mobile;
      case ResponsiveSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ResponsiveSize.desktopLarge:
        return desktopLarge ?? desktop ?? tablet ?? mobile;
    }
  }
  
  // Responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.all(value(
      context: context,
      mobile: DesignTokens.spacing3,
      tablet: DesignTokens.spacing4,
      desktop: DesignTokens.spacing5,
      desktopLarge: DesignTokens.spacing6,
    ));
  }
  
  // Responsive margins
  static EdgeInsets margin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value(
        context: context,
        mobile: DesignTokens.spacing3,
        tablet: DesignTokens.spacing5,
        desktop: DesignTokens.spacing7,
        desktopLarge: DesignTokens.spacing8,
      ),
      vertical: value(
        context: context,
        mobile: DesignTokens.spacing2,
        tablet: DesignTokens.spacing3,
        desktop: DesignTokens.spacing4,
        desktopLarge: DesignTokens.spacing5,
      ),
    );
  }
  
  // Grid columns
  static int gridColumns(BuildContext context) {
    return value(
      context: context,
      mobile: 4,
      tablet: 8,
      desktop: 12,
      desktopLarge: 16,
    );
  }
  
  // Component sizes
  static double knobSize(BuildContext context) {
    return value(
      context: context,
      mobile: DesignTokens.knobSizeSmall,
      tablet: DesignTokens.knobSizeMedium,
      desktop: DesignTokens.knobSizeLarge,
    );
  }
  
  static double faderHeight(BuildContext context) {
    return value(
      context: context,
      mobile: 120,
      tablet: 160,
      desktop: 200,
    );
  }
  
  static double buttonHeight(BuildContext context) {
    return value(
      context: context,
      mobile: 44,
      tablet: 48,
      desktop: 56,
    );
  }
  
  // Font scaling
  static double fontScale(BuildContext context) {
    return value(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
      desktopLarge: 1.3,
    );
  }
  
  // Layout helpers
  static bool isMobile(BuildContext context) => getSize(context) == ResponsiveSize.mobile;
  static bool isTablet(BuildContext context) => getSize(context) == ResponsiveSize.tablet;
  static bool isDesktop(BuildContext context) => 
    getSize(context) == ResponsiveSize.desktop || getSize(context) == ResponsiveSize.desktopLarge;
  
  // Orientation helpers
  static bool isPortrait(BuildContext context) => 
    MediaQuery.of(context).orientation == Orientation.portrait;
  static bool isLandscape(BuildContext context) => 
    MediaQuery.of(context).orientation == Orientation.landscape;
}

/// Responsive size categories
enum ResponsiveSize {
  mobile,
  tablet,
  desktop,
  desktopLarge,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ResponsiveSize) builder;
  final Widget? mobileBuilder;
  final Widget? tabletBuilder;
  final Widget? desktopBuilder;
  
  const ResponsiveBuilder({
    Key? key,
    required this.builder,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final size = SyntherResponsive.getSize(context);
    
    // Use specific builders if provided
    switch (size) {
      case ResponsiveSize.mobile:
        if (mobileBuilder != null) return mobileBuilder!;
        break;
      case ResponsiveSize.tablet:
        if (tabletBuilder != null) return tabletBuilder!;
        break;
      case ResponsiveSize.desktop:
      case ResponsiveSize.desktopLarge:
        if (desktopBuilder != null) return desktopBuilder!;
        break;
    }
    
    // Fall back to general builder
    return builder(context, size);
  }
}

/// Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? overrideColumns;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = DesignTokens.spacing2,
    this.runSpacing = DesignTokens.spacing2,
    this.overrideColumns,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final columns = overrideColumns ?? SyntherResponsive.gridColumns(context);
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - (spacing * (columns - 1))) / columns;
    
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) => SizedBox(
        width: itemWidth,
        child: child,
      )).toList(),
    );
  }
}

/// Responsive row that switches to column on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool forceRow;
  
  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = DesignTokens.spacing3,
    this.forceRow = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isMobile = SyntherResponsive.isMobile(context);
    final isPortrait = SyntherResponsive.isPortrait(context);
    final shouldStack = !forceRow && isMobile && isPortrait;
    
    if (shouldStack) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i == 0 || i == children.length - 1)
            children[i]
          else
            Flexible(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;
  
  const ResponsivePadding({
    Key? key,
    required this.child,
    this.customPadding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: customPadding ?? SyntherResponsive.padding(context),
      child: child,
    );
  }
}