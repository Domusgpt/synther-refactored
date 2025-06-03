import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';

/// A widget for controlling wavetable oscillator parameters
class WavetableControlsWidget extends StatefulWidget {
  final int oscillatorIndex;
  
  const WavetableControlsWidget({
    Key? key,
    required this.oscillatorIndex,
  }) : super(key: key);

  @override
  State<WavetableControlsWidget> createState() => _WavetableControlsWidgetState();
}

class _WavetableControlsWidgetState extends State<WavetableControlsWidget> {
  // Available wavetables
  static const List<String> wavetableNames = [
    'Basic Shapes',
    'PWM',
    'Harmonic Series',
    'Vocal Formants',
    'Bell',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        if (widget.oscillatorIndex >= model.oscillators.length) {
          return const SizedBox.shrink();
        }
        
        final osc = model.oscillators[widget.oscillatorIndex];
        
        // Only show wavetable controls if this oscillator is in wavetable mode
        if (osc.type != OscillatorType.wavetable) {
          return const SizedBox.shrink();
        }
        
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.waves,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wavetable Controls - Oscillator ${widget.oscillatorIndex + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Wavetable selection
                Text(
                  'Wavetable',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: osc.wavetableIndex.clamp(0, wavetableNames.length - 1),
                  isExpanded: true,
                  onChanged: (index) {
                    if (index != null) {
                      model.updateOscillator(
                        widget.oscillatorIndex,
                        osc.copyWith(wavetableIndex: index),
                      );
                    }
                  },
                  items: wavetableNames.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 20),
                
                // Wavetable position
                Text(
                  'Position: ${osc.wavetablePosition.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: osc.wavetablePosition,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    model.updateOscillator(
                      widget.oscillatorIndex,
                      osc.copyWith(wavetablePosition: value),
                    );
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.grey.shade700,
                ),
                
                const SizedBox(height: 8),
                
                // Visual representation of wavetable position
                _WavetableVisualizer(
                  wavetableName: wavetableNames[osc.wavetableIndex.clamp(0, wavetableNames.length - 1)],
                  position: osc.wavetablePosition,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A visual representation of the wavetable and current position
class _WavetableVisualizer extends StatelessWidget {
  final String wavetableName;
  final double position;
  
  const _WavetableVisualizer({
    required this.wavetableName,
    required this.position,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: CustomPaint(
        painter: _WavetablePainter(
          wavetableName: wavetableName,
          position: position,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Custom painter for wavetable visualization
class _WavetablePainter extends CustomPainter {
  final String wavetableName;
  final double position;
  final Color color;
  
  _WavetablePainter({
    required this.wavetableName,
    required this.position,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw a simple waveform representation
    final path = Path();
    final numSamples = 100;
    
    for (int i = 0; i < numSamples; i++) {
      final x = (i / numSamples) * size.width;
      
      // Different waveforms for different wavetables
      double y = size.height / 2;
      
      switch (wavetableName) {
        case 'Basic Shapes':
          // Morph between sine and saw
          final t = (i / numSamples) * 2 * 3.14159;
          final sine = sin(t);
          final saw = (i / numSamples * 2 - 1);
          y += (sine * (1 - position) + saw * position) * size.height * 0.3;
          break;
          
        case 'PWM':
          // Pulse with changing width
          final pulseWidth = 0.1 + position * 0.8;
          final t = i / numSamples;
          y += (t < pulseWidth ? 1 : -1) * size.height * 0.3;
          break;
          
        case 'Harmonic Series':
          // More harmonics with position
          final t = (i / numSamples) * 2 * 3.14159;
          final harmonics = (1 + position * 10).toInt();
          double sample = 0;
          for (int h = 1; h <= harmonics; h++) {
            sample += sin(t * h) / h;
          }
          y += sample * size.height * 0.3 / harmonics;
          break;
          
        default:
          // Simple sine
          final t = (i / numSamples) * 2 * 3.14159;
          y += sin(t) * size.height * 0.3;
      }
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw position indicator
    final posX = position * size.width;
    paint.color = Colors.white;
    canvas.drawLine(
      Offset(posX, 0),
      Offset(posX, size.height),
      paint,
    );
    
    // Draw position text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Pos: ${(position * 100).toInt()}%',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 5));
  }
  
  @override
  bool shouldRepaint(covariant _WavetablePainter oldDelegate) {
    return oldDelegate.position != position ||
           oldDelegate.wavetableName != wavetableName;
  }
  
  double sin(double x) => Math.sin(x);
}

class Math {
  static double sin(double x) {
    // Simple sin approximation for painting
    return (x % (2 * 3.14159) < 3.14159) 
        ? (x % 3.14159) / 3.14159 * 2 - 1
        : -((x % 3.14159) / 3.14159 * 2 - 1);
  }
}