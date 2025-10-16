import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/parameter_models.dart';
import '../core/parameter_registry.dart';
import '../visualizer/hypercube_visualizer.dart';

/// Multi-panel holographic dashboard inspired by the VIB34D redesign.
///
/// The interface focuses on three pillars:
///  * expressive tone shaping controls with contextual feedback
///  * a rich metrics column that surfaces real-time performance data
///  * a dedicated canvas viewport that streams the 4D visualiser output
class VaporwaveInterface extends StatefulWidget {
  const VaporwaveInterface({super.key});

  @override
  State<VaporwaveInterface> createState() => _VaporwaveInterfaceState();
}

class _VaporwaveInterfaceState extends State<VaporwaveInterface> {
  final ParameterRegistry _registry = ParameterRegistry.instance;
  Offset _xyNormalized = const Offset(0.6, 0.35);
  bool _xyInteracting = false;

  void _syncXyFromEngine(AudioEngine engine) {
    if (_xyInteracting) return;

    final cutoffRange = _registry.descriptorFor('filterCutoff')?.range;
    final resonanceRange = _registry.descriptorFor('filterResonance')?.range;
    if (cutoffRange == null || resonanceRange == null) {
      return;
    }

    final x = cutoffRange.normalize(engine.filterCutoff).clamp(0.0, 1.0);
    final y = 1 - resonanceRange.normalize(engine.filterResonance).clamp(0.0, 1.0);
    _xyNormalized = Offset(x, y);
  }

