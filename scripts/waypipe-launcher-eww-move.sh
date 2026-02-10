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

trap 'notify_err "move error at line $LINENO: $BASH_COMMAND"' ERR

log_file="${XDG_RUNTIME_DIR:-/tmp}/waypipe-launcher.log"
log() {
  printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "move: $*" >>"$log_file" 2>/dev/null || true
}

need() { command -v "$1" >/dev/null 2>&1 || { notify_err "Missing dependency: $1"; exit 1; }; }
need eww
need jq

cfg="${1:-$HOME/.home-manager/config_files/eww-waypipe-launcher}"
dir="${2:-}"

case "$dir" in
  up|-1) delta=-1 ;;
  down|+1|1) delta=1 ;;
  *) notify_err "Usage: $(basename "$0") [configDir] up|down"; exit 1 ;;
esac

hosts_json="$(eww --config "$cfg" get hosts 2>/dev/null || printf '[]')"
len="$(jq -r 'length' <<<"$hosts_json" 2>/dev/null || echo 0)"
[[ "$len" =~ ^[0-9]+$ ]] || len=0
(( len > 0 )) || exit 0

cursor_raw="$(eww --config "$cfg" get cursor 2>/dev/null || echo 0)"
cursor_raw="${cursor_raw//$'\n'/}"
cursor_raw="${cursor_raw%\"}"; cursor_raw="${cursor_raw#\"}"

if [[ ! "$cursor_raw" =~ ^-?[0-9]+$ ]]; then
  cursor_raw=0
fi

new=$(( cursor_raw + delta ))
if (( new < 0 )); then
  new=$(( len - 1 ))
elif (( new >= len )); then
  new=0
fi

eww --config "$cfg" update cursor="$new" >/dev/null
