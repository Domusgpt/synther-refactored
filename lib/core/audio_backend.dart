import 'package:flutter/foundation.dart';

/// Platform-agnostic interface for talking to the audio layer.
///
/// The original project expected a native C++ backend.  For the purposes of
/// this refactor we expose only the behaviour that is required by the Dart
/// codebase so the higher level UI can function without native bindings.
abstract class AudioBackend {
  /// Indicates if the backend has finished initialising.
  bool get isInitialized;

  /// Provides the most recent error message if initialisation failed.
  String? get lastError;

  /// Prepare the backend for use. Implementations must be idempotent so it is
  /// safe to call multiple times.
  Future<void> initialize();

  /// Release all resources that belong exclusively to this backend instance.
  void dispose();

  /// Trigger a voice. [voiceId] is used to reference the voice when it needs
  /// to be turned off again, [note] is a MIDI note number and [velocity] the
  /// 0-1 velocity value.
  void noteOn(int voiceId, int note, double velocity);

  /// Stop a voice that was started with [noteOn].
  void noteOff(int voiceId);

  /// Update a numerical parameter that is identified by [parameterId].
  void setParameter(int parameterId, double value);

  /// Apply a pitch bend offset in semitones to all active voices.
  ///
  /// Values are clamped by the backend against the configured pitch bend range
  /// so callers may supply any double within a sensible range (e.g. -24 to 24).
  void setPitchBend(double semitoneOffset);

  /// Retrieve the current value for a numerical parameter.
  double getParameter(int parameterId);

  /// Data that is consumed by the Hypercube visualiser.  All values are
  /// expected to be normalised between sensible ranges (0-1 or Hertz for
  /// frequency) so the visualiser has something meaningful to work with.
  Map<String, double> getVisualizerData();
}

/// Utility clamp helper used by multiple backends.
@protected
T clampValue<T extends num>(T value, T min, T max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
