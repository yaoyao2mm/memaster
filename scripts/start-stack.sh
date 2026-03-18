#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
LOG_DIR="$RUN_DIR/logs"

BACKEND_PORT="${PORT:-4318}"
FRONTEND_DEVICE="${1:-macos}"

BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"

mkdir -p "$LOG_DIR"

is_running() {
  local pid_file="$1"
  if [[ ! -f "$pid_file" ]]; then
    return 1
  fi

  local pid
  pid="$(cat "$pid_file")"
  if [[ -z "$pid" ]]; then
    return 1
  fi

  kill -0 "$pid" >/dev/null 2>&1
}

start_backend() {
  if is_running "$BACKEND_PID_FILE"; then
    echo "Backend is already running with PID $(cat "$BACKEND_PID_FILE")."
    return
  fi

  if ! command -v uv >/dev/null 2>&1; then
    echo "Error: uv is not installed or not in PATH." >&2
    exit 1
  fi

  echo "Starting backend on port $BACKEND_PORT..."
  (
    cd "$ROOT_DIR/service"
    exec uv run uvicorn app.main:app --reload --port "$BACKEND_PORT"
  ) >"$BACKEND_LOG" 2>&1 &
  echo $! >"$BACKEND_PID_FILE"
}

start_frontend() {
  if is_running "$FRONTEND_PID_FILE"; then
    echo "Frontend is already running with PID $(cat "$FRONTEND_PID_FILE")."
    return
  fi

  if ! command -v flutter >/dev/null 2>&1; then
    echo "Error: flutter is not installed or not in PATH." >&2
    exit 1
  fi

  echo "Starting frontend on device $FRONTEND_DEVICE..."
  (
    cd "$ROOT_DIR"
    exec flutter run -d "$FRONTEND_DEVICE"
  ) >"$FRONTEND_LOG" 2>&1 &
  echo $! >"$FRONTEND_PID_FILE"
}

start_backend
sleep 2
start_frontend
sleep 2

echo "Stack start requested."
echo "Backend log: $BACKEND_LOG"
echo "Frontend log: $FRONTEND_LOG"
echo "Check status with: ./scripts/status-stack.sh"
