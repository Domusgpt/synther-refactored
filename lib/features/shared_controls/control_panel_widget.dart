import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';
import 'control_knob_widget.dart';
import '../wavetable/wavetable_controls_widget.dart';

/// A widget that displays a control panel for the synthesizer.
class ControlPanelWidget extends StatelessWidget {
  const ControlPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel label
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Control Panel',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            
            // Master controls
            _buildSectionHeader(context, 'Master'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ControlKnob(
                  value: model.masterVolume,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: 'Volume',
                  onChanged: (value) => model.setMasterVolume(value),
                ),
                Switch(
                  value: !model.isMasterMuted,
                  onChanged: (value) => model.setMasterMuted(!value),
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
                Text(
                  model.isMasterMuted ? 'Muted' : 'Unmuted',
                  style: TextStyle(
                    color: model.isMasterMuted 
                        ? Colors.grey 
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filter controls
            _buildSectionHeader(context, 'Filter'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ControlKnob(
                  value: model.filterCutoff,
                  min: 20,
                  max: 20000,
                  divisions: 100,
                  logarithmic: true,
                  label: 'Cutoff',
                  valueFormat: (v) => '${v.toInt()} Hz',
                  onChanged: (value) => model.setFilterCutoff(value),
                ),
                ControlKnob(
                  value: model.filterResonance,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: 'Resonance',
                  valueFormat: (v) => (v * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) => model.setFilterResonance(value),
                ),
                // Filter type selector
                Column(
                  children: [
                    const Text('Type'),
                    const SizedBox(height: 8),
                    DropdownButton<FilterType>(
                      value: model.filterType,
                      onChanged: (FilterType? newValue) {
                        if (newValue != null) {
                          model.setFilterType(newValue);
                        }
                      },
                      items: FilterType.values.map<DropdownMenuItem<FilterType>>((FilterType value) {
                        return DropdownMenuItem<FilterType>(
                          value: value,
                          child: Text(_getFilterTypeName(value)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Envelope controls
            _buildSectionHeader(context, 'Envelope'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ControlKnob(
                  value: model.attackTime,
                  min: 0.001,
                  max: 5,
                  divisions: 100,
                  logarithmic: true,
                  label: 'Attack',
                  valueFormat: (v) => _formatTime(v),
                  onChanged: (value) => model.setAttackTime(value),
                ),
                ControlKnob(
                  value: model.decayTime,
                  min: 0.001,
                  max: 5,
                  divisions: 100,
                  logarithmic: true,
                  label: 'Decay',
                  valueFormat: (v) => _formatTime(v),
                  onChanged: (value) => model.setDecayTime(value),
                ),
                ControlKnob(
                  value: model.sustainLevel,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: 'Sustain',
                  valueFormat: (v) => (v * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) => model.setSustainLevel(value),
                ),
                ControlKnob(
                  value: model.releaseTime,
                  min: 0.001,
                  max: 10,
                  divisions: 100,
                  logarithmic: true,
                  label: 'Release',
                  valueFormat: (v) => _formatTime(v),
                  onChanged: (value) => model.setReleaseTime(value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Effects controls
            _buildSectionHeader(context, 'Effects'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ControlKnob(
                  value: model.reverbMix,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: 'Reverb',
                  valueFormat: (v) => (v * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) => model.setReverbMix(value),
                ),
                ControlKnob(
                  value: model.delayTime,
                  min: 0.01,
                  max: 2,
                  divisions: 100,
                  logarithmic: true,
                  label: 'Delay Time',
                  valueFormat: (v) => _formatTime(v),
                  onChanged: (value) => model.setDelayTime(value),
                ),
                ControlKnob(
                  value: model.delayFeedback,
                  min: 0,
                  max: 0.95,
                  divisions: 100,
                  label: 'Feedback',
                  valueFormat: (v) => (v * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) => model.setDelayFeedback(value),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Oscillator controls including wavetable
            _buildSectionHeader(context, 'Oscillators'),
            _buildOscillatorControls(context, model),
          ],
        );
      },
    );
  }
  
  Widget _buildOscillatorControls(BuildContext context, SynthParametersModel model) {
    return Column(
      children: [
        for (int i = 0; i < model.oscillators.length; i++)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Oscillator type selector
                  Column(
                    children: [
                      Text('Osc ${i + 1} Type'),
                      const SizedBox(height: 8),
                      DropdownButton<OscillatorType>(
                        value: model.oscillators[i].type,
                        onChanged: (OscillatorType? newValue) {
                          if (newValue != null) {
                            model.updateOscillator(
                              i,
                              model.oscillators[i].copyWith(type: newValue),
                            );
                          }
                        },
                        items: OscillatorType.values.map<DropdownMenuItem<OscillatorType>>((OscillatorType value) {
                          return DropdownMenuItem<OscillatorType>(
                            value: value,
                            child: Text(_getOscillatorTypeName(value)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  ControlKnob(
                    value: model.oscillators[i].volume,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    label: 'Volume',
                    valueFormat: (v) => (v * 100).toStringAsFixed(0) + '%',
                    onChanged: (value) {
                      model.updateOscillator(
                        i,
                        model.oscillators[i].copyWith(volume: value),
                      );
                    },
                  ),
                  ControlKnob(
                    value: model.oscillators[i].detune,
                    min: -100,
                    max: 100,
                    divisions: 200,
                    label: 'Detune',
                    valueFormat: (v) => '${v.toStringAsFixed(0)} cents',
                    onChanged: (value) {
                      model.updateOscillator(
                        i,
                        model.oscillators[i].copyWith(detune: value),
                      );
                    },
                  ),
                ],
              ),
              // Show wavetable controls if this oscillator is in wavetable mode
              if (model.oscillators[i].type == OscillatorType.wavetable)
                WavetableControlsWidget(oscillatorIndex: i),
              const SizedBox(height: 16),
            ],
          ),
      ],
    );
  }
  
  String _getOscillatorTypeName(OscillatorType type) {
    switch (type) {
      case OscillatorType.sine:
        return 'Sine';
      case OscillatorType.square:
        return 'Square';
      case OscillatorType.triangle:
        return 'Triangle';
      case OscillatorType.sawtooth:
        return 'Sawtooth';
      case OscillatorType.noise:
        return 'Noise';
      case OscillatorType.pulse:
        return 'Pulse';
      case OscillatorType.wavetable:
        return 'Wavetable';
      default:
        return 'Unknown';
    }
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(double seconds) {
    if (seconds < 0.01) {
      return '${(seconds * 1000).toStringAsFixed(1)}ms';
    } else if (seconds < 1) {
      return '${(seconds * 1000).toStringAsFixed(0)}ms';
    } else {
      return '${seconds.toStringAsFixed(1)}s';
    }
  }
  
  String _getFilterTypeName(FilterType type) {
    switch (type) {
      case FilterType.lowPass:
        return 'Low Pass';
      case FilterType.highPass:
        return 'High Pass';
      case FilterType.bandPass:
        return 'Band Pass';
      case FilterType.notch:
        return 'Notch';
      case FilterType.lowShelf:
        return 'Low Shelf';
      case FilterType.highShelf:
        return 'High Shelf';
      default:
        return 'Unknown';
    }
  }
}