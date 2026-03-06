#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
output_dir="${2:-$HOME/Pictures/Screenshots}"

require_cmd() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf 'Missing required command: %s\n' "$cmd" >&2
      exit 1
    fi
  done
}

require_cmd hyprctl grim slurp jq
mkdir -p "$output_dir"

get_focused_monitor() {
  hyprctl -j monitors | jq -r 'first(.[] | select(.focused) | .name) // empty'
}

get_monitor_field() {
  local monitor="$1"
  local field="$2"
  hyprctl -j monitors | jq -r --arg monitor "$monitor" "first(.[] | select(.name == \$monitor) | .$field) // empty"
}

infer_bitdepth() {
  local monitor="$1"
  local format
  format="$(get_monitor_field "$monitor" "currentFormat")"
  if [[ "$format" == *2101010* ]]; then
    printf '10\n'
  else
    printf '8\n'
  fi
}

build_monitor_rule() {
  local monitor="$1"
  local cm="$2"
  local bitdepth="$3"

  local fields width height refresh x y scale transform sdrbrightness sdrsaturation sdrmin sdrmax
  fields="$(
    hyprctl -j monitors | jq -r --arg monitor "$monitor" '
      first(.[] | select(.name == $monitor))
      | [
          (.width | tostring),
          (.height | tostring),
          (.refreshRate | tostring),
          (.x | tostring),
          (.y | tostring),
          (.scale | tostring),
          (.transform | tostring),
          (.sdrBrightness | tostring),
          (.sdrSaturation | tostring),
          (.sdrMinLuminance | tostring),
          (.sdrMaxLuminance | tostring)
        ]
      | @tsv
    '
  )"

  IFS=$'\t' read -r width height refresh x y scale transform sdrbrightness sdrsaturation sdrmin sdrmax <<<"$fields"

  local refresh_fmt
  refresh_fmt="$(printf '%.2f' "$refresh")"

  printf '%s,%sx%s@%s,%sx%s,%s,transform,%s,bitdepth,%s,cm,%s,sdrbrightness,%s,sdrsaturation,%s,sdr_min_luminance,%s,sdr_max_luminance,%s' \
    "$monitor" "$width" "$height" "$refresh_fmt" "$x" "$y" "$scale" "$transform" "$bitdepth" "$cm" "$sdrbrightness" "$sdrsaturation" "$sdrmin" "$sdrmax"
}

switch_monitor_cm() {
  local monitor="$1"
  local cm="$2"
  local bitdepth="$3"
  local rule
  rule="$(build_monitor_rule "$monitor" "$cm" "$bitdepth")"
  hyprctl keyword monitor "$rule" >/dev/null
}

geometry=""
target_monitor=""
capture_mode=""

case "$mode" in
  output)
    target_monitor="$(slurp -o -f '%o')" || exit 0
    capture_mode="output"
    ;;
  region)
    selection="$(slurp -f '%x,%y %wx%h|%o')" || exit 0
    geometry="${selection%%|*}"
    target_monitor="${selection##*|}"
    capture_mode="geometry"
    ;;
  window)
    windows="$(
      hyprctl -j clients | jq -r '
        .[]
        | select(.mapped and (.hidden | not) and (.workspace.id > 0))
        | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.address)"
      '
    )"

    if [[ -z "$windows" ]]; then
      printf 'No visible windows to select\n' >&2
      exit 1
    fi

    selection="$(printf '%s\n' "$windows" | slurp -r -f '%x,%y %wx%h|%o')" || exit 0
    geometry="${selection%%|*}"
    target_monitor="${selection##*|}"
    capture_mode="geometry"
    ;;
  *)
    printf 'Usage: %s <output|region|window> [output_dir]\n' "$0" >&2
    exit 2
    ;;
esac

if [[ -z "$target_monitor" || "$target_monitor" == "<unknown>" ]]; then
  target_monitor="$(get_focused_monitor)"
fi

if [[ -z "$target_monitor" ]]; then
  printf 'Unable to determine target monitor\n' >&2
  exit 1
fi

original_cm="$(get_monitor_field "$target_monitor" "colorManagementPreset")"
original_bitdepth="$(infer_bitdepth "$target_monitor")"
did_switch=0

restore_hdr_state() {
  if [[ "$did_switch" -eq 1 ]]; then
    switch_monitor_cm "$target_monitor" "$original_cm" "$original_bitdepth" || true
  fi
}

if [[ "$original_cm" == hdr* ]]; then
  did_switch=1
  trap restore_hdr_state EXIT INT TERM
  switch_monitor_cm "$target_monitor" "srgb" "8"
  sleep 0.08
fi

timestamp="$(date '+%Y-%m-%d %H-%M-%S')"
outfile="$output_dir/Screenshot from $timestamp.png"

case "$capture_mode" in
  output)
    grim -o "$target_monitor" "$outfile"
    ;;
  geometry)
    grim -g "$geometry" "$outfile"
    ;;
esac

if command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$outfile"
fi

if command -v dunstify >/dev/null 2>&1; then
  dunstify "Screenshot saved" "$outfile"
fi
