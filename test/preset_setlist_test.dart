import 'package:test/test.dart';

import 'package:synther_holographic_pro/core/preset_setlist.dart';

void main() {
  group('PresetSetlistEntry', () {
    test('serialises to and from json', () {
      const entry = PresetSetlistEntry(
        id: 'slot-1',
        presetId: 'factory-glow-pad',
        label: 'Intro Pad',
        notes: 'Fade in with expression pedal',
        cueBeats: 16,
      );

      final restored = PresetSetlistEntry.fromJson(entry.toJson());

      expect(restored.id, entry.id);
      expect(restored.presetId, entry.presetId);
      expect(restored.label, entry.label);
      expect(restored.notes, entry.notes);
      expect(restored.cueBeats, entry.cueBeats);
    });
  });

  group('PresetSetlist', () {
    test('supports reordering entries', () {
      const entries = <PresetSetlistEntry>[
        PresetSetlistEntry(id: 'a', presetId: 'one'),
        PresetSetlistEntry(id: 'b', presetId: 'two'),
        PresetSetlistEntry(id: 'c', presetId: 'three'),
      ];
      const setlist = PresetSetlist(id: 'demo', name: 'Demo', entries: entries);

      final moved = setlist.moveEntry('c', 1);

      expect(moved.entries.map((e) => e.id), ['a', 'c', 'b']);
    });
  });

  group('PresetSetlistLibrary', () {
    final library = PresetSetlistLibrary.instance;

    setUp(() {
      library.reset();
    });

    test('registers and finds setlists', () {
      const setlist = PresetSetlist(
        id: 'performance',
        name: 'Performance',
        entries: [
          PresetSetlistEntry(id: 'slot', presetId: 'factory-glow-pad'),
        ],
      );

      library.register(setlist);

      expect(library.findById('performance')?.name, 'Performance');
      expect(library.allSetlists.length, 1);
    });

    test('ensures built-in vaporwave showcase setlist', () {
      library.ensureBuiltInSetlists();

      final setlists = library.allSetlists;
      expect(setlists, isNotEmpty);
      final showcase = setlists.firstWhere(
        (candidate) => candidate.id == 'factory-vaporwave-showcase',
      );
      expect(showcase.entries.length, 4);
    });

    test('updating entries preserves order', () {
      const initial = PresetSetlist(
        id: 'performance',
        name: 'Performance',
        entries: [
          PresetSetlistEntry(id: 'intro', presetId: 'factory-glow-pad'),
        ],
      );
      library.register(initial);

      library.upsertEntry(
        'performance',
        const PresetSetlistEntry(
          id: 'intro',
          presetId: 'factory-glow-pad',
          label: 'Updated Intro',
        ),
      );

      final result = library.findById('performance');
      expect(result?.entries.first.label, 'Updated Intro');
    });

    test('reset clears registry and built-ins flag', () {
      library.ensureBuiltInSetlists();
      expect(library.allSetlists, isNotEmpty);

      library.reset();

      expect(library.allSetlists, isEmpty);
      library.ensureBuiltInSetlists();
      expect(library.allSetlists, isNotEmpty);
    });
  });
}
