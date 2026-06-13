#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${SUNSHINE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_error() {
    local msg="$1"
    if ! debug; then
        return 0
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Sunshine Launcher" -u critical -t 8000 "Sunshine Launcher" "$msg" || true
    else
        printf 'Sunshine Launcher: %s\n' "$msg" >&2
    fi
}

need() { command -v "$1" >/dev/null 2>&1 || { dbg_error "Missing dependency: $1"; exit 1; }; }
need eww
need jq

cfg="${1:-$HOME/.home-manager/config_files/eww-sunshine-launcher}"

sel_file="$(eww --config "$cfg" get sl_sel_file 2>/dev/null || true)"
sel_file="${sel_file//$'\n'/}"
sel_file="${sel_file%\"}"; sel_file="${sel_file#\"}"

[[ -n "${sel_file// }" ]] || { dbg_error "No selection file set (sl_sel_file is empty)."; exit 1; }

hosts_json="$(eww --config "$cfg" get hosts 2>/dev/null || printf '[]')"
cursor_raw="$(eww --config "$cfg" get cursor 2>/dev/null || echo 0)"
cursor_raw="${cursor_raw//$'\n'/}"
cursor_raw="${cursor_raw%\"}"; cursor_raw="${cursor_raw#\"}"

if [[ ! "$cursor_raw" =~ ^-?[0-9]+$ ]]; then
    cursor_raw=0
fi

ssh_host="$(jq -r --argjson i "$cursor_raw" '.[$i].ssh // empty' <<<"$hosts_json")"

[[ -n "${ssh_host// }" ]] || { dbg_error "Failed to resolve selected host."; exit 1; }

mkdir -p "$(dirname "$sel_file")"
if ! printf '%s\n' "$ssh_host" >"$sel_file"; then
    dbg_error "Failed to write selection file: $sel_file"
    exit 1
fi

eww --config "$cfg" close sunshine-hosts >/dev/null 2>&1 || true
