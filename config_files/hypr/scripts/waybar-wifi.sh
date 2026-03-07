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

connected_icon=""
disconnected_icon="󰖪"

if ! command -v nmcli >/dev/null 2>&1; then
  printf '{"text":"%s","class":"disconnected","tooltip":"nmcli not found"}\n' "$disconnected_icon"
  exit 0
fi

active_device="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null | awk -F: '$2 == "wifi" && $3 == "connected" { print $1; exit }' || true)"
connection_name="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null | awk -F: '$2 == "wifi" && $3 == "connected" { print $4; exit }' || true)"

if [[ -z "$active_device" ]]; then
  printf '{"text":"%s","class":"disconnected","tooltip":"No Wi-Fi connection"}\n' "$disconnected_icon"
  exit 0
fi

signal="$(nmcli -t -e no -f ACTIVE,SIGNAL dev wifi list ifname "$active_device" 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }' || true)"

if [[ -n "$connection_name" && -n "$signal" ]]; then
  tooltip="Connected to $connection_name ($signal%%)"
elif [[ -n "$connection_name" ]]; then
  tooltip="Connected to $connection_name"
else
  tooltip="Wi-Fi connected"
fi

tooltip="$(json_escape "$tooltip")"
printf '{"text":"%s","class":"connected","tooltip":"%s"}\n' "$connected_icon" "$tooltip"
