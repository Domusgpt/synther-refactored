import 'package:flutter/material.dart';
import '../design_system.dart';
import '../layout/morph_layout_manager.dart';

/// Demo showcasing the Morph-UI system
class MorphUIDemo extends StatefulWidget {
  const MorphUIDemo({Key? key}) : super(key: key);
  
  @override
  State<MorphUIDemo> createState() => _MorphUIDemoState();
}

class _MorphUIDemoState extends State<MorphUIDemo> {
  MorphLayoutPreset _currentPreset = MorphLayoutPresets.defaultLayout;
  double _xyX = 0.5;
  double _xyY = 0.5;
  double _cutoff = 0.7;
  double _resonance = 0.3;
  double _envelope = 0.5;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundPrimary,
      body: Stack(
        children: [
          // 4D Visualizer background (placeholder)
          _buildVisualizerBackground(),
          
          // Morph-UI layout
          MorphLayoutManager(
            initialPreset: _currentPreset,
            onLayoutChanged: (preset) {
              setState(() => _currentPreset = preset);
            },
            topPane: _buildXYPad(),
            middlePane: _buildControlPanel(),
            bottomPane: _buildBottomPanel(),
          ),
          
          // Bezel tabs
          _buildBezelTabs(),
        ],
      ),
    );
  }
  
  Widget _buildVisualizerBackground() {
    // Placeholder for 4D visualizer
    // In real implementation, this would be the WebGL canvas
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(
            (_xyX - 0.5) * 2,
            (_xyY - 0.5) * 2,
          ),
          colors: [
            DesignTokens.neonCyan.withOpacity(0.2 * _envelope),
            DesignTokens.neonPurple.withOpacity(0.1 * _resonance),
            DesignTokens.backgroundPrimary,
          ],
          stops: const [0.0, 0.5, 1.0],
          radius: 1.5 + _cutoff,
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(
          lineThickness: 0.5 + (_cutoff * 2),
          hueShift: _xyY,
          rotationSpeed: _xyX,
        ),
      ),
    );
  }
  
  Widget _buildXYPad() {
    return Column(
      children: [
        Text(
          'XY PAD',
          style: SyntherTypography.titleMedium.copyWith(
            color: DesignTokens.neonCyan,
          ),
        ),
        SizedBox(height: DesignTokens.spacing2),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _xyX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                    _xyY = 1.0 - (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DesignTokens.neonCyan.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Grid overlay
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _XYGridPainter(),
                      ),
                      
                      // XY position indicator
                      Positioned(
                        left: _xyX * constraints.maxWidth - 10,
                        top: (1.0 - _xyY) * constraints.maxHeight - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.neonCyan,
                            boxShadow: [
                              BoxShadow(
                                color: DesignTokens.neonCyan,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildControlPanel() {
    return Column(
      children: [
        Text(
          'CONTROLS',
          style: SyntherTypography.titleMedium.copyWith(
            color: DesignTokens.neonPurple,
          ),
        ),
        SizedBox(height: DesignTokens.spacing2),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKnobControl(
                'CUTOFF',
                _cutoff,
                (value) => setState(() => _cutoff = value),
                DesignTokens.neonCyan,
              ),
              _buildKnobControl(
                'RESONANCE',
                _resonance,
                (value) => setState(() => _resonance = value),
                DesignTokens.neonPurple,
              ),
              _buildKnobControl(
                'ENVELOPE',
                _envelope,
                (value) => setState(() => _envelope = value),
                DesignTokens.neonPink,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildKnobControl(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SyntherKnob(
          value: value,
          onChanged: onChanged,
          size: 60,
          glowColor: color,
          showValue: false,
        ),
        SizedBox(height: DesignTokens.spacing1),
        Text(
          label,
          style: SyntherTypography.labelSmall,
        ),
        Text(
          value.toStringAsFixed(2),
          style: SyntherTypography.monoSmall.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomPanel() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            indicatorColor: DesignTokens.neonPink,
            tabs: const [
              Tab(text: 'DRUM PADS'),
              Tab(text: 'KEYBOARD'),
              Tab(text: 'PRESETS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDrumPads(),
                _buildKeyboard(),
                _buildPresets(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrumPads() {
    return GridView.builder(
      padding: EdgeInsets.all(DesignTokens.spacing2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 16,
      itemBuilder: (context, index) {
        return GlassmorphicStyles.drumPad(
          onTap: () {
            // Trigger drum sound
          },
          child: Center(
            child: Text(
              '${index + 1}',
              style: SyntherTypography.labelMedium,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildKeyboard() {
    return Center(
      child: Text(
        'Piano Keyboard',
        style: SyntherTypography.bodyLarge,
      ),
    );
  }
  
  Widget _buildPresets() {
    return ListView(
      padding: EdgeInsets.all(DesignTokens.spacing3),
      children: [
        _buildPresetItem('Ambient Pad'),
        _buildPresetItem('Bass Wobble'),
        _buildPresetItem('Lead Synth'),
        _buildPresetItem('Arp Sequence'),
      ],
    );
  }
  
  Widget _buildPresetItem(String name) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing2),
      child: GlassmorphicPane(
        height: 60,
        tintColor: DesignTokens.neonPurple,
        onTap: () {
          // Load preset
        },
        child: Center(
          child: Text(
            name,
            style: SyntherTypography.bodyLarge,
          ),
        ),
      ),
    );
  }
  
  Widget _buildBezelTabs() {
    return Positioned(
      right: 0,
      top: 100,
      child: Column(
        children: [
          _buildBezelTab('XY PAD', DesignTokens.neonCyan, true),
          _buildBezelTab('CONTROLS', DesignTokens.neonPurple, false),
          _buildBezelTab('KEYBOARD', DesignTokens.neonPink, false),
        ],
      ),
    );
  }
  
  Widget _buildBezelTab(String label, Color color, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing1),
      child: GlassmorphicStyles.bezelTab(
        tintColor: color,
        isActive: isActive,
        onTap: () {
          // Switch layout
        },
        child: Center(
          child: Text(
            label,
            style: SyntherTypography.labelSmall,
          ),
        ),
      ),
    );
  }
}

// Simple grid painter for demo
class _GridPainter extends CustomPainter {
  final double lineThickness;
  final double hueShift;
  final double rotationSpeed;
  
  _GridPainter({
    required this.lineThickness,
    required this.hueShift,
    required this.rotationSpeed,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HSVColor.fromAHSV(
        0.3,
        hueShift * 360,
        1.0,
        1.0,
      ).toColor()
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;
    
    // Draw grid
    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (rotationSpeed * 20), size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (rotationSpeed * 20)),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineThickness != lineThickness ||
           oldDelegate.hueShift != hueShift ||
           oldDelegate.rotationSpeed != rotationSpeed;
  }
}

// XY grid painter
class _XYGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    // Draw grid
    const divisions = 8;
    for (int i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}