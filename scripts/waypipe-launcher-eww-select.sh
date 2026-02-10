#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_error() {
  local msg="$1"
  if ! debug; then
    return 0
  fi

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

sel_file="${1:-}"
cfg_dir="${2:-}"
host="${3:-}"

if [[ -z "${sel_file// }" || -z "${cfg_dir// }" || -z "${host// }" ]]; then
  dbg_error "Selection script called with missing args."
  exit 1
fi

mkdir -p "$(dirname "$sel_file")"
if ! printf '%s\n' "$host" >"$sel_file"; then
  dbg_error "Failed to write selection file: $sel_file"
  exit 1
fi

if command -v eww >/dev/null 2>&1; then
  eww --config "$cfg_dir" close waypipe-hosts >/dev/null 2>&1 || true
fi
