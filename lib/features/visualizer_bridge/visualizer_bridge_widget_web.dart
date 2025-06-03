import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';

/// Web-specific implementation of the visualizer bridge
class VisualizerBridgeWidget extends StatefulWidget {
  final bool showControls;
  final double opacity;
  
  const VisualizerBridgeWidget({
    Key? key,
    this.showControls = false,
    this.opacity = 1.0,
  }) : super(key: key);
  
  @override
  State<VisualizerBridgeWidget> createState() => _VisualizerBridgeWidgetState();
}

class _VisualizerBridgeWidgetState extends State<VisualizerBridgeWidget> {
  late html.IFrameElement _iFrameElement;
  final String _viewType = 'visualizer-iframe';
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _setupIFrame();
  }
  
  void _setupIFrame() {
    _iFrameElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..src = 'assets/visualizer/index-flutter.html'
      ..onLoad.listen((_) {
        setState(() {
          _isLoaded = true;
        });
        _injectParameterBridge();
      });
    
    // Register the iframe with Flutter's platform view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iFrameElement,
    );
  }
  
  void _injectParameterBridge() {
    // Set up message passing with the iframe
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data == 'bridgeReady') {
        debugPrint('Visualizer bridge ready');
      }
    });
  }
  
  void _updateVisualizerParameter(String parameter, double value) {
    if (!_isLoaded) return;
    
    // Send parameter updates to the iframe
    _iFrameElement.contentWindow?.postMessage({
      'type': 'parameterUpdate',
      'parameter': parameter,
      'value': value,
    }, '*');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        // Update visualizer when parameters change
        _syncParametersToVisualizer(model);
        
        return Stack(
          children: [
            // HtmlElementView for the iframe
            Opacity(
              opacity: widget.opacity,
              child: HtmlElementView(
                viewType: _viewType,
              ),
            ),
            
            // Loading indicator
            if (!_isLoaded)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
  
  void _syncParametersToVisualizer(SynthParametersModel model) {
    if (!_isLoaded) return;
    
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
}

/// Transparent overlay version for use over UI
class VisualizerOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double opacity;
  
  const VisualizerOverlay({
    Key? key,
    required this.child,
    this.enabled = true,
    this.opacity = 0.3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    
    return Stack(
      children: [
        // Visualizer background
        Positioned.fill(
          child: VisualizerBridgeWidget(
            opacity: opacity,
            showControls: false,
          ),
        ),
        
        // UI content on top
        child,
      ],
    );
  }
}