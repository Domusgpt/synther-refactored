import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/synth_parameters.dart';
import '../../core/audio_service.dart';

/// A widget that displays an XY pad for controlling 
/// pitch (X axis) and sound modulation (Y axis).
class XYPad extends StatefulWidget {
  const XYPad({
    super.key,
    this.width = double.infinity,
    this.height = 300,
    this.backgroundColor = Colors.black,
    this.gridColor = Colors.grey,
    this.cursorColor = Colors.green,
    this.cursorSize = 20,
    this.label = 'XY Pad',
    this.octaveRange = 2, // Default to 2 octaves range
    this.baseNote = 48, // Default to C3
    this.scale = Scale.chromatic, // Default scale
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final Color gridColor;
  final Color cursorColor;
  final double cursorSize;
  final String label;
  final int octaveRange;
  final int baseNote;
  final Scale scale;

  @override
  State<XYPad> createState() => _XYPadState();
}

/// Available musical scales
enum Scale {
  chromatic,
  major,
  minor,
  majorPentatonic,
  minorPentatonic,
  blues,
  // More scales can be added here
}

class _XYPadState extends State<XYPad> {
  // Touch position (0.0 to 1.0 range)
  double _xPosition = 0.5;
  double _yPosition = 0.5;
  
  // Currently playing note
  int? _currentNote;
  bool _isPadActive = false;
  
  // Scale and key settings
  late Scale _currentScale;
  late int _baseNote;
  late int _octaveRange;
  
  // Modulation parameter currently controlled by Y axis
  YAxisParameter _yAxisParameter = YAxisParameter.filterCutoff;
  
  // Path of recent touches for visual trail effect (Kaossilator-style)
  final List<Offset> _touchPath = [];
  final int _maxPathLength = 20; // Increased for smoother trail
  
  // Synthesizer engine bindings
  final AudioService _audioService = AudioService.instance;
  
  // Performance optimization
  DateTime? _lastUpdate;
  final Duration _updateThrottle = const Duration(milliseconds: 16); // 60fps
  
  @override
  void initState() {
    super.initState();
    
    // Initialize synth engine
    _initSynthEngine();
    
    // Set initial scale settings
    _currentScale = widget.scale;
    _baseNote = widget.baseNote;
    _octaveRange = widget.octaveRange;
  }
  
  @override
  void didUpdateWidget(XYPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update settings if props change
    if (widget.scale != oldWidget.scale) {
      _currentScale = widget.scale;
    }
    if (widget.baseNote != oldWidget.baseNote) {
      _baseNote = widget.baseNote;
    }
    if (widget.octaveRange != oldWidget.octaveRange) {
      _octaveRange = widget.octaveRange;
    }
  }
  
  @override
  void dispose() {
    // Release any active notes
    _releaseCurrentNote();
    super.dispose();
  }
  
  Future<void> _initSynthEngine() async {
    try {
      // Audio service is already a singleton
      await _audioService.initialize();
    } catch (e) {
      print('Failed to initialize synthesizer engine: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XY Pad label and scale selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Label
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                // Scale selector
                DropdownButton<Scale>(
                  value: _currentScale,
                  onChanged: (newScale) {
                    if (newScale != null) {
                      setState(() {
                        _currentScale = newScale;
                      });
                    }
                  },
                  items: Scale.values.map((scale) {
                    return DropdownMenuItem<Scale>(
                      value: scale,
                      child: Text(_getScaleName(scale)),
                    );
                  }).toList(),
                ),
              ],
            ),
            
            // Settings row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Base note display
                  PopupMenuButton<int>(
                    child: Chip(
                      label: Text('Root: ${_getNoteNameWithOctave(_baseNote)}'),
                    ),
                    onSelected: (newBaseNote) {
                      setState(() {
                        _baseNote = newBaseNote;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      // Generate items for C1 through C6
                      List<PopupMenuItem<int>> items = [];
                      for (int octave = 1; octave <= 6; octave++) {
                        for (int noteIndex = 0; noteIndex < 12; noteIndex++) {
                          final noteNumber = (octave + 1) * 12 + noteIndex;
                          items.add(PopupMenuItem<int>(
                            value: noteNumber,
                            child: Text(_getNoteNameWithOctave(noteNumber)),
                          ));
                        }
                      }
                      return items;
                    },
                  ),
                  
                  // Y-axis parameter selector
                  DropdownButton<YAxisParameter>(
                    value: _yAxisParameter,
                    onChanged: (newParam) {
                      if (newParam != null) {
                        setState(() {
                          _yAxisParameter = newParam;
                        });
                      }
                    },
                    items: YAxisParameter.values.map((param) {
                      return DropdownMenuItem<YAxisParameter>(
                        value: param,
                        child: Text(_getParameterName(param)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // XY Pad touchable area
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: RepaintBoundary(
                child: GestureDetector(
                  onPanStart: (details) => _handleTouchStart(details.localPosition, model),
                  onPanUpdate: (details) => _handleTouchUpdate(details.localPosition, model),
                  onPanEnd: (_) => _handleTouchEnd(),
                  onTapDown: (details) => _handleTouchStart(details.localPosition, model),
                  onTapUp: (_) => _handleTouchEnd(),
                  onTapCancel: () => _handleTouchEnd(),
                  child: CustomPaint(
                  painter: XYPadPainter(
                    x: _xPosition,
                    y: _yPosition,
                    gridColor: widget.gridColor,
                    cursorColor: widget.cursorColor,
                    cursorSize: widget.cursorSize,
                    isActive: _isPadActive,
                    touchPath: _touchPath,
                    scale: _currentScale,
                  ),
                  ),
                ),
              ),
            ),
            
            // Display area for current note and parameter
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isPadActive
                        ? 'Playing: ${_getNoteNameWithOctave(_currentNote ?? 60)} | ${_getParameterName(_yAxisParameter)}: ${(_yPosition * 100).toStringAsFixed(0)}%'
                        : 'Touch pad to play',
                    style: TextStyle(
                      fontWeight: _isPadActive ? FontWeight.bold : FontWeight.normal,
                      color: _isPadActive ? widget.cursorColor : null,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _getScaleName(Scale scale) {
    switch (scale) {
      case Scale.chromatic:
        return 'Chromatic';
      case Scale.major:
        return 'Major';
      case Scale.minor:
        return 'Minor';
      case Scale.majorPentatonic:
        return 'Major Pentatonic';
      case Scale.minorPentatonic:
        return 'Minor Pentatonic';
      case Scale.blues:
        return 'Blues';
      default:
        return 'Unknown';
    }
  }
  
  String _getParameterName(YAxisParameter param) {
    switch (param) {
      case YAxisParameter.filterCutoff:
        return 'Filter Cutoff';
      case YAxisParameter.filterResonance:
        return 'Resonance';
      case YAxisParameter.oscillatorMix:
        return 'Osc Mix';
      case YAxisParameter.reverbMix:
        return 'Reverb';
      case YAxisParameter.modulationDepth:
        return 'Mod Depth';
      default:
        return 'Unknown';
    }
  }
  
  String _getNoteNameWithOctave(int midiNote) {
    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (midiNote / 12).floor() - 1;
    final noteIndex = midiNote % 12;
    return '${noteNames[noteIndex]}$octave';
  }
  
  void _handleTouchStart(Offset localPosition, SynthParametersModel model) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final xPos = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final yPos = (1.0 - localPosition.dy / box.size.height).clamp(0.0, 1.0); // Invert Y for intuitive control
    
    setState(() {
      _xPosition = xPos;
      _yPosition = yPos;
      _isPadActive = true;
      
      // Start a new touch path
      _touchPath.clear();
      _touchPath.add(Offset(xPos, yPos));
    });
    
    // Get note from X position based on scale
    final note = _getNoteFromPosition(xPos);
    
    // Apply Y-axis parameter
    _applyYAxisParameter(yPos, model);
    
    // Update XY Pad position in model for parameter sync
    model.setXYPadPosition(xPos, yPos);
    
    // Trigger note via model instead of audio service directly
    model.noteOn(note, 100);
    
    setState(() {
      _currentNote = note;
      _lastUpdate = DateTime.now();
    });
  }
  
  void _handleTouchUpdate(Offset localPosition, SynthParametersModel model) {
    // Throttle updates for performance
    final now = DateTime.now();
    if (_lastUpdate != null && now.difference(_lastUpdate!) < _updateThrottle) {
      return;
    }
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final xPos = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final yPos = (1.0 - localPosition.dy / box.size.height).clamp(0.0, 1.0); // Invert Y for intuitive control
    
    // Update touch trail
    setState(() {
      _xPosition = xPos;
      _yPosition = yPos;
      _lastUpdate = now;
      
      _touchPath.add(Offset(xPos, yPos));
      if (_touchPath.length > _maxPathLength) {
        _touchPath.removeAt(0);
      }
    });
    
    // Get new note from X position
    final note = _getNoteFromPosition(xPos);
    
    // Apply Y-axis parameter
    _applyYAxisParameter(yPos, model);
    
    // Update XY Pad position in model
    model.setXYPadPosition(xPos, yPos);
    
    // If note changed, trigger the new note
    if (note != _currentNote) {
      // Release previous note
      if (_currentNote != null) {
        model.noteOff(_currentNote!);
      }
      
      // Trigger new note
      model.noteOn(note, 100);
      
      setState(() {
        _currentNote = note;
      });
    }
  }
  
  void _handleTouchEnd() {
    _releaseCurrentNote();
    
    setState(() {
      _isPadActive = false;
      _touchPath.clear();
    });
  }
  
  void _releaseCurrentNote() {
    if (_currentNote != null) {
      final model = context.read<SynthParametersModel>();
      model.noteOff(_currentNote!);
      
      setState(() {
        _currentNote = null;
      });
    }
  }
  
  int _getNoteFromPosition(double xPos) {
    // Get note based on scale and x position
    switch (_currentScale) {
      case Scale.chromatic:
        // Full chromatic scale across the X axis
        final noteRange = _octaveRange * 12;
        return _baseNote + (xPos * noteRange).round();
        
      case Scale.major:
        // Major scale (W-W-H-W-W-W-H pattern)
        final majorScale = [0, 2, 4, 5, 7, 9, 11]; // Whole and half steps
        final notesInScale = majorScale.length * _octaveRange;
        final scaleIndex = (xPos * notesInScale).floor();
        final octave = scaleIndex ~/ majorScale.length;
        final degree = scaleIndex % majorScale.length;
        return _baseNote + octave * 12 + majorScale[degree];
        
      case Scale.minor:
        // Natural minor scale (W-H-W-W-H-W-W pattern)
        final minorScale = [0, 2, 3, 5, 7, 8, 10]; // Whole and half steps
        final notesInScale = minorScale.length * _octaveRange;
        final scaleIndex = (xPos * notesInScale).floor();
        final octave = scaleIndex ~/ minorScale.length;
        final degree = scaleIndex % minorScale.length;
        return _baseNote + octave * 12 + minorScale[degree];
        
      case Scale.majorPentatonic:
        // Major pentatonic (1, 2, 3, 5, 6 of major scale)
        final pentatonicScale = [0, 2, 4, 7, 9];
        final notesInScale = pentatonicScale.length * _octaveRange;
        final scaleIndex = (xPos * notesInScale).floor();
        final octave = scaleIndex ~/ pentatonicScale.length;
        final degree = scaleIndex % pentatonicScale.length;
        return _baseNote + octave * 12 + pentatonicScale[degree];
        
      case Scale.minorPentatonic:
        // Minor pentatonic (1, 3, 4, 5, 7 of natural minor scale)
        final pentatonicScale = [0, 3, 5, 7, 10];
        final notesInScale = pentatonicScale.length * _octaveRange;
        final scaleIndex = (xPos * notesInScale).floor();
        final octave = scaleIndex ~/ pentatonicScale.length;
        final degree = scaleIndex % pentatonicScale.length;
        return _baseNote + octave * 12 + pentatonicScale[degree];
        
      case Scale.blues:
        // Blues scale (minor pentatonic + blue note)
        final bluesScale = [0, 3, 5, 6, 7, 10];
        final notesInScale = bluesScale.length * _octaveRange;
        final scaleIndex = (xPos * notesInScale).floor();
        final octave = scaleIndex ~/ bluesScale.length;
        final degree = scaleIndex % bluesScale.length;
        return _baseNote + octave * 12 + bluesScale[degree];
        
      default:
        // Default to chromatic
        final noteRange = _octaveRange * 12;
        return _baseNote + (xPos * noteRange).round();
    }
  }
  
  void _applyYAxisParameter(double yPos, SynthParametersModel model) {
    // Apply the selected parameter based on Y position
    switch (_yAxisParameter) {
      case YAxisParameter.filterCutoff:
        // Exponential mapping for filter cutoff (20Hz - 20kHz)
        final cutoff = 20 * pow(1000, yPos);
        model.setFilterCutoff(cutoff);
        break;
        
      case YAxisParameter.filterResonance:
        model.setFilterResonance(yPos);
        break;
        
      case YAxisParameter.oscillatorMix:
        if (model.oscillators.length >= 2) {
          // Use a temporary local copy for the operation
          final osc0 = model.oscillators[0].copyWith(volume: 1 - yPos);
          final osc1 = model.oscillators[1].copyWith(volume: yPos);
          
          // Update both oscillators
          model.updateOscillator(0, osc0);
          model.updateOscillator(1, osc1);
        }
        break;
        
      case YAxisParameter.reverbMix:
        model.setReverbMix(yPos);
        break;
        
      case YAxisParameter.modulationDepth:
        // This would connect to a modulation parameter if available
        // For now, we'll simply print it for debugging
        print('Modulation depth: $yPos');
        break;
    }
  }
  
  // Exponential mapping for filter cutoff
  double pow(double base, double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return base;
    // Approximate exponential curve for filter mapping
    double result = base;
    for (int i = 1; i < exponent.toInt(); i++) {
      result *= base;
    }
    return result;
  }
}

// Parameters controllable by Y axis
enum YAxisParameter {
  filterCutoff,
  filterResonance,
  oscillatorMix,
  reverbMix,
  modulationDepth,
}

/// Custom painter for the XY pad display with LED trail effect
class XYPadPainter extends CustomPainter {
  final double x;
  final double y;
  final Color gridColor;
  final Color cursorColor;
  final double cursorSize;
  final bool isActive;
  final List<Offset> touchPath;
  final Scale scale;
  
  XYPadPainter({
    required this.x,
    required this.y,
    required this.gridColor,
    required this.cursorColor,
    required this.cursorSize,
    this.isActive = false,
    required this.touchPath,
    required this.scale,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid
    _drawGrid(canvas, size);
    
    // Draw scale guide if not chromatic
    if (scale != Scale.chromatic) {
      _drawScaleGuide(canvas, size);
    }
    
    // Draw touch trail (Kaossilator LED path effect)
    _drawTouchTrail(canvas, size);
    
    // Draw cursor if active
    if (isActive) {
      _drawCursor(canvas, size);
    }
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    // Draw primary grid (5x5)
    final int gridDivisions = 5;
    for (int i = 1; i < gridDivisions; i++) {
      final double dx = size.width * i / gridDivisions;
      final double dy = size.height * i / gridDivisions;
      
      // Vertical lines
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, size.height),
        gridPaint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, dy),
        Offset(size.width, dy),
        gridPaint,
      );
    }
    
    // Draw major grid lines (center lines)
    final majorGridPaint = Paint()
      ..color = gridColor.withOpacity(0.5)
      ..strokeWidth = 1.5;
    
    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      majorGridPaint,
    );
    
    // Horizontal center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      majorGridPaint,
    );
  }
  
  void _drawScaleGuide(Canvas canvas, Size size) {
    // Get scale pattern based on scale type
    List<int> scalePattern;
    switch (scale) {
      case Scale.major:
        scalePattern = [0, 2, 4, 5, 7, 9, 11];
        break;
      case Scale.minor:
        scalePattern = [0, 2, 3, 5, 7, 8, 10];
        break;
      case Scale.majorPentatonic:
        scalePattern = [0, 2, 4, 7, 9];
        break;
      case Scale.minorPentatonic:
        scalePattern = [0, 3, 5, 7, 10];
        break;
      case Scale.blues:
        scalePattern = [0, 3, 5, 6, 7, 10];
        break;
      default:
        return; // Don't draw for chromatic
    }
    
    // Draw note markers
    final notePaint = Paint()
      ..color = cursorColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final double noteSize = 8;
    final int octaves = 2; // Assuming 2 octaves
    final double octaveWidth = size.width / octaves;
    
    for (int octave = 0; octave < octaves; octave++) {
      for (int noteIndex in scalePattern) {
        // Calculate x position based on note in scale
        final double xPos = octave * octaveWidth + (noteIndex / 12) * octaveWidth;
        
        // Draw note markers along the bottom
        canvas.drawCircle(
          Offset(xPos, size.height - 10),
          noteSize / 2,
          notePaint,
        );
      }
    }
  }
  
  void _drawTouchTrail(Canvas canvas, Size size) {
    if (touchPath.isEmpty) return;
    
    // Draw touch trail with decreasing opacity
    for (int i = 0; i < touchPath.length; i++) {
      final point = touchPath[i];
      final progress = i / touchPath.length;
      final opacity = progress;
      
      final trailPaint = Paint()
        ..color = cursorColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      final pointSize = cursorSize * (0.3 + (0.7 * progress));
      
      canvas.drawCircle(
        Offset(point.dx * size.width, (1 - point.dy) * size.height),
        pointSize,
        trailPaint,
      );
    }
  }
  
  void _drawCursor(Canvas canvas, Size size) {
    final cursorX = x * size.width;
    final cursorY = (1.0 - y) * size.height; // Invert Y for display
    
    // Draw cursor glow effect
    final glowPaint = Paint()
      ..color = cursorColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize * 2.5,
      glowPaint,
    );
    
    // Draw cursor shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize + 2,
      shadowPaint,
    );
    
    // Draw cursor (main circle)
    final cursorPaint = Paint()
      ..color = cursorColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize,
      cursorPaint,
    );
    
    // Draw cursor border
    final cursorBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize,
      cursorBorderPaint,
    );
    
    // Draw crosshairs
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.0;
    
    // Horizontal crosshair
    canvas.drawLine(
      Offset(0, cursorY),
      Offset(size.width, cursorY),
      crosshairPaint,
    );
    
    // Vertical crosshair
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      crosshairPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant XYPadPainter oldDelegate) {
    return x != oldDelegate.x || 
           y != oldDelegate.y ||
           gridColor != oldDelegate.gridColor ||
           cursorColor != oldDelegate.cursorColor ||
           cursorSize != oldDelegate.cursorSize ||
           isActive != oldDelegate.isActive ||
           touchPath != oldDelegate.touchPath ||
           scale != oldDelegate.scale;
  }
}