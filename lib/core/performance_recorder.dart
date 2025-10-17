import 'dart:collection';

import 'audio_engine.dart';
import 'audio_engine_events.dart';

/// Immutable snapshot of a single event captured during a performance.
class PerformanceRecordEvent {
  const PerformanceRecordEvent({
    required this.position,
    required this.event,
  });

  /// Position relative to the start of the recording.
  final Duration position;

  /// Event emitted by the audio engine at [position].
  final AudioEngineEvent event;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'positionMs': position.inMilliseconds,
        'event': event.toJson(),
      };
}

/// Aggregate bundle that represents a captured performance.
class PerformanceRecording {
  PerformanceRecording({
    required this.label,
    required this.startedAt,
    required List<PerformanceRecordEvent> events,
  }) : events = UnmodifiableListView<PerformanceRecordEvent>(events);

  /// Optional label describing the performance.
  final String? label;

  /// Wall clock time when the recording started.
  final DateTime startedAt;

  /// Ordered events captured during the performance.
  final UnmodifiableListView<PerformanceRecordEvent> events;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (label != null) 'label': label,
        'startedAt': startedAt.toIso8601String(),
        'events': events.map((event) => event.toJson()).toList(growable: false),
      };
}

/// Utility that listens for [AudioEngine] events and captures them as a
/// timestamped performance timeline.
class PerformanceRecorder {
  PerformanceRecorder({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<PerformanceRecordEvent> _events = <PerformanceRecordEvent>[];
  AudioEngine? _engine;
  DateTime? _recordingStart;
  bool _isRecording = false;
  String? _label;

  /// Whether the recorder is currently capturing events.
  bool get isRecording => _isRecording;

  /// Attach the recorder to an [AudioEngine]. Existing attachments are replaced.
  void attach(AudioEngine engine) {
    if (identical(engine, _engine)) {
      return;
    }
    detach();
    _engine = engine;
    engine.addEventListener(_handleEvent);
  }

  /// Detach the recorder from the previously attached engine.
  void detach() {
    final engine = _engine;
    if (engine != null) {
      engine.removeEventListener(_handleEvent);
    }
    _engine = null;
  }

  /// Begin capturing a new performance.
  void startRecording({String? label}) {
    _events.clear();
    _label = label;
    _recordingStart = _clock();
    _isRecording = true;
  }

  /// Stop capturing events and return the resulting [PerformanceRecording].
  PerformanceRecording stopRecording() {
    if (!_isRecording || _recordingStart == null) {
      return PerformanceRecording(
        label: _label,
        startedAt: _clock(),
        events: const <PerformanceRecordEvent>[],
      );
    }

    final recording = PerformanceRecording(
      label: _label,
      startedAt: _recordingStart!,
      events: _events.toList(growable: false),
    );

    _isRecording = false;
    _recordingStart = null;
    return recording;
  }

  /// Clear any buffered events without affecting the recording state.
  void clear() {
    _events.clear();
  }

  void _handleEvent(AudioEngineEvent event) {
    if (!_isRecording || _recordingStart == null) {
      return;
    }

    final position = _clock().difference(_recordingStart!);
    _events.add(
      PerformanceRecordEvent(
        position: position,
        event: event,
      ),
    );
  }
}
