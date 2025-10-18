#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'MSG'
Usage: tool/build_artifact.sh <platform> [--release|--debug]

Builds the Flutter project for the requested platform and stores verbose logs
under build_logs/ for later inspection. Supported platforms:
  android-apk     Build an Android APK (arm64, release by default)
  android-appbundle Build an Android App Bundle (AAB)
  ios-ipa         Archive an iOS .ipa (requires macOS)
  web             Build the web bundle
  windows         Build a Windows desktop runner
  macos           Build a macOS desktop runner
  linux           Build a Linux desktop runner

Examples:
  tool/build_artifact.sh android-apk --release
  tool/build_artifact.sh web
  tool/build_artifact.sh windows --debug
MSG
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Run tool/setup_dev_environment.sh first." >&2
  exit 1
fi

PLATFORM=$1
shift

MODE="--release"
if [[ $# -gt 0 ]]; then
  case "$1" in
    --release|--debug|--profile)
      MODE=$1
      ;;
    *)
      echo "Unknown mode flag: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
fi

mkdir -p build_logs
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="build_logs/${PLATFORM}-${MODE#--}-${TIMESTAMP}.log"

echo "[build_artifact] Building $PLATFORM ($MODE)"

declare -A COMMANDS=(
  [android-apk]="flutter build apk"
  [android-appbundle]="flutter build appbundle"
  [ios-ipa]="flutter build ipa"
  [web]="flutter build web"
  [windows]="flutter build windows"
  [macos]="flutter build macos"
  [linux]="flutter build linux"
)

if [[ -z ${COMMANDS[$PLATFORM]:-} ]]; then
  echo "Unknown platform: $PLATFORM" >&2
  usage >&2
  exit 1
fi

IFS=' ' read -r -a CMD <<< "${COMMANDS[$PLATFORM]}"

# Combine base command with build mode when supported.
case "$PLATFORM" in
  android-apk|android-appbundle|windows|macos|linux)
    CMD+=("$MODE")
    ;;
  web)
    case "$MODE" in
      --release)
        CMD+=("--release")
        ;;
      --profile)
        CMD+=("--profile")
        ;;
      --debug)
        echo "[build_artifact] 'flutter build web' does not support --debug; using --profile instead." >&2
        CMD+=("--profile")
        ;;
    esac
    ;;
  ios-ipa)
    if [[ $MODE != "--release" ]]; then
      echo "[build_artifact] 'flutter build ipa' only supports release archives; ignoring $MODE." >&2
    fi
    CMD+=("--export-method" "ad-hoc")
    ;;
esac

{
  set -x
  "${CMD[@]}"
} |& tee "$LOG_FILE"

echo "[build_artifact] Build finished. Log saved to $LOG_FILE"
