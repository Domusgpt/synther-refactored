# Handoff Status

This document captures the latest synthesiser updates, outstanding follow-up
work, and tooling recommendations so the next engineer can pick up where this
iteration ended.

## Latest Changes

- Introduced a performance recorder (`lib/core/performance_recorder.dart`) and
  integrated it with `AudioEngine` so note events, parameter sweeps, transport
  changes, preset loads, and setlist transitions can be captured as JSON for QA.
  Added dedicated docs plus regression coverage in
  `test/performance_recorder_test.dart` and updated `test/audio_engine_test.dart`
  to verify engine integration.
- Added a transport-aware step sequencer (`lib/core/step_sequencer.dart`) that
  integrates with `AudioEngine` to emit backend note events, bridge metrics, and
  performance recorder snapshots. Authored the workflow guide and new coverage
  in `test/step_sequencer_test.dart` plus additional integration cases in
  `test/audio_engine_test.dart`.
- Added performance setlist support (`lib/core/preset_setlist.dart`) with a
  built-in vaporwave showcase library, JSON helpers, and reset hooks so curated
  run sheets can be registered, reordered, and exercised in tests.
- Extended the `AudioEngine` with setlist-aware helpers (`availableSetlists`,
  `loadSetlistEntry`, `clearSetlistContext`) and updated the HUD to surface the
  active setlist slot alongside tempo metadata.
- Introduced a registry-aware MIDI binding layer (`lib/core/midi_binding.dart`)
  that maps control change numbers to canonical parameters, exposes JSON helpers
  for saving layouts, and adds `AudioEngine.handleMidiControlChange` so bindings
  can drive the backend and bridge directly.
- Expanded regression coverage (`test/preset_setlist_test.dart`,
  `test/audio_engine_test.dart`) to cover the new library behaviours, engine
  integration, and setlist context resets.
- Introduced tempo/transport state (`lib/core/tempo_transport.dart`) to the
  engine, registry, and backend so BPM, play state, and time signature metadata
  synchronise across the bridge, presets, and visualiser metrics.
- Added arpeggiator tempo-sync controls (boolean + note division) with backend
  rate conversion, division parsing, preset capture/load support, and
  alias-aware parameter coercion.
- Refreshed the factory preset library with tempo metadata, sync-aware
  arpeggiator defaults, and documented transport controls so presets now round
  trip BPM/clock information.
- Introduced macro control surfaces (`lib/core/macro_controls.dart`) and wired
  them into `AudioEngine`, `SynthPreset`, and `AudioPresetLibrary` so presets can
  persist multi-parameter sweeps that reload alongside modulation routes.
- Documented the macro workflow (`documentation/macro_controls.md`) and added
  regression coverage (`test/macro_controls_test.dart`, updated
  `test/audio_engine_test.dart`) to lock in the new behaviour.
- Expanded regression coverage (`test/audio_engine_test.dart`,
  `test/basic_audio_backend_test.dart`, `test/parameter_registry_test.dart`)
  for transport setters, tempo-synchronised arpeggiator behaviour, and registry
  alias handling.
- Added a tempo transport control panel to the holographic UI so BPM, play
  state, and time signature can be tweaked live from the status HUD.
- Introduced UI snapshot tooling – the status HUD camera button captures PNG
  previews plus analytics, and `tool/capture_ui_snapshot.sh` generates
  reproducible widget snapshots for PRs and QA handoffs.
- Delivered a holographic step sequencer editor with per-step inspectors,
  pattern controls, and footer utilities so performers can sculpt patterns
  without leaving the vaporwave interface.
- Added a macro control panel that exposes sliders, assignment metadata, and
  reset helpers for every registered macro with direct audio engine bindings.
- Implemented setlist persistence with a new storage helper, integrated it into
  the audio engine/bootstrap flow, and shipped a setlist manager UI for
  creating, editing, and loading curated showcases.
- Delivered a holographic performance recorder panel so QA and performers can
  start, resume, and export recording sessions without touching code while
  monitoring live event payloads directly inside the vaporwave HUD.
- Added a release packaging helper (`tool/package_release.sh`) and a detailed
  [Release Checklist](documentation/release_checklist.md) so Android APK and web
  bundles can be generated, verified, and shared with a single scripted flow.

## Outstanding Opportunities

- **Modulation enhancements:** Extend the modulation panel with preset
  browsing, route search, and quick actions (e.g. duplicate, reorder) to
  streamline complex patch design.
- **Automation sources:** Only a few shorthand source names (e.g. `lfo1`,
  `expression`, `aftertouch`) are validated. Consider enumerating known sources
  or surfacing metadata so the UI can present available modulators.
