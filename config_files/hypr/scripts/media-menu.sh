#!/usr/bin/env bash
set -euo pipefail

choice="$({
  printf 'Toggle Play/Pause\n'
  printf 'Next Track\n'
  printf 'Previous Track\n'
  printf 'Stop\n'
} | wofi --dmenu --prompt 'Media')"

case "${choice:-}" in
  "Toggle Play/Pause") playerctl play-pause ;;
  "Next Track") playerctl next ;;
  "Previous Track") playerctl previous ;;
  "Stop") playerctl stop ;;
  *) exit 0 ;;
esac
