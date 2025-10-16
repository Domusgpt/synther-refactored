import 'dart:async';

import 'parameter_models.dart';
import 'parameter_registry.dart';

typedef MidiNoteOnCallback = void Function(int note, double velocity);
typedef MidiNoteOffCallback = void Function(int note);
typedef MidiPitchBendCallback = void Function(double normalizedAmount);
typedef MidiParameterCallback = FutureOr<void> Function(
    String parameter, double value);

class MidiControlBinding {
  const MidiControlBinding({
    required this.controller,
    required this.parameter,
    this.minValue,
    this.maxValue,
    this.curve,
  })  : assert(controller >= 0 && controller <= 127,
            'controller must be between 0 and 127'),
        assert(parameter.isNotEmpty, 'parameter name must not be empty');

  final int controller;
  final String parameter;
  final double? minValue;
  final double? maxValue;
  final ParameterCurve? curve;
}

class MidiRouter {
  MidiRouter({
    required MidiNoteOnCallback onNoteOn,
    required MidiNoteOffCallback onNoteOff,
    required MidiParameterCallback onParameter,
    required MidiPitchBendCallback onPitchBend,
    ParameterRegistry? parameterRegistry,
  })  : _onNoteOn = onNoteOn,
        _onNoteOff = onNoteOff,
        _onParameter = onParameter,
        _onPitchBend = onPitchBend,
        _parameterRegistry = parameterRegistry ?? ParameterRegistry.instance;

  final MidiNoteOnCallback _onNoteOn;
  final MidiNoteOffCallback _onNoteOff;
  final MidiParameterCallback _onParameter;
  final MidiPitchBendCallback _onPitchBend;
  final ParameterRegistry _parameterRegistry;

  final Map<int, _ResolvedMidiBinding> _bindings =
      <int, _ResolvedMidiBinding>{};

  int? _channel;

  int? get channel => _channel;

  set channel(int? value) {
    if (value == null) {
      _channel = null;
      return;
    }

    if (value < 0 || value > 15) {
      throw ArgumentError.value(value, 'channel', 'must be between 0 and 15');
    }

    _channel = value;
  }

  void listenToChannel(int? value) => channel = value;

  void bindControl(MidiControlBinding binding) {
    final canonical = _parameterRegistry.canonicalName(binding.parameter) ??
        binding.parameter;
    final descriptor = _parameterRegistry.descriptorFor(canonical);

    _bindings[binding.controller] = _ResolvedMidiBinding(
      controller: binding.controller,
      parameter: canonical,
      descriptorRange: descriptor?.range,
      overrideMin: binding.minValue,
      overrideMax: binding.maxValue,
      overrideCurve: binding.curve,
    );
  }

  void bindControllerToParameter({
    required int controller,
    required String parameter,
    double? minValue,
    double? maxValue,
    ParameterCurve? curve,
  }) {
    bindControl(
      MidiControlBinding(
        controller: controller,
        parameter: parameter,
        minValue: minValue,
        maxValue: maxValue,
        curve: curve,
      ),
    );
  }

  void unbindControl(int controller) {
    _bindings.remove(controller);
  }

  void clearBindings() {
    _bindings.clear();
  }

  void handleMessage(List<int> data) {
    if (data.isEmpty) {
      return;
    }

    final status = data[0];
    if (status < 0x80) {
      return; // Running status is not handled.
    }

    if (status >= 0xF0) {
      return; // Ignore system messages.
    }

    final messageType = status & 0xF0;
    final messageChannel = status & 0x0F;
    final targetChannel = _channel;
    if (targetChannel != null && messageChannel != targetChannel) {
      return;
    }

    switch (messageType) {
      case 0x80: // Note off
        if (data.length < 2) {
          return;
        }
        _onNoteOff(data[1] & 0x7F);
        break;
      case 0x90: // Note on
        if (data.length < 3) {
          return;
        }
        final note = data[1] & 0x7F;
        final velocity = data[2] & 0x7F;
        if (velocity == 0) {
          _onNoteOff(note);
        } else {
          _onNoteOn(note, velocity / 127.0);
        }
        break;
      case 0xB0: // Control change
        if (data.length < 3) {
          return;
        }
        final controller = data[1] & 0x7F;
        final value = data[2] & 0x7F;
        final binding = _bindings[controller];
        if (binding == null) {
          return;
        }

        final mapped = binding.map(value);
        final result = _onParameter(binding.parameter, mapped);
        if (result is Future<void>) {
          unawaited(result);
        }
        break;
      case 0xE0: // Pitch bend
        if (data.length < 3) {
          return;
        }
        final lsb = data[1] & 0x7F;
        final msb = data[2] & 0x7F;
        final value14 = (msb << 7) | lsb;
        final normalized = ((value14 - 8192) / 8192.0)
            .clamp(-1.0, 1.0)
            .toDouble();
        _onPitchBend(normalized);
        break;
      default:
        break;
    }
  }
}

class _ResolvedMidiBinding {
  _ResolvedMidiBinding({
    required this.controller,
    required this.parameter,
    required this.descriptorRange,
    this.overrideMin,
    this.overrideMax,
    this.overrideCurve,
  });

  final int controller;
  final String parameter;
  final ParameterRange? descriptorRange;
  final double? overrideMin;
  final double? overrideMax;
  final ParameterCurve? overrideCurve;

  double map(int rawValue) {
    final normalized = rawValue.clamp(0, 127) / 127.0;
    final range = descriptorRange;
    final min = overrideMin ?? range?.min ?? 0.0;
    final max = overrideMax ?? range?.max ?? 1.0;
    final curve = overrideCurve ?? range?.curve ?? ParameterCurve.linear;
    final mappingRange = ParameterRange(
      min: min,
      max: max,
      defaultValue: (min + max) * 0.5,
      curve: curve,
    );
    return mappingRange.denormalize(normalized);
  }
}
