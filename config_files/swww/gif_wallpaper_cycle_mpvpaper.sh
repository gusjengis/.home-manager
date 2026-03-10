#!/usr/bin/env bash
set -euo pipefail

# store pid in a file so hyprland can signal it to change wallpaper
echo $$ > /tmp/wallpaper-script.pid

ambxst_wallpaper_state="${XDG_CACHE_HOME:-$HOME/.cache}/ambxst/wallpapers.json"

sleep_pid=""
advance_requested=0

next_wallpaper() {
  advance_requested=1

  # If we're currently sleeping, wake up immediately so the loop advances
  if [[ -n "${sleep_pid}" ]] && kill -0 "${sleep_pid}" 2>/dev/null; then
    kill "${sleep_pid}" 2>/dev/null || true
  fi
}

wait_or_advance() {
  local seconds="$1"

  if (( advance_requested )); then
    advance_requested=0
    return 0
  fi

  sleep "$seconds" &
  sleep_pid=$!

  wait "$sleep_pid" 2>/dev/null || true
  sleep_pid=""
  advance_requested=0
}

write_ambxst_wallpaper() {
  local img="$1"

  mkdir -p "$(dirname "${ambxst_wallpaper_state}")"

  python3 - "$ambxst_wallpaper_state" "$HOME/.home-manager/wallpapers" "$img" <<'PY'
import json
import os
import sys

state_path, wall_path, current_wall = sys.argv[1:4]

data = {
    "activeColorPreset": "",
    "currentWall": current_wall,
    "matugenScheme": "scheme-tonal-spot",
    "tintEnabled": False,
    "wallPath": wall_path,
}

if os.path.exists(state_path):
    try:
        with open(state_path, "r", encoding="utf-8") as fh:
            existing = json.load(fh)
        if isinstance(existing, dict):
            data.update(existing)
    except Exception:
        pass

data["wallPath"] = wall_path
data["currentWall"] = current_wall

with open(state_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=4)
    fh.write("\n")
PY
}

cleanup() {
  rm -f /tmp/wallpaper-script.pid
}

# SIGUSR1 => advance to next wallpaper
trap 'next_wallpaper' USR1
trap 'cleanup' EXIT INT TERM

while true; do
  shopt -s nullglob

  # load all wallpapers in the folder and shuffle list
  wallpapers=(
    ~/.home-manager/wallpapers/*.jpeg
    ~/.home-manager/wallpapers/*.JPEG
    ~/.home-manager/wallpapers/*.jpg
    ~/.home-manager/wallpapers/*.png
    ~/.home-manager/wallpapers/*.gif
    ~/.home-manager/wallpapers/*.mp4
    ~/.home-manager/wallpapers/*.webm
    ~/.home-manager/wallpapers/*.mov
    ~/.home-manager/wallpapers/*.avi
    ~/.home-manager/wallpapers/*.mkv
    ~/.home-manager/wallpapers/*.tif
    ~/.home-manager/wallpapers/*.tiff
    ~/.home-manager/wallpapers/*.webp
  )

  if (( ${#wallpapers[@]} == 0 )); then
    wait_or_advance 60
    continue
  fi

  mapfile -t shuffled < <(shuf -e "${wallpapers[@]}")

  for img in "${shuffled[@]}"; do
    write_ambxst_wallpaper "$img"
    "$HOME/.home-manager/config_files/hypr/scripts/update-accent.sh" "$img" >/dev/null 2>&1 || true
    wait_or_advance 300
  done
done
