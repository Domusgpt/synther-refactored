import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../core/audio_engine.dart';

/// Professional 4D Hypercube Visualizer
/// 
/// This widget displays the real-time 4D polytope projections that react
/// to audio parameters. It uses WebGL for high-performance rendering.
class HypercubeVisualizer extends StatefulWidget {
  final AudioEngine audioEngine;
  
  const HypercubeVisualizer({
    super.key,
    required this.audioEngine,
  });
  
  @override
  State<HypercubeVisualizer> createState() => _HypercubeVisualizerState();
}

class _HypercubeVisualizerState extends State<HypercubeVisualizer> 
    with TickerProviderStateMixin {
  
  late WebViewController _controller;
  bool _isLoaded = false;
  late AnimationController _updateController;
  
  @override
  void initState() {
    super.initState();
    
    // Update visualizer 60fps
    _updateController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60fps
      vsync: this,
    )..addListener(_updateVisualizer);
    
    _initializeWebView();
    _startVisualizerUpdates();
  }
  
  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }
  
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('🎨 4D Visualizer loaded');
            setState(() => _isLoaded = true);
            _initializeVisualizerParameters();
          },
        ),
      )
      ..loadFlutterAsset('assets/visualizer/index-flutter.html');
  }
  
  void _startVisualizerUpdates() {
    _updateController.repeat();
  }
  
  void _updateVisualizer() {
    if (!_isLoaded) return;
    
    final data = widget.audioEngine.getVisualizerData();
    final jsCommand = '''
      if (window.updateAudioData) {
        window.updateAudioData(${jsonEncode(data)});
      }
    ''';
    
    _controller.runJavaScript(jsCommand);
  }
  
  void _initializeVisualizerParameters() {
    const initCommand = '''
      // Initialize 4D visualizer with professional parameters
      if (window.initializeHypercube) {
        window.initializeHypercube({
          rotationSpeed: 0.02,
          morphSpeed: 0.01,
          layers: 5,
          quality: 'high',
          effects: {
            bloom: true,
            glow: true,
            particles: true,
            trails: true
          }
        });
      }
    ''';
    
    _controller.runJavaScript(initCommand);
  }
  
  /// Update 4D rotation based on XY pad input
  void updateRotation(double x, double y) {
    if (!_isLoaded) return;
    
    final jsCommand = '''
      if (window.setRotation4D) {
        window.setRotation4D($x, $y);
      }
    ''';
    
    _controller.runJavaScript(jsCommand);
  }
  
  /// Set the intensity of the 4D morphing
  void setMorphIntensity(double intensity) {
    if (!_isLoaded) return;
    
    final jsCommand = '''
      if (window.setMorphIntensity) {
        window.setMorphIntensity($intensity);
      }
    ''';
    
    _controller.runJavaScript(jsCommand);
  }
  
  /// Set color palette based on audio characteristics
  void setColorPalette(String palette) {
    if (!_isLoaded) return;
    
    final jsCommand = '''
      if (window.setColorPalette) {
        window.setColorPalette('$palette');
      }
    ''';
    
    _controller.runJavaScript(jsCommand);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF000010),
            Color(0xFF000020),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 4D Visualizer WebView
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          
          // Loading indicator
          if (!_isLoaded)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00FFFF),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'INITIALIZING 4D HYPERCUBE',
                    style: TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Visualizer parameter presets for different music styles
class VisualizerPresets {
  static const Map<String, Map<String, dynamic>> presets = {
    'vaporwave': {
      'colorPalette': 'vaporwave',
      'rotationSpeed': 0.015,
      'morphSpeed': 0.008,
      'effects': {
        'bloom': true,
        'glow': true,
        'chromatic': true,
        'scanlines': true,
      }
    },
    'cyberpunk': {
      'colorPalette': 'cyberpunk',
      'rotationSpeed': 0.025,
      'morphSpeed': 0.012,
      'effects': {
        'bloom': true,
        'glow': true,
        'glitch': true,
        'particles': true,
      }
    },
    'synthwave': {
      'colorPalette': 'synthwave',
      'rotationSpeed': 0.02,
      'morphSpeed': 0.01,
      'effects': {
        'bloom': true,
        'glow': true,
        'trails': true,
        'laser': true,
      }
    },
    'holographic': {
      'colorPalette': 'holographic',
      'rotationSpeed': 0.01,
      'morphSpeed': 0.005,
      'effects': {
        'bloom': true,
        'glow': true,
        'iridescent': true,
        'depth': true,
      }
    },
  };
  
  static Map<String, dynamic>? getPreset(String name) {
    return presets[name];
  }
  
  static List<String> getPresetNames() {
    return presets.keys.toList();
  }
}