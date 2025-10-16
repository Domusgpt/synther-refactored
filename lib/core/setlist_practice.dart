import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'preset_setlist.dart';
import 'tempo_transport.dart';

double _secondsPerBeatFor(double bpm) {
  return 60.0 / math.max(bpm, 0.0001);
}

@immutable
class SetlistPracticeOptions {
  const SetlistPracticeOptions({
    this.defaultCueBeats = 8.0,
    this.defaultEntryBeats = 32.0,
    this.countInBeats = 4.0,
    this.loop = true,
  }) : assert(defaultCueBeats >= 0.0),
       assert(defaultEntryBeats > 0.0),
       assert(countInBeats >= 0.0);

  final double defaultCueBeats;
  final double defaultEntryBeats;
  final double countInBeats;
  final bool loop;

  SetlistPracticeOptions copyWith({
    double? defaultCueBeats,
    double? defaultEntryBeats,
    double? countInBeats,
    bool? loop,
  }) {
    return SetlistPracticeOptions(
      defaultCueBeats: defaultCueBeats ?? this.defaultCueBeats,
      defaultEntryBeats: defaultEntryBeats ?? this.defaultEntryBeats,
      countInBeats: countInBeats ?? this.countInBeats,
      loop: loop ?? this.loop,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'defaultCueBeats': defaultCueBeats,
      'defaultEntryBeats': defaultEntryBeats,
      'countInBeats': countInBeats,
      'loop': loop,
    };
  }

  factory SetlistPracticeOptions.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return fallback;
    }

    double parseDouble(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return SetlistPracticeOptions(
      defaultCueBeats: math.max(0.0, parseDouble(json['defaultCueBeats'], 8.0)),
      defaultEntryBeats: math.max(
        0.0001,
        parseDouble(json['defaultEntryBeats'], 32.0),
      ),
      countInBeats: math.max(0.0, parseDouble(json['countInBeats'], 4.0)),
      loop: parseBool(json['loop'], true),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetlistPracticeOptions &&
        other.defaultCueBeats == defaultCueBeats &&
        other.defaultEntryBeats == defaultEntryBeats &&
        other.countInBeats == countInBeats &&
        other.loop == loop;
  }

  @override
  int get hashCode =>
      Object.hash(defaultCueBeats, defaultEntryBeats, countInBeats, loop);
}

@immutable
class SetlistPracticeSegment {
  const SetlistPracticeSegment({
    required this.entry,
    required this.index,
    required this.startBeat,
    required this.endBeat,
    required this.cueBeats,
    required this.secondsPerBeat,
    required this.beatsPerBar,
  });

  final PresetSetlistEntry entry;
  final int index;
  final double startBeat;
  final double endBeat;
  final double cueBeats;
  final double secondsPerBeat;
  final double beatsPerBar;

  double get cueStartBeat => math.max(0.0, startBeat - cueBeats);
  double get cueStartSeconds => cueStartBeat * secondsPerBeat;
  double get startSeconds => startBeat * secondsPerBeat;
  double get endSeconds => endBeat * secondsPerBeat;
  double get durationBeats => math.max(0.0, endBeat - startBeat);
  double get durationSeconds => durationBeats * secondsPerBeat;
  double get cueSeconds => cueBeats * secondsPerBeat;
  double get barCount =>
      beatsPerBar <= 0.0 ? durationBeats : durationBeats / beatsPerBar;

  Duration get cueDuration =>
      Duration(milliseconds: (cueSeconds * 1000).round());
  Duration get duration =>
      Duration(milliseconds: (durationSeconds * 1000).round());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'entryId': entry.id,
      'presetId': entry.presetId,
      'index': index,
      'startBeat': startBeat,
      'endBeat': endBeat,
      'cueBeats': cueBeats,
      'startSeconds': startSeconds,
      'endSeconds': endSeconds,
      'cueSeconds': cueSeconds,
      'durationBeats': durationBeats,
      'durationSeconds': durationSeconds,
      'bars': barCount,
    };
  }
}

@immutable
class SetlistPracticeSnapshot {
  const SetlistPracticeSnapshot({
    required this.setlistId,
    required this.totalEntries,
    required this.currentIndex,
    required this.loopCount,
    required this.options,
    required this.tempo,
    this.current,
    this.next,
    this.previous,
  });

