import 'dart:async';

import 'package:flutter/foundation.dart';

/// Represents a single programmed step inside the sequencer.
@immutable
class StepSequencerStep {
  const StepSequencerStep({
    this.note,
    this.velocity = 1.0,
    this.gate = 1.0,
    this.tie = false,
    this.rest = false,
    this.accent = false,
    this.metadata = const <String, dynamic>{},
  }) : assert(velocity >= 0.0 && velocity <= 1.0,
            'Velocity must be normalised between 0 and 1.');

  /// MIDI note number that should be triggered.  When `null` the step is treated
  /// as a rest unless [tie] is also `true`.
  final int? note;

  /// Normalised velocity that will be passed to the synth engine.
  final double velocity;

  /// Portion of the step that should be held for.  Currently informational but
  /// preserved for future backend integration.
  final double gate;

  /// Whether the step should continue holding the previous note.
  final bool tie;

  /// Marks the step as a rest.  Rests always release the currently held note.
  final bool rest;

  /// Optional accent flag that downstream consumers can use for styling.
  final bool accent;

  /// Extra metadata preserved during serialisation.
  final Map<String, dynamic> metadata;

  StepSequencerStep copyWith({
    int? note,
    double? velocity,
    double? gate,
    bool? tie,
    bool? rest,
    bool? accent,
    Map<String, dynamic>? metadata,
  }) {
    return StepSequencerStep(
      note: note ?? this.note,
      velocity: velocity ?? this.velocity,
      gate: gate ?? this.gate,
      tie: tie ?? this.tie,
      rest: rest ?? this.rest,
      accent: accent ?? this.accent,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'note': note,
      'velocity': velocity,
      'gate': gate,
      'tie': tie,
      'rest': rest,
      'accent': accent,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  factory StepSequencerStep.fromJson(Map<String, dynamic> json) {
    int? parseNote(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double parseDouble(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase();
        if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
          return true;
        }
        if (lowered == 'false' || lowered == '0' || lowered == 'no') {
          return false;
        }
      }
      return fallback;
    }

    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMetadata)
        : const <String, dynamic>{};

    return StepSequencerStep(
      note: parseNote(json['note']),
      velocity:
          parseDouble(json['velocity'], 1.0).clamp(0.0, 1.0).toDouble(),
      gate: parseDouble(json['gate'], 1.0).clamp(0.0, 8.0).toDouble(),
      tie: parseBool(json['tie'], false),
      rest: parseBool(json['rest'], false),
      accent: parseBool(json['accent'], false),
      metadata: metadata,
    );
  }
}

/// Container describing the sequencer layout and playback behaviour.
@immutable
class StepSequencerPattern {
  const StepSequencerPattern({
    required this.steps,
    this.stepsPerBeat = 4,
    this.loop = true,
  })  : assert(stepsPerBeat > 0, 'stepsPerBeat must be positive'),
        assert(stepsPerBeat <= 64, 'stepsPerBeat must be reasonable'),
        assert(steps.isNotEmpty, 'A pattern requires at least one step.');

  /// Ordered list of steps that make up the pattern.
  final List<StepSequencerStep> steps;

  /// Number of steps contained within a single beat.  4 represents sixteenth
  /// notes at a 4/4 time signature.
  final int stepsPerBeat;

  /// Whether playback should loop after hitting the last step.
  final bool loop;

  int get length => steps.length;

  Duration stepDuration(double bpm) {
    final clampedBpm = bpm.clamp(10.0, 400.0);
    final stepsPerSecond = (clampedBpm / 60.0) * stepsPerBeat;
    if (stepsPerSecond <= 0) {
      return const Duration(milliseconds: 250);
    }
    final microseconds = (Duration.microsecondsPerSecond / stepsPerSecond)
        .round()
        .clamp(1, 10000000)
        .toInt();
    return Duration(microseconds: microseconds);
  }

  StepSequencerPattern copyWith({
    List<StepSequencerStep>? steps,
    int? stepsPerBeat,
    bool? loop,
  }) {
    return StepSequencerPattern(
      steps: steps ?? this.steps,
      stepsPerBeat: stepsPerBeat ?? this.stepsPerBeat,
      loop: loop ?? this.loop,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stepsPerBeat': stepsPerBeat,
      'loop': loop,
      'steps': steps.map((step) => step.toJson()).toList(growable: false),
    };
  }

