# Practice Timeline & Rehearsal Guide

The practice timeline extends performance setlists with rehearsal-friendly
helpers that live entirely in Dart. It lets you plan cue lead-ins, rehearse slots
without bespoke scripts, and surface upcoming entries in the vaporwave HUD.

## Core Building Blocks

- `PresetSetlistEntry.lengthBeats` (optional) captures the expected duration of a
  slot in beats. Entries without a value fall back to the defaults described
  below.
- `SetlistPracticeOptions` (see `lib/core/setlist_practice.dart`) controls the
  global rehearsal defaults:
  - `defaultEntryBeats` – duration applied to entries without their own
    `lengthBeats` override.
  - `defaultCueBeats` – per-slot lead-in used when a `cueBeats` value is not
    provided.
  - `countInBeats` – global count-in before the first slot starts.
  - `loop` – whether the timeline wraps around after the final slot.
- `SetlistPracticeController` – immutable timeline definitions live here. The
  controller exposes convenience getters (`currentSegment`, `nextSegment`,
  `timeline`, etc.), handles advance/retreat/reset logic, and keeps tempo/time
  signature metadata in sync with `TempoTransportSettings`.

## Audio Engine Integration

`AudioEngine` wires the practice controller directly into the existing setlist
APIs:

- `setlistPracticeSnapshot` – returns a `SetlistPracticeSnapshot` describing the
  current slot, neighbours, loop count, and tempo metadata. Useful for HUDs or
  status overlays.
- `setlistPracticeTimeline` – exposes an `UnmodifiableListView` of
  `SetlistPracticeSegment` instances so you can render progress meters, printable
  run sheets, or analytics dashboards.
- `configureSetlistPractice` – overrides the global defaults (`defaultEntryBeats`,
  `defaultCueBeats`, `countInBeats`, `loop`) at runtime. The engine preserves the
  active entry where possible and rebuilds the timeline when defaults change.
- `advanceSetlistPractice` / `retreatSetlistPractice` – step through the setlist
  programmatically. Pass `loadPreset: true` (the default) to apply the next/previous
  preset automatically, or `false` to simply move the rehearsal cursor.
- `resetSetlistPractice` – rewind to the active slot and clear the loop counter
  without disturbing the loaded preset.

Loading a setlist entry automatically initialises the practice controller; manual
preset loads clear the setlist context (and therefore the timeline) just like
before.

The vaporwave HUD exposes a dedicated **Practice** bottom sheet (implemented in
`lib/ui/setlist_practice_panel.dart`) that binds to these APIs. Use it to tweak
defaults, monitor cue/duration metrics, and jump directly to any slot in the
active setlist during rehearsal.

## Example

```dart
await engine.loadSetlistEntry(
  setlistId: 'tour-leg-01',
  entryId: 'intro-pad',
);

final snapshot = engine.setlistPracticeSnapshot;
debugPrint('Current slot: ${snapshot?.current?.entry.label}');

engine.configureSetlistPractice(defaultEntryBeats: 32, loop: false);

await engine.advanceSetlistPractice();

for (final segment in engine.setlistPracticeTimeline) {
  debugPrint('${segment.entry.label} starts at beat ${segment.startBeat}');
}
```

## Testing & Tooling

- `test/setlist_practice_test.dart` covers the controller’s JSON helpers,
  tempo/option updates, looping, and timeline generation.
- `test/audio_engine_test.dart` exercises the engine wrappers, ensuring
  snapshots/timelines update as presets advance and that loop defaults behave as
  expected.
- Use `engine.setlistPracticeSnapshot?.toJson()` when debugging UI integrations –
  the payload mirrors what the HUD consumes.

## Future Enhancements

- Expand the practice sheet with metronome previews, slot-specific overrides,
  and footswitch/MIDI bindings for hands-free advance/retreat.
- Persist per-setlist `SetlistPracticeOptions` so rehearsal defaults survive app
  restarts.
