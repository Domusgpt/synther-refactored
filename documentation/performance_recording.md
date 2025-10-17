# Performance Recording Workflow

The performance recorder captures note events, parameter sweeps, macro updates,
transport changes, preset loads, and setlist transitions while the synth is
running. Recordings are exported as JSON so QA sessions, bug repro steps, or
future automation features can be reconstructed without screen captures.

## Attaching the Recorder

```dart
final engine = AudioEngine();
await engine.initialize();

final recorder = PerformanceRecorder();
engine.attachPerformanceRecorder(recorder);

recorder.start();
// play notes, tweak parameters, load presets …
final recording = recorder.stop();
print(recording.toJson());
```

`AudioEngine.attachPerformanceRecorder` accepts an optional `emitSnapshot`
argument. When `true` (the default) and the recorder is already running the
engine emits a full parameter snapshot and transport state immediately so
recordings start with deterministic context.

## Event Coverage

The recorder writes timestamped [`PerformanceEvent`](../lib/core/performance_recorder.dart)
objects that share a common schema:

- **`noteOn`** – payload: `note`, `velocity`, `voiceId`, optional `source`.
  Emitted whenever the engine allocates a voice. Stolen voices are released and
  logged immediately before the new note triggers.
- **`noteOff`** – payload: `note`, `voiceId`, optional `velocity` and `reason`.
  Fired for manual releases, voice stealing, polyphony trims, and engine
  disposal.
- **`parameter`** – payload: `parameter`, `value`. Recorded whenever
  `_updateParameter` applies a clamped value, including transport tempo/running
  changes and synth parameters updated via the bridge or macros.
- **`macro`** – payload: `macroId`, `value`, optional `resolved` map containing
  the concrete parameter updates produced by the macro sweep.
- **`preset`** – payload: optional `presetId`, `presetName`, and `snapshot`
  (canonical parameter map). Fired after `applyPreset` completes or permissive
  JSON is parsed via `loadPreset`.
- **`setlist`** – payload: optional `setlistId`, `entryId`, `presetId`,
  `presetName`, plus `cleared` when context resets. Captures setlist navigation
  and context clearing when presets diverge from the active slot.
- **`transport`** – payload: `tempo`, `running`, `numerator`, `denominator`,
  optional `positionBeats`. Mirrors transport panel interactions and backend
  updates.
- **`snapshot`** – payload: `parameters` plus optional preset/setlist metadata.
  Emitted automatically when attaching a recorder that is already running.
- **`custom`** – payload: at minimum `label`. Available for callers who invoke
  `recordCustom` with additional metadata.

All offsets are stored in microseconds relative to the time `start()` was
invoked. Use a custom clock in tests (see `test/performance_recorder_test.dart`)
to produce deterministic durations.

## JSON Round-Tripping

`PerformanceRecording.toJson()` yields the structure below. Each event can be
rebuilt via `PerformanceEvent.fromJson` for log playback or analytics.

```json
{
  "startedAt": "2024-01-01T12:30:00.000Z",
  "durationMicros": 1200000,
  "events": [
    {
      "type": "noteOn",
      "offsetMicros": 5000,
      "payload": {"note": 60, "velocity": 0.75, "voiceId": 1}
    },
    {
      "type": "parameter",
      "offsetMicros": 10500,
      "payload": {"parameter": "masterVolume", "value": 0.5}
    },
    {
      "type": "preset",
      "offsetMicros": 20000,
      "payload": {"presetId": "vaporwave-01", "presetName": "Vapor Skies"}
    }
  ]
}
```

## QA & Automation Tips

- Pair the recorder with the existing [UI snapshot tooling](ui_snapshots.md) to
  correlate PNG previews, tempo statistics, and parameter timelines in handoff
  reports.
- Store recordings alongside bug reports so another developer can recreate
  controller moves locally without screen sharing.
- Future work can consume `PerformanceRecording` instances to drive scripted UI
  demos or automated regression passes once a playback harness is added (see the
  handoff document for follow-up ideas).