  final String setlistId;
  final int totalEntries;
  final int currentIndex;
  final int loopCount;
  final SetlistPracticeOptions options;
  final TempoTransportSettings tempo;
  final SetlistPracticeSegment? current;
  final SetlistPracticeSegment? next;
  final SetlistPracticeSegment? previous;

  double get secondsPerBeat => _secondsPerBeatFor(tempo.bpm);
  double get countInSeconds => options.countInBeats * secondsPerBeat;
  Duration get countInDuration =>
      Duration(milliseconds: (countInSeconds * 1000).round());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'setlistId': setlistId,
      'totalEntries': totalEntries,
      'currentIndex': currentIndex,
      'loopCount': loopCount,
      'options': options.toJson(),
      'tempo': tempo.toJson(),
      'current': current?.toJson(),
      'next': next?.toJson(),
      'previous': previous?.toJson(),
      'countInSeconds': countInSeconds,
    };
  }
}

class SetlistPracticeController {
  SetlistPracticeController({
    required PresetSetlist setlist,
    required TempoTransportSettings tempo,
    SetlistPracticeOptions options = const SetlistPracticeOptions(),
    String? currentEntryId,
  }) : _setlist = setlist,
       _tempo = tempo,
       _options = options,
       _secondsPerBeat = _secondsPerBeatFor(tempo.bpm),
       _beatsPerBar = math.max(1.0, tempo.timeSignatureNumerator.toDouble()),
       _segments = _buildSegments(setlist, options),
       _currentIndex =
           _resolveIndex(setlist, currentEntryId) ??
           (setlist.entries.isEmpty ? -1 : 0),
       _loopCount = 0;

  PresetSetlist _setlist;
  TempoTransportSettings _tempo;
  SetlistPracticeOptions _options;
  double _secondsPerBeat;
  double _beatsPerBar;
  List<_SegmentBlueprint> _segments;
  int _currentIndex;
  int _loopCount;

  PresetSetlist get setlist => _setlist;
  SetlistPracticeOptions get options => _options;
  TempoTransportSettings get tempo => _tempo;
  int get loopCount => _loopCount;
  int get totalEntries => _segments.length;
  bool get isEmpty => _segments.isEmpty;

  int? get currentIndex => _currentIndex >= 0 ? _currentIndex : null;

  SetlistPracticeSegment? get currentSegment {
    if (_currentIndex < 0 || _currentIndex >= _segments.length) {
      return null;
    }
    return _materialise(_segments[_currentIndex]);
  }

