#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  s="${s//$'\t'/ }"
  printf '%s' "$s"
}

if ! command -v bluetoothctl >/dev/null 2>&1; then
  printf '{"text":"BT N/A","class":"off","tooltip":"bluetoothctl not found"}\n'
  exit 0
fi

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')"
if [[ "${powered:-no}" != "yes" ]]; then
  printf '{"text":"BT Off","class":"off","tooltip":"Bluetooth is powered off"}\n'
  exit 0
fi

connected_lines="$(bluetoothctl devices Connected 2>/dev/null || true)"
connected_count="$(printf '%s\n' "$connected_lines" | sed '/^$/d' | wc -l)"

if (( connected_count > 0 )); then
  names="$(printf '%s\n' "$connected_lines" | sed 's/^Device [0-9A-F:]* //')"
  tooltip="Connected: $(printf '%s' "$names" | paste -sd ', ' -)"
  tooltip="$(json_escape "$tooltip")"
  printf '{"text":"BT %d","class":"on","tooltip":"%s"}\n' "$connected_count" "$tooltip"
  exit 0
fi

printf '{"text":"BT On","class":"idle","tooltip":"Bluetooth is on"}\n'
