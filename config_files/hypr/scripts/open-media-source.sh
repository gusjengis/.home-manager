#!/usr/bin/env bash
set -euo pipefail

run_first_available() {
  local cmd
  for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      "$cmd" >/dev/null 2>&1 &
      return 0
    fi
  done
  return 1
}

regex_escape() {
  local s="$1"
  s="${s//\/\\}"
  s="${s//./\.}"
  s="${s//^/\^}"
  s="${s//\$/\\$}"
  s="${s//\*/\\*}"
  s="${s//+/\\+}"
  s="${s//\?/\\?}"
  s="${s//\[/\\[}"
  s="${s//\]/\\]}"
  s="${s//\(/\\(}"
  s="${s//\)/\\)}"
  s="${s//\{/\\{}"
  s="${s//\}/\\}}"
  s="${s//|/\\|}"
  printf '%s' "$s"
}

class_regex_for_player() {
  local player="$1"
  local short="${player%%.*}"
  short="${short,,}"

  case "$short" in
    spotify)
      printf 'spotify'
      ;;
    firefox)
      printf 'firefox'
      ;;
    chromium|chromium-browser|google-chrome|google-chrome-stable|chrome|brave|brave-browser)
      printf 'chromium|chrome|brave'
      ;;
    mpv)
      printf '^mpv$'
      ;;
    vlc)
      printf 'vlc'
      ;;
    *)
      regex_escape "$short"
      ;;
  esac
}

focus_player_window() {
  local player="$1"
  local media_title="$2"
  local media_url="$3"
  local class_re title_lc url_hint address

  command -v hyprctl >/dev/null 2>&1 || return 1

  class_re="$(class_regex_for_player "$player")"
  title_lc="${media_title,,}"

  case "${media_url,,}" in
    *qobuz*) url_hint="qobuz" ;;
    *music.youtube.com*|*youtube.com*) url_hint="youtube" ;;
    *open.spotify.com*) url_hint="spotify" ;;
    *) url_hint="" ;;
  esac

  address="$(
    hyprctl -j clients | jq -r --arg class_re "$class_re" --arg title_lc "$title_lc" '
      def classmatch: ((.class // "" | test($class_re; "i")) or (.initialClass // "" | test($class_re; "i")));
      first(.[] | select(classmatch and (($title_lc | length) > 0) and ((.title // "" | ascii_downcase | contains($title_lc)))) | .address) // empty
    '
  )"

  if [[ -z "$address" && -n "$url_hint" ]]; then
    address="$(
      hyprctl -j clients | jq -r --arg class_re "$class_re" --arg hint "$url_hint" '
        def classmatch: ((.class // "" | test($class_re; "i")) or (.initialClass // "" | test($class_re; "i")));
        first(.[] | select(classmatch and ((.title // "" | ascii_downcase | contains($hint)))) | .address) // empty
      '
    )"
  fi

  if [[ -z "$address" ]]; then
    address="$(
      hyprctl -j clients | jq -r --arg class_re "$class_re" '
        def classmatch: ((.class // "" | test($class_re; "i")) or (.initialClass // "" | test($class_re; "i")));
        first(.[] | select(classmatch) | .address) // empty
      '
    )"
  fi

  [[ -z "$address" ]] && return 1
  hyprctl dispatch focuswindow "address:$address" >/dev/null 2>&1
}

open_player_app() {
  local player="$1"
  local short="${player%%.*}"
  short="${short,,}"

  case "$short" in
    spotify)
      run_first_available spotify spotify-launcher
      ;;
    firefox)
      run_first_available firefox
      ;;
    chromium|chromium-browser)
      run_first_available chromium chromium-browser google-chrome-stable google-chrome brave
      ;;
    brave)
      run_first_available brave brave-browser
      ;;
    mpv)
      run_first_available mpv
      ;;
    vlc)
      run_first_available vlc
      ;;
    *)
      run_first_available "$short"
      ;;
  esac
}

players="$(playerctl -l 2>/dev/null || true)"
[[ -z "$players" ]] && exit 0

selected_player=""
fallback_player=""

while IFS= read -r player; do
  [[ -z "$player" ]] && continue
  status="$(playerctl -p "$player" status 2>/dev/null || true)"
  [[ -z "$status" ]] && continue

  if [[ -z "$fallback_player" ]]; then
    fallback_player="$player"
  fi

  if [[ "$status" == "Playing" ]]; then
    selected_player="$player"
    break
  fi
done <<< "$players"

if [[ -z "$selected_player" ]]; then
  selected_player="$fallback_player"
fi

[[ -z "$selected_player" ]] && exit 0

media_title="$(playerctl -p "$selected_player" metadata xesam:title 2>/dev/null || true)"
media_url="$(playerctl -p "$selected_player" metadata xesam:url 2>/dev/null || true)"

if focus_player_window "$selected_player" "$media_title" "$media_url"; then
  exit 0
fi

if command -v xdg-open >/dev/null 2>&1; then
  if [[ -n "$media_url" ]]; then
    xdg-open "$media_url" >/dev/null 2>&1 &
    exit 0
  fi
fi

open_player_app "$selected_player" || true
