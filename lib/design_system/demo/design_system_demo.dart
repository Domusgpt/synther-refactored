import 'dart:math' as math;
import '../design_system.dart';

/// Comprehensive demo of the Synther Design System
/// Showcases all components and design tokens
class DesignSystemDemo extends StatefulWidget {
  const DesignSystemDemo({Key? key}) : super(key: key);
  
  @override
  State<DesignSystemDemo> createState() => _DesignSystemDemoState();
}

class _DesignSystemDemoState extends State<DesignSystemDemo>
    with TickerProviderStateMixin {
  double _knobValue = 0.5;
  double _faderValue = 0.7;
  bool _buttonToggled = false;
  bool _spectrumEnabled = true;
  
  late List<double> _demoSpectrumData;
  late AnimationController _spectrumController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize demo spectrum data
    _demoSpectrumData = List.generate(32, (i) => 0.0);
    
    // Create animation for demo spectrum
    _spectrumController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _startSpectrumAnimation();
  }
  
  @override
  void dispose() {
    _spectrumController.dispose();
    super.dispose();
  }
  
  void _startSpectrumAnimation() {
    _spectrumController.addListener(() {
      if (mounted && _spectrumEnabled) {
        setState(() {
          // Generate fake spectrum data
          for (int i = 0; i < _demoSpectrumData.length; i++) {
            final frequency = i / _demoSpectrumData.length;
            final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
            _demoSpectrumData[i] = (math.sin(time * 2 + frequency * 10) * 0.5 + 0.5) *
                                   math.exp(-frequency * 2) *
                                   (_knobValue + 0.1);
          }
        });
      }
    });
    
    _spectrumController.repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundPrimary,
      appBar: AppBar(
        title: GlowingText(
          'Synther Design System',
          style: SyntherTypography.headlineMedium,
          glowColor: DesignTokens.neonCyan,
        ),
        backgroundColor: DesignTokens.backgroundSecondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: SyntherResponsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorPalette(),
            SizedBox(height: DesignTokens.spacing6),
            _buildTypography(),
            SizedBox(height: DesignTokens.spacing6),
            _buildComponents(),
            SizedBox(height: DesignTokens.spacing6),
            _buildAnimations(),
            SizedBox(height: DesignTokens.spacing6),
            _buildShadows(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Palette',
          style: SyntherTypography.headlineSmall,
        ),
        SizedBox(height: DesignTokens.spacing3),
        ResponsiveGrid(
          children: [
            _colorCard('Neon Cyan', DesignTokens.neonCyan),
            _colorCard('Neon Purple', DesignTokens.neonPurple),
            _colorCard('Neon Pink', DesignTokens.neonPink),
            _colorCard('Surface', DesignTokens.surface),
            _colorCard('Background', DesignTokens.backgroundPrimary),
            _colorCard('Text Primary', DesignTokens.textPrimary),
          ],
        ),
      ],
    );
  }
  
  Widget _colorCard(String name, Color color) {
    return NeumorphicContainer(
      height: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              boxShadow: SyntherShadows.customGlow(color: color),
            ),
          ),
          SizedBox(height: DesignTokens.spacing1),
          Text(
            name,
            style: SyntherTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypography() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typography',
          style: SyntherTypography.headlineSmall,
        ),
        SizedBox(height: DesignTokens.spacing3),
        NeumorphicContainer(
          padding: EdgeInsets.all(DesignTokens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Large',
                style: SyntherTypography.displayLarge,
              ),
              SizedBox(height: DesignTokens.spacing2),
              Text(
                'Headline Medium',
                style: SyntherTypography.headlineMedium,
              ),
              SizedBox(height: DesignTokens.spacing2),
              Text(
                'Body Large - This is body text that would be used for general content and descriptions.',
                style: SyntherTypography.bodyLarge,
              ),
              SizedBox(height: DesignTokens.spacing2),
              Text(
                'Monospace for values: 440.00 Hz',
                style: SyntherTypography.monoMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildComponents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Components',
          style: SyntherTypography.headlineSmall,
        ),
        SizedBox(height: DesignTokens.spacing3),
        ResponsiveRow(
          children: [
            // Knobs section
            Expanded(
              child: NeumorphicContainer(
                padding: EdgeInsets.all(DesignTokens.spacing4),
                child: Column(
                  children: [
                    Text(
                      'Knobs',
                      style: SyntherTypography.titleMedium,
                    ),
                    SizedBox(height: DesignTokens.spacing3),
                    ResponsiveRow(
                      children: [
                        SyntherKnob(
                          value: _knobValue,
                          label: 'Cutoff',
                          unit: ' Hz',
                          min: 20,
                          max: 20000,
                          onChanged: (value) => setState(() => _knobValue = value),
                          glowColor: DesignTokens.neonCyan,
                        ),
                        SyntherKnob(
                          value: 0.3,
                          label: 'Resonance',
                          showValue: true,
                          onChanged: (value) {},
                          glowColor: DesignTokens.neonPurple,
                        ),
                        SyntherKnob(
                          value: 0.8,
                          label: 'Drive',
                          enabled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Faders section
            Expanded(
              child: NeumorphicContainer(
                padding: EdgeInsets.all(DesignTokens.spacing4),
                child: Column(
                  children: [
                    Text(
                      'Faders',
                      style: SyntherTypography.titleMedium,
                    ),
                    SizedBox(height: DesignTokens.spacing3),
                    ResponsiveRow(
                      children: [
                        SyntherFader(
                          value: _faderValue,
                          label: 'Volume',
                          height: 120,
                          onChanged: (value) => setState(() => _faderValue = value),
                          glowColor: DesignTokens.neonCyan,
                        ),
                        SyntherFader(
                          value: 0.4,
                          label: 'Pan',
                          height: 120,
                          glowColor: DesignTokens.neonPurple,
                        ),
                        SyntherFader(
                          value: 0.6,
                          label: 'Send',
                          height: 120,
                          enabled: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacing4),
        
        // Buttons section
        NeumorphicContainer(
          padding: EdgeInsets.all(DesignTokens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buttons',
                style: SyntherTypography.titleMedium,
              ),
              SizedBox(height: DesignTokens.spacing3),
              ResponsiveRow(
                children: [
                  SyntherButton.primary(
                    text: 'Primary',
                    onPressed: () {},
                  ),
                  SyntherButton(
                    text: 'Toggle',
                    type: SyntherButtonType.secondary,
                    isToggled: _buttonToggled,
                    onPressed: () => setState(() => _buttonToggled = !_buttonToggled),
                  ),
                  SyntherButton(
                    text: 'Outline',
                    type: SyntherButtonType.outline,
                    onPressed: () {},
                  ),
                  SyntherButton.icon(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(height: DesignTokens.spacing4),
        
        // Spectrum analyzer section
        NeumorphicContainer(
          padding: EdgeInsets.all(DesignTokens.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveRow(
                children: [
                  Text(
                    'Spectrum Analyzer',
                    style: SyntherTypography.titleMedium,
                  ),
                  SyntherButton(
                    text: _spectrumEnabled ? 'Enabled' : 'Disabled',
                    type: SyntherButtonType.ghost,
                    isToggled: _spectrumEnabled,
                    onPressed: () => setState(() => _spectrumEnabled = !_spectrumEnabled),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacing3),
              ResponsiveRow(
                children: [
                  Expanded(
                    child: SpectrumAnalyzer(
                      frequencyData: _demoSpectrumData,
                      height: 100,
                      enabled: _spectrumEnabled,
                      style: SpectrumStyle.bars,
                      primaryColor: DesignTokens.neonCyan,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacing3),
                  Expanded(
                    child: SpectrumAnalyzer(
                      frequencyData: _demoSpectrumData,
                      height: 100,
                      enabled: _spectrumEnabled,
                      style: SpectrumStyle.line,
                      primaryColor: DesignTokens.neonPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnimations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Animations',
          style: SyntherTypography.headlineSmall,
        ),
        SizedBox(height: DesignTokens.spacing3),
        ResponsiveRow(
          children: [
            Expanded(
              child: NeumorphicContainer(
                padding: EdgeInsets.all(DesignTokens.spacing4),
                child: Column(
                  children: [
                    Text(
                      'Pulsing Glow',
                      style: SyntherTypography.titleMedium,
                    ),
                    SizedBox(height: DesignTokens.spacing3),
                    PulseAnimation(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan,
                          shape: BoxShape.circle,
                          boxShadow: SyntherShadows.glowCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: NeumorphicContainer(
                padding: EdgeInsets.all(DesignTokens.spacing4),
                child: Column(
                  children: [
                    Text(
                      'Shimmer Effect',
                      style: SyntherTypography.titleMedium,
                    ),
                    SizedBox(height: DesignTokens.spacing3),
                    ShimmerAnimation(
                      child: Container(
                        width: 200,
                        height: 20,
                        decoration: BoxDecoration(
                          color: DesignTokens.surface,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildShadows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neumorphic Shadows',
          style: SyntherTypography.headlineSmall,
        ),
        SizedBox(height: DesignTokens.spacing3),
        ResponsiveGrid(
          children: [
            _shadowCard('Elevation 1', SyntherShadows.elevation1),
            _shadowCard('Elevation 2', SyntherShadows.elevation2),
            _shadowCard('Elevation 3', SyntherShadows.elevation3),
            _shadowCard('Inset', SyntherShadows.inset1),
            _shadowCard('Glow Cyan', SyntherShadows.glowCyan),
            _shadowCard('Glow Purple', SyntherShadows.glowPurple),
          ],
        ),
      ],
    );
  }
  
  Widget _shadowCard(String name, List<BoxShadow> shadows) {
    return Container(
      height: 100,
      margin: EdgeInsets.all(DesignTokens.spacing2),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          name,
          style: SyntherTypography.labelMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}