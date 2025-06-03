import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
class VisualizerWeb extends StatelessWidget {
  final bool showControls;
  final double opacity;
  
  const VisualizerWeb({
    Key? key,
    this.showControls = false,
    this.opacity = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(opacity * 0.3),
      child: const Center(
        child: Text(
          'Visualizer only available on web platform',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}