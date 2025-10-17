#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'MSG'
Usage: tool/package_release.sh [--android|--no-android] [--web|--no-web] [--mode <release|profile>] [--flutter-dir <path>]

Builds distributable artifacts for Android (APK) and the web by default. Wraps
`tool/build_artifact.sh` to ensure logs are captured and release outputs are
copied into `build/packages/` for easy sharing.

Options:
  --android / --no-android   Enable or disable the Android APK build (enabled by default)
  --web / --no-web           Enable or disable the web build (enabled by default)
  --mode <release|profile>   Build mode for supported targets (default: release)
  --flutter-dir <path>       Optional Flutter SDK directory to prepend to PATH
  -h, --help                 Show this message

Examples:
  tool/package_release.sh
  tool/package_release.sh --mode profile --no-web
  tool/package_release.sh --flutter-dir "$HOME/flutter"
MSG
}

ANDROID=1
WEB=1
MODE="release"
FLUTTER_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --android)
      ANDROID=1
      ;;
    --no-android)
      ANDROID=0
      ;;
    --web)
      WEB=1
      ;;
    --no-web)
      WEB=0
      ;;
    --mode)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --mode" >&2
        exit 1
      fi
      MODE="$2"
      shift
      case "$MODE" in
        release|profile)
          ;;
        *)
          echo "Unsupported mode: $MODE" >&2
          exit 1
          ;;
      esac
      ;;
    --flutter-dir)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --flutter-dir" >&2
        exit 1
      fi
      FLUTTER_DIR="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ -n "$FLUTTER_DIR" ]]; then
  if [[ ! -d "$FLUTTER_DIR" ]]; then
    echo "Provided Flutter directory does not exist: $FLUTTER_DIR" >&2
    exit 1
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Run tool/setup_dev_environment.sh first or supply --flutter-dir." >&2
  exit 1
fi

mkdir -p build/packages

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

if [[ $ANDROID -eq 1 ]]; then
  echo "[package_release] Building Android APK (${MODE})"
  tool/build_artifact.sh android-apk --${MODE}
  APK_SOURCE="build/app/outputs/flutter-apk/app-${MODE}.apk"
  if [[ ! -f "$APK_SOURCE" ]]; then
    # Fallback for legacy Flutter layout
    APK_SOURCE="build/app/outputs/apk/${MODE}/app-${MODE}.apk"
  fi
  if [[ ! -f "$APK_SOURCE" ]]; then
    echo "Could not find APK output after build. Check build logs." >&2
    exit 1
  fi
  APK_TARGET="build/packages/synther-${MODE}-${TIMESTAMP}.apk"
  cp "$APK_SOURCE" "$APK_TARGET"
  echo "[package_release] APK copied to $APK_TARGET"
fi

if [[ $WEB -eq 1 ]]; then
  echo "[package_release] Building web bundle (${MODE})"
  # flutter build web does not support debug. We map release/profile accordingly.
  case "$MODE" in
    release)
      tool/build_artifact.sh web --release
      ;;
    profile)
      tool/build_artifact.sh web --profile
      ;;
  esac
  WEB_SOURCE="build/web"
  if [[ ! -d "$WEB_SOURCE" ]]; then
    echo "Could not find web build output at $WEB_SOURCE" >&2
    exit 1
  fi
  WEB_ARCHIVE="build/packages/synther-web-${MODE}-${TIMESTAMP}.zip"
  echo "[package_release] Archiving web bundle to ${WEB_ARCHIVE}"
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import os
import zipfile

source = ${WEB_SOURCE!r}
archive = ${WEB_ARCHIVE!r}

with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(source):
        for name in files:
            path = os.path.join(root, name)
            rel = os.path.relpath(path, source)
            zf.write(path, rel)
PY
  else
    (cd "$WEB_SOURCE" && zip -r "../packages/$(basename "$WEB_ARCHIVE")" . >/dev/null)
  fi
  echo "[package_release] Web bundle archived to ${WEB_ARCHIVE}"
fi

echo "[package_release] Done. Inspect build_logs/ for verbose command output."
