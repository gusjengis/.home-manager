#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/wallpaper-script.pid"
advance_request_file="/tmp/wallpaper-script.advance"
wallpaper_script="$HOME/.home-manager/features/desktop/wallpaper/wallpaper-cycle-mpvpaper.sh"

request_advance() {
  : > "$advance_request_file"
}

script_running() {
  local pid="$1"

  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    return 0
  fi

  return 1
}

if [[ -f "${pid_file}" ]]; then
  pid="$(<"${pid_file}")"
  if script_running "${pid}"; then
    request_advance
    exit 0
  fi

  rm -f "${pid_file}"
fi

existing_pid="$(pgrep -f "/features/desktop/wallpaper/wallpaper-cycle-mpvpaper.sh" | head -n 1 || true)"
if script_running "${existing_pid}"; then
  request_advance
  exit 0
fi

nohup "${wallpaper_script}" >/tmp/gif_wallpaper_cycle_mpvpaper.log 2>&1 &
sleep 0.2
request_advance
exit 0