- **Preset migrations:** Existing saved presets created before the modulation
  matrix feature won’t include routes. If you introduce migrations, ensure the
  loader gracefully upgrades older JSON blobs.
- **Audio backend parity:** The pure Dart backend records modulation analytics
  for the visualiser but does not drive a real DSP graph. Native backends should
  mirror the `ModulationMatrixCodec` contract when implemented.
- **External clocking:** Wire the tempo transport to MIDI clock/Ableton Link so
  tempo-synced presets follow host applications or hardware sequencers.
- **Transport automation:** Build automation lanes or sequencing tools for
  BPM/time-signature changes now that the core UI controls exist.
- **Step sequencer refinements:** Add drag reordering, velocity curves, and
  live preview playback inside the new editor.
- **MIDI capture:** The arpeggiator and performance controllers would benefit
  from MIDI clock/transport capture tooling for live sequencing once external
  sync is available.
- **Snapshot export integrations:** The in-app panel copies PNG/metadata to the
  clipboard. Adding OS share sheet hooks or direct disk export would streamline
  attaching captures to bug reports on mobile devices.
- **Setlist polish:** Introduce drag-and-drop slot ordering, quick audition
  shortcuts, and cloud sync/export for setlists now that persistence exists.
- **MIDI UX polish:** Expose a holographic MIDI learn workflow, editing panel,
  and preset-aware binding presets so performers can re-map hardware quickly.
- **High-resolution controllers:** Extend the binding manager with NRPN/14-bit
  CC handling and per-binding smoothing curves for endless encoders.
- **Macro UX polish:** Add HUD shortcuts, macro snapshots, and MIDI learn
  integration to streamline live tweaking from the new panel.
- **Macro sharing:** Add JSON import/export helpers for macro snapshots so
  presets generated by LLMs or collaborators can bundle expressive sweeps.
- **Performance playback:** Build a lightweight replayer that feeds captured
  `PerformanceRecording` timelines back into the engine for regression tests,
  automation demos, or live loopback previews inside the holographic UI.
- **Recorder exports:** Surface disk sharing/export hooks from the new panel so
  long takes can be archived outside the clipboard and attached to bug reports
  without relying on manual copy/paste.

## Tooling & Environment Notes

- The container environment currently lacks the Flutter/Dart SDK, so commands
  like `flutter test` or `dart test` cannot be executed here. Run
  `tool/setup_dev_environment.sh` to download a local SDK (or install Flutter
  3.19+ globally) before executing the full test suite.
- Use `tool/install_flutter_sdk.sh` if you want to prefetch/update the Flutter
  archive without running diagnostics.
- Add `melos` or `very_good_cli` if you plan to manage multiple packages or run
  lint/test pipelines from a single command.
- Consider installing `dart fix --apply` and `flutter analyze` hooks in CI to
  keep the growing codebase tidy, especially now that modulation routing adds
  richer JSON surface areas.
- For authoring presets or modulation tables, tools like [Open Stage Control](https://openstagecontrol.ammd.net/)
  or the `ctrlr` panel editor can speed up MIDI/controller exploration before
  encoding routes into JSON.
- Install MIDI monitoring utilities (e.g. `MIDI Monitor` on macOS, `MIDI-OX`
  on Windows, `aseqdump`/`kmidimon` on Linux) to verify controller data when
  testing bindings alongside the new manager.
- Install a lightweight BPM tap tool or MIDI clock generator (e.g. `mididings`
  or Ableton Link) when developing the arpeggiator so rate/gate behaviour can be
  verified against external clocks.
- Capture deterministic UI previews with `tool/capture_ui_snapshot.sh` when
  reviewing layout tweaks or before sharing PRs – the script writes PNGs and
  metadata to `build/ui_snapshots/` so reviewers can sanity check without
  running the app.

## Quick Start for the Next Engineer

1. Run `tool/setup_dev_environment.sh` to download/activate Flutter, pull
   dependencies, and enable web/desktop targets if needed.
2. Execute `flutter test` locally to exercise the expanded regression suite.
3. Explore the modulation matrix by calling `AudioEngine.setModulationRoute` in
   integration tests or the debug console and inspect the visualiser metrics via
   `AudioEngine.getVisualizerData()`.
4. Experiment with the step sequencer by updating patterns through
   `AudioEngine.updateStepSequencerPattern` and monitoring `sequencerStepIndex`
   in `AudioEngine.getVisualizerData()`.
5. Extend the UI or preset authoring tools to write to
   `ModulationMatrixCodec.encodeBridgeKey(source, destination)` so audio, UI, and
   visualiser layers stay synchronised.

