import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/synth_parameters.dart';
import '../../core/audio_service.dart';

/// A widget that displays an XY pad for controlling parameters and triggering notes.
class XYPadWidget extends StatefulWidget {
  const XYPadWidget({
    super.key,
    this.width = double.infinity,
    this.height = 300,
    this.backgroundColor = Colors.black,
    this.gridColor = Colors.grey,
    this.cursorColor = Colors.white,
    this.cursorSize = 20,
    this.label = 'XY Pad',
    this.showNoteMode = true,
  });

  final double width;
  final double height;
  final Color backgroundColor;
  final Color gridColor;
  final Color cursorColor;
  final double cursorSize;
  final String label;
  final bool showNoteMode; // Whether to show note triggering mode option

  @override
  State<XYPadWidget> createState() => _XYPadWidgetState();
}

class _XYPadWidgetState extends State<XYPadWidget> {
  // Local position state (0.0 to 1.0 range)
  double _xPosition = 0.5;
  double _yPosition = 0.5;
  
  // Note mode toggle
  bool _noteMode = false;
  
  // Currently playing note
  int? _currentNote;
  
  // Note velocity
  int _velocity = 100;
  
  // Audio service
  final AudioService _audioService = AudioService.instance;
  
  // For note mapping
  // Default range: C2 (36) to C6 (84)
  int _lowestNote = 36;
  int _highestNote = 84;
  
  // Controllers for the XY pad
  XYPadAssignment _xAxisAssignment = XYPadAssignment.filterCutoff;
  XYPadAssignment _yAxisAssignment = XYPadAssignment.filterResonance;
  
