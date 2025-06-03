import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../core/audio_engine.dart';

/// Holographic Hexagonal Note Grid
class HolographicHexGrid extends StatefulWidget {
  final AudioEngine audioEngine;
  
  const HolographicHexGrid({super.key, required this.audioEngine});
  
  @override
  State<HolographicHexGrid> createState() => _HolographicHexGridState();
}

class _HolographicHexGridState extends State<HolographicHexGrid>
    with TickerProviderStateMixin {
  
  final Set<int> _activeNotes = {};
  int _baseOctave = 4;
  late AnimationController _glowController;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 350,
      child: Stack(
        children: [
          // Glow effect background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFFF).withOpacity(0.3 * _glowController.value),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Hex grid
          CustomPaint(
            painter: HolographicHexPainter(
              activeNotes: _activeNotes,
              baseOctave: _baseOctave,
              glowIntensity: _glowController.value,
            ),
            child: GestureDetector(
              onPanStart: (details) => _handleTouch(details.localPosition, true),
              onPanUpdate: (details) => _handleTouch(details.localPosition, true),
              onPanEnd: (_) => _releaseAllNotes(),
              onTapDown: (details) => _handleTouch(details.localPosition, true),
              onTapUp: (_) => _releaseAllNotes(),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleTouch(Offset position, bool pressed) {
    final note = _positionToNote(position);
    if (note != null && note >= 0 && note <= 127) {
      if (pressed && !_activeNotes.contains(note)) {
        setState(() => _activeNotes.add(note));
        widget.audioEngine.noteOn(note, 0.8);
        HapticFeedback.mediumImpact();
      }
    }
  }
  
  void _releaseAllNotes() {
    for (final note in _activeNotes) {
      widget.audioEngine.noteOff(note);
    }
    setState(() => _activeNotes.clear());
    HapticFeedback.lightImpact();
  }
  
  int? _positionToNote(Offset position) {
    final center = Offset(175, 175);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    
    // Hexagonal grid math
    final hexSize = 35.0;
    final q = (2/3 * dx) / hexSize;
    final r = (-1/3 * dx + math.sqrt(3)/3 * dy) / hexSize;
    
    final roundedQ = q.round();
    final roundedR = r.round();
    final roundedS = -roundedQ - roundedR;
    
    // Cube coordinate rounding
    final qDiff = (q - roundedQ).abs();
    final rDiff = (r - roundedR).abs();
    final sDiff = (-q - r - roundedS).abs();
    
    if (qDiff > rDiff && qDiff > sDiff) {
      // Use rounded r and s
    } else if (rDiff > sDiff) {
      // Use rounded q and s
    }
    
    // Convert to note using harmonic relationships
    final noteOffset = roundedQ * 7 + roundedR * 4; // Perfect fifth + major third
    final note = 60 + (_baseOctave - 4) * 12 + noteOffset;
    
    // Check if within valid hex grid bounds
    if (roundedQ.abs() + roundedR.abs() + roundedS.abs() > 6) {
      return null;
    }
    
    return note.clamp(0, 127);
  }
}

/// Neon Orbital Control
class NeonOrbitalControl extends StatefulWidget {
  final String parameter;
  final double value;
  final Function(double) onChanged;
  final Color color;
  
  const NeonOrbitalControl({
    super.key,
    required this.parameter,
    required this.value,
    required this.onChanged,
    required this.color,
  });
  
  @override
  State<NeonOrbitalControl> createState() => _NeonOrbitalControlState();
}

class _NeonOrbitalControlState extends State<NeonOrbitalControl>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pulseController;
  bool _isActive = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        setState(() => _isActive = true);
        _pulseController.forward();
        HapticFeedback.selectionClick();
      },
      onPanUpdate: (details) {
        final delta = details.delta.dy / -100;
        widget.onChanged((widget.value + delta).clamp(0, 1));
      },
      onPanEnd: (_) {
        setState(() => _isActive = false);
        _pulseController.reverse();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.1);
          final glowIntensity = 0.3 + (_pulseController.value * 0.4);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(glowIntensity),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: GlassmorphicContainer(
                width: 100,
                height: 100,
                borderRadius: 50,
                blur: 20,
                alignment: Alignment.center,
                border: _isActive ? 3 : 2,
                linearGradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.3),
                    widget.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(_isActive ? 0.8 : 0.4),
                    widget.color.withOpacity(_isActive ? 0.4 : 0.2),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Value ring
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: widget.value,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                        strokeWidth: 4,
                      ),
                    ),
                    
                    // Label and value
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.parameter,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.value * 100).toInt()}%',
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Vaporwave Morph Pad
class VaporwaveMorphPad extends StatefulWidget {
  final AudioEngine audioEngine;
  
  const VaporwaveMorphPad({super.key, required this.audioEngine});
  
  @override
  State<VaporwaveMorphPad> createState() => _VaporwaveMorphPadState();
}

