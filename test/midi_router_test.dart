import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/midi_router.dart';
import 'package:synther_holographic_pro/core/parameter_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MidiRouter', () {
    test('dispatches note on/off events for the configured channel', () {
      var noteOnCount = 0;
      var noteOffCount = 0;
      double? lastVelocity;

      final router = MidiRouter(
        onNoteOn: (note, velocity) {
          expect(note, 64);
          noteOnCount++;
          lastVelocity = velocity;
        },
        onNoteOff: (note) {
          expect(note, 64);
          noteOffCount++;
        },
        onParameter: (_, __) {},
        onPitchBend: (_) {},
      );

      router.listenToChannel(1);
      router.handleMessage(<int>[0x91, 64, 100]); // Channel 1 note on
      router.handleMessage(<int>[0x81, 64, 0]); // Channel 1 note off
      router.handleMessage(<int>[0x92, 62, 127]); // Ignored (channel 2)

      expect(noteOnCount, 1);
      expect(noteOffCount, 1);
      expect(lastVelocity, closeTo(100 / 127.0, 1e-9));
    });

    test('maps control change values to parameter ranges', () {
      String? lastParameter;
      double? lastValue;
      final registry = ParameterRegistry.instance;

      final router = MidiRouter(
        onNoteOn: (_, __) {},
        onNoteOff: (_) {},
        onParameter: (parameter, value) {
          lastParameter = parameter;
          lastValue = value;
        },
        onPitchBend: (_) {},
      );

      router.bindControllerToParameter(controller: 74, parameter: 'filterCutoff');
      router.handleMessage(<int>[0xB0, 74, 64]);

      final descriptor = registry.descriptorFor('filterCutoff');
      expect(lastParameter, 'filterCutoff');
      expect(
        lastValue,
        closeTo(
          descriptor!.range.denormalize(64 / 127.0),
          1e-9,
        ),
      );
    });

    test('normalises pitch bend messages to the -1..1 range', () {
      final captured = <double>[];
      final router = MidiRouter(
        onNoteOn: (_, __) {},
        onNoteOff: (_) {},
        onParameter: (_, __) {},
        onPitchBend: (value) {
          captured.add(value);
        },
      );

      router.handleMessage(<int>[0xE0, 0x00, 0x40]);
      router.handleMessage(<int>[0xE0, 0x7F, 0x7F]);
      router.handleMessage(<int>[0xE0, 0x00, 0x00]);

      expect(captured.length, 3);
      expect(captured[0], closeTo(0.0, 1e-9));
      expect(captured[1], closeTo(0.9999, 1e-4));
      expect(captured[2], closeTo(-1.0, 1e-9));
    });
  });
}
