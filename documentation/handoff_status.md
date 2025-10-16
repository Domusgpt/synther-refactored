# Handoff Status

This document captures the latest synthesiser updates, outstanding follow-up
work, and tooling recommendations so the next engineer can pick up where this
iteration ended.

## Latest Changes

- Added performance setlist support (`lib/core/preset_setlist.dart`) with a
  built-in vaporwave showcase library, JSON helpers, and reset hooks so curated
  run sheets can be registered, reordered, and exercised in tests.
- Extended the `AudioEngine` with setlist-aware helpers (`availableSetlists`,
  `loadSetlistEntry`, `clearSetlistContext`) and updated the HUD to surface the
  active setlist slot alongside tempo metadata.
- Added a rehearsal-ready practice timeline (`lib/core/setlist_practice.dart`)
  with configurable cue/count-in defaults, per-slot `lengthBeats` overrides,
  and engine helpers (`setlistPracticeSnapshot`, `configureSetlistPractice`,
  `advanceSetlistPractice`, etc.) so testers can iterate through setlists or run
  virtual sound-checks without custom glue code.
- Introduced a holographic practice panel (`lib/ui/setlist_practice_panel.dart`)
  wired into the status HUD so rehearsal defaults, loop settings, and slot
  navigation can be managed directly in-app alongside the modulation and
  transport sheets.
- Expanded regression coverage (`test/preset_setlist_test.dart`,
  `test/audio_engine_test.dart`) to cover the new library behaviours, engine
  integration, setlist context resets, and practice timeline looping/defaults.
- Authored dedicated unit tests for the practice controller
  (`test/setlist_practice_test.dart`) validating options JSON, tempo updates,
  loop handling, and timeline generation.
- Introduced tempo/transport state (`lib/core/tempo_transport.dart`) to the
  engine, registry, and backend so BPM, play state, and time signature metadata
  synchronise across the bridge, presets, and visualiser metrics.
- Added arpeggiator tempo-sync controls (boolean + note division) with backend
  rate conversion, division parsing, preset capture/load support, and
  alias-aware parameter coercion.
- Refreshed the factory preset library with tempo metadata, sync-aware
  arpeggiator defaults, and documented transport controls so presets now round
  trip BPM/clock information.
- Expanded regression coverage (`test/audio_engine_test.dart`,
  `test/basic_audio_backend_test.dart`, `test/parameter_registry_test.dart`)
  for transport setters, tempo-synchronised arpeggiator behaviour, and registry
  alias handling.
- Added a tempo transport control panel to the holographic UI so BPM, play
  state, and time signature can be tweaked live from the status HUD.
- Introduced UI snapshot tooling – the status HUD camera button captures PNG
  previews plus analytics, and `tool/capture_ui_snapshot.sh` generates
  reproducible widget snapshots for PRs and QA handoffs.

## Outstanding Opportunities

- **UI enhancements:** Extend the modulation panel with preset browsing, route
  search, and quick actions (e.g. duplicate, reorder) to streamline complex
  patch design.
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
- **MIDI capture:** The arpeggiator and performance controllers would benefit
  from MIDI clock/transport capture tooling for live sequencing once external
  sync is available.
- **Snapshot export integrations:** The in-app panel copies PNG/metadata to the
  clipboard. Adding OS share sheet hooks or direct disk export would streamline
  attaching captures to bug reports on mobile devices.
- **Setlist persistence/UI:** Persist curated setlists to disk (JSON or cloud
  sync) and add a holographic editor for drag-and-drop slot ordering, cue
  editing, and quick auditioning directly from the app.
- **Practice UX:** Extend the new practice sheet with metronome previews,
  slot-specific overrides, and MIDI/footswitch bindings, then persist
  per-setlist `SetlistPracticeOptions` so rehearsal defaults survive app
  restarts.

## Tooling & Environment Notes

- `tool/setup_dev_environment.sh` bootstraps Flutter automatically when it is
  missing (downloading to `.tooling/flutter` by default), validates the toolchain
  with `flutter doctor`, and fetches project dependencies. Run it before the test
  suite if you do not have a global Flutter install.
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
4. Extend the UI or preset authoring tools to write to
   `ModulationMatrixCodec.encodeBridgeKey(source, destination)` so audio, UI, and
   visualiser layers stay synchronised.