class _VaporwaveMorphPadState extends State<VaporwaveMorphPad>
    with TickerProviderStateMixin {
  
  late AnimationController _waveController;
  Offset _touchPosition = const Offset(0.5, 0.5);
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return GlassmorphicContainer(
          width: double.infinity,
          height: 120,
          borderRadius: 25,
          blur: 30,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00FFFF).withOpacity(0.1),
              const Color(0xFFFF00FF).withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              const Color(0xFF00FFFF).withOpacity(0.4),
              const Color(0xFFFF00FF).withOpacity(0.4),
            ],
          ),
          child: Stack(
            children: [
              // Wave pattern background
              Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(
                    wavePhase: _waveController.value,
                    touchPosition: _touchPosition,
                  ),
                ),
              ),
              
              // Touch handler
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final size = context.size!;
                    final x = (details.localPosition.dx / size.width).clamp(0, 1);
                    final y = 1 - (details.localPosition.dy / size.height).clamp(0, 1);
                    
                    setState(() => _touchPosition = Offset(x, y));
                    
                    // Update audio parameters
                    widget.audioEngine.setFilterCutoff(x * 20000);
                    widget.audioEngine.setFilterResonance(y);
                    
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'MORPH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 28,
                              fontWeight: FontWeight.w100,
                              letterSpacing: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'FILTER',
                                style: TextStyle(
                                  color: const Color(0xFF00FFFF).withOpacity(0.7),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'RESONANCE',
                                style: TextStyle(
                                  color: const Color(0xFFFF00FF).withOpacity(0.7),
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Touch indicator
              Positioned(
                left: _touchPosition.dx * (context.size?.width ?? 0) - 10,
                top: (1 - _touchPosition.dy) * (context.size?.height ?? 0) - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painters
class HolographicHexPainter extends CustomPainter {
  final Set<int> activeNotes;
  final int baseOctave;
  final double glowIntensity;
  
  HolographicHexPainter({
    required this.activeNotes,
    required this.baseOctave,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final hexRadius = 35.0;
    
    // Draw hexagonal grid
    for (int q = -3; q <= 3; q++) {
      for (int r = -3; r <= 3; r++) {
        final s = -q - r;
        if (q.abs() + r.abs() + s.abs() > 6) continue;
        
        final x = hexRadius * 3/2 * q;
        final y = hexRadius * math.sqrt(3) * (r + q/2);
        
        final hexCenter = center + Offset(x, y);
        final note = _hexToNote(q, r, baseOctave);
        final isActive = activeNotes.contains(note);
        
        _drawHolographicHex(canvas, hexCenter, hexRadius * 0.9, isActive, note);
      }
    }
  }
  
  void _drawHolographicHex(Canvas canvas, Offset center, double radius, bool isActive, int note) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final point = center + Offset(
        radius * math.cos(angle),
        radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    
    // Base color
    final baseColor = isActive 
      ? const Color(0xFF00FFFF)
      : Colors.white.withOpacity(0.1);
    
    // Fill with gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withOpacity(isActive ? 0.6 : 0.1),
            baseColor.withOpacity(isActive ? 0.3 : 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    
    // Glowing border
    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor.withOpacity(isActive ? 1.0 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 3 : 1,
    );
    
    if (isActive) {
      // Outer glow
      canvas.drawPath(
        path,
        Paint()
          ..color = baseColor.withOpacity(0.4 * glowIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
      );
    }
  }
  
  int _hexToNote(int q, int r, int octave) {
    final noteOffset = q * 7 + r * 4; // Perfect fifth + major third
    return 60 + (octave - 4) * 12 + noteOffset;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParallaxGridPainter extends CustomPainter {
  final double breathing;
  final double rotation;
  final double globalDepth;
  
  ParallaxGridPainter({
    required this.breathing,
    required this.rotation,
    required this.globalDepth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.05 + globalDepth * 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    final gridSpacing = 60.0 + breathing * 20;
    final offset = rotation * 50;
    final depthSkew = globalDepth * 30;
    
    // Vertical lines with perspective
    for (double x = -gridSpacing; x < size.width + gridSpacing; x += gridSpacing) {
      canvas.drawLine(
        Offset(x + offset - depthSkew, 0),
        Offset(x + offset + depthSkew, size.height),
        paint,
      );
    }
    
    // Horizontal lines with perspective  
    for (double y = -gridSpacing; y < size.height + gridSpacing; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y + offset - depthSkew),
        Offset(size.width, y + offset + depthSkew),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ScanlinePainter extends CustomPainter {
  final double progress;
  
  ScanlinePainter({required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    final scanlineY = progress * size.height;
    
    canvas.drawLine(
      Offset(0, scanlineY),
      Offset(size.width, scanlineY),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.3)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlitchPainter extends CustomPainter {
  final double intensity;
  
  GlitchPainter({required this.intensity});
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(DateTime.now().millisecondsSinceEpoch);
    
    for (int i = 0; i < (intensity * 10).toInt(); i++) {
      final rect = Rect.fromLTWH(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
        random.nextDouble() * size.width * 0.3,
        random.nextDouble() * 20,
      );
      
      canvas.drawRect(
        rect,
        Paint()
          ..color = [
            const Color(0xFFFF00FF),
            const Color(0xFF00FFFF),
            const Color(0xFFFFFF00),
          ][random.nextInt(3)].withOpacity(intensity * 0.3),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WavePainter extends CustomPainter {
  final double wavePhase;
  final Offset touchPosition;
  
  WavePainter({
    required this.wavePhase,
    required this.touchPosition,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final waveCount = 8;
    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final waveAmplitude = 20.0 * (1 - touchPosition.dy);
      final waveFrequency = 0.02 * (1 + touchPosition.dx);
      
      for (double x = 0; x <= size.width; x += 2) {
        final y = size.height / 2 + 
                  math.sin(x * waveFrequency + wavePhase * math.pi * 2 + i * 0.5) * waveAmplitude +
                  (touchPosition.dy - 0.5) * size.height * 0.3;
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}