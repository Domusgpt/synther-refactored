import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/performance_recorder.dart';

class PerformanceRecorderPanel extends StatefulWidget {
  const PerformanceRecorderPanel({super.key});

  @override
  State<PerformanceRecorderPanel> createState() => _PerformanceRecorderPanelState();
}

class _PerformanceRecorderPanelState extends State<PerformanceRecorderPanel> {
  static const int _maxPreviewEvents = 200;

  AudioEngine? _engine;
  PerformanceRecorder? _recorder;
  final List<PerformanceEvent> _previewEvents = <PerformanceEvent>[];
  PerformanceRecording? _lastRecording;
  PerformanceEventListener? _listener;
  Timer? _ticker;
  bool _isRecording = false;
  int _totalEventCount = 0;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _listener = _handleEvent;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = Provider.of<AudioEngine>(context, listen: false);
    if (!identical(engine, _engine)) {
      _bindEngine(engine);
    }
  }

  @override
  void dispose() {
    _detachListener();
    _stopTicker();
    super.dispose();
  }

  void _bindEngine(AudioEngine engine) {
    _detachListener();
    _stopTicker();

    _engine = engine;
    var recorder = engine.performanceRecorder;
    if (recorder == null) {
      recorder = PerformanceRecorder();
      engine.attachPerformanceRecorder(recorder, emitSnapshot: false);
    }

    _recorder = recorder;
    final listener = _listener;
    if (listener != null) {
      _recorder!.addListener(listener);
    }

    _lastRecording = recorder.lastRecording;
    _previewEvents
      ..clear()
      ..addAll(_lastRecording?.events ?? const <PerformanceEvent>[]);
    _totalEventCount = _previewEvents.length;
    _isRecording = recorder.isRecording;
    if (_isRecording) {
      _startedAt ??= DateTime.now();
      _startTicker();
    } else {
      _elapsed = _lastRecording?.duration ?? Duration.zero;
    }
  }

  void _detachListener() {
    final listener = _listener;
    if (listener != null) {
      _recorder?.removeListener(listener);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) {
        return;
      }
      if (_isRecording && _startedAt != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt!);
        });
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _handleEvent(PerformanceEvent event) {
    setState(() {
      if (_previewEvents.length >= _maxPreviewEvents) {
        _previewEvents.removeAt(0);
      }
      _previewEvents.add(event);
      _totalEventCount += 1;
      _startedAt ??= DateTime.now().subtract(event.offset);
      if (_startedAt != null) {
        _elapsed = DateTime.now().difference(_startedAt!);
      }
      if (_ticker == null && _isRecording) {
        _startTicker();
      }
    });
  }

  void _startRecording({required bool reset}) {
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }

    recorder.start(reset: reset);
    setState(() {
      _isRecording = true;
      if (reset) {
        _previewEvents.clear();
        _totalEventCount = 0;
      }
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _startTicker();
    _showSnack(reset ? 'Recording started' : 'Recording resumed');
  }

  void _stopRecording() {
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }

    final recording = recorder.stop();
    setState(() {
      _isRecording = recorder.isRecording;
      _lastRecording = recording;
      _previewEvents
        ..clear()
        ..addAll(recording.events);
      _totalEventCount = recording.events.length;
      _elapsed = recording.duration;
      _startedAt = null;
    });
    _stopTicker();
    _showSnack('Recording captured (${recording.events.length} events)');
  }

  void _cancelRecording() {
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }

    recorder.cancel();
    setState(() {
      _isRecording = false;
      _previewEvents.clear();
      _totalEventCount = 0;
      _lastRecording = null;
      _elapsed = Duration.zero;
      _startedAt = null;
    });
    _stopTicker();
    _showSnack('Recording cleared');
  }

  Future<void> _copyRecordingJson() async {
    final recorder = _recorder;
    final recording = _lastRecording ?? recorder?.lastRecording;
    if (recording == null || recording.isEmpty) {
      _showSnack('No captured recording available yet', isError: true);
      return;
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final json = encoder.convert(recording.toJson());

    try {
      await Clipboard.setData(ClipboardData(text: json));
      _showSnack('Recording JSON copied to clipboard');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Clipboard copy failed: $error');
      }
      _showSnack('Clipboard unavailable – copy manually from the panel', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2B2F60),
      ),
    );
  }

  String _durationLabel() {
    if (_isRecording && _startedAt == null) {
      return '…';
    }
    return _formatDuration(_elapsed);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds.remainder(1000)).toString().padLeft(3, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds.$millis';
    }
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF080B26).withOpacity(0.96),
                const Color(0xFF03040F).withOpacity(0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF8A2BE2).withOpacity(0.45),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 34,
                spreadRadius: -12,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
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
                          'Performance Recorder',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.secondary,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capture live note, macro, preset, setlist, and transport changes as JSON timelines for QA and playback tooling.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close recorder',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatusChip('STATUS', _isRecording ? 'RECORDING' : 'IDLE',
                      background: _isRecording ? const Color(0x33FF1744) : const Color(0x3321D4FD)),
                  _buildStatusChip('EVENTS', _totalEventCount.toString()),
                  _buildStatusChip('DURATION', _durationLabel()),
                  _buildStatusChip(
                    'LAST EVENT',
                    _previewEvents.isEmpty ? '—' : _formatDuration(_previewEvents.last.offset),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _previewEvents.isEmpty
                    ? _buildEmptyState()
                    : _buildEventList(),
              ),
              const SizedBox(height: 20),
              _buildActionFooter(),
              if (_lastRecording != null && !_lastRecording!.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _buildJsonPreview(colorScheme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, {Color background = const Color(0x332196F3)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withOpacity(0.04),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.timeline,
            size: 42,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording
                ? 'Events will appear here as you play.'
                : 'Start a recording session to capture synth interactions.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (!_isRecording && _lastRecording != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'The last capture had ${_lastRecording!.events.length} events recorded at ${_formatDuration(_lastRecording!.duration)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final event = _previewEvents[index];
        return _buildEventTile(event);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _previewEvents.length,
    );
  }

  Widget _buildEventTile(PerformanceEvent event) {
    final payloadEntries = event.payload.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                event.type.name.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF64FFDA),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(event.offset),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (payloadEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'No payload captured',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: payloadEntries
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    final isIdle = !_isRecording;
    final hasRecording = (_lastRecording ?? _recorder?.lastRecording)?.isEmpty == false;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (isIdle)
          ElevatedButton.icon(
            onPressed: () => _startRecording(reset: true),
            icon: const Icon(Icons.fiber_manual_record, size: 18),
            label: const Text('START RECORDING'),
          )
        else
          ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop, size: 18),
            label: const Text('STOP'),
          ),
        if (isIdle)
          OutlinedButton.icon(
            onPressed: hasRecording ? () => _startRecording(reset: false) : null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('RESUME'),
          )
        else
          OutlinedButton.icon(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('CANCEL'),
          ),
        FilledButton.tonalIcon(
          onPressed: hasRecording ? _copyRecordingJson : null,
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('COPY JSON'),
        ),
      ],
    );
  }

  Widget _buildJsonPreview(ColorScheme colorScheme) {
    final recording = _lastRecording;
    if (recording == null || recording.isEmpty) {
      return const SizedBox.shrink();
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final jsonPreview = encoder.convert(recording.toJson());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest JSON Snapshot',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.secondary,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonPreview,
                style: const TextStyle(
                  fontFamily: 'SourceCodePro',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
