import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/performance_recorder.dart';

void main() {
  group('PerformanceRecorder', () {
    test('records events with offsets and listeners', () {
      final clock = _ManualClock();
      final recorder = PerformanceRecorder(clock: clock.now);
      final observed = <PerformanceEvent>[];
      recorder.addListener(observed.add);

      recorder.start();
      clock.advance(const Duration(milliseconds: 120));
      recorder.recordNoteOn(note: 60, velocity: 0.8, voiceId: 1);
      clock.advance(const Duration(milliseconds: 80));
      recorder.recordParameterChange('filterCutoff', 4200);
      clock.advance(const Duration(milliseconds: 40));
      recorder.recordSetlistChange(cleared: true);
      clock.advance(const Duration(milliseconds: 60));

      final recording = recorder.stop();

      expect(recording.events, hasLength(3));
      expect(observed, hasLength(3));
      expect(recording.events.first.type, PerformanceEventType.noteOn);
      expect(recording.events.first.offset,
          const Duration(milliseconds: 120));
      expect(recording.events[1].type, PerformanceEventType.parameter);
      expect(recording.events[1].payload['parameter'], 'filterCutoff');
      expect(recording.events[1].offset,
          const Duration(milliseconds: 200));
      expect(recording.events.last.type, PerformanceEventType.setlist);
      expect(recording.events.last.payload['cleared'], isTrue);
      expect(recording.duration, const Duration(milliseconds: 300));
    });

    test('serializes and deserializes recordings', () {
      final event = PerformanceEvent(
        type: PerformanceEventType.parameter,
        offset: const Duration(milliseconds: 45),
        payload: const <String, dynamic>{
          'parameter': 'masterVolume',
          'value': 0.4,
        },
      );
      final recording = PerformanceRecording(
        startedAt: DateTime.utc(2024, 1, 1, 12, 30),
        duration: const Duration(seconds: 12),
        events: <PerformanceEvent>[event],
      );

      final json = recording.toJson();
      final roundTrip = PerformanceRecording.fromJson(json);

      expect(roundTrip.duration, recording.duration);
      expect(roundTrip.events, hasLength(1));
      expect(roundTrip.events.first.type, PerformanceEventType.parameter);
      expect(roundTrip.events.first.payload['parameter'], 'masterVolume');
      expect(roundTrip.events.first.offset, const Duration(milliseconds: 45));
    });
  });
}

class _ManualClock {
  DateTime _now = DateTime.fromMillisecondsSinceEpoch(0);

  DateTime now() => _now;

  void advance(Duration delta) {
    _now = _now.add(delta);
  }
}