  SetlistPracticeSegment? get nextSegment {
    if (_segments.isEmpty) {
      return null;
    }
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _segments.length) {
      return _materialise(_segments[nextIndex]);
    }
    if (!_options.loop || _segments.isEmpty) {
      return null;
    }
    return _materialise(_segments.first);
  }

  SetlistPracticeSegment? get previousSegment {
    if (_segments.isEmpty) {
      return null;
    }
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      return _materialise(_segments[prevIndex]);
    }
    if (!_options.loop || _segments.isEmpty) {
      return null;
    }
    return _materialise(_segments.last);
  }

  UnmodifiableListView<SetlistPracticeSegment> get timeline {
    return UnmodifiableListView<SetlistPracticeSegment>(
      _segments.map(_materialise).toList(growable: false),
    );
  }

  SetlistPracticeSnapshot snapshot() {
    return SetlistPracticeSnapshot(
      setlistId: _setlist.id,
      totalEntries: totalEntries,
      currentIndex: _currentIndex,
      loopCount: _loopCount,
      options: _options,
      tempo: _tempo,
      current: currentSegment,
      next: nextSegment,
      previous: previousSegment,
    );
  }

  bool advance() {
    if (_segments.isEmpty || _currentIndex < 0) {
      return false;
    }
    if (_segments.length == 1) {
      if (_options.loop) {
        _loopCount += 1;
        return true;
      }
      return false;
    }
    final nextIndex = _currentIndex + 1;
    if (nextIndex < _segments.length) {
      _currentIndex = nextIndex;
      return true;
    }
    if (!_options.loop) {
      return false;
    }
    _currentIndex = 0;
    _loopCount += 1;
    return true;
  }

  bool retreat() {
    if (_segments.isEmpty || _currentIndex < 0) {
      return false;
    }
    final prevIndex = _currentIndex - 1;
    if (prevIndex >= 0) {
      _currentIndex = prevIndex;
      return true;
    }
    if (!_options.loop) {
      return false;
    }
    _currentIndex = _segments.length - 1;
    if (_loopCount > 0) {
      _loopCount -= 1;
    }
    return true;
  }

  bool jumpToEntry(String entryId) {
    if (_segments.isEmpty) {
      return false;
    }
    final index = _segments.indexWhere(
      (segment) => segment.entry.id == entryId,
    );
    if (index == -1 || index == _currentIndex) {
      return false;
    }
    _currentIndex = index;
    return true;
  }

  void reset({String? entryId}) {
    _loopCount = 0;
    if (_segments.isEmpty) {
      _currentIndex = -1;
      return;
    }
    if (entryId != null && jumpToEntry(entryId)) {
      return;
    }
    _currentIndex = math.min(_currentIndex, _segments.length - 1);
    if (_currentIndex < 0) {
      _currentIndex = 0;
    }
  }

  void updateTempo(TempoTransportSettings tempo) {
    _tempo = tempo;
    _secondsPerBeat = _secondsPerBeatFor(tempo.bpm);
    _beatsPerBar = math.max(1.0, tempo.timeSignatureNumerator.toDouble());
  }

  void updateOptions(SetlistPracticeOptions options, {String? currentEntryId}) {
    if (options == _options && currentEntryId == null) {
      return;
    }
    _options = options;
    _rebuildSegments(preferredEntryId: currentEntryId);
  }

  void updateSetlist(PresetSetlist setlist, {String? currentEntryId}) {
    if (identical(setlist, _setlist)) {
      return;
    }
    _setlist = setlist;
    _rebuildSegments(preferredEntryId: currentEntryId);
  }

  void _rebuildSegments({String? preferredEntryId}) {
    final targetEntryId = preferredEntryId ?? currentSegment?.entry.id;
    _segments = _buildSegments(_setlist, _options);
    if (_segments.isEmpty) {
      _currentIndex = -1;
    } else {
      _currentIndex =
          _resolveIndex(_setlist, targetEntryId) ??
          math.min(_currentIndex, _segments.length - 1);
      if (_currentIndex < 0) {
        _currentIndex = 0;
      }
    }
    _loopCount = 0;
  }

  SetlistPracticeSegment _materialise(_SegmentBlueprint blueprint) {
    return SetlistPracticeSegment(
      entry: blueprint.entry,
      index: blueprint.index,
      startBeat: blueprint.startBeat,
      endBeat: blueprint.endBeat,
      cueBeats: blueprint.cueBeats,
      secondsPerBeat: _secondsPerBeat,
      beatsPerBar: _beatsPerBar,
    );
  }

  static List<_SegmentBlueprint> _buildSegments(
    PresetSetlist setlist,
    SetlistPracticeOptions options,
  ) {
    final segments = <_SegmentBlueprint>[];
    var cursor = 0.0;
    for (var i = 0; i < setlist.entries.length; i++) {
      final entry = setlist.entries[i];
      final lengthBeats = math.max(
        0.0001,
        entry.lengthBeats ?? options.defaultEntryBeats,
      );
      final cueBeats = math.max(0.0, entry.cueBeats ?? options.defaultCueBeats);
      final start = cursor;
      final end = start + lengthBeats;
      cursor = end;
      segments.add(
        _SegmentBlueprint(
          entry: entry,
          index: i,
          startBeat: start,
          endBeat: end,
          cueBeats: cueBeats,
        ),
      );
    }
    return segments;
  }

  static int? _resolveIndex(PresetSetlist setlist, String? entryId) {
    if (entryId == null) {
      if (setlist.entries.isEmpty) {
        return null;
      }
      return 0;
    }
    final index = setlist.entries.indexWhere(
      (candidate) => candidate.id == entryId,
    );
    if (index == -1) {
      return setlist.entries.isEmpty ? null : 0;
    }
    return index;
  }
}

class _SegmentBlueprint {
  const _SegmentBlueprint({
    required this.entry,
    required this.index,
    required this.startBeat,
    required this.endBeat,
    required this.cueBeats,
  });

  final PresetSetlistEntry entry;
  final int index;
  final double startBeat;
  final double endBeat;
  final double cueBeats;
}
