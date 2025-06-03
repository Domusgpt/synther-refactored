import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'core/parameter_visualizer_bridge.dart';
import 'core/layout_preset_manager.dart';
import 'design_system/design_system.dart';
import 'design_system/layout/morph_layout_manager.dart';
import 'design_system/components/components.dart';
import 'features/xy_pad/xy_pad.dart';
import 'features/keyboard/keyboard_widget.dart';
import 'features/shared_controls/control_panel_widget.dart';
import 'features/microphone_input/mic_input_widget.dart';
import 'features/llm_presets/llm_preset_widget.dart';
import 'features/granular/granular_controls_widget.dart';
import 'features/presets/preset_dialog.dart';
import 'features/visualizer_bridge/morph_ui_visualizer_bridge.dart';
import 'features/visualizer_bridge/visualizer_stub.dart'
    if (dart.library.html) 'features/visualizer_bridge/visualizer_web.dart';
import 'utils/audio_ui_sync.dart';

/// Morph-UI enhanced synthesizer app
class MorphSynthesizerApp extends StatelessWidget {
  const MorphSynthesizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    return MaterialApp(
      title: 'Synther - Visual Synthesizer',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DesignTokens.backgroundPrimary,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const MorphSynthesizerHomePage(),
    );
  }
}

class MorphSynthesizerHomePage extends StatefulWidget {
  const MorphSynthesizerHomePage({super.key});

  @override
  State<MorphSynthesizerHomePage> createState() => _MorphSynthesizerHomePageState();
}

class _MorphSynthesizerHomePageState extends State<MorphSynthesizerHomePage> {
  // Layout management
  late LayoutPresetManager _layoutPresetManager;
  MorphLayoutPreset _currentPreset = MorphLayoutPresets.defaultLayout;
  
  // Parameter visualization
  late ParameterVisualizerBridge _parameterBridge;
  
  // UI state
  bool _showParameterVault = false;
  String _activeMode = 'default'; // default, performance, keyboard, touchgrid
  
  @override
  void initState() {
    super.initState();
    _layoutPresetManager = LayoutPresetManager();
    _parameterBridge = ParameterVisualizerBridge(
      synthParameters: context.read<SynthParametersModel>(),
    );
    _loadLastLayout();
  }
  
  Future<void> _loadLastLayout() async {
    final lastPreset = await _layoutPresetManager.getLastUsedPreset();
    if (lastPreset != null) {
      setState(() {
        _currentPreset = MorphLayoutPreset(
          presetId: lastPreset.id,
          name: lastPreset.name,
          topRatio: lastPreset.paneRatios[0],
          middleRatio: lastPreset.paneRatios[1],
          bottomRatio: lastPreset.paneRatios[2],
          topPaneColor: DesignTokens.neonCyan,
          middlePaneColor: DesignTokens.neonPurple,
          bottomPaneColor: DesignTokens.neonPink,
        );
      });
    }
  }
  
