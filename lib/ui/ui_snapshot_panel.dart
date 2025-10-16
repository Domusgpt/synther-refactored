import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UISnapshotMetadata {
  UISnapshotMetadata({
    required this.capturedAt,
    required this.activeVoices,
    required this.maxPolyphony,
    required this.transportTempo,
    required this.transportRunning,
    required this.presetName,
    required this.visualizerMetrics,
  });

  final DateTime capturedAt;
  final int activeVoices;
  final int maxPolyphony;
  final double transportTempo;
  final bool transportRunning;
  final String? presetName;
  final Map<String, double> visualizerMetrics;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'capturedAt': capturedAt.toIso8601String(),
      'activeVoices': activeVoices,
      'maxPolyphony': maxPolyphony,
      'transportTempo': transportTempo,
      'transportRunning': transportRunning,
      'presetName': presetName,
      'visualizerMetrics': visualizerMetrics,
    };
  }

  String toPrettyJson() {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  List<_SnapshotFact> highLevelFacts() {
    final transportState = transportRunning ? 'Running' : 'Stopped';
    return <_SnapshotFact>[
      _SnapshotFact('Preset', presetName ?? 'Unassigned'),
      _SnapshotFact('Active Voices', '$activeVoices / $maxPolyphony'),
      _SnapshotFact('Tempo', '${transportTempo.toStringAsFixed(1)} BPM'),
      _SnapshotFact('Transport', transportState),
      _SnapshotFact('Captured', capturedAt.toLocal().toString()),
    ];
  }
}

class _SnapshotFact {
  const _SnapshotFact(this.label, this.value);

  final String label;
  final String value;
}

class UISnapshotPanel extends StatelessWidget {
  const UISnapshotPanel({
    super.key,
    required this.imageBytes,
    required this.metadata,
  });

  final Uint8List imageBytes;
  final UISnapshotMetadata metadata;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        color: const Color(0xFF07000F).withOpacity(0.9),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SafeArea(
          top: false,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UI Snapshot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SnapshotPreview(imageBytes: imageBytes),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metadata
                      .highLevelFacts()
                      .map(
                        (fact) => _SnapshotFactChip(label: fact.label, value: fact.value),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Flexible(
                  fit: FlexFit.loose,
                  child: _SnapshotMetricsView(
                    metadata: metadata,
                  ),
                ),
                const SizedBox(height: 12),
                _SnapshotActions(metadata: metadata, imageBytes: imageBytes),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnapshotPreview extends StatelessWidget {
  const _SnapshotPreview({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _SnapshotFactChip extends StatelessWidget {
  const _SnapshotFactChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.16),
            Colors.white.withOpacity(0.06),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              color: Color(0xFF65F5FF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetricsView extends StatefulWidget {
  const _SnapshotMetricsView({
    required this.metadata,
  });

  final UISnapshotMetadata metadata;

  @override
  State<_SnapshotMetricsView> createState() => _SnapshotMetricsViewState();
}

class _SnapshotMetricsViewState extends State<_SnapshotMetricsView> {
  bool _showRawMetrics = false;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, double>> highlightedMetrics = [
      MapEntry('performanceEnergy',
          widget.metadata.visualizerMetrics['performanceEnergy'] ?? 0.0),
      MapEntry('modulationEnergy',
          widget.metadata.visualizerMetrics['modulationEnergy'] ?? 0.0),
      MapEntry('granularMotion',
          widget.metadata.visualizerMetrics['granularMotion'] ?? 0.0),
      MapEntry('transportBeats',
          widget.metadata.visualizerMetrics['transportBeats'] ?? 0.0),
    ];

    final sortedMetrics = widget.metadata.visualizerMetrics.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return AnimatedCrossFade(
      crossFadeState:
          _showRawMetrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 250),
      firstChild: _buildInsightGrid(highlightedMetrics),
      secondChild: _buildRawMetrics(sortedMetrics),
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          children: <Widget>[
            Positioned.fill(key: bottomChildKey, child: bottomChild),
            Positioned.fill(key: topChildKey, child: topChild),
          ],
        );
      },
    );
  }

  Widget _buildInsightGrid(List<MapEntry<String, double>> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Highlighted Metrics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics
              .map(
                (metric) => _MetricCard(
                  label: metric.key,
                  value: metric.value,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _showRawMetrics = true),
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white70),
            label: const Text(
              'View Raw Metrics',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawMetrics(List<MapEntry<String, double>> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Raw Visualiser Metrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showRawMetrics = false),
              icon: const Icon(Icons.close_fullscreen, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final entry = metrics[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value.toStringAsFixed(4),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FFFF).withOpacity(0.2),
            const Color(0xFFFF00FF).withOpacity(0.2),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotActions extends StatefulWidget {
  const _SnapshotActions({
    required this.metadata,
    required this.imageBytes,
  });

  final UISnapshotMetadata metadata;
  final Uint8List imageBytes;

  @override
  State<_SnapshotActions> createState() => _SnapshotActionsState();
}

class _SnapshotActionsState extends State<_SnapshotActions> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final base64Preview = base64Encode(widget.imageBytes);
    final truncatedPreview =
        base64Preview.length > 200 ? '${base64Preview.substring(0, 200)}…' : base64Preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _copyPayload,
          icon: Icon(
            _copied ? Icons.check_circle : Icons.copy_outlined,
            color: _copied ? Colors.greenAccent : Colors.white70,
          ),
          label: Text(
            _copied ? 'Copied to clipboard' : 'Copy JSON & image payload',
            style: TextStyle(
              color: _copied ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Base64 Preview',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.1,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
          ),
          child: SelectableText(
            truncatedPreview,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyPayload() async {
    final payload = {
      'metadata': widget.metadata.toJson(),
      'imageBase64': base64Encode(widget.imageBytes),
    };
    final encoder = const JsonEncoder.withIndent('  ');
    await Clipboard.setData(ClipboardData(text: encoder.convert(payload)));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }
}
