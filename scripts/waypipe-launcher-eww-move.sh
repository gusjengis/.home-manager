#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_error() {
  local msg="$1"
  if ! debug; then
    return 0
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || { dbg_error "Missing dependency: $1"; exit 1; }; }
need eww
need jq

cfg="${1:-$HOME/.home-manager/config_files/eww-waypipe-launcher}"
dir="${2:-}"

case "$dir" in
  up|-1) delta=-1 ;;
  down|+1|1) delta=1 ;;
  *) dbg_error "Usage: $(basename "$0") [configDir] up|down"; exit 1 ;;
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
