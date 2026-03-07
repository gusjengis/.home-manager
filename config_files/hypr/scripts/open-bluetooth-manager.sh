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
  existing_address="$(hyprctl -j clients 2>/dev/null | jq -r '.[] | select(.class == ".blueman-manager-wrapped") | .address' | head -n 1)"
  if [[ -n "$existing_address" && "$existing_address" != "null" ]]; then
    hyprctl dispatch closewindow "address:$existing_address" >/dev/null 2>&1 || true
    exit 0
  fi

  wifi_address="$(hyprctl -j clients 2>/dev/null | jq -r '.[] | select(.class == "wifi-popup") | .address' | head -n 1)"
  if [[ -n "$wifi_address" && "$wifi_address" != "null" ]]; then
    hyprctl dispatch closewindow "address:$wifi_address" >/dev/null 2>&1 || true
  fi
fi

if command -v blueman-manager >/dev/null 2>&1; then
  nohup blueman-manager >/dev/null 2>&1 &
  exit 0
fi

if command -v gnome-control-center >/dev/null 2>&1; then
  nohup gnome-control-center bluetooth >/dev/null 2>&1 &
  exit 0
fi

if command -v kcmshell6 >/dev/null 2>&1; then
  nohup kcmshell6 kcm_bluetooth >/dev/null 2>&1 &
  exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Bluetooth" "No Bluetooth manager found (tried blueman, GNOME, KDE)."
fi
