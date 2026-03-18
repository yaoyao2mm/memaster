#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="${1:-macos}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter is not installed or not in PATH." >&2
  exit 1
fi

cd "$ROOT_DIR"

echo "Installing Flutter dependencies..."
flutter pub get

echo "Starting Flutter app on device: $DEVICE"
flutter run -d "$DEVICE"
