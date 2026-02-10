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

trap 'notify_err "activate error at line $LINENO: $BASH_COMMAND"' ERR

log_file="${XDG_RUNTIME_DIR:-/tmp}/waypipe-launcher.log"
log() {
  printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "activate: $*" >>"$log_file" 2>/dev/null || true
}

need() { command -v "$1" >/dev/null 2>&1 || { notify_err "Missing dependency: $1"; exit 1; }; }
need eww
need jq

cfg="${1:-$HOME/.home-manager/config_files/eww-waypipe-launcher}"

sel_file="$(eww --config "$cfg" get wp_sel_file 2>/dev/null || true)"
sel_file="${sel_file//$'\n'/}"
sel_file="${sel_file%\"}"; sel_file="${sel_file#\"}"

[[ -n "${sel_file// }" ]] || { notify_err "No selection file set (wp_sel_file is empty)."; exit 1; }
log "sel_file=$sel_file"

hosts_json="$(eww --config "$cfg" get hosts 2>/dev/null || printf '[]')"
cursor_raw="$(eww --config "$cfg" get cursor 2>/dev/null || echo 0)"
cursor_raw="${cursor_raw//$'\n'/}"
cursor_raw="${cursor_raw%\"}"; cursor_raw="${cursor_raw#\"}"

if [[ ! "$cursor_raw" =~ ^-?[0-9]+$ ]]; then
  cursor_raw=0
fi

ssh_host="$(jq -r --argjson i "$cursor_raw" '.[$i].ssh // empty' <<<"$hosts_json")"
online="$(jq -r --argjson i "$cursor_raw" '.[$i].online // false' <<<"$hosts_json")"

log "cursor=$cursor_raw ssh_host=$ssh_host online=$online"

# Allow selecting hosts marked offline; tailscale status can be stale.
[[ -n "${ssh_host// }" ]] || { notify_err "Failed to resolve selected host."; exit 1; }

mkdir -p "$(dirname "$sel_file")"
if ! printf '%s\n' "$ssh_host" >"$sel_file"; then
  notify_err "Failed to write selection file: $sel_file"
  exit 1
fi

eww --config "$cfg" close waypipe-hosts >/dev/null 2>&1 || true
