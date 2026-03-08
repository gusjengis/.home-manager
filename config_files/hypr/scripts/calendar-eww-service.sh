#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/eww-calendar"
RENDERER="$HOME/.home-manager/config_files/hypr/scripts/google-calendar-timeline.py"
INTERVAL="${CALENDAR_TIMELINE_INTERVAL_SECONDS:-300}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'calendar-eww-service: missing dependency: %s\n' "$1" >&2
    exit 1
  }
}

need_path_or_cmd() {
  if [[ "$1" == */* ]]; then
    [[ -x "$1" ]] || {
      printf 'calendar-eww-service: missing dependency: %s\n' "$1" >&2
      exit 1
    }
    return 0
  fi

  need "$1"
}

need eww
need jq

python_bin="${CALENDAR_TIMELINE_PYTHON:-python3}"
need_path_or_cmd "$python_bin"

screen_arg=()
if command -v hyprctl >/dev/null 2>&1; then
  focused_monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null | head -n1 || true)"
  if [[ -n "${focused_monitor:-}" && "$focused_monitor" != "null" ]]; then
    screen_arg=(--arg screen="$focused_monitor")
  fi
fi

if [[ ! -f "$CONFIG_DIR/eww.yuck" ]]; then
  printf 'calendar-eww-service: missing eww config at %s/eww.yuck\n' "$CONFIG_DIR" >&2
  exit 1
fi

if [[ ! -f "$RENDERER" ]]; then
  printf 'calendar-eww-service: missing renderer at %s\n' "$RENDERER" >&2
  exit 1
fi

if ! eww --config "$CONFIG_DIR" ping >/dev/null 2>&1; then
  eww --config "$CONFIG_DIR" daemon >/dev/null 2>&1 &
  disown || true
  for _ in $(seq 1 30); do
    if eww --config "$CONFIG_DIR" ping >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done
fi

eww --config "$CONFIG_DIR" ping >/dev/null 2>&1

refresh_timeline() {
  local payload image_path tooltip
  payload="$("$python_bin" "$RENDERER")"
  image_path="$(printf '%s' "$payload" | jq -r '.image')"
  tooltip="$(printf '%s' "$payload" | jq -r '.tooltip')"
  eww --config "$CONFIG_DIR" update calendar_timeline_path="$image_path" calendar_timeline_tooltip="$tooltip" >/dev/null
}

refresh_timeline

if ! eww --config "$CONFIG_DIR" active-windows 2>/dev/null | grep -q 'calendar-timeline'; then
  eww --config "$CONFIG_DIR" open calendar-timeline "${screen_arg[@]}" >/dev/null
fi

while true; do
  sleep "$INTERVAL"
  refresh_timeline
done
