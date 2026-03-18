#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_DIR="$ROOT_DIR/service"
PORT="${PORT:-4318}"

if ! command -v uv >/dev/null 2>&1; then
  echo "Error: uv is not installed or not in PATH." >&2
  exit 1
fi

cd "$SERVICE_DIR"

echo "Syncing backend dependencies..."
uv sync

echo "Starting FastAPI service on port: $PORT"
uv run uvicorn app.main:app --reload --port "$PORT"
