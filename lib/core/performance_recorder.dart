import 'dart:collection';

/// Event categories emitted while recording a live performance.
enum PerformanceEventType {
  noteOn,
  noteOff,
  parameter,
  macro,
  preset,
  setlist,
  transport,
  snapshot,
  custom,
}

/// Immutable event captured by [PerformanceRecorder].
class PerformanceEvent {
  PerformanceEvent({
    required this.type,
    required Duration offset,
    Map<String, dynamic>? payload,
  })  : offset = offset,
        payload = UnmodifiableMapView(Map<String, dynamic>.from(payload ?? const <String, dynamic>{}));

  /// The semantic type of the recorded event.
  final PerformanceEventType type;

  /// Time elapsed since the beginning of the recording.
  final Duration offset;

  /// Optional payload describing the event.
  final UnmodifiableMapView<String, dynamic> payload;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'offsetMicros': offset.inMicroseconds,
      'payload': payload,
    };
  }

  factory PerformanceEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? PerformanceEventType.custom.name;
    final type = PerformanceEventType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => PerformanceEventType.custom,
    );
    final offsetMicros = (json['offsetMicros'] as num?)?.toInt() ?? 0;
    final payload = json['payload'];
    return PerformanceEvent(
      type: type,
      offset: Duration(microseconds: offsetMicros),
      payload: payload is Map<String, dynamic>
          ? payload
          : payload is Map
              ? payload.map((key, value) => MapEntry(key.toString(), value))
              : const <String, dynamic>{},
    );
  }
}

/// Finished capture describing a recorded performance run.
class PerformanceRecording {
  PerformanceRecording({
    required this.startedAt,
    required this.duration,
    Iterable<PerformanceEvent>? events,
  }) : events = UnmodifiableListView(List<PerformanceEvent>.from(events ?? const <PerformanceEvent>[]));

  final DateTime startedAt;
  final Duration duration;
  final UnmodifiableListView<PerformanceEvent> events;

  bool get isEmpty => events.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startedAt': startedAt.toIso8601String(),
      'durationMicros': duration.inMicroseconds,
      'events': events.map((event) => event.toJson()).toList(),
    };
  }

  factory PerformanceRecording.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'] as Iterable<dynamic>?;
    return PerformanceRecording(
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      duration: Duration(microseconds: (json['durationMicros'] as num?)?.toInt() ?? 0),
      events: eventsRaw == null
          ? const <PerformanceEvent>[]
          : eventsRaw
              .whereType<Map<String, dynamic>>()
              .map(PerformanceEvent.fromJson)
              .toList(),
    );
  }
}

typedef PerformanceEventListener = void Function(PerformanceEvent event);

