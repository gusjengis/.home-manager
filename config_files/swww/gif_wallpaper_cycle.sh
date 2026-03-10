#!/usr/bin/env bash
set -euo pipefail

# store pid in a file so hyprland can signal it to change wallpaper
echo $$ > /tmp/wallpaper-script.pid

swww-daemon &

CMD_PREFIX=(swww img)
SETTINGS=(--filter Nearest --transition-type none)

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

# SIGUSR1 => advance to next wallpaper
trap 'next_wallpaper' USR1

while true; do
  shopt -s nullglob

  # load all wallpapers in the folder and shuffle list
  wallpapers=(
    ~/.home-manager/wallpapers/*.avif
    ~/.home-manager/wallpapers/*.jpeg
    ~/.home-manager/wallpapers/*.JPEG
    ~/.home-manager/wallpapers/*.jpg
    ~/.home-manager/wallpapers/*.png
    ~/.home-manager/wallpapers/*.gif
    ~/.home-manager/wallpapers/*.pnm
    ~/.home-manager/wallpapers/*.tga
    ~/.home-manager/wallpapers/*.tiff
    ~/.home-manager/wallpapers/*.webp
    ~/.home-manager/wallpapers/*.bmp
    ~/.home-manager/wallpapers/*.farbfeld
    ~/.home-manager/wallpapers/*.svg 
  )

  mapfile -t shuffled < <(shuf -e "${wallpapers[@]}")

  for img in "${shuffled[@]}"; do
    "${CMD_PREFIX[@]}" "$img" "${SETTINGS[@]}"
    "$HOME/.home-manager/config_files/hypr/scripts/update-accent.sh" "$img" >/dev/null 2>&1 || true
    wait_or_advance 300
  done
done
