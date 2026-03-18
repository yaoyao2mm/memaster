#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
BACKEND_PORT="${PORT:-4318}"

BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"

find_backend_pids() {
  pgrep -f "uvicorn app.main:app --reload --port $BACKEND_PORT" || true
}

find_frontend_pids() {
  {
    pgrep -f "$ROOT_DIR/build/macos/Build/Products/Debug/codex_feishu_home.app/Contents/MacOS/codex_feishu_home" || true
    pgrep -f "flutter_tools.snapshot run -d .*codex-feishu-home" || true
    pgrep -f "flutter_tools.snapshot run -d macos" || true
  } | awk 'NF && !seen[$0]++'
}

stop_process() {
  local name="$1"
  local pid_file="$2"
  local finder="$3"

  if [[ ! -f "$pid_file" ]]; then
    local discovered
    discovered="$($finder)"
    if [[ -z "$discovered" ]]; then
      echo "$name is not running."
      return
    fi

    echo "Stopping discovered $name process(es): $discovered"
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      kill "$pid" >/dev/null 2>&1 || true
    done <<<"$discovered"
    sleep 2
    while IFS= read -r pid; do
      [[ -z "$pid" ]] && continue
      if kill -0 "$pid" >/dev/null 2>&1; then
        kill -9 "$pid" >/dev/null 2>&1 || true
      fi
    done <<<"$discovered"
    return
  fi

  local pid
  pid="$(cat "$pid_file")"
  if [[ -z "$pid" ]]; then
    rm -f "$pid_file"
    echo "$name PID file was empty and has been cleared."
    return
  fi

  if kill -0 "$pid" >/dev/null 2>&1; then
    echo "Stopping $name (PID $pid)..."
    kill "$pid" >/dev/null 2>&1 || true
    sleep 2
    if kill -0 "$pid" >/dev/null 2>&1; then
      echo "Force stopping $name (PID $pid)..."
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  else
    echo "$name PID $pid was stale."
  fi

  rm -f "$pid_file"
}

stop_process "Frontend" "$FRONTEND_PID_FILE" find_frontend_pids
stop_process "Backend" "$BACKEND_PID_FILE" find_backend_pids

"$ROOT_DIR/scripts/start-stack.sh" "${1:-macos}"
