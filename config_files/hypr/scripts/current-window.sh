#!/usr/bin/env bash
set -euo pipefail

raw="$(hyprctl activewindow 2>/dev/null || true)"

if [[ -z "$raw" ]] || [[ "$raw" == "invalid" ]] || [[ "$raw" == "Invalid" ]]; then
  printf 'No active window\n'
  exit 0
fi

title="$(printf '%s\n' "$raw" | awk -F': ' '/^[[:space:]]*title: /{print $2; exit}')"
class="$(printf '%s\n' "$raw" | awk -F': ' '/^[[:space:]]*class: /{print $2; exit}')"

if [[ -n "$title" ]]; then
  printf '%s\n' "$title"
elif [[ -n "$class" ]]; then
  printf '%s\n' "$class"
else
  printf 'No active window\n'
fi
