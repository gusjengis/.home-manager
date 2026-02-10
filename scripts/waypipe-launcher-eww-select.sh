#!/usr/bin/env bash
set -euo pipefail

notify_err() {
  local msg="$1"
  local dunstify_bin notify_bin
  dunstify_bin="${DUNSTIFY_BIN:-}"
  notify_bin="${NOTIFY_SEND_BIN:-}"
  if [[ -z "${dunstify_bin:-}" ]]; then dunstify_bin="$(command -v dunstify 2>/dev/null || true)"; fi
  if [[ -z "${notify_bin:-}" ]]; then notify_bin="$(command -v notify-send 2>/dev/null || true)"; fi
  if [[ -n "${dunstify_bin:-}" ]]; then
    "$dunstify_bin" -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  elif [[ -n "${notify_bin:-}" ]]; then
    "$notify_bin" "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

trap 'notify_err "select error at line $LINENO: $BASH_COMMAND"' ERR

log_file="${XDG_RUNTIME_DIR:-/tmp}/waypipe-launcher.log"
log() {
  printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "select: $*" >>"$log_file" 2>/dev/null || true
}

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }
notify_dbg() {
  local msg="$1"
  if ! debug; then
    return 0
  fi
  local dunstify_bin notify_bin
  dunstify_bin="${DUNSTIFY_BIN:-}"
  notify_bin="${NOTIFY_SEND_BIN:-}"
  if [[ -z "${dunstify_bin:-}" ]]; then dunstify_bin="$(command -v dunstify 2>/dev/null || true)"; fi
  if [[ -z "${notify_bin:-}" ]]; then notify_bin="$(command -v notify-send 2>/dev/null || true)"; fi
  if [[ -n "${dunstify_bin:-}" ]]; then
    "$dunstify_bin" -a "Waypipe Launcher" -u low -t 1500 "Waypipe Launcher" "$msg" || true
  elif [[ -n "${notify_bin:-}" ]]; then
    "$notify_bin" "Waypipe Launcher" "$msg" || true
  fi
}

sel_file="${1:-}"
cfg_dir="${2:-}"
host="${3:-}"

if [[ -z "${sel_file// }" || -z "${cfg_dir// }" || -z "${host// }" ]]; then
  notify_err "Selection script called with missing args."
  exit 1
fi

log "clicked host=$host sel_file=$sel_file"
notify_dbg "clicked $host"

mkdir -p "$(dirname "$sel_file")"
if ! printf '%s\n' "$host" >"$sel_file"; then
  notify_err "Failed to write selection file: $sel_file"
  exit 1
fi

if command -v eww >/dev/null 2>&1; then
  eww --config "$cfg_dir" close waypipe-hosts >/dev/null 2>&1 || true
fi