/// Records note, parameter, macro and transport changes for performance capture.
class PerformanceRecorder {
  PerformanceRecorder({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<PerformanceEvent> _events = <PerformanceEvent>[];
  final List<PerformanceEventListener> _listeners = <PerformanceEventListener>[];

  DateTime? _startedAt;
  PerformanceRecording? _lastRecording;

  bool get isRecording => _startedAt != null;

  PerformanceRecording? get lastRecording => _lastRecording;

  void start({bool reset = true}) {
    if (reset) {
      _events.clear();
    }
    _startedAt = _clock();
  }

  PerformanceRecording stop({bool retainForResume = false}) {
    final startedAt = _startedAt;
    final now = _clock();
    if (startedAt == null) {
      final recording = PerformanceRecording(startedAt: now, duration: Duration.zero);
      _lastRecording = recording;
      return recording;
    }

    final recording = PerformanceRecording(
      startedAt: startedAt,
      duration: now.difference(startedAt),
      events: _events,
    );
    _lastRecording = recording;
    if (!retainForResume) {
      _events.clear();
      _startedAt = null;
    } else {
      _startedAt = now;
    }
    return recording;
  }

  void cancel() {
    _events.clear();
    _startedAt = null;
  }

  void addListener(PerformanceEventListener listener) {
    if (_listeners.contains(listener)) {
      return;
    }
    _listeners.add(listener);
  }

  void removeListener(PerformanceEventListener listener) {
    _listeners.remove(listener);
  }

  void recordNoteOn({
    required int note,
    required double velocity,
    required int voiceId,
    String? source,
  }) {
    _recordEvent(
      PerformanceEventType.noteOn,
      <String, dynamic>{
        'note': note,
        'velocity': velocity,
        'voiceId': voiceId,
        if (source != null) 'source': source,
      },
    );
  }

  void recordNoteOff({
    required int note,
    required int voiceId,
    double? velocity,
    String? reason,
  }) {
    _recordEvent(
      PerformanceEventType.noteOff,
      <String, dynamic>{
        'note': note,
        'voiceId': voiceId,
        if (velocity != null) 'velocity': velocity,
        if (reason != null) 'reason': reason,
      },
    );
  }

  void recordParameterChange(String parameterId, double value) {
    _recordEvent(
      PerformanceEventType.parameter,
      <String, dynamic>{
        'parameter': parameterId,
        'value': value,
      },
    );
  }

  void recordMacroValue(String macroId, double value, Map<String, double> resolved) {
    _recordEvent(
      PerformanceEventType.macro,
      <String, dynamic>{
        'macroId': macroId,
        'value': value,
        if (resolved.isNotEmpty) 'resolved': resolved,
      },
    );
  }

  void recordPresetChange({
    String? presetId,
    String? presetName,
    Map<String, double>? snapshot,
  }) {
    _recordEvent(
      PerformanceEventType.preset,
      <String, dynamic>{
        if (presetId != null) 'presetId': presetId,
        if (presetName != null) 'presetName': presetName,
        if (snapshot != null && snapshot.isNotEmpty) 'snapshot': snapshot,
      },
    );
  }

  void recordSetlistChange({
    String? setlistId,
    String? entryId,
    String? presetId,
    String? presetName,
    bool cleared = false,
  }) {
    _recordEvent(
      PerformanceEventType.setlist,
      <String, dynamic>{
        if (setlistId != null) 'setlistId': setlistId,
        if (entryId != null) 'entryId': entryId,
        if (presetId != null) 'presetId': presetId,
        if (presetName != null) 'presetName': presetName,
        if (cleared) 'cleared': true,
      },
    );
  }

  void recordTransportState({
    required double tempo,
    required bool running,
    required int numerator,
    required int denominator,
    double? positionBeats,
  }) {
    _recordEvent(
      PerformanceEventType.transport,
      <String, dynamic>{
        'tempo': tempo,
        'running': running,
        'numerator': numerator,
        'denominator': denominator,
        if (positionBeats != null) 'positionBeats': positionBeats,
      },
    );
  }

  void recordSnapshot({
    required Map<String, double> parameters,
    String? presetId,
    String? presetName,
    String? setlistId,
    String? setlistEntryId,
  }) {
    _recordEvent(
      PerformanceEventType.snapshot,
      <String, dynamic>{
        if (presetId != null) 'presetId': presetId,
        if (presetName != null) 'presetName': presetName,
        if (setlistId != null) 'setlistId': setlistId,
        if (setlistEntryId != null) 'setlistEntryId': setlistEntryId,
        'parameters': parameters,
      },
    );
  }

  void recordCustom(String label, Map<String, dynamic> payload) {
    _recordEvent(
      PerformanceEventType.custom,
      <String, dynamic>{
        'label': label,
        ...payload,
      },
    );
  }

  void _recordEvent(PerformanceEventType type, Map<String, dynamic> payload) {
    final start = _startedAt;
    if (start == null) {
      return;
    }
    final now = _clock();
    final event = PerformanceEvent(
      type: type,
      offset: now.difference(start),
      payload: payload,
    );
    _events.add(event);
    for (final listener in List<PerformanceEventListener>.from(_listeners)) {
      listener(event);
    }
  }
}
