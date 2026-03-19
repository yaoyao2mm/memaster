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

find_backend_pids() {
  pgrep -f "uvicorn app.main:app( |$).*--port $BACKEND_PORT" || true
}

find_frontend_pids() {
  {
    pgrep -f "$ROOT_DIR/build/macos/Build/Products/Debug/codex_feishu_home.app/Contents/MacOS/codex_feishu_home" || true
    pgrep -f "flutter_tools.snapshot run -d .*codex-feishu-home" || true
    pgrep -f "flutter_tools.snapshot run -d macos" || true
  } | awk 'NF && !seen[$0]++'
}

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

wait_for_pid() {
  local pid_file="$1"
  local finder="$2"
  local label="$3"

  for _ in $(seq 1 40); do
    local discovered
    discovered="$($finder | head -n 1)"
    if [[ -n "$discovered" ]]; then
      echo "$discovered" >"$pid_file"
      return 0
    fi
    sleep 0.25
  done

  echo "Warning: could not confirm $label PID." >&2
  rm -f "$pid_file"
  return 1
}

start_backend() {
  if is_running "$BACKEND_PID_FILE"; then
    echo "Backend is already running with PID $(cat "$BACKEND_PID_FILE")."
    return
  fi

  local discovered
  discovered="$(find_backend_pids | head -n 1)"
  if [[ -n "$discovered" ]]; then
    echo "$discovered" >"$BACKEND_PID_FILE"
    echo "Backend is already running with PID $discovered."
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
  wait_for_pid "$BACKEND_PID_FILE" find_backend_pids "backend" || true
}

start_frontend() {
  if is_running "$FRONTEND_PID_FILE"; then
    echo "Frontend is already running with PID $(cat "$FRONTEND_PID_FILE")."
    return
  fi

  local discovered
  discovered="$(find_frontend_pids | head -n 1)"
  if [[ -n "$discovered" ]]; then
    echo "$discovered" >"$FRONTEND_PID_FILE"
    echo "Frontend is already running with PID $discovered."
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
  wait_for_pid "$FRONTEND_PID_FILE" find_frontend_pids "frontend" || true
}

start_backend
sleep 2
start_frontend
sleep 2

echo "Stack start requested."
echo "Backend log: $BACKEND_LOG"
echo "Frontend log: $FRONTEND_LOG"
echo "Check status with: ./scripts/status-stack.sh"
