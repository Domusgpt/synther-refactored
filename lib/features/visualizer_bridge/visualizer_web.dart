import 'dart:html' as html;
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';

/// Web-specific visualizer that embeds the HyperAV visualizer using an iframe
class VisualizerWeb extends StatefulWidget {
  final bool showControls;
  final double opacity;
  
  const VisualizerWeb({
    Key? key,
    this.showControls = false,
    this.opacity = 1.0,
  }) : super(key: key);
  
  @override
  State<VisualizerWeb> createState() => _VisualizerWebState();
}

class _VisualizerWebState extends State<VisualizerWeb> {
  final String _iframeId = 'hyperav-visualizer-${DateTime.now().millisecondsSinceEpoch}';
  html.IFrameElement? _iframe;
  
  @override
  void initState() {
    super.initState();
    _setupIframe();
  }
  
  void _setupIframe() {
    // Create iframe element
    _iframe = html.IFrameElement()
      ..src = 'assets/visualizer/index-flutter.html'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';
    
    // Register the iframe with Flutter
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeId,
      (int viewId) => _iframe!,
    );
    
    // Wait for iframe to load
    _iframe!.onLoad.listen((_) {
      _injectParameterBridge();
    });
  }
  
  void _injectParameterBridge() {
    // Inject parameter sync code
    final code = '''
      window.synthBridge = {
        parameters: {},
        
        updateParameter: function(name, value) {
          this.parameters[name] = value;
          
          // Trigger visualizer update
          if (window.updateVisualizerParameter) {
            window.updateVisualizerParameter(name, value);
          }
        },
        
        getAllParameters: function() {
          return this.parameters;
        }
      };
    ''';
    
    _iframe!.contentWindow!.postMessage(code, '*');
  }
  
  void _updateVisualizerParameter(String parameter, double value) {
    if (_iframe == null) return;
    
    final message = {
      'type': 'updateParameter',
      'parameter': parameter,
      'value': value,
    };
    
    _iframe!.contentWindow!.postMessage(message, '*');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        // Update visualizer when parameters change
        _syncParametersToVisualizer(model);
        
        return Stack(
          children: [
            // Iframe with visualizer
            Opacity(
              opacity: widget.opacity,
              child: HtmlElementView(
                viewType: _iframeId,
              ),
            ),
            
            // Optional controls overlay
            if (widget.showControls)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildControlsOverlay(),
              ),
          ],
        );
      },
    );
  }
  
  void _syncParametersToVisualizer(SynthParametersModel model) {
    // Map audio parameters to visualizer parameters
    _updateVisualizerParameter('filterCutoff', model.filterCutoff / 20000);
    _updateVisualizerParameter('filterResonance', model.filterResonance);
    _updateVisualizerParameter('reverbMix', model.reverbMix);
    _updateVisualizerParameter('masterVolume', model.masterVolume);
    
    // Map XY pad to 4D rotation
    _updateVisualizerParameter('rotationX', model.xyPadX);
    _updateVisualizerParameter('rotationY', model.xyPadY);
    
    // Map envelope to visual dynamics
    _updateVisualizerParameter('attackTime', model.attackTime);
    _updateVisualizerParameter('releaseTime', model.releaseTime);
    
    // Map oscillator params to geometry
    if (model.oscillators.isNotEmpty) {
      final osc = model.oscillators[0];
      _updateVisualizerParameter('waveformType', osc.type.index.toDouble());
      _updateVisualizerParameter('oscillatorVolume', osc.volume);
    }
  }
  
  Widget _buildControlsOverlay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.blur_on,
            label: 'Effects',
            onPressed: () => _toggleVisualizerEffect('blur'),
          ),
          _buildControlButton(
            icon: Icons.grid_3x3,
            label: 'Grid',
            onPressed: () => _toggleVisualizerEffect('grid'),
          ),
          _buildControlButton(
            icon: Icons.motion_photos_on,
            label: 'Trails',
            onPressed: () => _toggleVisualizerEffect('trails'),
          ),
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Reset',
            onPressed: () => _resetVisualizer(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleVisualizerEffect(String effect) {
    final message = {
      'type': 'toggleEffect',
      'effect': effect,
    };
    _iframe?.contentWindow?.postMessage(message, '*');
  }
  
  void _resetVisualizer() {
    final message = {
      'type': 'resetVisualizer',
    };
    _iframe?.contentWindow?.postMessage(message, '*');
  }
  
  @override
  void dispose() {
    _iframe?.remove();
    super.dispose();
  }
}