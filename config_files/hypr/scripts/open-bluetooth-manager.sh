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

if command -v blueman-manager >/dev/null 2>&1; then
  if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    nohup blueman-manager >/dev/null 2>&1 &
    (
      sleep 0.6

      monitor_json="$(hyprctl -j monitors 2>/dev/null || true)"
      target_x="3386"
      target_y="56"
      target_w="420"
      target_h="520"

      if [[ -n "$monitor_json" ]]; then
        monitor_values="$(printf '%s' "$monitor_json" | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width)"' | head -n 1)"
        if [[ -n "$monitor_values" ]]; then
          read -r monitor_x monitor_y monitor_width <<< "$monitor_values"
          target_x="$((monitor_x + monitor_width - target_w - 34))"
          target_y="$((monitor_y + 56))"
        fi
      fi

      for _ in $(seq 1 30); do
        client_address="$(hyprctl -j clients 2>/dev/null | jq -r '.[] | select(.class == ".blueman-manager-wrapped") | .address' | head -n 1)"
        if [[ -n "$client_address" && "$client_address" != "null" ]]; then
          hyprctl dispatch setfloating "address:$client_address" >/dev/null 2>&1 || true
          hyprctl dispatch resizewindowpixel "exact $target_w $target_h,address:$client_address" >/dev/null 2>&1 || true
          hyprctl dispatch movewindowpixel "exact $target_x $target_y,address:$client_address" >/dev/null 2>&1 || true
          exit 0
        fi
        sleep 0.1
      done
    ) >/dev/null 2>&1 &
  else
    nohup blueman-manager >/dev/null 2>&1 &
  fi
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