  // Get parameter name for display
  String _getAxisName(XYPadAssignment assignment) {
    switch (assignment) {
      case XYPadAssignment.filterCutoff:
        return 'Filter Cutoff';
      case XYPadAssignment.filterResonance:
        return 'Filter Resonance';
      case XYPadAssignment.oscillatorMix:
        return 'Oscillator Mix';
      case XYPadAssignment.reverbMix:
        return 'Reverb Mix';
      default:
        return 'Unknown';
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize synth engine
    _initSynthEngine();
    
    // Initialize controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = Provider.of<SynthParametersModel>(context, listen: false);
      _xPosition = model.xyPadX;
      _yPosition = model.xyPadY;
      _xAxisAssignment = model.xAxisAssignment;
      _yAxisAssignment = model.yAxisAssignment;
    });
  }
  
  @override
  void dispose() {
    // Release any active notes
    _releaseCurrentNote();
    super.dispose();
  }
  
  Future<void> _initSynthEngine() async {
    try {
      await _audioService.initialize();
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        // Update local state if model values changed externally and in parameter mode
        if (!_noteMode && (_xPosition != model.xyPadX || _yPosition != model.xyPadY)) {
          _xPosition = model.xyPadX;
          _yPosition = model.xyPadY;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XY Pad label and mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Label
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                // Mode toggle
                if (widget.showNoteMode)
                  Row(
                    children: [
                      const Text('Note Mode'),
                      Switch(
                        value: _noteMode,
                        onChanged: (value) {
                          setState(() {
                            _noteMode = value;
                            // Release any playing note when switching away from note mode
                            if (!_noteMode) {
                              _releaseCurrentNote();
                            }
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            
            // Mode-specific controls
            if (!_noteMode) 
              // Parameter mode controls - XY Pad axis assignments
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // X-Axis assignment dropdown
                    Row(
                      children: [
                        const Text('X: '),
                        DropdownButton<XYPadAssignment>(
                          value: model.xAxisAssignment,
                          onChanged: (XYPadAssignment? newValue) {
                            if (newValue != null) {
                              model.setXAxisAssignment(newValue);
                            }
                          },
                          items: XYPadAssignment.values.map<DropdownMenuItem<XYPadAssignment>>((XYPadAssignment value) {
                            return DropdownMenuItem<XYPadAssignment>(
                              value: value,
                              child: Text(_getAxisName(value)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    
                    // Y-Axis assignment dropdown
                    Row(
                      children: [
                        const Text('Y: '),
                        DropdownButton<XYPadAssignment>(
                          value: model.yAxisAssignment,
                          onChanged: (XYPadAssignment? newValue) {
                            if (newValue != null) {
                              model.setYAxisAssignment(newValue);
                            }
                          },
                          items: XYPadAssignment.values.map<DropdownMenuItem<XYPadAssignment>>((XYPadAssignment value) {
                            return DropdownMenuItem<XYPadAssignment>(
                              value: value,
                              child: Text(_getAxisName(value)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // Note mode controls - Note range and velocity
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Note range display
                    Text('Range: ${_getNoteName(_lowestNote)} - ${_getNoteName(_highestNote)}'),
                    
                    // Velocity slider
                    Row(
                      children: [
                        const Text('Velocity: '),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: _velocity.toDouble(),
                            min: 1,
                            max: 127,
                            divisions: 126,
                            onChanged: (value) {
                              setState(() {
                                _velocity = value.round();
                              });
                            },
                          ),
                        ),
                        Text('$_velocity'),
                      ],
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
              ),
              child: GestureDetector(
                onPanStart: (details) => _handleTouchStart(details.localPosition, model),
                onPanUpdate: (details) => _handleTouchUpdate(details.localPosition, model),
                onPanEnd: (details) => _handleTouchEnd(),
                onTapDown: (details) => _handleTouchStart(details.localPosition, model),
                onTapUp: (details) => _handleTouchEnd(),
                onTapCancel: () => _handleTouchEnd(),
                child: CustomPaint(
                  painter: XYPadPainter(
                    x: _xPosition,
                    y: _yPosition,
                    gridColor: widget.gridColor,
                    cursorColor: widget.cursorColor,
                    cursorSize: widget.cursorSize,
                    noteMode: _noteMode,
                    currentNote: _currentNote,
                  ),
                ),
              ),
            ),
            
            // Display area
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _noteMode
                  ? _buildNoteModeDisplay()
                  : _buildParameterModeDisplay(model),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildParameterModeDisplay(SynthParametersModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_getAxisName(model.xAxisAssignment)}: ${(_xPosition * 100).toStringAsFixed(1)}%'),
        Text('${_getAxisName(model.yAxisAssignment)}: ${(_yPosition * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
  
  Widget _buildNoteModeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _currentNote != null
              ? 'Playing: ${_getNoteName(_currentNote!)} (${_currentNote!})'
              : 'Touch to play notes',
          style: TextStyle(
            fontWeight: _currentNote != null ? FontWeight.bold : FontWeight.normal,
            color: _currentNote != null ? Colors.deepPurple : null,
          ),
        ),
      ],
    );
  }
  
  String _getNoteName(int midiNote) {
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
    });
    
    if (_noteMode) {
      // Note mode: trigger note based on position
      _triggerNote(xPos, yPos);
    } else {
      // Parameter mode: update synth parameters
      model.setXYPadPosition(xPos, yPos);
    }
  }
  
  void _handleTouchUpdate(Offset localPosition, SynthParametersModel model) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final xPos = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final yPos = (1.0 - localPosition.dy / box.size.height).clamp(0.0, 1.0); // Invert Y for intuitive control
    
    setState(() {
      _xPosition = xPos;
      _yPosition = yPos;
    });
    
    if (_noteMode) {
      // Note mode: update current note
      _updateNote(xPos, yPos);
    } else {
      // Parameter mode: update synth parameters
      model.setXYPadPosition(xPos, yPos);
    }
  }
  
  void _handleTouchEnd() {
    if (_noteMode) {
      _releaseCurrentNote();
    }
  }
  
  void _triggerNote(double x, double y) {
    // Map x position to note (pitch)
    final noteRange = _highestNote - _lowestNote;
    final note = _lowestNote + (x * noteRange).round();
    
    // Map y position to velocity or filter
    // In this implementation, y directly controls velocity
    final adjustedVelocity = (_velocity * y).round().clamp(1, 127);
    
    // Trigger note via audio service
    _audioService.noteOn(0, note, adjustedVelocity / 127.0);
      
      setState(() {
        _currentNote = note;
      });
    }
  }
  
  void _updateNote(double x, double y) {
    // Only update if we have an active note
    if (_currentNote != null) {
      // Map x position to note (pitch)
      final noteRange = _highestNote - _lowestNote;
      final note = _lowestNote + (x * noteRange).round();
      
      // If note changed, release old note and play new one
      if (note != _currentNote) {
        _releaseCurrentNote();
        
        // Map y position to velocity
        final adjustedVelocity = (_velocity * y).round().clamp(1, 127);
        
        // Trigger new note
        _audioService.noteOn(0, note, adjustedVelocity / 127.0);
          
          setState(() {
            _currentNote = note;
          });
        }
      }
    }
  }
  
  void _releaseCurrentNote() {
    if (_currentNote != null && _synthEngine != null) {
      _audioService.noteOff(0);
      
      setState(() {
        _currentNote = null;
      });
    }
  }
}

/// Custom painter for the XY pad display
class XYPadPainter extends CustomPainter {
  final double x;
  final double y;
  final Color gridColor;
  final Color cursorColor;
  final double cursorSize;
  final bool noteMode;
  final int? currentNote;
  
  XYPadPainter({
    required this.x,
    required this.y,
    required this.gridColor,
    required this.cursorColor,
    required this.cursorSize,
    this.noteMode = false,
    this.currentNote,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    // Draw grid lines
    final int divisions = noteMode ? 12 : 5; // 12 divisions in note mode (for octaves)
    for (int i = 1; i < divisions; i++) {
      final double dx = size.width * i / divisions;
      final double dy = size.height * i / divisions;
      
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
    
    // Draw piano keys in note mode
    if (noteMode) {
      _drawPianoLayout(canvas, size);
    }
    
    // Draw cursor
    final cursorX = x * size.width;
    final cursorY = (1.0 - y) * size.height; // Invert Y for display
    
    // Draw cursor shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize + 2,
      shadowPaint,
    );
    
    // Draw cursor
    final cursorPaint = Paint()
      ..color = currentNote != null ? Colors.green : cursorColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize,
      cursorPaint,
    );
    
    // Draw cursor border
    final cursorBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(cursorX, cursorY),
      cursorSize,
      cursorBorderPaint,
    );
    
    // Draw crosshairs
    final crosshairPaint = Paint()
      ..color = cursorColor.withOpacity(0.5)
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
  
  void _drawPianoLayout(Canvas canvas, Size size) {
    // Draw piano key outlines along the bottom
    final int numKeys = 36; // 3 octaves
    final keyWidth = size.width / numKeys;
    
    // White key paint
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Black key paint
    final blackPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // Draw white keys background
    for (int i = 0; i < numKeys; i++) {
      final isBlackKey = [1, 3, 6, 8, 10].contains(i % 12);
      if (!isBlackKey) {
        canvas.drawRect(
          Rect.fromLTWH(i * keyWidth, size.height - 30, keyWidth, 30),
          whitePaint,
        );
      }
    }
    
    // Draw black keys on top
    for (int i = 0; i < numKeys; i++) {
      final isBlackKey = [1, 3, 6, 8, 10].contains(i % 12);
      if (isBlackKey) {
        canvas.drawRect(
          Rect.fromLTWH(i * keyWidth - (keyWidth * 0.3), size.height - 30, keyWidth * 0.6, 20),
          blackPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant XYPadPainter oldDelegate) {
    return x != oldDelegate.x || 
           y != oldDelegate.y ||
           gridColor != oldDelegate.gridColor ||
           cursorColor != oldDelegate.cursorColor ||
           cursorSize != oldDelegate.cursorSize ||
           noteMode != oldDelegate.noteMode ||
           currentNote != oldDelegate.currentNote;
  }
}