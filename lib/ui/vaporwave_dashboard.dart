import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A minimal vaporwave-inspired dashboard that provides a place holder UI
/// while the legacy implementation is rebuilt.
class VaporwaveDashboardPage extends StatefulWidget {
  const VaporwaveDashboardPage({super.key});

  @override
  State<VaporwaveDashboardPage> createState() => _VaporwaveDashboardPageState();
}

class _VaporwaveDashboardPageState extends State<VaporwaveDashboardPage> {
  double masterVolume = 0.5;
  double filterCutoff = 0.65;
  double resonance = 0.25;
  bool arpeggiatorEnabled = true;
  bool shimmerEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildControls(context)),
                      const SizedBox(width: 32),
                      SizedBox(
                        width: math.min(constraints.maxWidth * 0.28, 320),
                        child: _buildMetrics(context),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildVisualizer(context),
                      const SizedBox(height: 16),
                      _buildControls(context),
                      const SizedBox(height: 16),
                      _buildMetrics(context),
                    ],
                  );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF080812), Color(0xFF141427)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 1200 : double.infinity,
                  ),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width >= 900) ...[
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildVisualizer(context),
          const SizedBox(height: 24),
        ],
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ControlCard(
              title: 'Master Volume',
              subtitle: 'Output gain',
              child: _SliderTile(
                value: masterVolume,
                onChanged: (value) => setState(() => masterVolume = value),
              ),
            ),
            _ControlCard(
              title: 'Filter Cutoff',
              subtitle: 'LPF frequency',
              child: _SliderTile(
                value: filterCutoff,
                onChanged: (value) => setState(() => filterCutoff = value),
              ),
            ),
            _ControlCard(
              title: 'Resonance',
              subtitle: 'Filter emphasis',
              child: _SliderTile(
                value: resonance,
                onChanged: (value) => setState(() => resonance = value),
              ),
            ),
            _ControlCard(
              title: 'Performance',
              subtitle: 'Live toggles',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: arpeggiatorEnabled,
                    onChanged: (value) =>
                        setState(() => arpeggiatorEnabled = value),
                    title: const Text('Arpeggiator'),
                    subtitle: const Text('Sequence incoming notes'),
                  ),
                  SwitchListTile.adaptive(
                    value: shimmerEnabled,
                    onChanged: (value) => setState(() => shimmerEnabled = value),
                    title: const Text('Shimmer Reverb'),
                    subtitle: const Text('Adds octave reflection'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFF232347),
          child: Icon(Icons.graphic_eq, color: Color(0xFF00E5FF), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Synther Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8EAFF),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'A lightweight rebuild of the vaporwave control surface.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9BA0C8),
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9F45FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Preview'),
        ),
      ],
    );
  }

  Widget _buildVisualizer(BuildContext context) {
    return _ControlCard(
      title: 'Pulse Visualizer',
      subtitle: 'Mock levels respond to controls',
      child: _LiveLevelVisualizer(
        intensity: masterVolume,
        cutoff: filterCutoff,
        resonance: resonance,
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final List<_Metric> metrics = [
      _Metric('Scene BPM', '92', Icons.speed_rounded),
      _Metric('Voices Active', arpeggiatorEnabled ? '8' : '3', Icons.surround_sound),
      _Metric('Reverb Mix', shimmerEnabled ? '42%' : '21%', Icons.grain),
      _Metric('CPU Usage', '${(masterVolume * 32 + 18).toStringAsFixed(0)}%',
          Icons.memory_rounded),
      _Metric('Spectral Tilt',
          shimmerEnabled ? '+3.1 dB' : '-1.4 dB', Icons.auto_graph_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Session Metrics',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8EAFF),
          ),
        ),
        const SizedBox(height: 12),
        ...metrics.map(
          (metric) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MetricTile(metric: metric),
          ),
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0x33181832), Color(0x66181832)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x443D3D58)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFE8EAFF),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9BA0C8),
                  letterSpacing: 0.2,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0,
          max: 1,
          activeColor: const Color(0xFF00E5FF),
          inactiveColor: const Color(0x33232347),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE8EAFF),
              ),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33181832),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x223D3D58)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9F45FF), Color(0xFF00E5FF)],
              ),
            ),
            child: Icon(metric.icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFE8EAFF),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9BA0C8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveLevelVisualizer extends StatefulWidget {
  const _LiveLevelVisualizer({
    required this.intensity,
    required this.cutoff,
    required this.resonance,
  });

  final double intensity;
  final double cutoff;
  final double resonance;

  @override
  State<_LiveLevelVisualizer> createState() => _LiveLevelVisualizerState();
}

class _LiveLevelVisualizerState extends State<_LiveLevelVisualizer> {
  late Timer _timer;
  late List<double> _levels;

  @override
  void initState() {
    super.initState();
    _levels = List<double>.filled(18, 0.2);
    _timer = Timer.periodic(const Duration(milliseconds: 180), _tick);
  }

  @override
  void didUpdateWidget(covariant _LiveLevelVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity ||
        oldWidget.cutoff != widget.cutoff ||
        oldWidget.resonance != widget.resonance) {
      _tick(_timer);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    final random = math.Random();
    setState(() {
      final envelope = widget.intensity.clamp(0.1, 1.0);
      final tilt = (widget.cutoff - 0.5) * 0.6;
      final resonanceSpike = widget.resonance * 0.8;

      _levels = List<double>.generate(_levels.length, (index) {
        final base = random.nextDouble() * 0.65 * envelope;
        final position = index / _levels.length;
        final tonalBias = (position - 0.5) * tilt * 2;
        final resonanceBoost =
            (math.sin(position * math.pi) * resonanceSpike).abs();
        return (base + tonalBias + resonanceBoost).clamp(0.05, 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _levels
            .map(
              (level) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    height: level * 150,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF9F45FF).withOpacity(0.8),
                          const Color(0xFF00E5FF).withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
