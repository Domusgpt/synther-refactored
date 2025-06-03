import 'dart:ui';
import '../design_system.dart';

/// Glassmorphic pane component for Morph-UI
/// Creates translucent windows that float over the visualizer
class GlassmorphicPane extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color tintColor;
  final double blurIntensity;
  final double opacity;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool showBorder;
  final double borderWidth;
  final double borderRadius;
  final bool enableGlow;
  final double glowIntensity;
  final Duration animationDuration;
  
  const GlassmorphicPane({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.tintColor = DesignTokens.neonCyan,
    this.blurIntensity = 10.0,
    this.opacity = 0.1,
    this.isCollapsed = false,
    this.onTap,
    this.onDoubleTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
    this.showBorder = true,
    this.borderWidth = 1.0,
    this.borderRadius = 20.0,
    this.enableGlow = true,
    this.glowIntensity = 1.0,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  State<GlassmorphicPane> createState() => _GlassmorphicPaneState();
}

class _GlassmorphicPaneState extends State<GlassmorphicPane>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
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
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isCollapsed) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(GlassmorphicPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
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
  
  void _handlePointerEnter(PointerEnterEvent event) {
    setState(() => _isHovered = true);
  }
  
  void _handlePointerExit(PointerExitEvent event) {
    setState(() => _isHovered = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedOpacity(
            opacity: _opacityAnimation.value,
            duration: widget.animationDuration,
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              child: MouseRegion(
                onEnter: _handlePointerEnter,
                onExit: _handlePointerExit,
                child: GestureDetector(
                  onTap: widget.onTap,
                  onDoubleTap: widget.onDoubleTap,
                  child: Stack(
                    children: [
                      // Glow effect layer
                      if (widget.enableGlow)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: widget.tintColor.withOpacity(
                                  _isHovered ? 0.4 * widget.glowIntensity : 0.2 * widget.glowIntensity
                                ),
                                blurRadius: _isHovered ? 30 : 20,
                                spreadRadius: _isHovered ? 5 : 0,
                              ),
                              BoxShadow(
                                color: widget.tintColor.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      
                      // Main glassmorphic container
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              widget.tintColor.withOpacity(widget.opacity),
                              widget.tintColor.withOpacity(widget.opacity * 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          border: widget.showBorder
                            ? Border.all(
                                width: widget.borderWidth,
                                color: widget.tintColor.withOpacity(
                                  _isHovered ? 0.5 : 0.3
                                ),
                              )
                            : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: widget.blurIntensity,
                              sigmaY: widget.blurIntensity,
                            ),
                            child: Container(
                              padding: widget.padding,
                              child: widget.child,
                            ),
                          ),
                        ),
                      ),
                      
                      // Edge highlight
                      if (widget.showBorder && _isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.1),
                                ],
                                stops: const [0.0, 0.1, 0.9, 1.0],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Preset glassmorphic pane styles
class GlassmorphicStyles {
  // XY Pad style (cyan tinted)
  static GlassmorphicPane xyPad({
    required Widget child,
    double? width,
    double? height,
    VoidCallback? onTap,
  }) {
    return GlassmorphicPane(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      tintColor: DesignTokens.neonCyan,
      opacity: 0.08,
      blurIntensity: 15.0,
      enableGlow: true,
      glowIntensity: 1.2,
      onTap: onTap,
      child: child,
    );
  }
  
  // Control panel style (magenta tinted)
  static GlassmorphicPane controlPanel({
    required Widget child,
    double? width,
    double? height,
    bool isCollapsed = false,
  }) {
    return GlassmorphicPane(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      tintColor: DesignTokens.neonPurple,
      opacity: 0.1,
      blurIntensity: 12.0,
      isCollapsed: isCollapsed,
      child: child,
    );
  }
  
  // Drum pad style (pink tinted)
  static GlassmorphicPane drumPad({
    required Widget child,
    double? size,
    VoidCallback? onTap,
  }) {
    return GlassmorphicPane(
      width: size ?? 80,
      height: size ?? 80,
      tintColor: DesignTokens.neonPink,
      opacity: 0.12,
      blurIntensity: 8.0,
      borderRadius: 12.0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(4),
      onTap: onTap,
      child: child,
    );
  }
  
  // Bezel tab style
  static GlassmorphicPane bezelTab({
    required Widget child,
    required Color tintColor,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GlassmorphicPane(
      width: 100,
      height: 40,
      tintColor: tintColor,
      opacity: isActive ? 0.2 : 0.05,
      blurIntensity: 6.0,
      borderRadius: 8.0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(4),
      enableGlow: isActive,
      glowIntensity: 0.8,
      onTap: onTap,
      child: child,
    );
  }
  
  // Parameter vault style
  static GlassmorphicPane parameterVault({
    required Widget child,
    double? width,
    double? height,
    bool isOpen = false,
  }) {
    return GlassmorphicPane(
      width: width ?? 200,
      height: height ?? 300,
      tintColor: DesignTokens.neonCyan,
      opacity: 0.15,
      blurIntensity: 20.0,
      borderRadius: 16.0,
      isCollapsed: !isOpen,
      child: child,
    );
  }
}

/// Animated glassmorphic container that pulses with audio
class AudioReactiveGlassmorphicPane extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color baseColor;
  final double audioLevel;
  final double sensitivity;
  
  const AudioReactiveGlassmorphicPane({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.baseColor = DesignTokens.neonCyan,
    this.audioLevel = 0.0,
    this.sensitivity = 1.0,
  }) : super(key: key);
  
  @override
  State<AudioReactiveGlassmorphicPane> createState() => 
      _AudioReactiveGlassmorphicPaneState();
}

class _AudioReactiveGlassmorphicPaneState 
    extends State<AudioReactiveGlassmorphicPane>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void didUpdateWidget(AudioReactiveGlassmorphicPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioLevel != oldWidget.audioLevel) {
      _pulseController.forward(from: 0);
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final intensity = widget.audioLevel * widget.sensitivity;
        final pulseValue = _pulseAnimation.value * intensity;
        
        return GlassmorphicPane(
          width: widget.width,
          height: widget.height,
          tintColor: widget.baseColor,
          opacity: 0.1 + (pulseValue * 0.1),
          blurIntensity: 10.0 + (pulseValue * 5.0),
          glowIntensity: 0.8 + (pulseValue * 0.4),
          borderWidth: 1.0 + (pulseValue * 0.5),
          child: widget.child,
        );
      },
    );
  }
}