#!/usr/bin/env bash
set -euo pipefail

# Ensures Flutter/Dart tooling is available and fetches project dependencies.

if ! command -v flutter >/dev/null 2>&1; then
  cat <<'MSG' >&2
Flutter SDK not found.
Install Flutter from https://docs.flutter.dev/get-started/install and ensure the
`flutter` binary is on your PATH before running this script.
MSG
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  cat <<'MSG' >&2
Dart SDK not found.
Install Dart by installing Flutter (which bundles Dart) or from
https://dart.dev/get-dart and ensure the `dart` binary is on your PATH.
MSG
  exit 1
fi

flutter --version
flutter doctor

# Optionally enable additional platforms. Controlled by environment variables so
# CI or developers can opt out by exporting the value to 0.
if [[ "${ENABLE_FLUTTER_WEB:-1}" == "1" ]]; then
  flutter config --enable-web
fi

if [[ "${ENABLE_FLUTTER_DESKTOP:-1}" == "1" ]]; then
  flutter config --enable-windows-desktop || true
  flutter config --enable-macos-desktop || true
  flutter config --enable-linux-desktop || true
fi

flutter pub get

dart --version

echo "\nFlutter and Dart dependencies fetched successfully."
