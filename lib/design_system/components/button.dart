import '../design_system.dart';

/// Professional synthesizer button component
/// Supports various styles including toggle, momentary, and icon buttons
enum SyntherButtonType {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

enum SyntherButtonSize {
  small,
  medium,
  large,
}

class SyntherButton extends StatefulWidget {
  final String? text;
  final Widget? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final SyntherButtonType type;
  final SyntherButtonSize size;
  final bool isToggled;
  final bool isLoading;
  final bool enabled;
  final Color? customColor;
  final String? tooltip;
  final Duration animationDuration;
  
  const SyntherButton({
    Key? key,
    this.text,
    this.icon,
    this.child,
    this.onPressed,
    this.onLongPress,
    this.type = SyntherButtonType.primary,
    this.size = SyntherButtonSize.medium,
    this.isToggled = false,
    this.isLoading = false,
    this.enabled = true,
    this.customColor,
    this.tooltip,
    this.animationDuration = const Duration(milliseconds: 150),
  }) : assert(
         text != null || icon != null || child != null,
         'Button must have text, icon, or child widget',
       ),
       super(key: key);
  
  // Convenience constructors
  const SyntherButton.primary({
    Key? key,
    String? text,
    Widget? icon,
    Widget? child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    SyntherButtonSize size = SyntherButtonSize.medium,
    bool isToggled = false,
    bool isLoading = false,
    bool enabled = true,
    String? tooltip,
  }) : this(
         key: key,
         text: text,
         icon: icon,
         child: child,
         onPressed: onPressed,
         onLongPress: onLongPress,
         type: SyntherButtonType.primary,
         size: size,
         isToggled: isToggled,
         isLoading: isLoading,
         enabled: enabled,
         tooltip: tooltip,
       );
  
  const SyntherButton.icon({
    Key? key,
    required Widget icon,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    SyntherButtonType type = SyntherButtonType.ghost,
    SyntherButtonSize size = SyntherButtonSize.medium,
    bool isToggled = false,
    bool enabled = true,
    String? tooltip,
  }) : this(
         key: key,
         icon: icon,
         onPressed: onPressed,
         onLongPress: onLongPress,
         type: type,
         size: size,
         isToggled: isToggled,
         enabled: enabled,
         tooltip: tooltip,
       );
  
