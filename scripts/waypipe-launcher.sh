#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_notify() {
  local msg="$1"
  if ! debug; then
    return 0
  fi

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Waypipe Launcher" -u normal -t 2500 "Waypipe Launcher" "$msg" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

dbg_error() {
  local msg="$1"
  if ! debug; then
    return 0
  fi

  if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || { dbg_error "Missing dependency: $1"; exit 1; }; }

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
  dbg_error "Missing eww config: $eww_cfg/eww.yuck"
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

# Let Hyprland keybinds (up/down/enter) know where to write the selection.
eww --config "$eww_cfg" update wp_sel_file="$sel_file" cursor=0 >/dev/null 2>&1 || true

# Allow ESC to close the picker using a Hyprland submap (if configured).
use_hypr_submap=0
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl binds -j 2>/dev/null | jq -e '.[] | select(.submap == "waypipe-launcher")' >/dev/null 2>&1; then
    hyprctl dispatch submap waypipe-launcher >/dev/null 2>&1 || true
    use_hypr_submap=1
  fi
fi

screen_arg=()
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  focused_monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -n1)"
  if [[ -n "${focused_monitor:-}" && "$focused_monitor" != "null" ]]; then
    screen_arg=(--arg screen="$focused_monitor")
  fi
fi

eww --config "$eww_cfg" open waypipe-hosts --arg selFile="$sel_file" --arg configDir="$eww_cfg" "${screen_arg[@]}" >/dev/null

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
dbg_notify "selected $host"

if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch submap reset >/dev/null 2>&1 || true
  use_hypr_submap=0
fi

# Run remote wofi (drun), get the printed command, eval it remotely.
# Use stdin (bash -s) to avoid ssh/quote parsing issues.
if debug; then
  tmp_err="$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" waypipe-launcher.err.XXXXXX)"
  set +e
  waypipe --no-gpu --xwls ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=4 \
    -o ServerAliveInterval=5 \
    -o ServerAliveCountMax=1 \
    "$host" bash -s <<'REMOTE' 2>"$tmp_err"
set -euo pipefail

if ! command -v wofi >/dev/null 2>&1; then
  echo "wofi not found on remote host" >&2
  exit 127
fi

cmd="$(GDK_BACKEND=wayland wofi --show drun --define drun-print_command=true)"
[[ -n "${cmd// }" ]] || exit 0

eval "$cmd" || true
exit 0
REMOTE
  rc=$?
  set -e

  if (( rc != 0 )); then
    tail_msg="$(tail -n 12 "$tmp_err" 2>/dev/null || true)"
    if rg -q "Host key verification failed" "$tmp_err" 2>/dev/null; then
      dbg_error "SSH host key not trusted for '$host'.\nRun: ssh $host"
    else
      dbg_error "Remote launcher failed on '$host' (rc=$rc).\n${tail_msg}"
    fi
    rm -f "$tmp_err" 2>/dev/null || true
    exit 1
  fi

  rm -f "$tmp_err" 2>/dev/null || true
else
  waypipe --no-gpu --xwls ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=4 \
    -o ServerAliveInterval=5 \
    -o ServerAliveCountMax=1 \
    "$host" bash -s <<'REMOTE' >/dev/null 2>&1
set -euo pipefail

if ! command -v wofi >/dev/null 2>&1; then
  exit 127
fi

cmd="$(GDK_BACKEND=wayland wofi --show drun --define drun-print_command=true)"
[[ -n "${cmd// }" ]] || exit 0

eval "$cmd" || true
exit 0
REMOTE
fi
