#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/wallpaper-script.pid"
wallpaper_script="$HOME/.home-manager/config_files/swww/gif_wallpaper_cycle_mpvpaper.sh"

signal_pid() {
  local pid="$1"

  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill -USR1 "${pid}"
    return 0
  fi

  return 1
}

if [[ -f "${pid_file}" ]]; then
  pid="$(<"${pid_file}")"
  if signal_pid "${pid}"; then
    exit 0
  fi

  rm -f "${pid_file}"
fi

existing_pid="$(pgrep -f "/config_files/swww/gif_wallpaper_cycle_mpvpaper.sh" | head -n 1 || true)"
if signal_pid "${existing_pid}"; then
  exit 0
fi

nohup "${wallpaper_script}" >/tmp/gif_wallpaper_cycle_mpvpaper.log 2>&1 &
new_pid=$!
sleep 0.2

if signal_pid "${new_pid}"; then
  exit 0
fi

exit 1
