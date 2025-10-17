import 'dart:collection';

import 'parameter_definitions.dart';

/// Immutable configuration describing the synthesiser arpeggiator.
class ArpeggiatorSettings {
  const ArpeggiatorSettings({
    required this.enabled,
    required this.rate,
    required this.gate,
    required this.octaveSpan,
    required this.mode,
    required this.pattern,
    required this.swing,
    required this.latch,
    required this.tempoSync,
    required this.division,
    List<int>? heldNotes,
  }) : heldNotes = UnmodifiableListView(List<int>.from(heldNotes ?? const <int>[]));

  /// Whether the arpeggiator is currently active.
  final bool enabled;

  /// Steps per second. The engine clamps values to a musical range.
  final double rate;

  /// Proportion of the step spent with notes held (0–1).
  final double gate;

  /// Number of octaves cycled through (1–4 typical).
  final int octaveSpan;

  /// Playback direction for the generated pattern.
  final ArpeggiatorMode mode;

  /// Musical pattern applied to the held chord.
  final ArpeggiatorPattern pattern;

  /// Swing amount applied to alternate steps (0–1).
  final double swing;

  /// Whether the arpeggiator should latch when all keys are released.
  final bool latch;

  /// Whether the arpeggiator should follow the global tempo transport.
  final bool tempoSync;

  /// Division used to calculate steps when tempo sync is enabled.
  final ArpeggiatorDivision division;

  /// Snapshot of notes currently held by the arpeggiator.
  final UnmodifiableListView<int> heldNotes;

  ArpeggiatorSettings copyWith({
    bool? enabled,
    double? rate,
    double? gate,
    int? octaveSpan,
    ArpeggiatorMode? mode,
    ArpeggiatorPattern? pattern,
    double? swing,
    bool? latch,
    bool? tempoSync,
    ArpeggiatorDivision? division,
    List<int>? heldNotes,
  }) {
    return ArpeggiatorSettings(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      gate: gate ?? this.gate,
      octaveSpan: octaveSpan ?? this.octaveSpan,
      mode: mode ?? this.mode,
      pattern: pattern ?? this.pattern,
      swing: swing ?? this.swing,
      latch: latch ?? this.latch,
      tempoSync: tempoSync ?? this.tempoSync,
      division: division ?? this.division,
      heldNotes: heldNotes ?? this.heldNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'rate': rate,
      'gate': gate,
      'octaveSpan': octaveSpan,
      'mode': mode.name,
      'pattern': pattern.name,
      'swing': swing,
      'latch': latch,
      'tempoSync': tempoSync,
      'division': division.name,
      'heldNotes': heldNotes.toList(),
    };
  }

  factory ArpeggiatorSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return fallback;
    }

    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    ArpeggiatorMode parseMode(dynamic value) {
      if (value is String) {
        return ArpeggiatorMode.values.firstWhere(
          (mode) => mode.name == value,
          orElse: () => ArpeggiatorMode.up,
        );
      }
      if (value is num) {
        return ArpeggiatorMode.values
            .firstWhere((mode) => mode.value == value.toInt(), orElse: () => ArpeggiatorMode.up);
      }
      return ArpeggiatorMode.up;
    }

    ArpeggiatorPattern parsePattern(dynamic value) {
      if (value is String) {
        return ArpeggiatorPattern.values.firstWhere(
          (pattern) => pattern.name == value,
          orElse: () => ArpeggiatorPattern.asPlayed,
        );
      }
      if (value is num) {
        return ArpeggiatorPattern.values.firstWhere(
          (pattern) => pattern.value == value.toInt(),
          orElse: () => ArpeggiatorPattern.asPlayed,
        );
      }
      return ArpeggiatorPattern.asPlayed;
    }

    ArpeggiatorDivision parseDivision(dynamic value) {
      if (value is String) {
        final normalised = value.toLowerCase();
        return ArpeggiatorDivision.values.firstWhere(
          (division) =>
              division.name.toLowerCase() == normalised ||
              normalised == '${division.value}' ||
              normalised == divisionLabel(division),
          orElse: () => ArpeggiatorDivision.eighth,
        );
      }
      if (value is num) {
        final index = value.toInt().clamp(0, ArpeggiatorDivision.values.length - 1);
        return ArpeggiatorDivision.values[index];
      }
      return ArpeggiatorDivision.eighth;
    }

    final notesRaw = json['heldNotes'];
    final notes = <int>[];
    if (notesRaw is Iterable) {
      for (final value in notesRaw) {
        if (value is int) {
          notes.add(value);
        } else if (value is num) {
          notes.add(value.toInt());
        } else if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            notes.add(parsed);
          }
        }
      }
    }

    return ArpeggiatorSettings(
      enabled: parseBool(json['enabled'], false),
      rate: parseDouble(json['rate'], 8.0),
      gate: parseDouble(json['gate'], 0.6),
      octaveSpan: parseInt(json['octaveSpan'], 1).clamp(1, 4),
      mode: parseMode(json['mode'] ?? json['direction']),
      pattern: parsePattern(json['pattern']),
      swing: parseDouble(json['swing'], 0.0).clamp(0.0, 1.0),
      latch: parseBool(json['latch'], false),
      tempoSync: parseBool(json['tempoSync'] ?? json['sync'], false),
      division: parseDivision(json['division'] ?? json['rateDivision']),
      heldNotes: notes,
    );
  }

  /// Serialises the settings into parameter ids for backend hydration.
  Map<int, double> toParameterPayload() {
    return <int, double>{
      SynthParameterId.arpeggiatorEnabled: enabled ? 1.0 : 0.0,
      SynthParameterId.arpeggiatorRate: rate,
      SynthParameterId.arpeggiatorGate: gate,
      SynthParameterId.arpeggiatorOctaves: octaveSpan.toDouble(),
      SynthParameterId.arpeggiatorMode: mode.value.toDouble(),
      SynthParameterId.arpeggiatorPattern: pattern.value.toDouble(),
      SynthParameterId.arpeggiatorSwing: swing,
      SynthParameterId.arpeggiatorLatch: latch ? 1.0 : 0.0,
      SynthParameterId.arpeggiatorTempoSync: tempoSync ? 1.0 : 0.0,
      SynthParameterId.arpeggiatorDivision: division.value.toDouble(),
    };
  }
}

String divisionLabel(ArpeggiatorDivision division) {
  switch (division) {
    case ArpeggiatorDivision.whole:
      return '1/1';
    case ArpeggiatorDivision.half:
      return '1/2';
    case ArpeggiatorDivision.quarter:
      return '1/4';
    case ArpeggiatorDivision.eighth:
      return '1/8';
    case ArpeggiatorDivision.eighthTriplet:
      return '1/8T';
    case ArpeggiatorDivision.sixteenth:
      return '1/16';
    case ArpeggiatorDivision.sixteenthTriplet:
      return '1/16T';
    case ArpeggiatorDivision.thirtySecond:
      return '1/32';
  }
}
