#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  s="${s//$'\t'/ }"
  printf '%s' "$s"
}

players="$(playerctl -l 2>/dev/null || true)"
if [[ -z "$players" ]]; then
  exit 0
fi

selected_player=""
selected_status=""

while IFS= read -r player; do
  [[ -z "$player" ]] && continue
  status="$(playerctl -p "$player" status 2>/dev/null || true)"
  [[ -z "$status" ]] && continue

  if [[ "$status" == "Playing" ]]; then
    selected_player="$player"
    selected_status="$status"
    break
  fi
done <<< "$players"

if [[ -z "$selected_player" ]]; then
  exit 0
fi

artist="$(playerctl -p "$selected_player" metadata xesam:artist 2>/dev/null || true)"
title="$(playerctl -p "$selected_player" metadata xesam:title 2>/dev/null || true)"

if [[ -n "$artist" && -n "$title" ]]; then
  text="$artist - $title"
elif [[ -n "$title" ]]; then
  text="$title"
elif [[ -n "$artist" ]]; then
  text="$artist"
else
  text="$selected_player"
fi

case "$selected_status" in
  Playing) state="playing" ;;
  Paused) state="paused" ;;
  *) state="idle" ;;
esac

text_escaped="$(json_escape "$text")"
tooltip_escaped="$(json_escape "$selected_player ($selected_status)")"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text_escaped" "$state" "$tooltip_escaped"
