#!/usr/bin/env bash
set -euo pipefail

if command -v nmgui >/dev/null 2>&1; then
  nohup nmgui >/dev/null 2>&1 &
  exit 0
fi

notify-send "Network Manager" "nmgui is not installed"
