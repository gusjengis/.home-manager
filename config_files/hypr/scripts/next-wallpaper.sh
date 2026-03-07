#!/usr/bin/env bash
set -euo pipefail

pid_file="/tmp/wallpaper-script.pid"

if [[ -f "${pid_file}" ]]; then
  pid="$(<"${pid_file}")"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill -USR1 "${pid}"
    exit 0
  fi
fi

pkill -USR1 -f "/config_files/swww/gif_wallpaper_cycle.sh" || true