  factory StepSequencerPattern.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lowered = value.toLowerCase();
        if (lowered == 'true' || lowered == '1' || lowered == 'yes') {
          return true;
        }
        if (lowered == 'false' || lowered == '0' || lowered == 'no') {
          return false;
        }
      }
      return fallback;
    }

    final stepsJson = json['steps'];
    final steps = stepsJson is List
        ? stepsJson
            .whereType<Map<String, dynamic>>()
            .map(StepSequencerStep.fromJson)
            .toList(growable: false)
        : const <StepSequencerStep>[];

    return StepSequencerPattern(
      steps: steps.isEmpty
          ? const <StepSequencerStep>[StepSequencerStep(rest: true)]
          : steps,
      stepsPerBeat: parseInt(json['stepsPerBeat'], 4).clamp(1, 64).toInt(),
      loop: parseBool(json['loop'], true),
    );
  }

  factory StepSequencerPattern.empty({
    int length = 16,
    int stepsPerBeat = 4,
    bool loop = true,
  }) {
    assert(length > 0, 'A pattern must have a positive number of steps.');
    return StepSequencerPattern(
      steps: List<StepSequencerStep>.generate(
        length,
        (_) => const StepSequencerStep(rest: true),
        growable: false,
      ),
      stepsPerBeat: stepsPerBeat,
      loop: loop,
    );
  }
}

/// Type of playback event emitted by the sequencer.
enum StepSequencerPlaybackEventType { step, noteOn, noteOff }

/// A playback event emitted whenever the sequencer advances.
class StepSequencerPlaybackEvent {
  StepSequencerPlaybackEvent({
    required this.type,
    required this.stepIndex,
    required this.step,
    required this.iteration,
    this.note,
    this.velocity,
    this.gate,
    this.accent,
    this.noteInstanceId,
  });

  final StepSequencerPlaybackEventType type;
  final int stepIndex;
  final StepSequencerStep step;
  final int iteration;
  final int? note;
  final double? velocity;
  final double? gate;
  final bool? accent;
  final int? noteInstanceId;

  bool get isNoteOn => type == StepSequencerPlaybackEventType.noteOn;
  bool get isNoteOff => type == StepSequencerPlaybackEventType.noteOff;
}

/// Lightweight step sequencer that can drive the synth engine or be inspected
/// by the UI layer.
class StepSequencer extends ChangeNotifier {
  StepSequencer({
    StepSequencerPattern? pattern,
    double bpm = 120.0,
  })  : _pattern = pattern ?? StepSequencerPattern.empty(),
        _bpm = bpm.clamp(10.0, 400.0);

  StepSequencerPattern _pattern;
  double _bpm;
  int _currentStep = 0;
  bool _running = false;
  int _stepIteration = 0;
  int _noteInstanceCounter = 0;
  Timer? _timer;
  int? _activeNote;
  int? _activeNoteInstanceId;

  final StreamController<StepSequencerPlaybackEvent> _playbackController =
      StreamController<StepSequencerPlaybackEvent>.broadcast(sync: true);

  StepSequencerPattern get pattern => _pattern;
  double get bpm => _bpm;
  int get currentStep => _currentStep;
  bool get isRunning => _running;
  bool get hasActiveNote => _activeNote != null;
  Stream<StepSequencerPlaybackEvent> get playbackStream =>
      _playbackController.stream;

  Duration get stepDuration => _pattern.stepDuration(_bpm);

  void setPattern(StepSequencerPattern pattern, {bool resetPosition = true}) {
    final wasRunning = _running;
    stop(resetPosition: false);
    _pattern = pattern;
    if (resetPosition) {
      _currentStep = 0;
    } else {
      _currentStep = _currentStep.clamp(0, _pattern.length - 1).toInt();
    }
    if (wasRunning) {
      start(resetPosition: false);
    } else {
      notifyListeners();
    }
  }

