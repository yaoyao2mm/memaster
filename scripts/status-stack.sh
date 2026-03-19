#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
LOG_DIR="$RUN_DIR/logs"

BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
BACKEND_URL="http://127.0.0.1:${PORT:-4318}"

find_backend_pids() {
  pgrep -f "uvicorn app.main:app( |$).*--port ${PORT:-4318}" || true
}

find_frontend_pids() {
  {
    pgrep -f "$ROOT_DIR/build/macos/Build/Products/Debug/codex_feishu_home.app/Contents/MacOS/codex_feishu_home" || true
    pgrep -f "flutter_tools.snapshot run -d .*codex-feishu-home" || true
    pgrep -f "flutter_tools.snapshot run -d macos" || true
  } | awk 'NF && !seen[$0]++'
}

print_status() {
  local name="$1"
  local pid_file="$2"
  local log_file="$3"
  local finder="$4"

  if [[ ! -f "$pid_file" ]]; then
    local discovered
    discovered="$($finder)"
    if [[ -n "$discovered" ]]; then
      echo "$name: running (discovered PID ${discovered//$'\n'/, })"
    else
      echo "$name: stopped"
    fi
    return
  fi

  local pid
  pid="$(cat "$pid_file")"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    echo "$name: running (PID $pid)"
  else
    echo "$name: stale PID file ($(cat "$pid_file"))"
  fi

  if [[ -f "$log_file" ]]; then
    echo "$name log: $log_file"
  fi
}

print_status "Backend" "$BACKEND_PID_FILE" "$BACKEND_LOG" find_backend_pids
if command -v curl >/dev/null 2>&1; then
  if curl -fsS "$BACKEND_URL/dashboard" >/dev/null 2>&1; then
    echo "Backend health: reachable at $BACKEND_URL"
  else
    echo "Backend health: not responding at $BACKEND_URL"
  fi
fi

print_status "Frontend" "$FRONTEND_PID_FILE" "$FRONTEND_LOG" find_frontend_pids
