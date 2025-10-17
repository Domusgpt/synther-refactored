# Performance Recording Workflow

The audio engine now emits high-level events whenever important actions occur
(parameter updates, note on/off events, preset transitions, and setlist swaps).
The new `PerformanceRecorder` listens to those events and captures them with
relative timing information so QA sessions, creative takes, or automated tests
can be reproduced later.

## Subscribing to Engine Events

```dart
final engine = AudioEngine();
await engine.initialize();

engine.addEventListener((event) {
  debugPrint('Event: ' + event.type.name + ' ' + event.toJson().toString());
});
```

The `AudioEngineEvent` payload includes the canonical parameter ID, note number,
voice identifier, preset/setlist identifiers, and a timestamp. Consumers can use
this feed directly (e.g. to drive analytics dashboards) without starting a
recording session.

## Capturing Performances

```dart
final recorder = PerformanceRecorder();
recorder.attach(engine);

recorder.startRecording(label: 'Evening Jam');
// ...perform tweaks or play notes...
final recording = recorder.stopRecording();
```

Each `PerformanceRecordEvent` stores the elapsed time since `startRecording`
alongside the raw `AudioEngineEvent` payload. The resulting
`PerformanceRecording` exposes the events as an immutable list and can be
serialised to JSON for storage or tooling integration:

```dart
final json = recording.toJson();
```

## Workflow Tips

- Use the optional `clock` argument when constructing a `PerformanceRecorder`
  during tests so you can inject deterministic timestamps.
- Attach a recorder per engine instance. Calling `attach` automatically detaches
  any previous engine to avoid duplicate subscriptions.
- Call `clear()` between takes if you want to discard buffered events without
  stopping an in-progress recording.
- Future enhancements can use the captured timelines to drive automation lanes,
  export CSV/JSON reports, or power a “performance playback” mode in the UI.
