import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../core/granular_parameters.dart' hide GrainWindowType;
import '../../core/synth_parameters.dart';
import '../../core/parameter_definitions.dart';
import '../shared_controls/control_knob_widget.dart';

/// Widget for controlling granular synthesis parameters
class GranularControlsWidget extends StatefulWidget {
  const GranularControlsWidget({Key? key}) : super(key: key);

  @override
  State<GranularControlsWidget> createState() => _GranularControlsWidgetState();
}

class _GranularControlsWidgetState extends State<GranularControlsWidget> {
  bool _isLoadingFile = false;
  String? _loadedFileName;
  
  @override
  Widget build(BuildContext context) {
    final synthProvider = context.watch<SynthParametersModel>();
    final params = synthProvider.granularParameters;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.grain,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Granular Synthesis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Switch(
                        value: params.isActive,
                        onChanged: (value) => params.setActive(value),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // File loading controls
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoadingFile ? null : _loadAudioFile,
                        icon: _isLoadingFile 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.folder_open),
                        label: Text(_loadedFileName ?? 'Load Audio File'),
                      ),
                      if (_loadedFileName != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearAudioFile,
                          tooltip: 'Clear audio file',
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Only show controls if granular is active
                  if (params.isActive) ...[
                    // Grain parameters
                    _buildSectionHeader('Grain Parameters'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ControlKnob(
                            value: params.grainRate,
                            min: 0.1,
                            max: 100,
                            divisions: 100,
                            label: 'Rate',
                            valueFormat: (v) => '${v.toStringAsFixed(1)} Hz',
                            onChanged: params.setGrainRate,
                          ),
                        ),
                        Expanded(
                          child: ControlKnob(
                            value: params.grainDuration * 1000,
                            min: 1,
                            max: 1000,
                            divisions: 100,
                            logarithmic: true,
                            label: 'Duration',
                            valueFormat: (v) => '${v.toStringAsFixed(0)} ms',
                            onChanged: (v) => params.setGrainDuration(v / 1000),
                          ),
                        ),
                        Expanded(
                          child: ControlKnob(
                            value: params.position,
                            min: 0,
                            max: 1,
                            divisions: 100,
                            label: 'Position',
                            valueFormat: (v) => '${(v * 100).toStringAsFixed(0)}%',
                            onChanged: params.setPosition,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Pitch and amplitude
                    _buildSectionHeader('Pitch & Amplitude'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ControlKnob(
                            value: params.pitch,
                            min: 0.1,
                            max: 4,
                            divisions: 100,
                            label: 'Pitch',
                            valueFormat: (v) => v.toStringAsFixed(2),
                            onChanged: params.setPitch,
                          ),
                        ),
                        Expanded(
                          child: ControlKnob(
                            value: params.amplitude,
                            min: 0,
                            max: 1,
                            divisions: 100,
                            label: 'Amplitude',
                            valueFormat: (v) => '${(v * 100).toStringAsFixed(0)}%',
                            onChanged: params.setAmplitude,
                          ),
                        ),
                        Expanded(
                          child: ControlKnob(
                            value: params.pan,
                            min: -1,
                            max: 1,
                            divisions: 100,
                            label: 'Pan',
                            valueFormat: (v) => v == 0 ? 'C' : v < 0 ? 'L${(-v * 100).toStringAsFixed(0)}' : 'R${(v * 100).toStringAsFixed(0)}',
                            onChanged: params.setPan,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Variations
                    _buildSectionHeader('Variations'),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Position'),
                              Slider(
                                value: params.positionVariation,
                                min: 0,
                                max: 1,
                                onChanged: params.setPositionVariation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Pitch'),
                              Slider(
                                value: params.pitchVariation,
                                min: 0,
                                max: 2,
                                onChanged: params.setPitchVariation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Duration'),
                              Slider(
                                value: params.durationVariation,
                                min: 0,
                                max: 1,
                                onChanged: params.setDurationVariation,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Pan'),
                              Slider(
                                value: params.panVariation,
                                min: 0,
                                max: 1,
                                onChanged: params.setPanVariation,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Window type
                    _buildSectionHeader('Window Type'),
                    DropdownButton<GrainWindowType>(
                      value: params.windowType,
                      isExpanded: true,
                      onChanged: (type) {
                        if (type != null) {
                          params.setWindowType(type);
                        }
                      },
                      items: GrainWindowType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getWindowTypeName(type)),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Visualizer
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: _GranularVisualizer(
                          position: params.position,
                          grainRate: params.grainRate,
                          grainDuration: params.grainDuration,
                          isActive: params.isActive,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
  
  String _getWindowTypeName(GrainWindowType type) {
    switch (type) {
      case GrainWindowType.rectangular:
        return 'Rectangular';
      case GrainWindowType.hann:
        return 'Hann';
      case GrainWindowType.hamming:
        return 'Hamming';
      case GrainWindowType.blackman:
        return 'Blackman';
    }
  }
  
  Future<void> _loadAudioFile() async {
    setState(() {
      _isLoadingFile = true;
    });
    
    try {
      // Use file picker to select audio file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        
        // Convert to float samples (assuming 16-bit PCM for simplicity)
        // In a real app, you'd use a proper audio decoding library
        final samples = Float32List(bytes.length ~/ 2);
        for (int i = 0; i < samples.length; i++) {
          final int16 = bytes[i * 2] | (bytes[i * 2 + 1] << 8);
          samples[i] = int16 / 32768.0;
        }
        
        // Load into granular synthesizer
        final synthModel = context.read<SynthParametersModel>();
        final loadResult = synthModel.engine.loadGranularBuffer(samples);
        
        if (loadResult == 0) {
          setState(() {
            _loadedFileName = result.files.single.name;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio file loaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to load audio buffer');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingFile = false;
      });
    }
  }
  
  void _clearAudioFile() {
    // Clear the buffer in the engine
    final synthModel = context.read<SynthParametersModel>();
    final engine = synthModel.engine;
    engine.loadGranularBuffer([]);
    
    setState(() {
      _loadedFileName = null;
    });
  }
}

/// Custom painter for visualizing granular synthesis
class _GranularVisualizer extends CustomPainter {
  final double position;
  final double grainRate;
  final double grainDuration;
  final bool isActive;
  
  _GranularVisualizer({
    required this.position,
    required this.grainRate,
    required this.grainDuration,
    required this.isActive,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw waveform placeholder
    paint.color = Colors.grey;
    final path = Path();
    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x += 5) {
      final y = size.height / 2 + Math.sin(x * 0.05) * 20;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    
    // Draw position indicator
    paint.color = Colors.white;
    paint.strokeWidth = 2.0;
    final posX = position * size.width;
    canvas.drawLine(
      Offset(posX, 0),
      Offset(posX, size.height),
      paint,
    );
    
    // Draw grains
    paint.color = Colors.cyan.withOpacity(0.7);
    final grainWidth = (grainDuration * 1000 / 50) * size.width;
    final grainSpacing = size.width / grainRate;
    
    for (double x = posX - grainSpacing * 2; x < posX + grainSpacing * 2; x += grainSpacing) {
      if (x >= 0 && x < size.width) {
        canvas.drawRect(
          Rect.fromLTWH(x - grainWidth / 2, 10, grainWidth, size.height - 20),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant _GranularVisualizer oldDelegate) {
    return position != oldDelegate.position ||
           grainRate != oldDelegate.grainRate ||
           grainDuration != oldDelegate.grainDuration ||
           isActive != oldDelegate.isActive;
  }
}

// Simple math helper
class Math {
  static double sin(double x) => (x % (2 * 3.14159) < 3.14159) 
      ? (x % 3.14159) / 3.14159 * 2 - 1
      : -((x % 3.14159) / 3.14159 * 2 - 1);
}