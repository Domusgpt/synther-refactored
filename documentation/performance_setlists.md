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
  `notes`, an optional `cueBeats` marker that indicates when the slot should
  launch relative to the transport timeline, and an optional `lengthBeats`
  estimate that feeds the practice timeline (see below).
- `PresetSetlist` – groups a collection of entries together with metadata such as
  a human friendly `name`, optional `description`, author credits, and tags.

Both types expose `toJson`/`fromJson` helpers so setlists can be exported or
synchronised with external tooling.

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

## Practice Timeline & Cue Planning

Setlists now integrate with a dedicated practice timeline so you can rehearse or
run virtual sound-checks without a full UI workflow. The new pieces are:

- `SetlistPracticeOptions` (default values live in `lib/core/setlist_practice.dart`)
  control the default slot length (`defaultEntryBeats`), cue lead-ins
  (`defaultCueBeats`), a global count-in (`countInBeats`), and whether the
  timeline loops when the final slot finishes.
- `PresetSetlistEntry.lengthBeats` lets individual slots override the default
  duration estimate so the timeline reflects longer improvisations or shorter
  transition stabs.
- `AudioEngine.setlistPracticeSnapshot` exposes the current, previous, and next
  slots plus loop counts, timeline length, and tempo metadata for HUDs or custom
  tooling.
- `AudioEngine.setlistPracticeTimeline` returns the full timeline as
  `SetlistPracticeSegment` instances so UI layers can render progress meters or
  printable run sheets.
- Runtime helpers – `configureSetlistPractice`, `advanceSetlistPractice`,
  `retreatSetlistPractice`, and `resetSetlistPractice` – make it trivial to
  adjust defaults, iterate through slots, or rewind to the beginning of the set.
- Vaporwave interface helpers – the status HUD now includes a **Practice**
  button that opens `SetlistPracticePanel`, letting you edit defaults, inspect
  cue/duration metrics, and jump directly to any slot without leaving the main
  performance view.

Example:

```dart
engine.configureSetlistPractice(
  defaultEntryBeats: 24,
  defaultCueBeats: 8,
  loop: false,
);

await engine.loadSetlistEntry(
  setlistId: 'tour-leg-01',
  entryId: 'intro-pad',
);

print(engine.setlistPracticeSnapshot?.current?.entry.label); // Intro Glow
await engine.advanceSetlistPractice(); // Jump to the next slot & load its preset

for (final segment in engine.setlistPracticeTimeline) {
  debugPrint('${segment.entry.label}: ${segment.durationBeats} beats');
}
```

See `documentation/setlist_practice.md` for a deeper dive into the available
APIs, JSON helpers, and test utilities that ship with the timeline module.

## UI & Snapshot Integration

The vaporwave HUD was updated to surface the active setlist and entry next to the
transport metadata. This means QA snapshot captures and in-app previews both show
which slot is currently active, making it easier to verify scripted performances
or setlist changes.

## Future Enhancements

- Persist setlists (including practice options) to disk and reload them on
  launch.
- Add a dedicated setlist editor panel in the holographic UI for drag-and-drop
  reordering and quick cue adjustments.
- Integrate transport automation so cue markers can trigger automatically based
  on timeline playback.
- Surface the practice timeline inside the modulation/transport sheets so live
  performers can rehearse without leaving the app.
