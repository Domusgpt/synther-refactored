import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio_service.dart';
import '../../core/synth_parameters.dart';

/// A widget that displays a piano keyboard for triggering notes.
class KeyboardWidget extends StatefulWidget {
  const KeyboardWidget({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.startOctave = 4,
    this.numOctaves = 2,
    this.showLabels = true,
  });

  final double width;
  final double height;
  final int startOctave;
  final int numOctaves;
  final bool showLabels;

  @override
  State<KeyboardWidget> createState() => _KeyboardWidgetState();
}

class _KeyboardWidgetState extends State<KeyboardWidget> {
  // Set of currently pressed keys (MIDI note numbers)
  final Set<int> _pressedKeys = {};
  
  // MIDI Note mapping
  final List<String> noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  
  // Synthesizer engine bindings
  final AudioService _audioService = AudioService.instance;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize synth engine
    _initSynthEngine();
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
  void dispose() {
    // Shut down synth engine
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keyboard label
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Keyboard',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        // Keyboard widget
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate key dimensions
              final totalNotes = widget.numOctaves * 12;
              final whiteKeyWidth = constraints.maxWidth / (widget.numOctaves * 7);
              final blackKeyWidth = whiteKeyWidth * 0.6;
              final whiteKeyHeight = constraints.maxHeight;
              final blackKeyHeight = whiteKeyHeight * 0.6;
              
              return Stack(
                children: [
                  // White keys
                  Row(
                    children: List.generate(widget.numOctaves * 7, (index) {
                      final octave = widget.startOctave + (index ~/ 7);
                      final noteIndex = [0, 2, 4, 5, 7, 9, 11][index % 7];
                      final midiNote = octave * 12 + noteIndex;
                      final noteName = noteNames[noteIndex];
                      final isPressed = _pressedKeys.contains(midiNote);
                      
                      return GestureDetector(
                        onTapDown: (_) => _noteOn(midiNote),
                        onTapUp: (_) => _noteOff(midiNote),
                        onTapCancel: () => _noteOff(midiNote),
                        child: Container(
                          width: whiteKeyWidth,
                          height: whiteKeyHeight,
                          decoration: BoxDecoration(
                            color: isPressed ? Colors.grey.shade300 : Colors.white,
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget.showLabels
                              ? Text(
                                  '$noteName$octave',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                  
                  // Black keys
                  Row(
                    children: List.generate(widget.numOctaves * 7, (index) {
                      final octave = widget.startOctave + (index ~/ 7);
                      final noteIndex = [0, 2, 4, 5, 7, 9, 11][index % 7];
                      final hasBlackKeyRight = [0, 2, 5, 7, 9].contains(noteIndex);
                      
                      if (!hasBlackKeyRight) {
                        return SizedBox(width: whiteKeyWidth);
                      }
                      
                      final blackNoteIndex = noteIndex + 1;
                      final blackMidiNote = octave * 12 + blackNoteIndex;
                      final isPressed = _pressedKeys.contains(blackMidiNote);
                      
                      return Stack(
                        children: [
                          SizedBox(width: whiteKeyWidth),
                          Positioned(
                            right: -(blackKeyWidth / 2),
                            child: GestureDetector(
                              onTapDown: (_) => _noteOn(blackMidiNote),
                              onTapUp: (_) => _noteOff(blackMidiNote),
                              onTapCancel: () => _noteOff(blackMidiNote),
                              child: Container(
                                width: blackKeyWidth,
                                height: blackKeyHeight,
                                decoration: BoxDecoration(
                                  color: isPressed ? Colors.grey.shade700 : Colors.black,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                padding: const EdgeInsets.only(bottom: 8),
                                child: widget.showLabels
                                    ? Text(
                                        '${noteNames[blackNoteIndex]}$octave',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _noteOn(int midiNote) {
    setState(() {
      _pressedKeys.add(midiNote);
    });
    
    // Send note-on message via synth parameters model
    final model = context.read<SynthParametersModel>();
    model.noteOn(midiNote, 100); // Default velocity
  }
  
  void _noteOff(int midiNote) {
    setState(() {
      _pressedKeys.remove(midiNote);
    });
    
    // Send note-off message via synth parameters model
    final model = context.read<SynthParametersModel>();
    model.noteOff(midiNote);
  }
}