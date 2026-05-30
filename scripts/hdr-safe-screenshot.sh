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
  local sdrbrightness="$4"
  local sdrsaturation="$5"

  local fields width height refresh x y scale transform
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
          (.transform | tostring)
        ]
      | @tsv
    '
  )"

  IFS=$'\t' read -r width height refresh x y scale transform <<<"$fields"

  if [[ -z "$width" || -z "$height" || -z "$refresh" ]]; then
    printf 'Unable to read monitor geometry for %s\n' "$monitor" >&2
    exit 1
  fi

  local refresh_fmt
  refresh_fmt="$(printf '%.2f' "$refresh")"

  printf '%s,%sx%s@%s,%sx%s,%s,transform,%s,bitdepth,%s,cm,%s,sdrbrightness,%s,sdrsaturation,%s' \
    "$monitor" "$width" "$height" "$refresh_fmt" "$x" "$y" "$scale" "$transform" "$bitdepth" "$cm" "$sdrbrightness" "$sdrsaturation"
}

switch_monitor_cm() {
  local monitor="$1"
  local cm="$2"
  local bitdepth="$3"
  local sdrbrightness="$4"
  local sdrsaturation="$5"
  local rule

  rule="$(build_monitor_rule "$monitor" "$cm" "$bitdepth" "$sdrbrightness" "$sdrsaturation")"
  hyprctl keyword monitor "$rule" >/dev/null
}

wait_for_cm() {
  local monitor="$1"
  local expected="$2"
  local attempts="$3"
  local i current

  for ((i = 0; i < attempts; i++)); do
    current="$(get_monitor_field "$monitor" "colorManagementPreset")"
    if [[ "$current" == "$expected" || "$current" == "$expected"* ]]; then
      return 0
    fi
    sleep 0.05
  done

  return 1
}

numeric_equal() {
  local left="$1"
  local right="$2"

  [[ "$(printf '%.3f' "$left")" == "$(printf '%.3f' "$right")" ]]
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
original_sdrbrightness="$(get_monitor_field "$target_monitor" "sdrBrightness")"
original_sdrsaturation="$(get_monitor_field "$target_monitor" "sdrSaturation")"
original_sdrmin="$(get_monitor_field "$target_monitor" "sdrMinLuminance")"
original_sdrmax="$(get_monitor_field "$target_monitor" "sdrMaxLuminance")"
original_cm="${original_cm:-srgb}"
original_sdrbrightness="${original_sdrbrightness:-1.0}"
original_sdrsaturation="${original_sdrsaturation:-1.0}"
original_sdrmin="${original_sdrmin:-0.0}"
original_sdrmax="${original_sdrmax:-80}"
did_switch=0
capture_sdrbrightness="${HDR_SAFE_SCREENSHOT_SDR_BRIGHTNESS:-1.0}"
capture_sdrsaturation="${HDR_SAFE_SCREENSHOT_SDR_SATURATION:-1.0}"
capture_bitdepth="${HDR_SAFE_SCREENSHOT_CAPTURE_BITDEPTH:-8}"
capture_cm="${HDR_SAFE_SCREENSHOT_CAPTURE_CM:-srgb}"
switch_verify_attempts="${HDR_SAFE_SCREENSHOT_SWITCH_VERIFY_ATTEMPTS:-5}"

restore_hdr_state() {
  if [[ "$did_switch" -eq 1 ]]; then
    switch_monitor_cm "$target_monitor" "$original_cm" "$original_bitdepth" "$original_sdrbrightness" "$original_sdrsaturation" || true
    wait_for_cm "$target_monitor" "$original_cm" "$switch_verify_attempts" || true

    current_sdrmin="$(get_monitor_field "$target_monitor" "sdrMinLuminance")"
    current_sdrmax="$(get_monitor_field "$target_monitor" "sdrMaxLuminance")"
    current_sdrmin="${current_sdrmin:-0.0}"
    current_sdrmax="${current_sdrmax:-80}"

    if ! numeric_equal "$current_sdrmin" "$original_sdrmin" || ! numeric_equal "$current_sdrmax" "$original_sdrmax"; then
      hyprctl reload >/dev/null 2>&1 || true
    fi
  fi
}

did_switch=1
trap restore_hdr_state EXIT INT TERM
if ! switch_monitor_cm "$target_monitor" "$capture_cm" "$capture_bitdepth" "$capture_sdrbrightness" "$capture_sdrsaturation"; then
  printf 'Failed to apply capture monitor override\n' >&2
fi

if ! wait_for_cm "$target_monitor" "$capture_cm" "$switch_verify_attempts"; then
  printf 'HDR->SDR switch did not confirm, re-applying monitor override\n' >&2
  switch_monitor_cm "$target_monitor" "$capture_cm" "$capture_bitdepth" "$capture_sdrbrightness" "$capture_sdrsaturation" || true
  if ! wait_for_cm "$target_monitor" "$capture_cm" "$switch_verify_attempts"; then
    printf 'HDR->SDR switch failed; refusing to take a blown-out screenshot\n' >&2
    exit 1
  fi
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

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Screenshot saved" "$outfile"
fi
