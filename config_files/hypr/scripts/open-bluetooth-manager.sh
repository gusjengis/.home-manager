#!/usr/bin/env bash
set -euo pipefail

if command -v blueman-manager >/dev/null 2>&1; then
  nohup blueman-manager >/dev/null 2>&1 &
  exit 0
fi

if command -v overskride >/dev/null 2>&1; then
  nohup overskride >/dev/null 2>&1 &
  exit 0
fi

if command -v blueberry >/dev/null 2>&1; then
  nohup blueberry >/dev/null 2>&1 &
  exit 0
fi

if command -v gnome-control-center >/dev/null 2>&1; then
  nohup gnome-control-center bluetooth >/dev/null 2>&1 &
  exit 0
fi

if command -v kcmshell6 >/dev/null 2>&1; then
  nohup kcmshell6 kcm_bluetooth >/dev/null 2>&1 &
  exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Bluetooth" "No Bluetooth manager found (tried blueman, overskride, blueberry, GNOME, KDE)."
fi