  void _handleXyInput(AudioEngine engine, Offset position, Size size) {
    final cutoffRange = _registry.descriptorFor('filterCutoff')?.range;
    final resonanceRange = _registry.descriptorFor('filterResonance')?.range;
    if (cutoffRange == null || resonanceRange == null) {
      return;
    }

    final normalizedX = (position.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (position.dy / size.height).clamp(0.0, 1.0);

    final newCutoff = cutoffRange.denormalize(normalizedX);
    final newResonance = resonanceRange.denormalize(1 - normalizedY);

    setState(() {
      _xyNormalized = Offset(normalizedX, normalizedY);
    });

    unawaited(engine.setFilterCutoff(newCutoff));
    unawaited(engine.setFilterResonance(newResonance));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioEngine>(
      builder: (context, audioEngine, _) {
        final visualizerData = audioEngine.getVisualizerData();
        _syncXyFromEngine(audioEngine);

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF050214),
                Color(0xFF12092B),
                Color(0xFF04010E),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 900;
                final statusBar = _buildStatusBar(audioEngine, visualizerData);
                final controlPanel = _buildControlPanel(audioEngine);
                final metricsPanel = _buildMetricsPanel(audioEngine, visualizerData);
                final visualizerPanel =
                    _buildVisualizerPanel(audioEngine, visualizerData, isNarrow);

                if (isNarrow) {
                  return Column(
                    children: [
                      statusBar,
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            children: [
                              visualizerPanel,
                              controlPanel,
                              metricsPanel,
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    statusBar,
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 340,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: controlPanel,
                            ),
                          ),
                          Expanded(child: visualizerPanel),
                          SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: metricsPanel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(AudioEngine engine, Map<String, double> data) {
    final activeVoices = data['activeVoices'] ?? 0;
    final maxVoices = (data['maxPolyphony'] ?? 1).clamp(1, 128);
    final sustainActive = (data['sustainActive'] ?? 0) >= 0.5;
    final modulationEnergy = (data['modulationEnergy'] ?? 0).clamp(0.0, 1.0);
    final performanceEnergy = (data['performanceEnergy'] ?? 0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _glassDecoration(const Color(0xFF00FFFF)),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusChip(
            label: 'ENGINE',
            value: engine.isInitialized ? 'ONLINE' : 'INITIALIZING',
            accent: engine.isInitialized
                ? const Color(0xFF54FFF4)
                : const Color(0xFFFFC861),
          ),
          _StatusChip(
            label: 'VOICES',
            value: '${activeVoices.round()} / ${maxVoices.round()}',
            accent: const Color(0xFF6C63FF),
          ),
          _StatusChip(
            label: 'PERFORMANCE',
            value: '${(performanceEnergy * 100).round()} %',
            accent: const Color(0xFFFF4FD8),
          ),
          _StatusChip(
            label: 'MOD MATRIX',
            value: '${(modulationEnergy * 100).round()} %',
            accent: const Color(0xFF2DE6FF),
          ),
          _StatusChip(
            label: 'SUSTAIN',
            value: sustainActive ? 'HELD' : 'IDLE',
            accent:
                sustainActive ? const Color(0xFF32FF84) : const Color(0xFF7A7A7A),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(AudioEngine engine) {
    final groups = <_ParameterGroup>[
      _ParameterGroup(
        title: 'Core Spectrum',
        icon: Icons.auto_awesome,
        parameters: [
          _ParameterSpec(
            parameterName: 'filterCutoff',
            label: 'Filter Cutoff',
            unit: ' Hz',
            precision: 0,
            valueGetter: (e) => e.filterCutoff,
            setter: (e, v) => unawaited(e.setFilterCutoff(v)),
          ),
          _ParameterSpec(
            parameterName: 'filterResonance',
            label: 'Filter Resonance',
            precision: 2,
            valueGetter: (e) => e.filterResonance,
            setter: (e, v) => unawaited(e.setFilterResonance(v)),
          ),
          _ParameterSpec(
            parameterName: 'oscillatorBlend',
            label: 'Oscillator Blend',
            precision: 2,
            valueGetter: (e) => e.oscillatorBlend,
            setter: (e, v) => unawaited(e.setOscillatorBlend(v)),
          ),
          _ParameterSpec(
            parameterName: 'oscillatorSpread',
            label: 'Unison Spread',
            precision: 2,
            valueGetter: (e) => e.oscillatorSpread,
            setter: (e, v) => unawaited(e.setOscillatorSpread(v)),
          ),
          _ParameterSpec(
            parameterName: 'oscillatorDetune',
            label: 'Detune',
            precision: 2,
            unit: ' st',
            valueGetter: (e) => e.oscillatorDetune,
            setter: (e, v) => unawaited(e.setOscillatorDetune(v)),
          ),
        ],
      ),
      _ParameterGroup(
        title: 'Envelope Sculpting',
        icon: Icons.timeline,
        parameters: [
          _ParameterSpec(
            parameterName: 'attackTime',
            label: 'Attack',
            precision: 2,
            unit: ' s',
            valueGetter: (e) => e.attackTime,
            setter: (e, v) => unawaited(e.setAttackTime(v)),
          ),
          _ParameterSpec(
            parameterName: 'decayTime',
            label: 'Decay',
            precision: 2,
            unit: ' s',
            valueGetter: (e) => e.decayTime,
            setter: (e, v) => unawaited(e.setDecayTime(v)),
          ),
          _ParameterSpec(
            parameterName: 'sustainLevel',
            label: 'Sustain',
            precision: 2,
            valueGetter: (e) => e.sustainLevel,
            setter: (e, v) => unawaited(e.setSustainLevel(v)),
          ),
          _ParameterSpec(
            parameterName: 'releaseTime',
            label: 'Release',
            precision: 2,
            unit: ' s',
            valueGetter: (e) => e.releaseTime,
            setter: (e, v) => unawaited(e.setReleaseTime(v)),
          ),
        ],
      ),
      _ParameterGroup(
        title: 'Motion & Modulation',
        icon: Icons.sync_alt,
        parameters: [
          _ParameterSpec(
            parameterName: 'lfoRate',
            label: 'LFO Rate',
            precision: 2,
            unit: ' Hz',
            valueGetter: (e) => e.lfoRate,
            setter: (e, v) => unawaited(e.setLfoRate(v)),
          ),
          _ParameterSpec(
            parameterName: 'lfoDepth',
            label: 'LFO Depth',
            precision: 2,
            valueGetter: (e) => e.lfoDepth,
            setter: (e, v) => unawaited(e.setLfoDepth(v)),
          ),
          _ParameterSpec(
            parameterName: 'glideTime',
            label: 'Glide Time',
            precision: 2,
            unit: ' s',
            valueGetter: (e) => e.glideTime,
            setter: (e, v) => unawaited(e.setGlideTime(v)),
          ),
          _ParameterSpec(
            parameterName: 'pitchBendRange',
            label: 'Pitch Bend Range',
            precision: 1,
            unit: ' st',
            valueGetter: (e) => e.pitchBendRange,
            setter: (e, v) => unawaited(e.setPitchBendRange(v)),
          ),
        ],
      ),
      _ParameterGroup(
        title: 'Spatial FX',
        icon: Icons.surround_sound,
        parameters: [
          _ParameterSpec(
            parameterName: 'reverbMix',
            label: 'Reverb Mix',
            precision: 2,
            valueGetter: (e) => e.reverbMix,
            setter: (e, v) => unawaited(e.setReverbMix(v)),
          ),
          _ParameterSpec(
            parameterName: 'delayTime',
            label: 'Delay Time',
            precision: 2,
            unit: ' s',
            valueGetter: (e) => e.delayTime,
            setter: (e, v) => unawaited(e.setDelayTime(v)),
          ),
          _ParameterSpec(
            parameterName: 'delayFeedback',
            label: 'Delay Feedback',
            precision: 2,
            valueGetter: (e) => e.delayFeedback,
            setter: (e, v) => unawaited(e.setDelayFeedback(v)),
          ),
          _ParameterSpec(
            parameterName: 'chorusRate',
            label: 'Chorus Rate',
            precision: 2,
            unit: ' Hz',
            valueGetter: (e) => e.chorusRate,
            setter: (e, v) => unawaited(e.setChorusRate(v)),
          ),
          _ParameterSpec(
            parameterName: 'chorusDepth',
            label: 'Chorus Depth',
            precision: 2,
            valueGetter: (e) => e.chorusDepth,
            setter: (e, v) => unawaited(e.setChorusDepth(v)),
          ),
          _ParameterSpec(
            parameterName: 'distortionDrive',
            label: 'Drive',
            precision: 2,
            valueGetter: (e) => e.distortionDrive,
            setter: (e, v) => unawaited(e.setDistortionDrive(v)),
          ),
        ],
      ),
      _ParameterGroup(
        title: 'Performance Layer',
        icon: Icons.piano,
        parameters: [
          _ParameterSpec(
            parameterName: 'masterVolume',
            label: 'Master Volume',
            precision: 2,
            valueGetter: (e) => e.masterVolume,
            setter: (e, v) => unawaited(e.setMasterVolume(v)),
          ),
          _ParameterSpec(
            parameterName: 'modWheel',
            label: 'Mod Wheel',
            precision: 2,
            valueGetter: (e) => e.modWheel,
            setter: (e, v) => unawaited(e.setModWheel(v)),
          ),
          _ParameterSpec(
            parameterName: 'expression',
            label: 'Expression',
            precision: 2,
            valueGetter: (e) => e.expression,
            setter: (e, v) => unawaited(e.setExpression(v)),
          ),
          _ParameterSpec(
            parameterName: 'sustainPedal',
            label: 'Sustain Pedal',
            precision: 2,
            valueGetter: (e) => e.sustainPedal,
            setter: (e, v) => unawaited(e.setSustainPedal(v)),
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildXyPad(engine),
        for (final group in groups) _buildParameterCard(group, engine),
      ],
    );
  }

  Widget _buildParameterCard(_ParameterGroup group, AudioEngine engine) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _glassDecoration(const Color(0xFF2DE6FF)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          iconColor: const Color(0xFF54FFF4),
          collapsedIconColor: const Color(0xFF54FFF4),
          title: Row(
            children: [
              Icon(group.icon, color: const Color(0xFF54FFF4)),
              const SizedBox(width: 12),
              Text(
                group.title.toUpperCase(),
                style: const TextStyle(
                  letterSpacing: 1.4,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: group.parameters
              .map((spec) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildParameterSlider(spec, engine),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildParameterSlider(_ParameterSpec spec, AudioEngine engine) {
    final descriptor = _registry.descriptorFor(spec.parameterName);
    if (descriptor == null) {
      return const SizedBox.shrink();
    }

    final ParameterRange range = descriptor.range;
    final double rawValue = spec.valueGetter(engine);
    final double value = rawValue.clamp(range.min, range.max);
    final double defaultValue = range.defaultValue;
    final bool modified = (value - defaultValue).abs() >
        ((range.max - range.min).abs() * 0.002 + 0.0001);

    final int divisions = spec.step != null
        ? ((range.max - range.min) / spec.step!)
            .round()
            .clamp(1, 1000)
        : 0;

    final String formattedValue = spec.precision <= 0
        ? value.round().toString()
        : value.toStringAsFixed(spec.precision);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              modified
                  ? '● ${spec.label.toUpperCase()}'
                  : spec.label.toUpperCase(),
              style: TextStyle(
                color: modified
                    ? const Color(0xFF54FFF4)
                    : Colors.white.withOpacity(0.72),
                fontWeight: modified ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            Text(
              '${formattedValue}${spec.unit}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF54FFF4),
            inactiveTrackColor: const Color(0xFF54FFF4).withOpacity(0.2),
            thumbColor: const Color(0xFF54FFF4),
            overlayColor: const Color(0xFF54FFF4).withOpacity(0.12),
          ),
          child: Slider(
            value: value,
            min: range.min,
            max: range.max,
            divisions: spec.step != null ? divisions : null,
            onChanged: (newValue) {
              spec.setter(engine, newValue);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildXyPad(AudioEngine engine) {
    final cutoff = engine.filterCutoff.round();
    final resonance = engine.filterResonance;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(const Color(0xFFFF4FD8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.track_changes, color: Color(0xFFFF4FD8)),
                  SizedBox(width: 12),
                  Text(
                    'FILTER MORPH PAD',
                    style: TextStyle(
                      letterSpacing: 1.4,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CUTOFF  $cutoff Hz',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'RESONANCE  ${resonance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                final indicator = Offset(
                  _xyNormalized.dx * size.width,
                  _xyNormalized.dy * size.height,
                );

                return GestureDetector(
                  onPanStart: (details) {
                    _xyInteracting = true;
                    _handleXyInput(engine, details.localPosition, size);
                  },
                  onPanUpdate: (details) {
                    _handleXyInput(engine, details.localPosition, size);
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _xyInteracting = false;
                    });
                  },
                  onTapDown: (details) {
                    _xyInteracting = true;
                    _handleXyInput(engine, details.localPosition, size);
                  },
                  onTapUp: (_) {
                    setState(() {
                      _xyInteracting = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x3300FFFF),
                          Color(0x3300FFA9),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF4FD8).withOpacity(0.3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: size,
                          painter: _CrosshairPainter(
                            position: indicator,
                            color: const Color(0xFFFF4FD8),
                          ),
                        ),
                        Positioned(
                          left: indicator.dx - 14,
                          top: indicator.dy - 14,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4FD8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF4FD8).withOpacity(0.4),
                                  blurRadius: 18,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.black.withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerPanel(
    AudioEngine engine,
    Map<String, double> data,
    bool isNarrow,
  ) {
    final masterVolume = engine.masterVolume;
    final lfoRate = engine.lfoRate;
    final granularMotion = (data['granularMotion'] ?? 0).clamp(0.0, 1.0);

    return Container(
      height: isNarrow ? 320 : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _glassDecoration(const Color(0xFF6C63FF)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            HypercubeVisualizer(audioEngine: engine),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'VIB34D VISUAL CORE',
                              style: TextStyle(
                                fontSize: 16,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '4D HYpercube PROJECTION',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.6,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _VisualizerBadge(
                              label: 'MASTER',
                              value: '${(masterVolume * 100).round()} %',
                            ),
                            const SizedBox(height: 8),
                            _VisualizerBadge(
                              label: 'LFO',
                              value: '${lfoRate.toStringAsFixed(2)} Hz',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _VisualizerBadge(
                        label: 'GRANULAR MOTION',
                        value: '${(granularMotion * 100).round()} %',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(AudioEngine engine, Map<String, double> data) {
    final activeVoices = data['activeVoices'] ?? 0;
    final maxVoices = (data['maxPolyphony'] ?? 1).clamp(1, 128);
    final performanceEnergy = (data['performanceEnergy'] ?? 0).clamp(0.0, 1.0);
    final modulationEnergy = (data['modulationEnergy'] ?? 0).clamp(0.0, 1.0);
    final granularMotion = (data['granularMotion'] ?? 0).clamp(0.0, 1.0);
    final sustainActive = (data['sustainActive'] ?? 0).clamp(0.0, 1.0);
    final filterCutoff = engine.filterCutoff;
    final cutoffRange = _registry.descriptorFor('filterCutoff')?.range;
    final normalizedCutoff = cutoffRange?.normalize(filterCutoff) ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _glassDecoration(const Color(0xFF9C6CFF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'LIVE SYSTEM METRICS',
              style: TextStyle(
                letterSpacing: 1.6,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildMetricTile(
            label: 'SOUNDSTAGE',
            headline: '${activeVoices.round()} VOICES',
            progress: (activeVoices / maxVoices).clamp(0.0, 1.0),
            accent: const Color(0xFF54FFF4),
            caption: 'Polyphony ${maxVoices.round()} max',
          ),
          _buildMetricTile(
            label: 'PERFORMANCE ENERGY',
            headline: '${(performanceEnergy * 100).round()} %',
            progress: performanceEnergy,
            accent: const Color(0xFFFF4FD8),
            caption: 'Mod wheel • aftertouch • expression blend',
          ),
          _buildMetricTile(
            label: 'MODULATION NETWORK',
            headline: '${(modulationEnergy * 100).round()} %',
            progress: modulationEnergy,
            accent: const Color(0xFF2DE6FF),
            caption: 'Sum of active modulation routes',
          ),
          _buildMetricTile(
            label: 'FILTER SPECTRUM',
            headline: '${filterCutoff.round()} Hz',
            progress: normalizedCutoff.clamp(0.0, 1.0),
            accent: const Color(0xFF9C6CFF),
            caption: 'Cutoff position relative to full range',
          ),
          _buildMetricTile(
            label: 'GRANULAR MOTION',
            headline: '${(granularMotion * 100).round()} %',
            progress: granularMotion,
            accent: const Color(0xFFFFC861),
            caption: 'Grain movement & variation',
          ),
          _buildMetricTile(
            label: 'SUSTAIN STATE',
            headline: sustainActive >= 0.5 ? 'HELD' : 'RELEASED',
            progress: sustainActive,
            accent: const Color(0xFF32FF84),
            caption: 'Pedal data mirrored in visualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String headline,
    required double progress,
    required Color accent,
    required String caption,
  }) {
    final safeProgress = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                headline,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 6,
              backgroundColor: accent.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration(Color accent) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: accent.withOpacity(0.25), width: 1.2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.04),
          Colors.white.withOpacity(0.01),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _ParameterGroup {
  const _ParameterGroup({
    required this.title,
    required this.icon,
    required this.parameters,
  });

  final String title;
  final IconData icon;
  final List<_ParameterSpec> parameters;
}

class _ParameterSpec {
  const _ParameterSpec({
    required this.parameterName,
    required this.label,
    required this.valueGetter,
    required this.setter,
    this.precision = 2,
    this.unit = '',
    this.step,
  });

  final String parameterName;
  final String label;
  final double Function(AudioEngine) valueGetter;
  final void Function(AudioEngine, double) setter;
  final int precision;
  final String unit;
  final double? step;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.35)),
        color: accent.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizerBadge extends StatelessWidget {
  const _VisualizerBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.4),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.6,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.3,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({required this.position, required this.color});

  final Offset position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(position.dx, 0),
      Offset(position.dx, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, position.dy),
      Offset(size.width, position.dy),
      linePaint,
    );

    final glowPaint = Paint()..color = color.withOpacity(0.08);
    canvas.drawCircle(position, 26, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.color != color;
  }
}
