#!/usr/bin/env bash
set -euo pipefail

# store pid in a file so hyprland can signal it to change wallpaper
echo $$ > /tmp/wallpaper-script.pid

swww-daemon &

CMD_PREFIX=(swww img)
SETTINGS=(--filter Nearest --transition-type none)

sleep_pid=""

next_wallpaper() {
  # If we're currently sleeping, wake up immediately so the loop advances
  if [[ -n "${sleep_pid}" ]] && kill -0 "${sleep_pid}" 2>/dev/null; then
    kill "${sleep_pid}" 2>/dev/null || true
  fi
}

# SIGUSR1 => advance to next wallpaper
trap 'next_wallpaper' USR1

while true; do
  # load all wallpapers in the folder and shuffle list
  wallpapers=(
    ~/.home-manager/wallpapers/*.gif
    ~/.home-manager/wallpapers/*.webp
    ~/.home-manager/wallpapers/*.png
  )
  mapfile -t shuffled < <(shuf -e "${wallpapers[@]}")

  for img in "${shuffled[@]}"; do
    "${CMD_PREFIX[@]}" "$img" "${SETTINGS[@]}" &

    # Sleep in the background so SIGUSR1 can interrupt it by killing this PID
    sleep 300 &
    sleep_pid=$!

    # Wait until either:
    # - the sleep finishes normally, or
    # - SIGUSR1 kills it (wait returns non-zero, which we ignore)
    wait "$sleep_pid" 2>/dev/null || true
    sleep_pid=""
  done
done
