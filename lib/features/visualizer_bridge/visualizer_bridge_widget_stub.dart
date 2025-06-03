import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
class VisualizerBridgeWidget extends StatelessWidget {
  final bool showControls;
  final double opacity;
  
  const VisualizerBridgeWidget({
    Key? key,
    this.showControls = false,
    this.opacity = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Text(
          'Visualizer not available on this platform',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
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
    // On non-web platforms, just return the child without overlay
    return child;
  }
}