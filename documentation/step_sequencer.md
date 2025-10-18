# Step Sequencer Workflow

The step sequencer provides a lightweight phrase programmer that lives entirely
in Dart. Patterns describe per-step notes, velocities, ties, rests, accents, and
metadata. The `AudioEngine` subscribes to sequencer playback events and routes
triggered notes through the shared voice allocator, backend, parameter bridge,
visualiser metrics, and performance recorder.

## Core Types

- [`StepSequencerStep`](../lib/core/step_sequencer.dart) – immutable description
  of a single step. Steps may specify a `note` (MIDI number), normalised
  `velocity`, `gate`, `tie`, `rest`, optional `accent`, and arbitrary
  `metadata`.
- [`StepSequencerPattern`](../lib/core/step_sequencer.dart) – ordered list of
  steps with `stepsPerBeat` and `loop` semantics. Patterns expose
  `toJson()/fromJson` for sharing presets or storing curated grooves.
- [`StepSequencer`](../lib/core/step_sequencer.dart) – mutable runtime that owns
  playback state, timers (optional), and a broadcast
  `playbackStream` emitting [`StepSequencerPlaybackEvent`](../lib/core/step_sequencer.dart)
  instances for step changes, note-on, and note-off transitions.

## Updating Patterns

```dart
final engine = AudioEngine();
await engine.initialize();

await engine.setTransportRunning(0); // Pause playback before editing.
engine.updateStepSequencerPattern(
  StepSequencerPattern(
    steps: const <StepSequencerStep>[
      StepSequencerStep(note: 60, velocity: 0.7),
      StepSequencerStep(note: 60, tie: true),
      StepSequencerStep(rest: true),
      StepSequencerStep(note: 62, velocity: 0.5, accent: true),
    ],
  ),
);

engine.stepSequencer.advance(); // Manually audition the first step.
```

`AudioEngine.updateStepSequencerPattern` replaces the active pattern and notifies
listeners. If the transport is running the sequencer restarts on the next tick;
otherwise you can audition steps manually via `advance()`.

## Holographic Editor

The vaporwave interface now ships with a dedicated **Step Sequencer** panel.
Open the status HUD and tap **SEQUENCER** to launch it. The editor provides:

- **Pattern metadata toolbar** – adjust length, steps per beat, and looping
  behaviour with instant feedback in the engine.
- **Per-step tiles** – tap any step to open the detail sheet where you can tweak
  note targets, velocity, gate proportion, ties, rests, and accents. Quick
  icons toggle rests, ties, and accents inline.
- **Footer utilities** – append new steps, duplicate entire patterns, reset
  content, or apply changes while keeping transport playback synchronised.

All edits call `AudioEngine.updateStepSequencerPattern`, so bridge metrics,
presets, and the performance recorder see the same data as manual API updates.

## Runtime Integration

The engine exposes its sequencer via `engine.stepSequencer`. Playback events are
consumed internally to drive:

- **Voice allocation** – events flow through `VoiceAllocator`, voice stealing
  logic, and `_backend.noteOn/off` just like manual note events.
- **Performance recorder** – sequencer-driven notes are logged with
  `source: 'sequencer'` (note-on) and `reason: 'sequencer'` (note-off) so QA
  timelines capture groove automation.
- **Bridge & visualiser metrics** – `_collectState()` and
  `getVisualizerData()` include `sequencerStepIndex` and `sequencerRunning`
  values, enabling HUD widgets or holographic overlays to reflect playback.
- **Transport coupling** – `setTransportTempo` updates the sequencer BPM and
  `setTransportRunning` starts/stops playback while releasing any held voices.

If you need a custom sequencer implementation (e.g. for a dedicated UI panel),
call `engine.attachStepSequencer(customSequencer, takeOwnership: true)` to swap
runtimes. The engine stops and disposes the previous instance (when owned),
subscribes to the replacement stream, and aligns it with the current transport
state.

## Testing Hooks

The sequencer broadcasts events synchronously, making it easy to test without
waiting for timers. See `test/step_sequencer_test.dart` for pattern/tie coverage
and `test/audio_engine_test.dart` for full engine integration scenarios.

```
final events = <StepSequencerPlaybackEvent>[];
final sub = engine.stepSequencer.playbackStream.listen(events.add);
engine.stepSequencer.advance();
await sub.cancel();
```

## Future Enhancements

- Drag-and-drop step reordering and multi-step selection inside the editor.
- Velocity curves, probability lanes, and modulation destinations per step.
- External clock support (MIDI clock, Ableton Link) leveraging the existing
  transport hooks.
- Parameterised gate handling (currently informational) once a DSP backend is
  available.
