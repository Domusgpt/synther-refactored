#!/usr/bin/env bash
set -euo pipefail

# Bootstraps the Flutter toolchain and executes key quality gates.
# Intended for fresh clones or CI agents to validate the project quickly.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pushd "$REPO_ROOT" >/dev/null

# Ensure the Flutter SDK and project dependencies are installed.
"$REPO_ROOT/tool/setup_dev_environment.sh"

# Run static analysis and automated tests to surface issues early.
flutter analyze
flutter test

popd >/dev/null

