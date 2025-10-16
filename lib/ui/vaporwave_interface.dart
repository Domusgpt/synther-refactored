import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/parameter_models.dart';
import '../core/parameter_registry.dart';
import '../visualizer/hypercube_visualizer.dart';
import 'modulation_matrix_panel.dart';

/// Holographic multi-panel interface inspired by the VIB34D dashboard.
///
/// The layout keeps the tone controls, performance metrics and visualiser
/// aligned with the synthesiser so the embedded WebGL overlay can mirror the
/// Flutter state.  It intentionally favours small, well-scoped widgets over the
/// previous mega build function which was difficult to maintain.
class VaporwaveInterface extends StatefulWidget {
  const VaporwaveInterface({super.key});

  @override
  State<VaporwaveInterface> createState() => _VaporwaveInterfaceState();
}

class _VaporwaveInterfaceState extends State<VaporwaveInterface> {
  final ParameterRegistry _registry = ParameterRegistry.instance;
  Offset _filterPadNormalized = const Offset(0.6, 0.35);
  bool _padInteracting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AudioEngine>(
        builder: (context, engine, _) {
          final visualizerData = engine.getVisualizerData();
          _syncPadFromEngine(engine);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF030112),
                  Color(0xFF12092B),
                  Color(0xFF02000A),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 1080;
                  final topBar = _TopBar(
                    engine: engine,
                    metrics: visualizerData,
                  );
                  final controlColumn = _buildControlColumn(engine);
                  final visualizerPanel = _VisualizerPanel(engine: engine);
                  final metricsColumn = _MetricsColumn(data: visualizerData);

                  if (isNarrow) {
                    return Column(
                      children: [
                        topBar,
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Column(
                              children: [
                                visualizerPanel,
                                const SizedBox(height: 24),
                                controlColumn,
                                const SizedBox(height: 24),
                                metricsColumn,
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      topBar,
                      const SizedBox(height: 24),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 22,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: controlColumn,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Flexible(flex: 32, child: visualizerPanel),
                              const SizedBox(width: 24),
                              Flexible(
                                flex: 20,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: metricsColumn,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlColumn(AudioEngine engine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VibPanel(
          title: 'Tone Sculpting',
          subtitle: 'Blend oscillators and shape the spectrum',
          child: _ParameterGrid(
            configs: [
              _sliderConfig(
                labelOverride: 'Master',
                parameter: 'masterVolume',
                value: engine.masterVolume,
                onChange: (value) => unawaited(engine.setMasterVolume(value)),
              ),
              _sliderConfig(
                labelOverride: 'Blend',
                parameter: 'oscillatorBlend',
                value: engine.oscillatorBlend,
                onChange: (value) =>
                    unawaited(engine.setOscillatorBlend(value)),
              ),
              _sliderConfig(
                labelOverride: 'Detune',
                parameter: 'oscillatorDetune',
                value: engine.oscillatorDetune,
                formatter: (descriptor, value) =>
                    '${value.toStringAsFixed(1)} st',
                onChange: (value) =>
                    unawaited(engine.setOscillatorDetune(value)),
              ),
              _sliderConfig(
                labelOverride: 'Spread',
                parameter: 'oscillatorSpread',
                value: engine.oscillatorSpread,
                onChange: (value) =>
                    unawaited(engine.setOscillatorSpread(value)),
              ),
              _sliderConfig(
                labelOverride: 'Cutoff',
                parameter: 'filterCutoff',
                value: engine.filterCutoff,
                formatter: _hzFormatter,
                onChange: (value) => unawaited(engine.setFilterCutoff(value)),
              ),
              _sliderConfig(
                labelOverride: 'Resonance',
                parameter: 'filterResonance',
                value: engine.filterResonance,
                formatter: _percentFormatter,
                onChange: (value) =>
                    unawaited(engine.setFilterResonance(value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _VibPanel(
          title: 'Filter Morph Pad',
          subtitle: 'Drag to sweep the cutoff and resonance simultaneously',
          child: SizedBox(
            height: 220,
            child: _FilterPad(
              normalizedPosition: _filterPadNormalized,
              onInteractionStart: () => setState(() => _padInteracting = true),
              onInteractionEnd: () => setState(() => _padInteracting = false),
              onPositionChanged: (normalized) {
                setState(() => _filterPadNormalized = normalized);
                _applyPadToEngine(engine, normalized);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _VibPanel(
          title: 'Envelope & Motion',
          subtitle: 'Dynamics, modulation and temporal effects',
          child: _ParameterGrid(
            configs: [
              _sliderConfig(
                labelOverride: 'Attack',
                parameter: 'attackTime',
                value: engine.attackTime,
                formatter: _secondsFormatter,
                onChange: (value) => unawaited(engine.setAttackTime(value)),
              ),
              _sliderConfig(
                labelOverride: 'Decay',
                parameter: 'decayTime',
                value: engine.decayTime,
                formatter: _secondsFormatter,
                onChange: (value) => unawaited(engine.setDecayTime(value)),
              ),
              _sliderConfig(
                labelOverride: 'Sustain',
                parameter: 'sustainLevel',
                value: engine.sustainLevel,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setSustainLevel(value)),
              ),
              _sliderConfig(
                labelOverride: 'Release',
                parameter: 'releaseTime',
                value: engine.releaseTime,
                formatter: _secondsFormatter,
                onChange: (value) => unawaited(engine.setReleaseTime(value)),
              ),
              _sliderConfig(
                labelOverride: 'LFO Rate',
                parameter: 'lfoRate',
                value: engine.lfoRate,
                formatter: (d, v) => '${v.toStringAsFixed(2)} Hz',
                onChange: (value) => unawaited(engine.setLfoRate(value)),
              ),
              _sliderConfig(
                labelOverride: 'LFO Depth',
                parameter: 'lfoDepth',
                value: engine.lfoDepth,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setLfoDepth(value)),
              ),
              _sliderConfig(
                labelOverride: 'Chorus Rate',
                parameter: 'chorusRate',
                value: engine.chorusRate,
                formatter: (d, v) => '${v.toStringAsFixed(2)} Hz',
                onChange: (value) => unawaited(engine.setChorusRate(value)),
              ),
              _sliderConfig(
                labelOverride: 'Chorus Depth',
                parameter: 'chorusDepth',
                value: engine.chorusDepth,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setChorusDepth(value)),
              ),
              _sliderConfig(
                labelOverride: 'Delay Time',
                parameter: 'delayTime',
                value: engine.delayTime,
                formatter: _secondsFormatter,
                onChange: (value) => unawaited(engine.setDelayTime(value)),
              ),
              _sliderConfig(
                labelOverride: 'Delay Feedback',
                parameter: 'delayFeedback',
                value: engine.delayFeedback,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setDelayFeedback(value)),
              ),
              _sliderConfig(
                labelOverride: 'Reverb Mix',
                parameter: 'reverbMix',
                value: engine.reverbMix,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setReverbMix(value)),
              ),
              _sliderConfig(
                labelOverride: 'Drive',
                parameter: 'distortionDrive',
                value: engine.distortionDrive,
                formatter: _percentFormatter,
                onChange: (value) =>
                    unawaited(engine.setDistortionDrive(value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _VibPanel(
          title: 'Performance Controllers',
          subtitle: 'Live expression and glide behaviour',
          child: _ParameterGrid(
            configs: [
              _sliderConfig(
                labelOverride: 'Glide',
                parameter: 'glideTime',
                value: engine.glideTime,
                formatter: _secondsFormatter,
                onChange: (value) => unawaited(engine.setGlideTime(value)),
              ),
              _sliderConfig(
                labelOverride: 'Pitch Bend',
                parameter: 'pitchBendRange',
                value: engine.pitchBendRange,
                formatter: (d, v) => '${v.toStringAsFixed(1)} st',
                onChange: (value) => unawaited(engine.setPitchBendRange(value)),
              ),
              _sliderConfig(
                labelOverride: 'Mod Wheel',
                parameter: 'modWheel',
                value: engine.modWheel,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setModWheel(value)),
              ),
              _sliderConfig(
                labelOverride: 'Aftertouch',
                parameter: 'channelAftertouch',
                value: engine.channelAftertouch,
                formatter: _percentFormatter,
                onChange: (value) =>
                    unawaited(engine.setChannelAftertouch(value)),
              ),
              _sliderConfig(
                labelOverride: 'Expression',
                parameter: 'expression',
                value: engine.expression,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setExpression(value)),
              ),
              _sliderConfig(
                labelOverride: 'Sustain Pedal',
                parameter: 'sustainPedal',
                value: engine.sustainPedal,
                formatter: _percentFormatter,
                onChange: (value) => unawaited(engine.setSustainPedal(value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _VibPanel(
          title: 'Modulation Matrix',
          subtitle: 'Route sources to destinations for evolving motion',
          child: const ModulationMatrixPanel(),
        ),
      ],
    );
  }

  void _applyPadToEngine(AudioEngine engine, Offset normalized) {
    final cutoffRange = _registry.descriptorFor('filterCutoff')?.range;
    final resonanceRange = _registry.descriptorFor('filterResonance')?.range;
    if (cutoffRange == null || resonanceRange == null) {
      return;
    }

    final cutoffValue = cutoffRange.denormalize(normalized.dx.clamp(0.0, 1.0));
    final resonanceValue = resonanceRange.denormalize(
      (1 - normalized.dy).clamp(0.0, 1.0),
    );

    unawaited(engine.setFilterCutoff(cutoffValue));
    unawaited(engine.setFilterResonance(resonanceValue));
  }

  void _syncPadFromEngine(AudioEngine engine) {
    if (_padInteracting) {
      return;
    }

    final cutoffRange = _registry.descriptorFor('filterCutoff')?.range;
    final resonanceRange = _registry.descriptorFor('filterResonance')?.range;
    if (cutoffRange == null || resonanceRange == null) {
      return;
    }

    final normalizedX = cutoffRange
        .normalize(engine.filterCutoff)
        .clamp(0.0, 1.0);
    final normalizedY =
        1 - resonanceRange.normalize(engine.filterResonance).clamp(0.0, 1.0);
    final nextOffset = Offset(normalizedX, normalizedY);

    if ((nextOffset - _filterPadNormalized).distance < 0.005) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _padInteracting) return;
      setState(() => _filterPadNormalized = nextOffset);
    });
  }

  _SliderConfig _sliderConfig({
    required String parameter,
    required double value,
    required ValueChanged<double> onChange,
    String? labelOverride,
    ParameterValueFormatter? formatter,
  }) {
    final descriptor = _registry.descriptorFor(parameter);
    return _SliderConfig(
      descriptor: descriptor,
      parameter: parameter,
      value: value,
      labelOverride: labelOverride,
      formatter: formatter,
      onChange: onChange,
    );
  }

  static String _percentFormatter(
    ParameterDescriptor descriptor,
    double value,
  ) {
    return '${(value * 100).clamp(0, 999).round()}%';
  }

  static String _secondsFormatter(
    ParameterDescriptor descriptor,
    double value,
  ) {
    if (value >= 1) {
      return '${value.toStringAsFixed(2)} s';
    }
    return '${(value * 1000).round()} ms';
  }

  static String _hzFormatter(ParameterDescriptor descriptor, double value) {
    if (value >= 1000) {
      final kilohertz = value / 1000;
      return '${kilohertz.toStringAsFixed(kilohertz >= 10 ? 1 : 2)} kHz';
    }
    return '${value.round()} Hz';
  }
}

class _VisualizerPanel extends StatelessWidget {
  const _VisualizerPanel({required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return _VibPanel(
      title: 'Spectral Visualiser',
      subtitle: 'Synced with the embedded VIB34D overlay',
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: HypercubeVisualizer(audioEngine: engine)),
            Positioned(
              left: 20,
              top: 16,
              right: 20,
              child: _VisualizerHUD(engine: engine),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualizerHUD extends StatelessWidget {
  const _VisualizerHUD({required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Colors.white.withValues(alpha: 0.78);
    final accent = const Color(0xFF54FFF4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.copyWith(
          color: textColor,
          letterSpacing: 1.1,
          fontSize: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    engine.activePreset?.metadata.name ?? 'Custom Patch',
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Polyphony ${engine.maxPolyphony}',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            _HudValue(
              label: 'Cutoff',
              value: _VaporwaveInterfaceState._hzFormatter(
                ParameterDescriptor(
                  name: 'filterCutoff',
                  range: ParameterRange(
                    min: 20,
                    max: 20000,
                    defaultValue: 1200,
                  ),
                  visualizerTarget: 'geometryComplexity',
                ),
                engine.filterCutoff,
              ),
            ),
            const SizedBox(width: 18),
            _HudValue(
              label: 'LFO',
              value: '${engine.lfoRate.toStringAsFixed(2)} Hz',
            ),
            const SizedBox(width: 18),
            _HudValue(
              label: 'Reverb',
              value: _VaporwaveInterfaceState._percentFormatter(
                ParameterDescriptor(
                  name: 'reverbMix',
                  range: const ParameterRange(
                    min: 0,
                    max: 1,
                    defaultValue: 0.25,
                  ),
                  visualizerTarget: 'reverbMix',
                ),
                engine.reverbMix,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall!.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium!.copyWith(
            color: const Color(0xFF54FFF4),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.engine, required this.metrics});

  final AudioEngine engine;
  final Map<String, double> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeVoices = metrics['activeVoices'] ?? 0;
    final maxPolyphony =
        metrics['maxPolyphony'] ?? engine.maxPolyphony.toDouble();
    final performance = metrics['performanceEnergy'] ?? 0;
    final modulation = metrics['modulationEnergy'] ?? 0;

    String presetLabel;
    if (engine.activePreset == null) {
      presetLabel = 'Custom Patch';
    } else {
      presetLabel = engine.activePreset!.metadata.name;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF54FFF4).withValues(alpha: 0.28),
          ),
          color: const Color(0x1100FFFF),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(
            color: Colors.white,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
          child: Row(
            children: [
              Text(
                'VIB34D SPECTRAL ENGINE',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: const Color(0xFF54FFF4),
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(width: 24),
              _TopBarBadge(label: 'Preset', value: presetLabel.toUpperCase()),
              const SizedBox(width: 12),
              _TopBarBadge(
                label: 'Voices',
                value: '${activeVoices.round()}/${maxPolyphony.round()}',
              ),
              const SizedBox(width: 12),
              _TopBarBadge(
                label: 'Performance',
                value: '${(performance.clamp(0, 1) * 100).round()}% ENERGY'
                    .toUpperCase(),
              ),
              const SizedBox(width: 12),
              _TopBarBadge(
                label: 'Mod Matrix',
                value: '${(modulation.clamp(0, 1) * 100).round()}%'
                    .toUpperCase(),
              ),
              const Spacer(),
              _TopBarBadge(
                label: 'Tempo',
                value: '${(metrics['tempo'] ?? 120).round()} BPM',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarBadge extends StatelessWidget {
  const _TopBarBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.bodySmall!.copyWith(
              color: Colors.white54,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: Colors.white,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsColumn extends StatelessWidget {
  const _MetricsColumn({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final activeVoices = data['activeVoices'] ?? 0;
    final maxPolyphony = math.max(data['maxPolyphony'] ?? 1, 1).round();
    final performance = data['performanceEnergy'] ?? 0;
    final modulation = data['modulationEnergy'] ?? 0;
    final sustainActive = (data['sustainActive'] ?? 0) >= 0.5;
    final granular = data['granularActivity'] ?? 0;
    final filterCutoff = data['filterCutoff'] ?? 0;

    return _VibPanel(
      title: 'Realtime Metrics',
      subtitle: 'Mirrored in the WebGL overlay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricTile(
            label: 'Active Voices',
            value: '${activeVoices.round()} / $maxPolyphony',
            ratio: (activeVoices / math.max(maxPolyphony, 1)).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            label: 'Performance Energy',
            value: '${(performance.clamp(0, 1) * 100).round()}%',
            ratio: performance.clamp(0.0, 1.0),
            accent: const Color(0xFF54FFF4),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            label: 'Modulation',
            value: '${(modulation.clamp(0, 1) * 100).round()}%',
            ratio: modulation.clamp(0.0, 1.0),
            accent: const Color(0xFF9C6CFF),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            label: 'Filter Cutoff',
            value: _VaporwaveInterfaceState._hzFormatter(
              ParameterDescriptor(
                name: 'filterCutoff',
                range: const ParameterRange(
                  min: 20,
                  max: 20000,
                  defaultValue: 1200,
                ),
                visualizerTarget: 'geometryComplexity',
              ),
              filterCutoff,
            ),
            ratio: (filterCutoff / 20000).clamp(0.0, 1.0),
            accent: const Color(0xFF4BD7FF),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            label: 'Granular Flux',
            value: '${(granular.clamp(0, 1) * 100).round()}%',
            ratio: granular.clamp(0.0, 1.0),
            accent: const Color(0xFFFFA85B),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            label: 'Sustain Pedal',
            value: sustainActive ? 'ENGAGED' : 'IDLE',
            ratio: sustainActive ? 1 : 0,
            accent: sustainActive ? const Color(0xFF54FF9F) : Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.ratio,
    this.accent = const Color(0xFF54FFF4),
  });

  final String label;
  final String value;
  final double ratio;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.bodySmall!.copyWith(
              color: Colors.white60,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium!.copyWith(
              color: Colors.white,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _VibPanel extends StatelessWidget {
  const _VibPanel({
    required this.title,
    required this.child,
    this.subtitle,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleSmall!.copyWith(
              color: Colors.white,
              letterSpacing: 2.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall!.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ParameterGrid extends StatelessWidget {
  const _ParameterGrid({required this.configs});

  final List<_SliderConfig> configs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: configs
          .where((config) => config.descriptor != null)
          .map(
            (config) =>
                SizedBox(width: 220, child: _ParameterSlider(config: config)),
          )
          .toList(),
    );
  }
}

class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({required this.config});

  final _SliderConfig config;

  @override
  Widget build(BuildContext context) {
    final descriptor = config.descriptor!;
    final theme = Theme.of(context);
    final normalized = descriptor.range.normalize(config.value).clamp(0.0, 1.0);
    final label = config.labelOverride ?? _formatLabel(descriptor.name);
    final valueLabel =
        config.formatter?.call(descriptor, config.value) ??
        _defaultFormatter(descriptor, config.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: theme.textTheme.bodySmall!.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbColor: const Color(0xFF54FFF4),
            activeTrackColor: const Color(0xFF54FFF4),
            inactiveTrackColor: Colors.white12,
          ),
          child: Slider(
            value: normalized,
            onChanged: (value) {
              final denormalized = descriptor.range.denormalize(value);
              config.onChange(denormalized);
            },
          ),
        ),
      ],
    );
  }

  static String _formatLabel(String name) {
    final buffer = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      final char = name[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (i == 0) {
        buffer.write(char.toUpperCase());
      } else if (isUpper) {
        buffer.write(' ');
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _defaultFormatter(
    ParameterDescriptor descriptor,
    double value,
  ) {
    if (descriptor.range.max <= 1.0) {
      return '${(value * 100).round()}%';
    }
    if (descriptor.range.max <= 10) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(1);
  }
}

typedef ParameterValueFormatter =
    String Function(ParameterDescriptor descriptor, double value);

class _SliderConfig {
  const _SliderConfig({
    required this.parameter,
    required this.value,
    required this.onChange,
    this.descriptor,
    this.labelOverride,
    this.formatter,
  });

  final String parameter;
  final double value;
  final ValueChanged<double> onChange;
  final ParameterDescriptor? descriptor;
  final String? labelOverride;
  final ParameterValueFormatter? formatter;
}

class _FilterPad extends StatelessWidget {
  const _FilterPad({
    required this.normalizedPosition,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    required this.onPositionChanged,
  });

  final Offset normalizedPosition;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final ValueChanged<Offset> onPositionChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final indicator = Offset(
          normalizedPosition.dx.clamp(0.0, 1.0) * width,
          normalizedPosition.dy.clamp(0.0, 1.0) * height,
        );

        return GestureDetector(
          onPanStart: (details) {
            onInteractionStart();
            onPositionChanged(_normalize(details.localPosition, width, height));
          },
          onPanUpdate: (details) {
            onPositionChanged(_normalize(details.localPosition, width, height));
          },
          onPanEnd: (_) => onInteractionEnd(),
          onTapDown: (details) {
            onInteractionStart();
            onPositionChanged(_normalize(details.localPosition, width, height));
          },
          onTapUp: (_) => onInteractionEnd(),
          child: CustomPaint(painter: _FilterPadPainter(indicator: indicator)),
        );
      },
    );
  }

  Offset _normalize(Offset position, double width, double height) {
    final dx = (position.dx / width).clamp(0.0, 1.0);
    final dy = (position.dy / height).clamp(0.0, 1.0);
    return Offset(dx, dy);
  }
}

class _FilterPadPainter extends CustomPainter {
  _FilterPadPainter({required this.indicator});

  final Offset indicator;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1C0F3A), Color(0xFF060214)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      borderPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;

    const divisions = 4;
    for (int i = 1; i < divisions; i++) {
      final dx = rect.left + rect.width / divisions * i;
      final dy = rect.top + rect.height / divisions * i;
      canvas.drawLine(
        Offset(dx, rect.top + 8),
        Offset(dx, rect.bottom - 8),
        gridPaint,
      );
      canvas.drawLine(
        Offset(rect.left + 8, dy),
        Offset(rect.right - 8, dy),
        gridPaint,
      );
    }

    final indicatorPaint = Paint()
      ..color = const Color(0xFF54FFF4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(indicator, 10, indicatorPaint);
    canvas.drawCircle(
      indicator,
      16,
      Paint()
        ..color = const Color(0xFF54FFF4).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FilterPadPainter oldDelegate) {
    return oldDelegate.indicator != indicator;
  }
}
