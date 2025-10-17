import 'package:meta/meta.dart';

/// Types of events emitted by the [AudioEngine].
enum AudioEngineEventType {
  parameterChanged,
  noteOn,
  noteOff,
  presetApplied,
  setlistChanged,
}

/// Immutable payload describing an event emitted by the [AudioEngine].
@immutable
class AudioEngineEvent {
  const AudioEngineEvent._({
    required this.type,
    required this.timestamp,
    this.parameterId,
    this.value,
    this.note,
    this.velocity,
    this.voiceId,
    this.presetId,
    this.setlistId,
    this.setlistEntryId,
  });

  /// The category of event that was emitted.
  final AudioEngineEventType type;

  /// The moment when the event was created.
  final DateTime timestamp;

  /// Canonical identifier for the parameter that changed.
  final String? parameterId;

  /// Updated value associated with a parameter change or transport event.
  final double? value;

  /// MIDI note number associated with note events.
  final int? note;

  /// Normalised velocity associated with note-on events.
  final double? velocity;

  /// Identifier of the voice allocated for the note event.
  final String? voiceId;

  /// Identifier of the preset involved in the event.
  final String? presetId;

  /// Identifier of the setlist involved in the event.
  final String? setlistId;

  /// Identifier of the setlist entry involved in the event.
  final String? setlistEntryId;

  /// Create a parameter changed event.
  factory AudioEngineEvent.parameterChanged(String parameterId, double value) {
    return AudioEngineEvent._(
      type: AudioEngineEventType.parameterChanged,
      timestamp: DateTime.now(),
      parameterId: parameterId,
      value: value,
    );
  }

  /// Create a note-on event.
  factory AudioEngineEvent.noteOn({
    required int note,
    required double velocity,
    required String voiceId,
  }) {
    return AudioEngineEvent._(
      type: AudioEngineEventType.noteOn,
      timestamp: DateTime.now(),
      note: note,
      velocity: velocity,
      voiceId: voiceId,
    );
  }

  /// Create a note-off event.
  factory AudioEngineEvent.noteOff({
    required int note,
    required String voiceId,
  }) {
    return AudioEngineEvent._(
      type: AudioEngineEventType.noteOff,
      timestamp: DateTime.now(),
      note: note,
      voiceId: voiceId,
    );
  }

  /// Create a preset applied event.
  factory AudioEngineEvent.presetApplied(String? presetId) {
    return AudioEngineEvent._(
      type: AudioEngineEventType.presetApplied,
      timestamp: DateTime.now(),
      presetId: presetId,
    );
  }

  /// Create a setlist changed event.
  factory AudioEngineEvent.setlistChanged({
    required String? setlistId,
    required String? setlistEntryId,
  }) {
    return AudioEngineEvent._(
      type: AudioEngineEventType.setlistChanged,
      timestamp: DateTime.now(),
      setlistId: setlistId,
      setlistEntryId: setlistEntryId,
    );
  }

  /// Serialize the event for persistence or debugging.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      if (parameterId != null) 'parameterId': parameterId,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
      if (velocity != null) 'velocity': velocity,
      if (voiceId != null) 'voiceId': voiceId,
      if (presetId != null) 'presetId': presetId,
      if (setlistId != null) 'setlistId': setlistId,
      if (setlistEntryId != null) 'setlistEntryId': setlistEntryId,
    };
  }
}

/// Callback signature used when subscribing to engine events.
typedef AudioEngineEventListener = void Function(AudioEngineEvent event);
