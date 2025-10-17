import 'dart:math' as math;

/// Describes the response curve used when normalising synthesiser parameters.
enum ParameterCurve {
  linear,
  exponential,
  logarithmic,
}

/// Defines the valid range, default value, and curve metadata for a parameter.
class ParameterRange {
  const ParameterRange({
    required this.min,
    required this.max,
    required this.defaultValue,
    this.curve = ParameterCurve.linear,
  }) : assert(min <= max, 'ParameterRange min must be <= max');

  final double min;
  final double max;
  final double defaultValue;
  final ParameterCurve curve;

  /// Clamps [value] to the allowed range.
  double clamp(double value) {
    return value.clamp(min, max).toDouble();
  }

  /// Maps [value] into the normalised 0-1 domain applying the configured curve.
  double normalize(double value) {
    final clamped = clamp(value);
    final normalized = (clamped - min) / (max - min);

    switch (curve) {
      case ParameterCurve.linear:
        return normalized;
      case ParameterCurve.exponential:
        return normalized * normalized;
      case ParameterCurve.logarithmic:
        if (normalized <= 0) {
          return 0;
        }
        return math.log(normalized * 9 + 1) / math.log(10);
    }
  }

  /// Converts [normalized] from 0-1 back to the real value domain.
  double denormalize(double normalized) {
    double curved;

    switch (curve) {
      case ParameterCurve.linear:
        final clamped = normalized.clamp(0.0, 1.0).toDouble();
        curved = clamped;
        break;
      case ParameterCurve.exponential:
        final clamped = normalized.clamp(0.0, 1.0).toDouble();
        curved = math.sqrt(clamped);
        break;
      case ParameterCurve.logarithmic:
        final clamped = normalized.clamp(0.0, 1.0).toDouble();
        if (clamped <= 0) {
          curved = 0;
        } else {
          final powValue = math.pow(10, clamped) as num;
          curved = ((powValue - 1) / 9).toDouble();
        }
        break;
    }

    return min + curved * (max - min);
  }
}
