import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../core/audio_engine.dart';
import '../visualizer/hypercube_visualizer.dart';
import 'holographic_widgets.dart';
import 'modulation_matrix_panel.dart';

/// Revolutionary Vaporwave Holographic Interface
/// 
/// Features intense parallax effects, skeuomorphic depth, and neon aesthetics
class VaporwaveInterface extends StatefulWidget {
  const VaporwaveInterface({super.key});
  
  @override
  State<VaporwaveInterface> createState() => _VaporwaveInterfaceState();
}

class _VaporwaveInterfaceState extends State<VaporwaveInterface> 
    with TickerProviderStateMixin {
  
  // Animation controllers for parallax and breathing effects
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scanlineController;
  late AnimationController _glitchController;
  
  // Touch interaction state
  final List<NeonRipple> _ripples = [];
  Offset? _lastTouchPosition;
  
  // UI state
  bool _isFullscreen = false;
  double _globalDepth = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    // Breathing effect - 6 second cycle
    _breathingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    
    // Continuous rotation - 30 second cycle  
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    // Pulse effects - 1.2 second cycle
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Scanline effect - 4 second cycle
    _scanlineController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    // Glitch effect - random intervals
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _startRandomGlitches();
  }
  
  void _startRandomGlitches() {
    Future.delayed(Duration(milliseconds: (math.Random().nextDouble() * 5000 + 2000).toInt()), () {
      if (mounted) {
        _glitchController.forward().then((_) {
          _glitchController.reset();
          _startRandomGlitches();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _scanlineController.dispose();
    _glitchController.dispose();
    super.dispose();
  }
  
  void _addNeonRipple(Offset position) {
    setState(() {
      _ripples.add(NeonRipple(
        position: position,
        startTime: DateTime.now(),
        color: _getRandomNeonColor(),
      ));
      if (_ripples.length > 8) {
        _ripples.removeAt(0);
      }
    });
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Trigger pulse animation
    _pulseController.forward().then((_) => _pulseController.reset());
  }
  
  Color _getRandomNeonColor() {
    final colors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Magenta  
      const Color(0xFF00FF00), // Lime
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF7B68EE), // Medium Slate Blue
      const Color(0xFFFF1493), // Deep Pink
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AudioEngine>(
        builder: (context, audioEngine, child) {
          return GestureDetector(
            onTapDown: (details) => _addNeonRipple(details.localPosition),
            onPanUpdate: (details) {
              _lastTouchPosition = details.localPosition;
              setState(() {
                _globalDepth = (details.localPosition.dy / MediaQuery.of(context).size.height);
              });
            },
            child: Stack(
              children: [
                // 4D Visualizer Background Layer
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1.0 + (_breathingController.value * 0.05),
                    child: HypercubeVisualizer(audioEngine: audioEngine),
                  ),
                ),
                
                // Parallax Grid Layer
                _buildParallaxGrid(),
                
                // Scanline Effect
                _buildScanlines(),
                
                // Main UI Container with Depth
                _buildMainInterface(audioEngine),
                
                // Floating Orbital Controls
                ..._buildOrbitalControls(audioEngine),
                
                // Neon Ripples
                ..._ripples.map(_buildNeonRipple),
                
                // Glitch Overlay
                if (_glitchController.value > 0)
                  _buildGlitchOverlay(),
                
                // Status HUD
                _buildStatusHUD(audioEngine),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildParallaxGrid() {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingController, _rotationController]),
      builder: (context, child) {
        return CustomPaint(
          painter: ParallaxGridPainter(
            breathing: _breathingController.value,
            rotation: _rotationController.value,
            globalDepth: _globalDepth,
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildScanlines() {
    return AnimatedBuilder(
      animation: _scanlineController,
      builder: (context, child) {
        return IgnorePointer(
          child: CustomPaint(
            painter: ScanlinePainter(progress: _scanlineController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildMainInterface(AudioEngine audioEngine) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Stack(
          children: [
            // Hexagonal Note Grid
            Center(
              child: Transform.translate(
                offset: Offset(0, _globalDepth * 20),
                child: HolographicHexGrid(audioEngine: audioEngine),
              ),
            ),
            
            // XY Morph Pad
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              height: 120,
              child: Transform.translate(
                offset: Offset(0, _globalDepth * 30),
                child: VaporwaveMorphPad(audioEngine: audioEngine),
              ),
            ),
          ],
        ),
      ),
    ).animate(effects: [
      const SlideEffect(
        duration: Duration(milliseconds: 800),
        begin: Offset(0, 0.1),
        end: Offset.zero,
        curve: Curves.easeOutCubic,
      ),
      const FadeEffect(
        duration: Duration(milliseconds: 600),
        begin: 0,
        end: 1,
      ),
    ]);
  }
  
  List<Widget> _buildOrbitalControls(AudioEngine audioEngine) {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    
    return List.generate(6, (index) {
      final angle = (index * math.pi / 3) + (_rotationController.value * math.pi * 2);
      final radius = math.min(screenSize.width, screenSize.height) * 0.35;
      final depthOffset = _globalDepth * 40;
      
      return Positioned(
        left: center.dx + math.cos(angle) * radius - 50 + depthOffset,
        top: center.dy + math.sin(angle) * radius - 50 - depthOffset,
        child: Transform.scale(
          scale: 1.0 + (_breathingController.value * 0.1),
          child: NeonOrbitalControl(
            parameter: _getParameterInfo(index),
            value: _getParameterValue(audioEngine, index),
            onChanged: (value) => _setParameterValue(audioEngine, index, value),
            color: _getParameterColor(index),
          ),
        ),
      );
    });
  }
  
  Widget _buildNeonRipple(NeonRipple ripple) {
    final age = DateTime.now().difference(ripple.startTime).inMilliseconds / 1000.0;
    if (age > 2.0) return const SizedBox.shrink();
    
    final radius = age * 150;
    final opacity = math.max(0, 1 - age / 2);
    
    return Positioned(
      left: ripple.position.dx - radius,
      top: ripple.position.dy - radius,
      child: IgnorePointer(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ripple.color.withOpacity(opacity),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: ripple.color.withOpacity(opacity * 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlitchOverlay() {
    return AnimatedBuilder(
      animation: _glitchController,
      builder: (context, child) {
        return IgnorePointer(
          child: CustomPaint(
            painter: GlitchPainter(intensity: _glitchController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildStatusHUD(AudioEngine audioEngine) {
    return Positioned(
      top: 50,
      right: 20,
      child: GlassmorphicContainer(
        width: 200,
        height: 150,
        borderRadius: 15,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            const Color(0xFF00FFFF).withOpacity(0.3),
            const Color(0xFFFF00FF).withOpacity(0.3),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusText('ENGINE', audioEngine.isInitialized ? 'ACTIVE' : 'OFFLINE'),
              _buildStatusText('LATENCY', '3.2ms'),
              _buildStatusText('4D MODE', 'HYPERCUBE'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0x3300FFFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onPressed: () => _openModulationMatrixPanel(audioEngine),
                  child: const Text('MOD MATRIX'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openModulationMatrixPanel(AudioEngine audioEngine) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: audioEngine,
          child: const ModulationMatrixPanel(),
        );
      },
    );
  }
  
  Widget _buildStatusText(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Parameter mapping helpers
  String _getParameterInfo(int index) {
    const params = ['FILTER', 'RESONANCE', 'ATTACK', 'DECAY', 'REVERB', 'VOLUME'];
    return params[index];
  }
  
  double _getParameterValue(AudioEngine engine, int index) {
    switch (index) {
      case 0: return engine.filterCutoff / 20000;
      case 1: return engine.filterResonance;
      case 2: return engine.attackTime / 5;
      case 3: return engine.decayTime / 5;
      case 4: return engine.reverbMix;
      case 5: return engine.masterVolume;
      default: return 0.5;
    }
  }
  
  void _setParameterValue(AudioEngine engine, int index, double value) {
    switch (index) {
      case 0: engine.setFilterCutoff(value * 20000); break;
      case 1: engine.setFilterResonance(value); break;
      case 2: engine.setAttackTime(value * 5); break;
      case 3: engine.setDecayTime(value * 5); break;
      case 4: engine.setReverbMix(value); break;
      case 5: engine.setMasterVolume(value); break;
    }
  }
  
  Color _getParameterColor(int index) {
    const colors = [
      Color(0xFF00FFFF), // Cyan
      Color(0xFF7B68EE), // Medium Slate Blue
      Color(0xFF00FF00), // Lime
      Color(0xFFFF1493), // Deep Pink
      Color(0xFFFFD700), // Gold
      Color(0xFFFF4500), // Orange Red
    ];
    return colors[index];
  }
}

// Supporting widgets and classes continue...
// (Due to length, I'll create separate files for the complex widgets)

class NeonRipple {
  final Offset position;
  final DateTime startTime;
  final Color color;
  
  NeonRipple({
    required this.position,
    required this.startTime,
    required this.color,
  });
}