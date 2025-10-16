import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/preset_setlist.dart';
import 'package:synther_holographic_pro/core/setlist_practice.dart';
import 'package:synther_holographic_pro/core/tempo_transport.dart';

void main() {
  group('SetlistPracticeOptions', () {
    test('serialises to and from json', () {
      const options = SetlistPracticeOptions(
        defaultCueBeats: 6,
        defaultEntryBeats: 24,
        countInBeats: 3,
        loop: false,
      );

      final restored = SetlistPracticeOptions.fromJson(options.toJson());

      expect(restored, options);
      expect(restored.loop, isFalse);
      expect(restored.defaultEntryBeats, 24);
    });
  });

  group('SetlistPracticeController', () {
    const setlist = PresetSetlist(
      id: 'demo',
      name: 'Demo',
      entries: [
        PresetSetlistEntry(
          id: 'slot-1',
          presetId: 'one',
          cueBeats: 2,
          lengthBeats: 8,
        ),
        PresetSetlistEntry(id: 'slot-2', presetId: 'two', cueBeats: 3),
      ],
    );

    test('builds timeline with defaults and entry overrides', () {
      final controller = SetlistPracticeController(
        setlist: setlist,
        tempo: const TempoTransportSettings(
          bpm: 120,
          timeSignatureNumerator: 3,
          timeSignatureDenominator: 4,
        ),
        options: const SetlistPracticeOptions(
          defaultEntryBeats: 12,
          defaultCueBeats: 4,
        ),
      );

      final timeline = controller.timeline;
      expect(timeline.length, 2);
      expect(timeline.first.entry.id, 'slot-1');
      expect(timeline.first.durationBeats, 8);
      expect(timeline[1].durationBeats, 12);
      expect(timeline.first.cueBeats, 2);
      expect(timeline[1].cueBeats, 4);
      expect(timeline.first.barCount, closeTo(8 / 3, 0.0001));

      final snapshot = controller.snapshot();
      expect(snapshot.current?.entry.id, 'slot-1');
      expect(snapshot.next?.entry.id, 'slot-2');
      expect(snapshot.countInSeconds, closeTo(4 * 0.5, 0.0001));

      expect(controller.advance(), isTrue);
      expect(controller.currentSegment?.entry.id, 'slot-2');
      expect(controller.advance(), isTrue);
      expect(controller.currentSegment?.entry.id, 'slot-1');
      expect(controller.loopCount, 1);
    });

    test('updates tempo and options while preserving current entry', () {
      final controller = SetlistPracticeController(
        setlist: setlist,
        tempo: const TempoTransportSettings(
          bpm: 100,
          timeSignatureNumerator: 4,
        ),
        options: const SetlistPracticeOptions(
          defaultEntryBeats: 8,
          defaultCueBeats: 2,
        ),
        currentEntryId: 'slot-2',
      );

      controller.updateTempo(
        const TempoTransportSettings(bpm: 90, timeSignatureNumerator: 5),
      );

      var snapshot = controller.snapshot();
      expect(snapshot.tempo.bpm, 90);
      expect(snapshot.current?.entry.id, 'slot-2');

      controller.updateOptions(
        const SetlistPracticeOptions(defaultEntryBeats: 16, defaultCueBeats: 1),
        currentEntryId: 'slot-2',
      );

      final timeline = controller.timeline;
      expect(timeline[1].durationBeats, 16);
      expect(timeline[1].cueBeats, 3);
      expect(controller.currentSegment?.entry.id, 'slot-2');

      controller.reset(entryId: 'slot-1');
      expect(controller.currentSegment?.entry.id, 'slot-1');
      expect(controller.loopCount, 0);

      snapshot = controller.snapshot();
      expect(snapshot.previous, isNull);
      expect(snapshot.next?.entry.id, 'slot-2');
    });

    test('handles empty setlists without crashing', () {
      const emptySetlist = PresetSetlist(
        id: 'empty',
        name: 'Empty',
        entries: <PresetSetlistEntry>[],
      );

      final controller = SetlistPracticeController(
        setlist: emptySetlist,
        tempo: const TempoTransportSettings(bpm: 120),
      );

      expect(controller.isEmpty, isTrue);
      expect(controller.currentSegment, isNull);
      expect(controller.advance(), isFalse);
      expect(controller.retreat(), isFalse);

      controller.reset();
      final snapshot = controller.snapshot();
      expect(snapshot.totalEntries, 0);
      expect(snapshot.current, isNull);
    });

    test('single-slot timelines respect loop configuration', () {
      const singleSetlist = PresetSetlist(
        id: 'solo',
        name: 'Solo',
        entries: <PresetSetlistEntry>[
          PresetSetlistEntry(id: 'slot-1', presetId: 'alpha'),
        ],
      );

      final controller = SetlistPracticeController(
        setlist: singleSetlist,
        tempo: const TempoTransportSettings(bpm: 100),
        options: const SetlistPracticeOptions(loop: false),
      );

      expect(controller.advance(), isFalse);
      expect(controller.loopCount, 0);

      controller.updateOptions(const SetlistPracticeOptions(loop: true));
      expect(controller.advance(), isTrue);
      expect(controller.loopCount, 1);

      controller.updateTempo(const TempoTransportSettings(bpm: 80));
      final segment = controller.currentSegment;
      expect(segment, isNotNull);
      expect(segment!.durationSeconds, closeTo(segment.durationBeats * 60 / 80, 0.0001));
    });
  });
}
