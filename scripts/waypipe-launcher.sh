#!/usr/bin/env bash
set -euo pipefail
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

need tailscale
need jq
need waypipe
need wofi
need eww

eww_cfg="$HOME/.home-manager/config_files/eww-waypipe-launcher"
if [[ ! -d "$eww_cfg" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  eww_cfg="$script_dir/../config_files/eww-waypipe-launcher"
fi

if [[ ! -f "$eww_cfg/eww.yuck" ]]; then
  echo "Missing eww config: $eww_cfg/eww.yuck" >&2
  exit 1
fi

tmp_root="${XDG_RUNTIME_DIR:-/tmp}"
tmp_dir="$(mktemp -d "$tmp_root/waypipe-launcher.XXXXXX")"
sel_file="$tmp_dir/selected"

cleanup() {
  if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch submap reset >/dev/null 2>&1 || true
  fi
  eww --config "$eww_cfg" close waypipe-hosts >/dev/null 2>&1 || true
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if ! eww --config "$eww_cfg" ping >/dev/null 2>&1; then
  eww --config "$eww_cfg" daemon >/dev/null 2>&1 &
  disown || true
fi

# Allow ESC to close the picker using a Hyprland submap (if configured).
use_hypr_submap=0
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl binds -j 2>/dev/null | jq -e '.[] | select(.submap == "waypipe-launcher")' >/dev/null 2>&1; then
    hyprctl dispatch submap waypipe-launcher >/dev/null 2>&1 || true
    use_hypr_submap=1
  fi
fi

eww --config "$eww_cfg" open waypipe-hosts --arg selFile="$sel_file" --arg configDir="$eww_cfg" >/dev/null

host=""
while true; do
  if [[ -s "$sel_file" ]]; then
    host="$(<"$sel_file")"
    break
  fi

  if ! eww --config "$eww_cfg" active-windows 2>/dev/null | grep -q "waypipe-hosts"; then
    exit 0
  fi

  sleep 0.05
done

host="${host//$'\n'/}"
[[ -n "${host// }" ]] || exit 0

if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch submap reset >/dev/null 2>&1 || true
  use_hypr_submap=0
fi

# Refuse offline selection (still shows in menu, but won't run).
ts_json="$(tailscale status --json)"
online="$(
  jq -r --arg h "$host" '
    .Peer
    | to_entries
    | map(.value)
    | map(select(((.DNSName // "") | sub("\\.$";"")) == $h))
    | .[0].Online // false
  ' <<<"$ts_json"
)"

if [[ "$online" != "true" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Remote Launcher" "'$host' is offline"
  exit 1
fi
# Run remote wofi (drun), get the printed command, eval it remotely.
# Use stdin (bash -s) to avoid ssh/quote parsing issues.
waypipe --no-gpu --xwls ssh "$host" bash -s <<'REMOTE'
set -euo pipefail

cmd="$(GDK_BACKEND=wayland wofi --show drun --define drun-print_command=true)"
[[ -n "${cmd// }" ]] || exit 0
eval "$cmd"
REMOTE
