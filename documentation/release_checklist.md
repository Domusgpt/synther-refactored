# Release Checklist

This checklist captures the recommended steps to produce verified Android APK and
web builds of Synther Refactored. It assumes you have followed the development
setup guide so a Flutter SDK is available either globally or via the local
`.tooling/flutter` directory.

## 1. Prepare the Environment

1. Run the setup helper to ensure dependencies are installed and targets are
   enabled. This downloads Flutter when missing and runs `flutter doctor`:

   ```bash
   tool/setup_dev_environment.sh
   ```

2. If you manage your own Flutter installation, export the SDK path for this
   session instead:

   ```bash
   export PATH="$HOME/flutter/bin:$PATH"
   flutter doctor
   flutter pub get
   ```

3. Review the regression suite locally:

   ```bash
   flutter test
   ```

## 2. Bump Version Metadata

1. Update the application version in `pubspec.yaml` if you are preparing a new
   public build. Flutter uses the format `major.minor.patch+build`.
2. Update the changelog or handoff report (`documentation/handoff_status.md`) so
   the build history is traceable.

## 3. Package Release Artifacts

Use the packaging helper to produce both the Android APK and the web bundle with
one command. Release mode is the default:

```bash
tool/package_release.sh
```

- The script delegates to `tool/build_artifact.sh`, stores verbose logs under
  `build_logs/`, and copies the generated APK and zipped web bundle into
  `build/packages/` with timestamped filenames.
- To build with a custom Flutter installation, point the helper at your SDK:

  ```bash
  tool/package_release.sh --flutter-dir "$HOME/flutter"
  ```

- To skip either target or switch to profile builds:

  ```bash
  tool/package_release.sh --no-web
  tool/package_release.sh --mode profile
  ```

After the script completes you will find:

- `build/packages/synther-release-<timestamp>.apk`
- `build/packages/synther-web-release-<timestamp>.zip`

## 4. Verify the Android APK

1. Install the generated APK on a device or emulator:

   ```bash
   flutter install --use-application-binary build/packages/synther-release-<timestamp>.apk
   ```

2. Launch the app and verify:
   - Audio engine controls respond as expected.
   - Modulation, macro, transport, sequencer, and setlist panels open from the
     HUD and display the latest presets.
   - Snapshot capture continues to generate PNG previews.

## 5. Verify the Web Build

1. Unzip the web archive into a staging directory and run a static server:

   ```bash
   unzip build/packages/synther-web-release-<timestamp>.zip -d build/web_staging
   cd build/web_staging
   python3 -m http.server 8080
   ```

2. Visit `http://localhost:8080` in Chrome (or another Flutter-supported
   browser) and validate the same checklist as the Android build.
3. Deploy the contents of `build/web_staging/web-*/` to your hosting provider
   (GitHub Pages, Firebase Hosting, Netlify, etc.).

## 6. Archive and Share

- Attach the APK and web zip to your release notes or upload them to your
  distribution platform.
- Capture UI snapshots (`tool/capture_ui_snapshot.sh`) and include the PNGs in
  QA reports or release announcements.
- Update `documentation/handoff_status.md` with any known issues encountered
  during verification.

Following this flow ensures every release bundles the latest regression-tested
features across both mobile and web delivery targets.
