import 'parameter_definitions.dart';

/// Immutable snapshot of the global tempo/transport state.
class TempoTransportSettings {
  const TempoTransportSettings({
    this.bpm = 120.0,
    this.running = true,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.positionBeats = 0.0,
  });

  /// Tempo in beats per minute used when tempo-sync features are enabled.
  final double bpm;

  /// Whether the transport is actively advancing.
  final bool running;

  /// Time signature numerator (beats per bar).
  final int timeSignatureNumerator;

  /// Time signature denominator (note value representing one beat).
  final int timeSignatureDenominator;

  /// Current position within the song in beats.
  final double positionBeats;

  TempoTransportSettings copyWith({
    double? bpm,
    bool? running,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    double? positionBeats,
  }) {
    return TempoTransportSettings(
      bpm: bpm ?? this.bpm,
      running: running ?? this.running,
      timeSignatureNumerator: timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator:
          timeSignatureDenominator ?? this.timeSignatureDenominator,
      positionBeats: positionBeats ?? this.positionBeats,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bpm': bpm,
      'running': running,
      'timeSignatureNumerator': timeSignatureNumerator,
      'timeSignatureDenominator': timeSignatureDenominator,
      'positionBeats': positionBeats,
    };
  }

  factory TempoTransportSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalised = value.toLowerCase();
        return normalised == 'true' || normalised == '1' || normalised == 'yes';
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

    return TempoTransportSettings(
      bpm: parseDouble(json['bpm'], 120.0),
      running: parseBool(json['running'], true),
      timeSignatureNumerator: parseInt(json['timeSignatureNumerator'] ?? json['tsNum'], 4)
          .clamp(1, 12),
      timeSignatureDenominator:
          parseInt(json['timeSignatureDenominator'] ?? json['tsDen'], 4)
              .clamp(1, 16),
      positionBeats: parseDouble(json['positionBeats'], 0.0),
    );
  }

  /// Converts the tempo/transport state to backend parameter payload values.
  Map<int, double> toParameterPayload() {
    return <int, double>{
      SynthParameterId.transportTempo: bpm,
      SynthParameterId.transportRunning: running ? 1.0 : 0.0,
      SynthParameterId.transportTimeSignatureNumerator:
          timeSignatureNumerator.toDouble(),
      SynthParameterId.transportTimeSignatureDenominator:
          timeSignatureDenominator.toDouble(),
    };
  }
}
