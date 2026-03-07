#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
hypr_dir="$runtime_dir/hypr"

if [[ -d "$hypr_dir" ]]; then
  latest_sig="$(ls -1t "$hypr_dir" | head -n 1)"
  if [[ -n "$latest_sig" ]]; then
    export XDG_RUNTIME_DIR="$runtime_dir"
    export HYPRLAND_INSTANCE_SIGNATURE="$latest_sig"
  fi
fi

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  existing_address="$(hyprctl -j clients 2>/dev/null | jq -r '.[] | select(.class == "com.network.manager") | .address' | head -n 1)"
  if [[ -n "$existing_address" && "$existing_address" != "null" ]]; then
    hyprctl dispatch closewindow "address:$existing_address" >/dev/null 2>&1 || true
    exit 0
  fi

  bluetooth_address="$(hyprctl -j clients 2>/dev/null | jq -r '.[] | select(.class == ".blueman-manager-wrapped") | .address' | head -n 1)"
  if [[ -n "$bluetooth_address" && "$bluetooth_address" != "null" ]]; then
    hyprctl dispatch closewindow "address:$bluetooth_address" >/dev/null 2>&1 || true
  fi
fi

if command -v nmgui >/dev/null 2>&1; then
  nohup nmgui >/dev/null 2>&1 &
  exit 0
fi

notify-send "Network Manager" "nmgui is not installed"
