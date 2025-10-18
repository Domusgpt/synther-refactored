import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/step_sequencer.dart';

class StepSequencerPanel extends StatefulWidget {
  const StepSequencerPanel({super.key});

  @override
  State<StepSequencerPanel> createState() => _StepSequencerPanelState();
}

class _StepSequencerPanelState extends State<StepSequencerPanel> {
  late StepSequencerPattern _workingPattern;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = Provider.of<AudioEngine>(context);
    _workingPattern = engine.stepSequencer.pattern;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0B0F2D).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA00FFFF),
                blurRadius: 28,
                spreadRadius: -14,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (context, engine, _) {
              _maybeSyncFromEngine(engine);
              final pattern = _workingPattern;
              final steps = pattern.steps;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Step Sequencer',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Program holographic patterns, tweak ties, accents and velocity, then let the transport drive playback.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close step sequencer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _PatternMetadataToolbar(
                    pattern: pattern,
                    onChanged: (updated) => _replacePattern(updated, resetPosition: true),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: steps.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : _buildStepGrid(context, steps),
                  ),
                  const SizedBox(height: 16),
                  _buildFooterActions(engine),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _maybeSyncFromEngine(AudioEngine engine) {
    final latest = engine.stepSequencer.pattern;
    if (!_patternsMatch(latest, _workingPattern)) {
      _workingPattern = latest;
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_4x4, color: colorScheme.primary.withOpacity(0.7), size: 40),
          const SizedBox(height: 16),
          const Text(
            'No steps configured yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the add controls below to craft a new pattern.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepGrid(BuildContext context, List<StepSequencerStep> steps) {
    final columns = math.min(16, steps.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: tileWidth / (tileWidth + 22),
          ),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];
            return _StepTile(
              index: index,
              step: step,
              onTap: () => _editStep(index, step),
              onToggleRest: () {
                final nextRest = !step.rest;
                _updateStep(
                  index,
                  step.copyWith(
                    rest: nextRest,
                    tie: nextRest ? false : step.tie,
                  ),
                );
              },
              onToggleTie: () {
                final nextTie = !step.tie;
                _updateStep(
                  index,
                  step.copyWith(
                    tie: nextTie,
                    rest: nextTie ? false : step.rest,
                  ),
                );
              },
              onToggleAccent: () => _updateStep(index, step.copyWith(accent: !step.accent)),
            );
          },
        );
      },
    );
  }

  Widget _buildFooterActions(AudioEngine engine) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_box_outlined),
          label: const Text('ADD STEP'),
          onPressed: () {
            final updated = _workingPattern.copyWith(
              steps: List<StepSequencerStep>.from(_workingPattern.steps)
                ..add(const StepSequencerStep(rest: true)),
            );
            _replacePattern(updated, resetPosition: false);
          },
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('DUPLICATE PATTERN'),
          onPressed: () {
            final duplicatedSteps = List<StepSequencerStep>.from(_workingPattern.steps)
              ..addAll(_workingPattern.steps);
            final updated = _workingPattern.copyWith(steps: duplicatedSteps);
            _replacePattern(updated, resetPosition: false);
          },
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('CLEAR ALL'),
          onPressed: () {
            final cleared = StepSequencerPattern.empty(
              length: _workingPattern.length,
              stepsPerBeat: _workingPattern.stepsPerBeat,
              loop: _workingPattern.loop,
            );
            _replacePattern(cleared, resetPosition: true);
          },
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            engine.updateStepSequencerPattern(_workingPattern, resetPosition: true);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('APPLY & CLOSE'),
        ),
      ],
    );
  }

  Future<void> _editStep(int index, StepSequencerStep step) async {
    final edited = await showModalBottomSheet<StepSequencerStep>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StepEditorSheet(initialStep: step, index: index);
      },
    );

    if (edited != null) {
      _updateStep(index, edited);
    }
  }

  void _updateStep(int index, StepSequencerStep step) {
    final updatedSteps = List<StepSequencerStep>.from(_workingPattern.steps);
    updatedSteps[index] = step;
    final updatedPattern = _workingPattern.copyWith(steps: updatedSteps);
    _replacePattern(updatedPattern, resetPosition: false);
  }

  void _replacePattern(StepSequencerPattern pattern, {required bool resetPosition}) {
    setState(() => _workingPattern = pattern);
    context.read<AudioEngine>().updateStepSequencerPattern(pattern, resetPosition: resetPosition);
  }

  bool _patternsMatch(StepSequencerPattern a, StepSequencerPattern b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.stepsPerBeat != b.stepsPerBeat || a.loop != b.loop || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.steps.length; i++) {
      final left = a.steps[i];
      final right = b.steps[i];
      if (left.note != right.note ||
          left.velocity != right.velocity ||
          left.gate != right.gate ||
          left.tie != right.tie ||
          left.rest != right.rest ||
          left.accent != right.accent) {
        return false;
      }
    }
    return true;
  }
}

class _PatternMetadataToolbar extends StatelessWidget {
  const _PatternMetadataToolbar({
    required this.pattern,
    required this.onChanged,
  });