  @override
  void dispose() {
    _parameterBridge.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundPrimary,
      body: Stack(
        children: [
          // 4D Visualizer background - ALWAYS visible
          Positioned.fill(
            child: MorphUIVisualizerBridge(
              parameterBridge: _parameterBridge,
              opacity: 0.9,
              showControls: false,
            ),
          ),
          
          // Morph-UI adaptive layout
          MorphLayoutManager(
            initialPreset: _currentPreset,
            onLayoutChanged: (preset) {
              setState(() {
                _currentPreset = preset;
                _layoutPresetManager.saveLastUsedPreset(
                  LayoutPresetData(
                    id: preset.presetId,
                    name: preset.name,
                    category: LayoutPresetCategory.user,
                    paneRatios: [preset.topRatio, preset.middleRatio, preset.bottomRatio],
                    parameterBindings: _parameterBridge.exportBindings(),
                    visualizerSettings: {},
                  ),
                );
              });
            },
            topPane: _buildTopPane(),
            middlePane: _buildMiddlePane(),
            bottomPane: _buildBottomPane(),
          ),
          
          // Bezel tabs for mode switching
          _buildBezelTabs(),
          
          // Parameter vault overlay
          if (_showParameterVault)
            _buildParameterVault(),
          
          // Floating action buttons
          _buildFloatingControls(),
        ],
      ),
    );
  }
  
  Widget _buildTopPane() {
    return GlassmorphicPane(
      tintColor: DesignTokens.neonCyan,
      blurIntensity: 10,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacing3),
        child: Column(
          children: [
            Text(
              'XY PAD',
              style: SyntherTypography.titleMedium.copyWith(
                color: DesignTokens.neonCyan,
                shadows: [DesignShadows.textGlow(DesignTokens.neonCyan)],
              ),
            ),
            SizedBox(height: DesignTokens.spacing2),
            Expanded(
              child: Consumer<SynthParametersModel>(
                builder: (context, synthParams, _) {
                  return XYPad(
                    backgroundColor: Colors.black.withOpacity(0.3),
                    gridColor: DesignTokens.neonCyan.withOpacity(0.2),
                    cursorColor: DesignTokens.neonCyan,
                    label: '',
                    octaveRange: 2,
                    baseNote: 48,
                    scale: Scale.minorPentatonic,
                    onXYChanged: (x, y) {
                      // Update parameter bridge for visual feedback
                      _parameterBridge.updateParameter('xy.x', x);
                      _parameterBridge.updateParameter('xy.y', y);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiddlePane() {
    return GlassmorphicPane(
      tintColor: DesignTokens.neonPurple,
      blurIntensity: 10,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacing3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTROLS',
                  style: SyntherTypography.titleMedium.copyWith(
                    color: DesignTokens.neonPurple,
                    shadows: [DesignShadows.textGlow(DesignTokens.neonPurple)],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: DesignTokens.neonPurple),
                  onPressed: () {
                    setState(() {
                      _showParameterVault = !_showParameterVault;
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: Consumer<SynthParametersModel>(
                builder: (context, synthParams, _) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Filter controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildKnobControl(
                              'CUTOFF',
                              synthParams.filterCutoff / 20000,
                              (value) {
                                synthParams.setFilterCutoff(value * 20000);
                                _parameterBridge.updateParameter('cutoff', value);
                              },
                              DesignTokens.neonCyan,
                            ),
                            _buildKnobControl(
                              'RESONANCE',
                              synthParams.filterResonance / 30,
                              (value) {
                                synthParams.setFilterResonance(value * 30);
                                _parameterBridge.updateParameter('resonance', value);
                              },
                              DesignTokens.neonPurple,
                            ),
                          ],
                        ),
                        SizedBox(height: DesignTokens.spacing3),
                        // ADSR controls
                        _buildADSRControls(synthParams),
                        SizedBox(height: DesignTokens.spacing3),
                        // Volume control
                        _buildVolumeControl(synthParams),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomPane() {
    return GlassmorphicPane(
      tintColor: DesignTokens.neonPink,
      blurIntensity: 10,
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            TabBar(
              indicatorColor: DesignTokens.neonPink,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'DRUM PADS'),
                Tab(text: 'KEYBOARD'),
                Tab(text: 'PRESETS'),
                Tab(text: 'SETTINGS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDrumPads(),
                  _buildKeyboard(),
                  _buildPresets(),
                  _buildSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
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
  
  Widget _buildADSRControls(SynthParametersModel synthParams) {
    return Column(
      children: [
        Text(
          'ENVELOPE',
          style: SyntherTypography.labelMedium.copyWith(
            color: DesignTokens.neonPink,
          ),
        ),
        SizedBox(height: DesignTokens.spacing2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMiniKnob('A', synthParams.attack, (v) {
              synthParams.setAttack(v);
              _parameterBridge.updateParameter('attack', v);
            }),
            _buildMiniKnob('D', synthParams.decay, (v) {
              synthParams.setDecay(v);
              _parameterBridge.updateParameter('decay', v);
            }),
            _buildMiniKnob('S', synthParams.sustain, (v) {
              synthParams.setSustain(v);
              _parameterBridge.updateParameter('sustain', v);
            }),
            _buildMiniKnob('R', synthParams.release, (v) {
              synthParams.setRelease(v);
              _parameterBridge.updateParameter('release', v);
            }),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMiniKnob(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        SyntherKnob(
          value: value,
          onChanged: onChanged,
          size: 40,
          glowColor: DesignTokens.neonPink,
          showValue: false,
        ),
        Text(label, style: SyntherTypography.labelSmall),
      ],
    );
  }
  
  Widget _buildVolumeControl(SynthParametersModel synthParams) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing4),
      child: Column(
        children: [
          Text(
            'MASTER VOLUME',
            style: SyntherTypography.labelMedium,
          ),
          SizedBox(height: DesignTokens.spacing2),
          SyntherFader(
            value: synthParams.masterVolume,
            onChanged: (value) {
              synthParams.setMasterVolume(value);
              _parameterBridge.updateParameter('volume', value);
            },
            height: 60,
            glowColor: DesignTokens.neonYellow,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrumPads() {
    return GridView.builder(
      padding: EdgeInsets.all(DesignTokens.spacing3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 16,
      itemBuilder: (context, index) {
        return GlassmorphicStyles.drumPad(
          onTap: () {
            // Trigger drum sound
            context.read<SynthParametersModel>().triggerNote(36 + index);
          },
          child: Center(
            child: Text(
              '${index + 1}',
              style: SyntherTypography.labelLarge.copyWith(
                color: DesignTokens.neonPink,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildKeyboard() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacing3),
      child: KeyboardWidget(
        height: 200,
        startOctave: 3,
        numOctaves: 2,
        showLabels: true,
      ),
    );
  }
  
  Widget _buildPresets() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(DesignTokens.spacing3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SyntherButton(
                label: 'SAVE',
                onPressed: () => PresetDialog.showSaveDialog(context),
                style: SyntherButtonStyle.secondary,
              ),
              SyntherButton(
                label: 'LOAD',
                onPressed: () => PresetDialog.showLoadDialog(context),
                style: SyntherButtonStyle.primary,
              ),
            ],
          ),
        ),
        Expanded(
          child: LlmPresetWidget(),
        ),
      ],
    );
  }
  
  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacing3),
      child: Column(
        children: [
          MicInputWidget(),
          SizedBox(height: DesignTokens.spacing4),
          GranularControlsWidget(),
        ],
      ),
    );
  }
  
  Widget _buildBezelTabs() {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).size.height * 0.2,
      child: Column(
        children: [
          BezelTab(
            label: 'DEFAULT',
            icon: Icons.grid_view,
            isActive: _activeMode == 'default',
            color: DesignTokens.neonCyan,
            onTap: () => _switchMode('default'),
          ),
          BezelTab(
            label: 'PERFORM',
            icon: Icons.visibility,
            isActive: _activeMode == 'performance',
            color: DesignTokens.neonPurple,
            onTap: () => _switchMode('performance'),
          ),
          BezelTab(
            label: 'KEYS',
            icon: Icons.piano,
            isActive: _activeMode == 'keyboard',
            color: DesignTokens.neonPink,
            onTap: () => _switchMode('keyboard'),
          ),
          BezelTab(
            label: 'GRID',
            icon: Icons.grid_4x4,
            isActive: _activeMode == 'touchgrid',
            color: DesignTokens.neonYellow,
            onTap: () => _switchMode('touchgrid'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParameterVault() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showParameterVault = false),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: GlassmorphicPane(
                  tintColor: DesignTokens.neonPurple,
                  blurIntensity: 20,
                  child: ParameterBindingManager(
                    parameterBridge: _parameterBridge,
                    onClose: () => setState(() => _showParameterVault = false),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingControls() {
    return Positioned(
      left: 16,
      bottom: 16,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: DesignTokens.neonCyan,
            onPressed: () async {
              final presets = await _layoutPresetManager.getAllPresets();
              if (!mounted) return;
              
              showDialog(
                context: context,
                builder: (context) => LayoutPresetSelector(
                  presets: presets,
                  onPresetSelected: (preset) {
                    setState(() {
                      _currentPreset = MorphLayoutPreset(
                        presetId: preset.id,
                        name: preset.name,
                        topRatio: preset.paneRatios[0],
                        middleRatio: preset.paneRatios[1],
                        bottomRatio: preset.paneRatios[2],
                      );
                    });
                    // Load parameter bindings
                    _parameterBridge.importBindings(preset.parameterBindings);
                  },
                ),
              );
            },
            child: Icon(Icons.dashboard_customize, size: 20),
          ),
          SizedBox(height: 8),
          AudioEngineStatusWidget(),
        ],
      ),
    );
  }
  
  void _switchMode(String mode) {
    setState(() {
      _activeMode = mode;
      
      switch (mode) {
        case 'performance':
          _currentPreset = MorphLayoutPresets.performance;
          break;
        case 'keyboard':
          _currentPreset = MorphLayoutPresets.soundDesign;
          break;
        case 'touchgrid':
          _currentPreset = MorphLayoutPresets.touchGrid;
          break;
        default:
          _currentPreset = MorphLayoutPresets.defaultLayout;
      }
    });
  }
}

/// Bezel tab widget for mode switching
class BezelTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  
  const BezelTab({
    Key? key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing1),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: isActive ? 80 : 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive 
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              if (isActive)
                Text(
                  label,
                  style: SyntherTypography.labelSmall.copyWith(
                    color: color,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}