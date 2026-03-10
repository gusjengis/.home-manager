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

get_monitor_layout_tsv() {
  local monitor="$1"
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
}

write_monitorv2_override() {
  local file="$1"
  local monitor="$2"
  local width="$3"
  local height="$4"
  local refresh="$5"
  local x="$6"
  local y="$7"
  local scale="$8"
  local transform="$9"
  local cm="${10}"
  local bitdepth="${11}"
  local sdrbrightness="${12}"
  local sdrmin="${13}"

  cat >"$file" <<EOF
monitorv2 {
 output = $monitor
 mode = ${width}x${height}@${refresh}
 scale = $scale
 transform = $transform
 position = ${x}x${y}
 bitdepth = $bitdepth
 cm = $cm
 sdrbrightness = $sdrbrightness
 sdr_min_luminance = $sdrmin
}
EOF
}

source_monitor_override() {
  local file="$1"
  hyprctl keyword source "$file" >/dev/null
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
  done

  return 1
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
original_sdrmin="$(get_monitor_field "$target_monitor" "sdrMinLuminance")"
original_cm="${original_cm:-srgb}"
original_sdrbrightness="${original_sdrbrightness:-1.0}"
original_sdrmin="${original_sdrmin:-0.0}"
did_switch=0
tmpdir=""
restore_override_file=""
capture_sdrbrightness="${HDR_SAFE_SCREENSHOT_SDR_BRIGHTNESS:-1.0}"
capture_sdrmin="${HDR_SAFE_SCREENSHOT_SDR_MIN_LUMINANCE:-0.0}"
capture_bitdepth="${HDR_SAFE_SCREENSHOT_CAPTURE_BITDEPTH:-8}"
capture_cm="${HDR_SAFE_SCREENSHOT_CAPTURE_CM:-srgb}"
switch_verify_attempts="${HDR_SAFE_SCREENSHOT_SWITCH_VERIFY_ATTEMPTS:-1}"

layout_fields="$(get_monitor_layout_tsv "$target_monitor")"
IFS=$'\t' read -r monitor_width monitor_height monitor_refresh monitor_x monitor_y monitor_scale monitor_transform <<<"$layout_fields"

if [[ -z "$monitor_width" || -z "$monitor_height" || -z "$monitor_refresh" ]]; then
  printf 'Unable to read monitor geometry for %s\n' "$target_monitor" >&2
  exit 1
fi

refresh_fmt="$(printf '%.2f' "$monitor_refresh")"

tmpdir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/hdr-safe-screenshot.XXXXXX")"
capture_override_file="$tmpdir/capture-monitorv2.conf"
restore_override_file="$tmpdir/restore-monitorv2.conf"

write_monitorv2_override "$capture_override_file" "$target_monitor" "$monitor_width" "$monitor_height" "$refresh_fmt" "$monitor_x" "$monitor_y" "$monitor_scale" "$monitor_transform" "$capture_cm" "$capture_bitdepth" "$capture_sdrbrightness" "$capture_sdrmin"
write_monitorv2_override "$restore_override_file" "$target_monitor" "$monitor_width" "$monitor_height" "$refresh_fmt" "$monitor_x" "$monitor_y" "$monitor_scale" "$monitor_transform" "$original_cm" "$original_bitdepth" "$original_sdrbrightness" "$original_sdrmin"

restore_hdr_state() {
  if [[ "$did_switch" -eq 1 ]]; then
    source_monitor_override "$restore_override_file" || true
  fi
  if [[ -n "$tmpdir" ]]; then
    rm -rf "$tmpdir" || true
  fi
}

did_switch=1
trap restore_hdr_state EXIT INT TERM
if ! source_monitor_override "$capture_override_file"; then
  printf 'Failed to apply capture monitorv2 override\n' >&2
fi

if ! wait_for_cm "$target_monitor" "$capture_cm" "$switch_verify_attempts"; then
  printf 'HDR->SDR switch did not confirm, re-applying monitorv2 override\n' >&2
  source_monitor_override "$capture_override_file" || true
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
