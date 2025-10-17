import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Represents an active voice allocation in the synthesiser.
@immutable
class VoiceState {
  const VoiceState({
    required this.voiceId,
    required this.note,
    required this.velocity,
    required this.startedAt,
  });

  final int voiceId;
  final int note;
  final double velocity;
  final DateTime startedAt;
}

/// The result of requesting a new voice allocation.
class VoiceAllocation {
  VoiceAllocation({
    required this.voice,
    List<VoiceState>? stolenVoices,
  }) : stolenVoices = List<VoiceState>.unmodifiable(stolenVoices ?? const []);

  final VoiceState voice;
  final List<VoiceState> stolenVoices;

  bool get hasStolenVoices => stolenVoices.isNotEmpty;
}

/// Allocates polyphonic voices while applying voice stealing when the limit is reached.
class VoiceAllocator {
  VoiceAllocator({
    int maxVoices = defaultMaxVoices,
    DateTime Function()? clock,
  })  : assert(maxVoices > 0, 'VoiceAllocator must allow at least one voice'),
        _maxVoices = _clampMaxVoices(maxVoices),
        _clock = clock ?? DateTime.now;

  static const int defaultMaxVoices = 16;
  static const int hardVoiceCeiling = 64;

  int _nextVoiceId = 0;
  int _maxVoices;
  final DateTime Function() _clock;
  final Map<int, VoiceState> _voicesById = <int, VoiceState>{};
  final Map<int, List<int>> _voicesByNote = <int, List<int>>{};

  /// Returns an immutable view of the currently active voices keyed by ID.
  UnmodifiableMapView<int, VoiceState> get activeVoices =>
      UnmodifiableMapView<int, VoiceState>(_voicesById);

  /// Returns the number of active voices being tracked.
  int get activeVoiceCount => _voicesById.length;

  /// Returns the configured polyphony limit.
  int get maxVoices => _maxVoices;

  /// Returns the set of active note numbers.
  Set<int> get activeNotes => Set<int>.unmodifiable(_voicesByNote.keys);

  /// Requests a new voice allocation for [note] with [velocity].
  ///
  /// When no free voice slots remain the quietest voice is released first. If
  /// there are multiple voices at an identical velocity the oldest one is
  /// recycled.
  VoiceAllocation allocate(int note, double velocity) {
    final now = _clock();
    final stolen = <VoiceState>[];

    if (_voicesById.length >= _maxVoices) {
      final victim = _selectVoiceToSteal();
      if (victim != null) {
        _removeVoice(victim.voiceId);
        stolen.add(victim);
      }
    }

    _nextVoiceId = (_nextVoiceId + 1) & 0x7fffffff;
    if (_nextVoiceId == 0) {
      _nextVoiceId = 1;
    }

    final voice = VoiceState(
      voiceId: _nextVoiceId,
      note: note,
      velocity: velocity,
      startedAt: now,
    );

    _voicesById[voice.voiceId] = voice;
    final voicesForNote = _voicesByNote.putIfAbsent(note, () => <int>[]);
    voicesForNote.add(voice.voiceId);

    return VoiceAllocation(voice: voice, stolenVoices: stolen);
  }

  /// Releases the most recent voice assigned to [note].
  VoiceState? release(int note) {
    final voicesForNote = _voicesByNote[note];
    if (voicesForNote == null || voicesForNote.isEmpty) {
      return null;
    }

    final voiceId = voicesForNote.removeLast();
    if (voicesForNote.isEmpty) {
      _voicesByNote.remove(note);
    }

    return _voicesById.remove(voiceId);
  }

  /// Forcefully release a specific voice ID, typically after voice stealing.
  VoiceState? releaseVoice(int voiceId) {
    final voice = _voicesById.remove(voiceId);
    if (voice == null) {
      return null;
    }

    final voicesForNote = _voicesByNote[voice.note];
    voicesForNote?.remove(voiceId);
    if (voicesForNote != null && voicesForNote.isEmpty) {
      _voicesByNote.remove(voice.note);
    }

    return voice;
  }

  /// Updates the polyphony limit and returns any voices that were released to
  /// honour the new limit.
  List<VoiceState> updateMaxVoices(int limit) {
    final clamped = _clampMaxVoices(limit);
    if (clamped == _maxVoices) {
      return const <VoiceState>[];
    }

    _maxVoices = clamped;
    final released = <VoiceState>[];

    while (_voicesById.length > _maxVoices) {
      final victim = _selectVoiceToSteal();
      if (victim == null) {
        break;
      }
      _removeVoice(victim.voiceId);
      released.add(victim);
    }

    return released;
  }

  /// Clears all tracked voices and returns the released set for callers who
  /// need to propagate note-off events.
  List<VoiceState> reset() {
    final released = _voicesById.values.toList(growable: false);
    _voicesById.clear();
    _voicesByNote.clear();
    _nextVoiceId = 0;
    return released;
  }

  VoiceState? _selectVoiceToSteal() {
    VoiceState? candidate;
    for (final voice in _voicesById.values) {
      if (candidate == null) {
        candidate = voice;
        continue;
      }

      if (_isVelocityLess(voice.velocity, candidate.velocity)) {
        candidate = voice;
        continue;
      }

      if (_isVelocityEqual(voice.velocity, candidate.velocity) &&
          voice.startedAt.isBefore(candidate.startedAt)) {
        candidate = voice;
      }
    }
    return candidate;
  }

  void _removeVoice(int voiceId) {
    final voice = _voicesById.remove(voiceId);
    if (voice == null) {
      return;
    }

    final voicesForNote = _voicesByNote[voice.note];
    voicesForNote?.remove(voiceId);
    if (voicesForNote != null && voicesForNote.isEmpty) {
      _voicesByNote.remove(voice.note);
    }
  }

  static int _clampMaxVoices(int value) {
    return value.clamp(1, hardVoiceCeiling);
  }

  static bool _isVelocityLess(double a, double b) {
    return a < b - 1e-9;
  }

  static bool _isVelocityEqual(double a, double b) {
    return (a - b).abs() <= 1e-9;
  }
}
