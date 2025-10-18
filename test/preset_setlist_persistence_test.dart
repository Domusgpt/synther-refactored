import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:synther_holographic_pro/core/preset_setlist.dart';
import 'package:synther_holographic_pro/utils/preset_setlist_persistence.dart';

void main() {
  group('PresetSetlistPersistence', () {
    late PresetSetlistLibrary library;

    setUp(() {
      library = PresetSetlistLibrary.instance;
      library.reset();
    });

    tearDown(() {
      library.reset();
    });

    test('save writes registered setlists to disk', () async {
      final tempDir = await Directory.systemTemp.createTemp('setlist_persistence');
      final persistence = PresetSetlistPersistence(
        library: library,
        storageDirectory: tempDir,
        fileName: 'state.json',
      );

      final setlist = PresetSetlist(
        id: 'custom-showcase',
        name: 'Custom Showcase',
        description: 'A bespoke vaporwave run.',
        entries: const <PresetSetlistEntry>[
          PresetSetlistEntry(id: 'slot-1', presetId: 'factory-glow-pad'),
        ],
      );
      library.register(setlist);

      await persistence.save();

      final file = File('${tempDir.path}/state.json');
      expect(await file.exists(), isTrue);
      final payload = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final setlists = payload['setlists'] as List<dynamic>;
      expect(setlists, isNotEmpty);
      expect(setlists.first['id'], 'custom-showcase');

      persistence.dispose();
      await tempDir.delete(recursive: true);
    });

    test('load merges persisted setlists into library', () async {
      final tempDir = await Directory.systemTemp.createTemp('setlist_persistence_load');
      final file = File('${tempDir.path}/state.json');
      await file.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'setlists': [
            {
              'id': 'tour-night',
              'name': 'Tour Night',
              'description': 'Evening showcase',
              'entries': [
                {
                  'id': 'slot-pad',
                  'presetId': 'factory-glow-pad',
                  'label': 'Opening pad',
                },
              ],
            },
          ],
        }),
      );

      final persistence = PresetSetlistPersistence(
        library: library,
        storageDirectory: tempDir,
        fileName: 'state.json',
      );

      await persistence.load();

      final setlist = library.findById('tour-night');
      expect(setlist, isNotNull);
      expect(setlist!.entries, isNotEmpty);
      expect(setlist.entries.first.label, 'Opening pad');

      persistence.dispose();
      await tempDir.delete(recursive: true);
    });
  });
}
