#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need eww
need jq

cfg="${1:-$HOME/.home-manager/config_files/eww-waypipe-launcher}"

sel_file="$(eww --config "$cfg" get wp_sel_file 2>/dev/null || true)"
sel_file="${sel_file//$'\n'/}"
sel_file="${sel_file%\"}"; sel_file="${sel_file#\"}"

[[ -n "${sel_file// }" ]] || exit 0

hosts_json="$(eww --config "$cfg" get hosts 2>/dev/null || printf '[]')"
cursor_raw="$(eww --config "$cfg" get cursor 2>/dev/null || echo 0)"
cursor_raw="${cursor_raw//$'\n'/}"
cursor_raw="${cursor_raw%\"}"; cursor_raw="${cursor_raw#\"}"

if [[ ! "$cursor_raw" =~ ^-?[0-9]+$ ]]; then
  cursor_raw=0
fi

ssh_host="$(jq -r --argjson i "$cursor_raw" '.[$i].ssh // empty' <<<"$hosts_json")"
online="$(jq -r --argjson i "$cursor_raw" '.[$i].online // false' <<<"$hosts_json")"

[[ "$online" == "true" ]] || exit 0
[[ -n "${ssh_host// }" ]] || exit 0

mkdir -p "$(dirname "$sel_file")"
printf '%s\n' "$ssh_host" >"$sel_file"

eww --config "$cfg" close waypipe-hosts >/dev/null 2>&1 || true
