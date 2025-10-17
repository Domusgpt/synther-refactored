import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/tempo_transport.dart';

class TempoTransportPanel extends StatefulWidget {
  const TempoTransportPanel({super.key});

  @override
  State<TempoTransportPanel> createState() => _TempoTransportPanelState();
}

class _TempoTransportPanelState extends State<TempoTransportPanel> {
  double? _draggingTempo;

  static const List<double> _quickTempos = <double>[
    90,
    100,
    110,
    120,
    128,
    140,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.75,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                const Color(0xFF090B1F).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0xAA00FFFF),
                blurRadius: 24,
                spreadRadius: -12,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (BuildContext context, AudioEngine engine, _) {
              final double tempo = (_draggingTempo ?? engine.transportTempo)
                  .clamp(20, 240);
              final bool running = engine.transportRunning;
              final int numerator = engine.transportTimeSignatureNumerator;
              final int denominator = engine.transportTimeSignatureDenominator;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Tempo & Transport',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sync BPM, playback, and time signature across the engine, presets, and visualiser.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close tempo transport panel',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111327).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              '${tempo.toStringAsFixed(1)} BPM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonal(
                              onPressed: () => _resetTransport(engine),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                              ),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 20,
                            ),
                            inactiveTrackColor: Colors.white24,
                          ),
                          child: Slider(
                            min: 20,
                            max: 240,
                            divisions: 220,
                            value: tempo,
                            label: '${tempo.toStringAsFixed(1)} BPM',
                            onChanged: (double value) {
                              setState(() => _draggingTempo = value);
                              engine.setTransportTempo(value);
                            },
                            onChangeEnd: (_) =>
                                setState(() => _draggingTempo = null),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickTempos
                              .map(
                                (double value) => ChoiceChip(
                                  label: Text('${value.toStringAsFixed(0)} BPM'),
                                  selected: (tempo - value).abs() < 0.5,
                                  onSelected: (_) {
                                    setState(() => _draggingTempo = null);
                                    engine.setTransportTempo(value);
                                  },
                                  labelStyle: const TextStyle(color: Colors.white),
                                  backgroundColor:
                                      const Color(0xFF1A1D3A).withOpacity(0.85),
                                  selectedColor:
                                      colorScheme.primary.withOpacity(0.35),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: (tempo - value).abs() < 0.5
                                          ? colorScheme.primary
                                          : Colors.white24,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141731).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SwitchListTile.adaptive(
                          value: running,
                          onChanged: (bool value) => engine.setTransportRunning(
                            value ? 1.0 : 0.0,
                          ),
                          activeColor: colorScheme.primary,
                          title: const Text(
                            'Transport running',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            running
                                ? 'Arpeggiators and sync-aware modulators advance in time.'
                                : 'Playback is paused – sync features will hold at the current beat.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Time signature',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: colorScheme.secondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _TimeSignatureDropdown(
                                label: 'Beats per bar',
                                value: numerator,
                                values: List<int>.generate(12, (int index) => index + 1),
                                onChanged: (int value) =>
                                    engine.setTransportTimeSignatureNumerator(
                                  value.toDouble(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeSignatureDropdown(
                                label: 'Beat unit',
                                value: denominator,
                                values: List<int>.generate(16, (int index) => index + 1),
                                onChanged: (int value) =>
                                    engine.setTransportTimeSignatureDenominator(
                                  value.toDouble(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.timelapse, color: Colors.white60),
                            const SizedBox(width: 8),
                            Text(
                              'Position: ${engine.transportPositionBeats.toStringAsFixed(2)} beats',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetTransport(AudioEngine engine) {
    _draggingTempo = null;
    engine.applyTempoTransport(const TempoTransportSettings());
  }
}

class _TimeSignatureDropdown extends StatelessWidget {
  const _TimeSignatureDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: values.contains(value) ? value : values.first,
      items: values
          .map(
            (int option) => DropdownMenuItem<int>(
              value: option,
              child: Text(option.toString()),
            ),
          )
          .toList(),
      onChanged: (int? option) {
        if (option != null) {
          onChanged(option);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1D3A).withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dropdownColor: const Color(0xFF1A1D3A),
      style: const TextStyle(color: Colors.white),
    );
  }
}
