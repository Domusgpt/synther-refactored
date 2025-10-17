# Android APK Agent Playbook

This guide distills the Android packaging workflow into a short, deterministic
checklist optimised for AI assistants such as Claude. Follow the sequence below
whenever you need to produce an installable APK from this repository.

## Quick Facts

- **Goal:** Generate an Android APK that can be sideloaded for testing or
  distribution.
- **Primary helper:** `tool/prepare_android_apk.sh` orchestrates toolchain
  setup, dependency resolution, and the build step.
- **Outputs:** An APK written to `build/app/outputs/flutter-apk/` (e.g.
  `app-release.apk`).

## Prerequisites

1. Linux, macOS, or Windows environment with `bash`, `curl`, `tar`, and `python3`
   available (identical to the requirements for the existing setup script).
2. Sufficient disk space (~3.5 GB) for the Flutter SDK download if one is not
   already present.
3. Android SDK components and device drivers if you plan to install the APK on a
   physical device. (Not strictly required for the build step itself.)

## Claude-Friendly Checklist

1. **Clone or fetch the repository** (if not already available):
   ```bash
   git clone https://github.com/<your-org>/synther-refactored.git
   cd synther-refactored
   ```
2. **Run the preparation script** – it will download Flutter (if needed), fetch
   dependencies, and trigger the APK build in one pass:
   ```bash
   tool/prepare_android_apk.sh --release
   ```
   - Use `--debug` or `--profile` instead of `--release` if you require those
     variants.
   - The script delegates to `tool/setup_dev_environment.sh` and
     `tool/build_artifact.sh` so all existing logging and configuration hooks
     remain available.
3. **Capture the output path** – the script prints the absolute location of the
   generated APK. Surface this path in the assistant’s response so a human can
   download or transfer the file immediately.
4. **(Optional) Verify build metadata** – if the environment includes the
   Android SDK tools, you can confirm the package details using `aapt dump badging`:
   ```bash
   ${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools/*/aapt dump badging \
     build/app/outputs/flutter-apk/app-release.apk | head
   ```
5. **Hand-off instructions** – remind the recipient to sideload the APK on a
   device or share it through their chosen distribution channel.

## Script Behaviour Notes

- `tool/prepare_android_apk.sh` is idempotent. Re-running it keeps the local
  Flutter SDK up to date and rebuilds the APK with the latest source changes.
- Build logs are stored under `build_logs/` via `tool/build_artifact.sh`. Use
  these logs to diagnose failures.
- The script echoes a warning and exits with a non-zero status if it cannot find
  the generated APK. Assistants should treat a non-zero exit as a failure and
  report the captured log path for follow-up.

## When Manual Steps Are Required

- **Signing for Play Store distribution:** configure `android/key.properties` and
  update `android/app/build.gradle` with the release signing config before
  running the script. The helper still produces the signed APK once these files
  exist.
- **Custom build flavours:** pass additional Gradle definitions via the
  `FLUTTER_BUILD_ARGS` environment variable before invoking the script. Example:
  ```bash
  FLUTTER_BUILD_ARGS="--flavor staging -t lib/main_staging.dart" \
    tool/prepare_android_apk.sh --release
  ```
- **Continuous integration:** call the script from CI to ensure a deterministic
  setup + build sequence without replicating the step-by-step logic in the CI
  configuration.

Following this playbook keeps APK generation repeatable and easy to delegate to
an agent, while still exposing the lower-level tooling when you need to customise
or debug the build process.
