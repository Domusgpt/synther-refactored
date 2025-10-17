# Performance Setlists

This guide explains how to build and consume performance setlists with the
`PresetSetlistLibrary` module that ships with the refactored audio engine. The
feature lets you curate run sheets, annotate cues, and drive the `AudioEngine`
with showtime context so the holographic status HUD always surfaces the current
preset and slot information during a performance.

## Data Model

Setlists live in `lib/core/preset_setlist.dart` and are composed of two immutable
structures:

- `PresetSetlistEntry` – describes a slot inside the setlist. Each entry stores a
  stable `id`, the `presetId` it should trigger, optional performer `label` and
  `notes`, plus an optional `cueBeats` marker that indicates when the slot should
  launch relative to the transport timeline.
- `PresetSetlist` – groups a collection of entries together with metadata such as
  a human friendly `name`, optional `description`, author credits, and tags.

Both types expose `toJson`/`fromJson` helpers so setlists can be exported or
synchronised with external tooling.

## Persistence

`PresetSetlistPersistence` listens to the library and serialises the current
state to disk. Instantiate it during app startup:

```dart
final engine = AudioEngine();
final persistence = PresetSetlistPersistence(
  library: PresetSetlistLibrary.instance,
);
engine.attachSetlistPersistence(persistence, load: true);
```

By default the helper writes `user_setlists.json` under `build/state/`. You can
override the storage directory and filename when constructing the persistence
instance. On load it seeds built-in showcases, merges any saved setlists, and
debounces future writes for efficient updates.

## Registering Setlists

The `PresetSetlistLibrary` singleton mirrors the preset library API and keeps all
setlists in memory. Registering a new run sheet is as simple as creating a
`PresetSetlist` and calling `register`:

```dart
final library = PresetSetlistLibrary.instance;

library.register(
  PresetSetlist(
    id: 'tour-leg-01',
    name: 'Tour – Leg 01',
    entries: const [
      PresetSetlistEntry(
        id: 'intro-pad',
        presetId: 'factory-glow-pad',
        label: 'Intro Glow',
        notes: 'Hold chords, swell expression pedal at bar 9',
        cueBeats: 0,
      ),
      PresetSetlistEntry(
        id: 'lead',
        presetId: 'factory-laser-pluck',
        label: 'Laser Lead',
        cueBeats: 64,
      ),
    ],
  ),
);
```

The library ships with a `factory-vaporwave-showcase` demo setlist that features
all built-in presets. Calling `ensureBuiltInSetlists()` registers the showcase the
first time it is needed.

Use `upsertEntry`, `removeEntry`, and `moveEntry` to maintain existing setlists,
and `reset()` to clear the registry (helpful for unit tests or when loading from
external storage).

## Driving the Audio Engine

The `AudioEngine` now exposes several helpers for showtime workflows:

- `availableSetlists` – returns all registered setlists (automatically seeding
  the factory showcase) for use in UI pickers or automation scripts.
- `loadSetlistEntry` – applies the preset referenced by a setlist slot while
  tracking the active setlist/entry context.
- `clearSetlistContext` – clears the active setlist metadata while leaving the
  currently loaded preset untouched. This is useful when improvising between
  programmed slots.

```dart
final engine = AudioEngine();
await engine.initialize();

await engine.loadSetlistEntry(
  setlistId: 'tour-leg-01',
  entryId: 'intro-pad',
);

// The status HUD now shows "TOUR – LEG 01 · INTRO GLOW"
print(engine.activeSetlist?.name);
print(engine.activeSetlistEntry?.label);
```

Loading a preset manually via `loadPresetById` or `applyPreset` will clear the
setlist context so the HUD accurately reflects that you are in "Free Play" mode.

## UI & Snapshot Integration

The vaporwave HUD surfaces the active setlist and entry next to the transport
metadata so QA snapshot captures and in-app previews always show the current cue.

Launch the **SETLISTS** panel from the status HUD to access the holographic
manager:

- Browse all registered setlists, duplicate or rename custom run sheets, and
  delete entries that no longer apply.
- Edit slots inline – update labels/notes, change presets, tweak cue markers,
  and reorder entries using the move controls.
- Clear or trigger cues directly from the panel; the audio engine keeps the HUD
  and bridge metrics aligned with each change.

## Future Enhancements

- Drag-and-drop slot ordering, copy/paste cues, and batch note editing inside the
  manager panel.
- Cloud sync, JSON export/import, or project-level versioning for curated
  performances.
- Integrate transport automation so cue markers can trigger automatically based
  on timeline playback.
