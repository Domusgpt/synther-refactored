import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/synth_parameters.dart';
import './mic_service_platform.dart';

/// A widget for controlling and visualizing microphone input.
class MicInputWidget extends StatefulWidget {
  const MicInputWidget({
    Key? key,
    this.height = 200,
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  final double height;
  final Color backgroundColor;

  @override
  State<MicInputWidget> createState() => _MicInputWidgetState();
}

class _MicInputWidgetState extends State<MicInputWidget> with SingleTickerProviderStateMixin {
  late MicrophoneService _micService;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for visualizer
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    // Set up mic service after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
      _micService = MicrophoneService(parametersModel: synthParams);
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MicrophoneService>(
      create: (context) {
        final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
        return MicrophoneService(parametersModel: synthParams);
      },
      child: Consumer<MicrophoneService>(
        builder: (context, micService, child) {
          _micService = micService;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Microphone Input',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      // Record button
                      IconButton(
                        icon: Icon(
                          micService.isRecording ? Icons.stop : Icons.mic,
                          color: micService.isRecording ? Colors.red : null,
                        ),
                        onPressed: () {
                          if (micService.isRecording) {
                            micService.stopRecording();
                          } else {
                            micService.startRecording();
                          }
                        },
                        tooltip: micService.isRecording ? 'Stop Recording' : 'Start Recording',
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Auto-control options
              Wrap(
                spacing: 16,
                children: [
                  // Filter auto-control
                  FilterChip(
                    label: const Text('Auto Filter'),
                    selected: micService.autoControlFilter,
                    onSelected: (selected) {
                      micService.toggleAutoControlFilter();
                    },
                  ),
                  
                  // Oscillator auto-control
                  FilterChip(
                    label: const Text('Auto Oscillator'),
                    selected: micService.autoControlOscillator,
                    onSelected: (selected) {
                      micService.toggleAutoControlOscillator();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Microphone visualizer
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: MicrophoneVisualizer(
                        volume: micService.volume,
                        isRecording: micService.isRecording,
                        animation: _animationController,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Volume level indicator
              if (micService.isRecording)
                LinearProgressIndicator(
                  value: micService.volume,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getVolumeColor(micService.volume),
                  ),
                ),
                
              const SizedBox(height: 8),
              
              // Recording status text
              Text(
                micService.isRecording
                    ? 'Recording... (Volume: ${(micService.volume * 100).toStringAsFixed(1)}%)'
                    : micService.hasPermission
                        ? 'Ready to record'
                        : 'Tap the microphone icon to start',
                style: TextStyle(
                  color: micService.isRecording ? Colors.red : null,
                  fontStyle: micService.isRecording ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          );
        }
      ),
    );
  }
  
  // Get color based on volume level
  Color _getVolumeColor(double volume) {
    if (volume < 0.3) {
      return Colors.green;
    } else if (volume < 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Custom painter for visualizing microphone input
class MicrophoneVisualizer extends CustomPainter {
  final double volume;
  final bool isRecording;
  final Animation<double> animation;
  
  MicrophoneVisualizer({
    required this.volume,
    required this.isRecording,
    required this.animation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) {
      _drawIdleState(canvas, size);
      return;
    }
    
    _drawActiveVisualizer(canvas, size);
  }
  
  void _drawIdleState(Canvas canvas, Size size) {
    // Draw a simple waveform
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    final centerY = size.height / 2;
    
    path.moveTo(0, centerY);
    
    for (double x = 0; x < size.width; x += 5) {
      final normalized = x / size.width;
      final y = centerY + sin(normalized * 10) * 10;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Draw a text in the center
    const text = 'Tap mic to start recording';
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 16,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }
  
  void _drawActiveVisualizer(Canvas canvas, Size size) {
    // Draw a dynamic waveform based on volume and animation
    final paint = Paint()
      ..color = _getVolumeColor(volume)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final centerY = size.height / 2;
    final maxAmplitude = size.height * 0.4 * volume;
    
    // Create multiple wave forms with phase offsets
    for (int i = 1; i <= 3; i++) {
      final path = Path();
      path.moveTo(0, centerY);
      
      final amplitude = maxAmplitude * (i / 3);
      final frequency = 3.0 * i;
      final phase = animation.value * 10 * i;
      
      for (double x = 0; x < size.width; x += 2) {
        final normalized = x / size.width;
        final y = centerY + sin((normalized * frequency * 2 * pi) + phase) * amplitude;
        path.lineTo(x, y);
      }
      
      // Adjust opacity based on layer
      paint.color = _getVolumeColor(volume).withOpacity(1.0 - (i - 1) * 0.3);
      canvas.drawPath(path, paint);
    }
    
    // Draw volume text
    final textSpan = TextSpan(
      text: 'Volume: ${(volume * 100).toStringAsFixed(0)}%',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - textPainter.width - 16,
        16,
      ),
    );
  }
  
  Color _getVolumeColor(double volume) {
    if (volume < 0.3) {
      return Colors.green;
    } else if (volume < 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Helper function to calculate sine
  double sin(double value) {
    return math.sin(value);
  }
  
  double pi = math.pi;
  
  @override
  bool shouldRepaint(covariant MicrophoneVisualizer oldDelegate) {
    return volume != oldDelegate.volume ||
           isRecording != oldDelegate.isRecording ||
           animation.value != oldDelegate.animation.value;
  }
}