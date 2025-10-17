# Distribution & Playability Guide

This project is built with Flutter and a pure Dart audio backend, so you can run
and ship the synthesiser on every platform that Flutter supports. The tables and
sections below summarise the supported targets, the typical use-cases, and the
commands you need to build or launch the app for each platform.

## Platform Overview

| Target            | How you play it                                           | Build / Run Command Examples                          | Notes |
| ----------------- | --------------------------------------------------------- | ----------------------------------------------------- | ----- |
| Android (phones & tablets) | Install an APK or publish to the Play Store.            | `flutter run -d android` (debug),<br>`flutter build apk --release` | Requires Android SDK & signing config for release uploads. |
| iOS (iPhone & iPad)        | Install via TestFlight/Ad Hoc build or through the App Store. | `flutter run -d ios`,<br>`flutter build ipa`                      | Needs Xcode on macOS and an Apple Developer account for distribution. |
| Web (Chrome / Edge / Safari / Firefox) | Host as a static site (e.g. GitHub Pages, Firebase Hosting) or run locally in a browser. | `flutter run -d chrome`,<br>`flutter run -d web-server --web-port 8080`,<br>`flutter build web` | The generated `build/web` directory can be deployed to any static host. |
| Windows / macOS / Linux desktop | Ship native desktop binaries for live performance setups. | `flutter run -d windows` / `macos` / `linux`,<br>`flutter build windows` / `macos` / `linux` | Desktop builds require the respective native toolchains enabled in Flutter. |

The existing Flutter UI works across all of these targets because the audio
engine is written entirely in Dart and does not rely on platform-specific
plugins.

## Android Deployment

1. **Enable Android toolchain**: Install Android Studio (or the command-line SDK
   tools) and accept the Android licenses via `flutter doctor --android-licenses`.
2. **Debug on device/emulator**: Connect a device with USB debugging enabled or
   start an emulator, then run:

   ```bash
   flutter run -d android
   ```

   Hot reload works in this mode, so you can tweak UI controls and hear the
   updated sound design instantly.
3. **Generate a release APK**: Prepare a signing keystore, configure
   `android/key.properties`, and run:

   ```bash
   flutter build apk --release
   ```

   The signed APK lives at `build/app/outputs/apk/release/app-release.apk` and
   can be sideloaded onto devices or submitted to the Play Store (after the
   usual Play Console steps).

   > **Shortcut:** Run `tool/prepare_android_apk.sh --release` to perform the
   > toolchain setup and release build in one command. The helper prints the
   > generated APK path when finished.

## Web Deployment

1. **Enable the web renderer (one-time)**:

   ```bash
   flutter config --enable-web
   ```

2. **Run locally in Chrome**:

   ```bash
   flutter run -d chrome
   ```

   This spins up a local dev server with hot reload. You can also expose the
   app over your LAN using the web-server device:

   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
   ```

3. **Build for static hosting**:

   ```bash
   flutter build web --release
   ```

   Deploy the generated `build/web` directory to any static hosting provider
   (GitHub Pages, Netlify, Firebase Hosting, etc.). The pure Dart audio backend
   runs inside the browser without extra plugins.

## Desktop Deployment

1. **Enable the desired desktop targets** (one-time):

   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter config --enable-linux-desktop
   ```

2. **Install native build tools**: follow the [Flutter desktop install
   guide](https://docs.flutter.dev/desktop) to install Visual Studio (Windows),
   Xcode (macOS), or the required Linux dependencies.

3. **Run and build**:

   ```bash
   flutter run -d windows   # or macos / linux
   flutter build windows    # produces build/windows/runner/Release/
   ```

   Desktop builds are great for studio setups where you want MIDI controllers,
   larger touchscreens, or to integrate with DAWs via virtual audio cables.

## iOS Deployment

1. **Set up the toolchain**: Install Xcode and the iOS SDK on macOS. Ensure
   `flutter doctor` reports no pending iOS issues.
2. **Run on simulator or device**:

   ```bash
   flutter run -d ios
   ```

3. **Archive for TestFlight/App Store**:

   ```bash
   flutter build ipa
   ```

   This produces an `.ipa` archive for distribution. Use Xcode’s Organizer or
   `xcrun altool`/`transportctl` to upload the package to App Store Connect.

## Automation Helpers

Use the updated `tool/setup_dev_environment.sh` to download a local Flutter SDK
when necessary, validate tooling, and fetch packages. For scripted builds, the
`tool/build_artifact.sh` helper provides a thin wrapper around the common Flutter
build commands and keeps logs under the `build_logs/` directory for inspection.

## Next Steps

- Connect a MIDI keyboard or use on-screen controls to trigger notes in any of
  the supported builds.
- Customise `lib/core/audio_preset_library.dart` or load captured presets to
  craft performance-ready patches before exporting builds for the stage or web.
- Combine with Flutter’s plugin ecosystem (e.g. `midi` or WebMIDI for browsers)
  if you need external controller support.

With these workflows you can rehearse locally with hot reload, publish APKs or
desktop binaries for live shows, or host the synthesiser as a web experience
that anyone can launch from their browser.
