import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/step_sequencer.dart';

void main() {
  group('StepSequencer', () {
    test('emits note on/off events respecting ties and rests', () async {
      final sequencer = StepSequencer(
        pattern: StepSequencerPattern(
          steps: const <StepSequencerStep>[
            StepSequencerStep(note: 60, velocity: 0.8),
            StepSequencerStep(note: 60, tie: true),
            StepSequencerStep(rest: true),
            StepSequencerStep(note: 62, velocity: 0.5),
          ],
          stepsPerBeat: 4,
        ),
      );

      final events = <StepSequencerPlaybackEvent>[];
      final subscription = sequencer.playbackStream.listen(events.add);

      sequencer.advance();
      sequencer.advance();
      sequencer.advance();
      sequencer.advance();

      await subscription.cancel();

      final noteEvents = events
          .where((event) => event.type != StepSequencerPlaybackEventType.step)
          .toList(growable: false);
      expect(noteEvents, hasLength(3));
      expect(noteEvents[0].type, StepSequencerPlaybackEventType.noteOn);
      expect(noteEvents[0].note, 60);
      expect(noteEvents[1].type, StepSequencerPlaybackEventType.noteOff);
      expect(noteEvents[1].note, 60);
      expect(noteEvents[2].type, StepSequencerPlaybackEventType.noteOn);
      expect(noteEvents[2].note, 62);
      expect(noteEvents[1].noteInstanceId, noteEvents[0].noteInstanceId);
      sequencer.dispose();
    });

    test('stop emits a release event for the active note', () async {
      final sequencer = StepSequencer(
        pattern: StepSequencerPattern(
          steps: const <StepSequencerStep>[
            StepSequencerStep(note: 64, velocity: 0.6),
            StepSequencerStep(note: 64, tie: true),
          ],
        ),
      );

      final events = <StepSequencerPlaybackEvent>[];
      final subscription = sequencer.playbackStream.listen(events.add);

      sequencer.advance();
      sequencer.advance();

      expect(events.where((event) => event.isNoteOff), isEmpty);

      sequencer.stop();

      await subscription.cancel();

      final releases = events.where((event) => event.isNoteOff).toList();
      expect(releases, hasLength(1));
      expect(releases.single.note, 64);
      sequencer.dispose();
    });

    test('patterns serialise and restore expected values', () {
      const pattern = StepSequencerPattern(
        steps: <StepSequencerStep>[
          StepSequencerStep(
            note: 72,
            velocity: 0.75,
            gate: 0.5,
            accent: true,
            metadata: <String, dynamic>{'label': 'lead'},
          ),
          StepSequencerStep(rest: true),
        ],
        stepsPerBeat: 8,
        loop: false,
      );

      final json = pattern.toJson();
      final restored = StepSequencerPattern.fromJson(json);

      expect(restored.stepsPerBeat, 8);
      expect(restored.loop, isFalse);
      expect(restored.steps, hasLength(2));
      expect(restored.steps.first.note, 72);
      expect(restored.steps.first.velocity, closeTo(0.75, 1e-6));
      expect(restored.steps.first.gate, closeTo(0.5, 1e-6));
      expect(restored.steps.first.accent, isTrue);
      expect(restored.steps.first.metadata['label'], 'lead');
      expect(restored.steps.last.rest, isTrue);
    });
  });
}