  final StepSequencerPattern pattern;
  final ValueChanged<StepSequencerPattern> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Steps per beat',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Slider(
                value: pattern.stepsPerBeat.toDouble(),
                divisions: 15,
                min: 1,
                max: 16,
                label: '${pattern.stepsPerBeat}',
                onChanged: (value) {
                  onChanged(
                    pattern.copyWith(stepsPerBeat: value.round()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loop playback',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Switch(
                value: pattern.loop,
                onChanged: (value) => onChanged(pattern.copyWith(loop: value)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pattern length',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              DropdownButton<int>(
                value: pattern.length,
                dropdownColor: const Color(0xFF0B0F2D),
                items: (<int>{8, 12, 16, 24, 32, pattern.length}.toList()
                      ..sort())
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value steps'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == pattern.length) {
                    return;
                  }
                  final current = pattern.steps;
                  final updatedSteps = List<StepSequencerStep>.generate(value, (index) {
                    if (index < current.length) {
                      return current[index];
                    }
                    return const StepSequencerStep(rest: true);
                  });
                  onChanged(pattern.copyWith(steps: updatedSteps));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.onTap,
    required this.onToggleRest,
    required this.onToggleTie,
    required this.onToggleAccent,
  });

  final int index;
  final StepSequencerStep step;
  final VoidCallback onTap;
  final VoidCallback onToggleRest;
  final VoidCallback onToggleTie;
  final VoidCallback onToggleAccent;

  @override
  Widget build(BuildContext context) {
    final displayNote = _formatNote(step);
    final color = step.rest
        ? Colors.white24
        : step.accent
            ? const Color(0xFFFF66FF)
            : const Color(0xFF00FFFF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.7), width: 1.2),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(step.rest ? 0.05 : 0.2),
              color.withOpacity(step.rest ? 0.03 : 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${index + 1}'.padLeft(3),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: step.rest ? 'Mark step as active note' : 'Mark step as rest',
                  onPressed: onToggleRest,
                  icon: Icon(step.rest ? Icons.music_off : Icons.music_note,
                      size: 16, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 22, height: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              displayNote,
              style: TextStyle(
                color: step.rest ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: step.velocity,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFFFFD700),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: step.tie ? 'Release at step start' : 'Tie from previous step',
                  onPressed: onToggleTie,
                  icon: Icon(
                    step.tie ? Icons.link : Icons.link_off,
                    size: 16,
                    color: step.tie ? const Color(0xFF80FFEA) : Colors.white54,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 22, height: 22),
                ),
                IconButton(
                  tooltip: step.accent ? 'Remove accent' : 'Accent this step',
                  onPressed: onToggleAccent,
                  icon: Icon(
                    Icons.bolt,
                    size: 16,
                    color: step.accent ? const Color(0xFFFF66FF) : Colors.white54,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 22, height: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNote(StepSequencerStep step) {
    if (step.rest) {
      return 'REST';
    }
    if (step.tie && step.note == null) {
      return 'TIE';
    }
    if (step.note == null) {
      return '—';
    }
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final note = step.note!.clamp(0, 127);
    final octave = (note ~/ 12) - 1;
    final label = names[note % 12];
    return '$label$octave';
  }
}

class _StepEditorSheet extends StatefulWidget {
  const _StepEditorSheet({
    required this.initialStep,
    required this.index,
  });

  final StepSequencerStep initialStep;
  final int index;

  @override
  State<_StepEditorSheet> createState() => _StepEditorSheetState();
}

class _StepEditorSheetState extends State<_StepEditorSheet> {
  late int? _note;
  late double _velocity;
  late double _gate;
  late bool _rest;
  late bool _tie;
  late bool _accent;

  @override
  void initState() {
    super.initState();
    final step = widget.initialStep;
    _note = step.note;
    _velocity = step.velocity;
    _gate = step.gate;
    _rest = step.rest;
    _tie = step.tie;
    _accent = step.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Color(0xFF040511), Color(0xFF080B1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Edit Step ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildNoteSelector()),
                const SizedBox(width: 16),
                Expanded(child: _buildVelocitySlider()),
              ],
            ),
            const SizedBox(height: 16),
            _buildGateSlider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  selected: _rest,
                  onSelected: (value) => setState(() {
                    _rest = value;
                    if (_rest) {
                      _tie = false;
                    }
                  }),
                  label: const Text('Rest'),
                ),
                FilterChip(
                  selected: _tie,
                  onSelected: (value) => setState(() {
                    _tie = value;
                    if (_tie) {
                      _rest = false;
                    }
                  }),
                  label: const Text('Tie'),
                ),
                FilterChip(
                  selected: _accent,
                  onSelected: (value) => setState(() => _accent = value),
                  label: const Text('Accent'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(
                    StepSequencerStep(
                      note: _rest ? null : _note,
                      velocity: _velocity,
                      gate: _gate,
                      rest: _rest,
                      tie: _tie,
                      accent: _accent,
                    ),
                  );
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Save Step'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: _note,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0x3300FFFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Inherit previous note')),
            ...List<DropdownMenuItem<int>>.generate(88, (index) {
              final midi = index + 21;
              return DropdownMenuItem<int>(
                value: midi,
                child: Text(_describeMidi(midi)),
              );
            }),
          ],
          onChanged: (value) => setState(() => _note = value),
        ),
      ],
    );
  }

  Widget _buildVelocitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Velocity', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Slider(
          value: _velocity,
          min: 0,
          max: 1,
          divisions: 100,
          label: (_velocity * 127).round().toString(),
          onChanged: (value) => setState(() => _velocity = value),
        ),
      ],
    );
  }

  Widget _buildGateSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gate proportion', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Slider(
          value: _gate,
          min: 0.1,
          max: 2.0,
          divisions: 38,
          label: _gate.toStringAsFixed(2),
          onChanged: (value) => setState(() => _gate = value),
        ),
      ],
    );
  }

  static String _describeMidi(int midi) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = names[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$noteName$octave ($midi)';
  }
}