  void setBpm(double bpm) {
    final clamped = bpm.clamp(10.0, 400.0);
    if ((clamped - _bpm).abs() < 0.00001) {
      return;
    }
    _bpm = clamped;
    if (_running) {
      _scheduleTimer();
    }
    notifyListeners();
  }

  void start({bool resetPosition = false}) {
    if (resetPosition) {
      _currentStep = 0;
    }
    if (_running) {
      return;
    }
    _running = true;
    _scheduleTimer();
    notifyListeners();
  }

  void stop({bool resetPosition = false, bool emitRelease = true}) {
    if (!_running && !emitRelease && !resetPosition) {
      return;
    }
    _running = false;
    _timer?.cancel();
    _timer = null;
    if (emitRelease) {
      _emitReleaseEvent(reasonIteration: _stepIteration);
    }
    if (resetPosition) {
      _currentStep = 0;
    }
    notifyListeners();
  }

  void reset() {
    stop(resetPosition: true);
    _stepIteration = 0;
    _noteInstanceCounter = 0;
  }

  void advance([int steps = 1]) {
    if (steps <= 0) {
      return;
    }
    for (var i = 0; i < steps; i++) {
      _advanceOneStep();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _playbackController.close();
    super.dispose();
  }

  void _scheduleTimer() {
    _timer?.cancel();
    final duration = stepDuration;
    _timer = Timer.periodic(duration, (_) => _advanceOneStep());
  }

  void _advanceOneStep() {
    if (_pattern.steps.isEmpty) {
      return;
    }

    final stepIndex = _currentStep;
    final step = _pattern.steps[stepIndex];
    _playbackController.add(
      StepSequencerPlaybackEvent(
        type: StepSequencerPlaybackEventType.step,
        stepIndex: stepIndex,
        step: step,
        iteration: _stepIteration,
      ),
    );

    final shouldRelease = _activeNote != null &&
        (!_isTieContinuation(step) || step.rest || step.note != _activeNote);

    if (shouldRelease) {
      _emitReleaseEvent(reasonIteration: _stepIteration);
    }

    if (!step.rest && step.note != null) {
      if (_isTieContinuation(step)) {
        // Keep holding the previous note without retriggering.
      } else {
        _activeNote = step.note;
        _activeNoteInstanceId = _nextInstanceId();
        _playbackController.add(
          StepSequencerPlaybackEvent(
            type: StepSequencerPlaybackEventType.noteOn,
            stepIndex: stepIndex,
            step: step,
            iteration: _stepIteration,
            note: step.note,
            velocity: step.velocity.clamp(0.0, 1.0),
            gate: step.gate,
            accent: step.accent,
            noteInstanceId: _activeNoteInstanceId,
          ),
        );
      }
    }

    _stepIteration = (_stepIteration + 1) & 0x7fffffff;
    if (_stepIteration == 0) {
      _stepIteration = 1;
    }

    _currentStep++;
    if (_currentStep >= _pattern.length) {
      if (_pattern.loop) {
        _currentStep = 0;
      } else {
        _currentStep = _pattern.length - 1;
        stop(resetPosition: false, emitRelease: false);
      }
    }

    notifyListeners();
  }

  bool _isTieContinuation(StepSequencerStep step) {
    return step.tie && _activeNote != null && step.note == _activeNote;
  }

  void _emitReleaseEvent({required int reasonIteration}) {
    if (_activeNote == null || _activeNoteInstanceId == null) {
      return;
    }
    final safeIndex =
        _currentStep.clamp(0, _pattern.length - 1).toInt();
    _playbackController.add(
      StepSequencerPlaybackEvent(
        type: StepSequencerPlaybackEventType.noteOff,
        stepIndex: safeIndex,
        step: _pattern.steps[safeIndex],
        iteration: reasonIteration,
        note: _activeNote,
        noteInstanceId: _activeNoteInstanceId,
      ),
    );
    _activeNote = null;
    _activeNoteInstanceId = null;
  }

  int _nextInstanceId() {
    _noteInstanceCounter = (_noteInstanceCounter + 1) & 0x7fffffff;
    if (_noteInstanceCounter == 0) {
      _noteInstanceCounter = 1;
    }
    return _noteInstanceCounter;
  }
}
