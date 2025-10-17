# UI Snapshot & QA Workflow

The holographic interface now ships with built-in snapshot tooling so you can
capture the current UI, tempo transport status, and visualiser analytics for QA
handoff notes or bug triage.

## In-App Snapshot Panel

1. Launch the synth (`flutter run`).
2. Tap the **camera icon** inside the Status HUD (top-right) to capture the
   current holographic interface.
3. A sheet appears with:
   - A PNG preview of the captured UI.
   - High level stats (preset, tempo, transport state, polyphony usage).
   - Highlighted analytics (performance energy, modulation energy, granular
     motion, transport position).
   - A toggle to inspect the raw visualiser metric table.
   - A “Copy JSON & image payload” button that copies the snapshot metadata and
     base64-encoded PNG. Paste this into bug reports or design docs.

If the boundary is not ready yet (e.g. immediately after opening the app), the
HUD surfaces a snack bar asking you to try again.

## Scripted Snapshots for CI & Handoff

Use the helper script to produce deterministic widget screenshots without a
running device or emulator:

```bash
./tool/capture_ui_snapshot.sh
```

The script ensures the Flutter SDK is available, then executes the
`test/ui_snapshotter_test.dart` widget test with `--update-goldens`. The test
pumps the full `VaporwaveInterface`, renders it with the fake webview platform
stub used for widget tests, captures the root repaint boundary, and writes a PNG
into `build/ui_snapshots/vaporwave_interface.png` (or a custom directory defined
via `--dart-define=SNAPSHOT_OUTPUT_DIR=/tmp/synther-snaps`).

These files are ideal for attaching to pull requests or validating that UI
regressions have not occurred when tweaking themes and layouts.

## Tips

- The PNG bytes copied from the panel include metadata, so you can decode the
  payload quickly with `jq` or any JSON viewer.
- When recording video walkthroughs, capture a snapshot before and after your
  tweak to highlight the delta using the metrics table.
- Integrate the script into CI to publish the latest UI preview as a build
  artifact for reviewers.