  @override
  State<SyntherButton> createState() => _SyntherButtonState();
}

class _SyntherButtonState extends State<SyntherButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
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
  
  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (!_isHovered) {
      _animationController.reverse();
    }
    widget.onPressed?.call();
  }
  
  void _handleTapCancel() {
    setState(() => _isPressed = false);
    if (!_isHovered) {
      _animationController.reverse();
    }
  }
  
  void _handlePointerEnter(PointerEnterEvent event) {
    if (!widget.enabled) return;
    setState(() => _isHovered = true);
    _animationController.forward();
  }
  
  void _handlePointerExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
    if (!_isPressed) {
      _animationController.reverse();
    }
  }
  
  ButtonStyle _getButtonStyle() {
    final colorScheme = _getColorScheme();
    final dimensions = _getDimensions();
    
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (!widget.enabled) return colorScheme.disabled;
        if (widget.isToggled) return colorScheme.primary;
        if (states.contains(MaterialState.pressed)) return colorScheme.pressed;
        if (states.contains(MaterialState.hovered)) return colorScheme.hovered;
        return colorScheme.background;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        if (!widget.enabled) return DesignTokens.textDisabled;
        if (widget.isToggled) return colorScheme.onPrimary;
        return colorScheme.foreground;
      }),
      minimumSize: MaterialStateProperty.all(Size(
        dimensions.minWidth,
        dimensions.height,
      )),
      padding: MaterialStateProperty.all(dimensions.padding),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        side: widget.type == SyntherButtonType.outline
          ? BorderSide(color: colorScheme.border)
          : BorderSide.none,
      )),
      elevation: MaterialStateProperty.all(0),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
    );
  }
  
  _ButtonColorScheme _getColorScheme() {
    final customColor = widget.customColor;
    
    switch (widget.type) {
      case SyntherButtonType.primary:
        return _ButtonColorScheme(
          background: customColor ?? DesignTokens.neonCyan,
          foreground: DesignTokens.backgroundPrimary,
          onPrimary: DesignTokens.backgroundPrimary,
          primary: customColor ?? DesignTokens.neonCyan,
          hovered: (customColor ?? DesignTokens.neonCyan).withOpacity(0.8),
          pressed: (customColor ?? DesignTokens.neonCyan).withOpacity(0.6),
          disabled: DesignTokens.surfaceDisabled,
          border: customColor ?? DesignTokens.neonCyan,
        );
      
      case SyntherButtonType.secondary:
        return _ButtonColorScheme(
          background: DesignTokens.surface,
          foreground: DesignTokens.textPrimary,
          onPrimary: DesignTokens.textPrimary,
          primary: DesignTokens.neonPurple,
          hovered: DesignTokens.surfaceHover,
          pressed: DesignTokens.surfacePressed,
          disabled: DesignTokens.surfaceDisabled,
          border: DesignTokens.borderSecondary,
        );
      
      case SyntherButtonType.outline:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: customColor ?? DesignTokens.textPrimary,
          onPrimary: DesignTokens.backgroundPrimary,
          primary: customColor ?? DesignTokens.neonCyan,
          hovered: (customColor ?? DesignTokens.neonCyan).withOpacity(0.1),
          pressed: (customColor ?? DesignTokens.neonCyan).withOpacity(0.2),
          disabled: DesignTokens.surfaceDisabled,
          border: customColor ?? DesignTokens.borderPrimary,
        );
      
      case SyntherButtonType.ghost:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: customColor ?? DesignTokens.textSecondary,
          onPrimary: DesignTokens.textPrimary,
          primary: customColor ?? DesignTokens.neonCyan,
          hovered: DesignTokens.surfaceHover.withOpacity(0.5),
          pressed: DesignTokens.surfacePressed.withOpacity(0.5),
          disabled: DesignTokens.surfaceDisabled,
          border: Colors.transparent,
        );
      
      case SyntherButtonType.danger:
        return _ButtonColorScheme(
          background: DesignTokens.errorColor,
          foreground: Colors.white,
          onPrimary: Colors.white,
          primary: DesignTokens.errorColor,
          hovered: DesignTokens.errorColor.withOpacity(0.8),
          pressed: DesignTokens.errorColor.withOpacity(0.6),
          disabled: DesignTokens.surfaceDisabled,
          border: DesignTokens.errorColor,
        );
    }
  }
  
  _ButtonDimensions _getDimensions() {
    switch (widget.size) {
      case SyntherButtonSize.small:
        return _ButtonDimensions(
          height: 32,
          minWidth: 64,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing2,
            vertical: DesignTokens.spacing1,
          ),
          borderRadius: DesignTokens.radiusSmall,
          fontSize: 12,
        );
      
      case SyntherButtonSize.medium:
        return _ButtonDimensions(
          height: 40,
          minWidth: 80,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing3,
            vertical: DesignTokens.spacing2,
          ),
          borderRadius: DesignTokens.radiusMedium,
          fontSize: 14,
        );
      
      case SyntherButtonSize.large:
        return _ButtonDimensions(
          height: 48,
          minWidth: 96,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing4,
            vertical: DesignTokens.spacing3,
          ),
          borderRadius: DesignTokens.radiusMedium,
          fontSize: 16,
        );
    }
  }
  
  Widget _buildButtonContent() {
    if (widget.child != null) {
      return widget.child!;
    }
    
    final children = <Widget>[];
    
    if (widget.isLoading) {
      children.add(
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.enabled ? DesignTokens.textPrimary : DesignTokens.textDisabled,
            ),
          ),
        ),
      );
    } else if (widget.icon != null) {
      children.add(widget.icon!);
    }
    
    if (widget.text != null) {
      if (children.isNotEmpty) {
        children.add(SizedBox(width: DesignTokens.spacing1));
      }
      
      children.add(
        Text(
          widget.text!,
          style: SyntherTypography.labelMedium.copyWith(
            fontSize: _getDimensions().fontSize,
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme();
    
    Widget button = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_getDimensions().borderRadius),
              boxShadow: [
                if (widget.enabled && !_isPressed) ...SyntherShadows.elevation1,
                if (widget.enabled && _isPressed) ...SyntherShadows.inset1,
                if (widget.enabled && (_isHovered || widget.isToggled))
                  ...SyntherShadows.customGlow(
                    color: widget.customColor ?? DesignTokens.neonCyan,
                    intensity: _glowAnimation.value,
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.enabled && !widget.isLoading ? () {} : null,
              onLongPress: widget.onLongPress,
              style: _getButtonStyle(),
              child: _buildButtonContent(),
            ),
          ),
        );
      },
    );
    
    button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: MouseRegion(
        onEnter: _handlePointerEnter,
        onExit: _handlePointerExit,
        cursor: widget.enabled 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.forbidden,
        child: button,
      ),
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

class _ButtonColorScheme {
  final Color background;
  final Color foreground;
  final Color onPrimary;
  final Color primary;
  final Color hovered;
  final Color pressed;
  final Color disabled;
  final Color border;
  
  _ButtonColorScheme({
    required this.background,
    required this.foreground,
    required this.onPrimary,
    required this.primary,
    required this.hovered,
    required this.pressed,
    required this.disabled,
    required this.border,
  });
}

class _ButtonDimensions {
  final double height;
  final double minWidth;
  final EdgeInsets padding;
  final double borderRadius;
  final double fontSize;
  
  _ButtonDimensions({
    required this.height,
    required this.minWidth,
    required this.padding,
    required this.borderRadius,
    required this.fontSize,
  });
}