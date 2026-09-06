#!/usr/bin/env bash
set -euo pipefail

img_path="${1:-}"
cache_dir="$HOME/.cache/theme"
out_file="$cache_dir/wofi-accent.css"
accent_cache_dir="$cache_dir/accent-cache"

mkdir -p "$cache_dir"
mkdir -p "$accent_cache_dir"

default_accent="#58a6ff"

write_css() {
  local accent="$1"
  local hex="${accent#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  local css

  css="$(cat <<EOF
@define-color accent ${accent};
@define-color accent_soft rgba(${r}, ${g}, ${b}, 0.22);
EOF
)"

  if [[ -f "$out_file" ]] && [[ "$(<"$out_file")" == "$css" ]]; then
    return 0
  fi

  printf '%s\n' "$css" > "$out_file"
}

clamp_luminance() {
  local color="$1"
  local min_luma=140
  local max_luma=200

  awk -v color="$color" -v min="$min_luma" -v max="$max_luma" '
    function clamp(v) {
      if (v < 0) return 0
      if (v > 255) return 255
      return int(v + 0.5)
    }
    BEGIN {
      hex = substr(color, 2)
      r = strtonum("0x" substr(hex, 1, 2))
      g = strtonum("0x" substr(hex, 3, 2))
      b = strtonum("0x" substr(hex, 5, 2))

      luma = int((30 * r + 59 * g + 11 * b) / 100)
      if (luma >= min && luma <= max) {
        printf "#%02X%02X%02X\n", r, g, b
        exit
      }

      target = (luma < min) ? min : max

      if (luma == 0) {
        r = target
        g = target
        b = target
      } else {
        scale = target / luma
        r = clamp(r * scale)
        g = clamp(g * scale)
        b = clamp(b * scale)

        adjusted = int((30 * r + 59 * g + 11 * b) / 100)
        if (adjusted < min || adjusted > max) {
          delta = target - adjusted
          r = clamp(r + delta)
          g = clamp(g + delta)
          b = clamp(b + delta)
        }
      }

      printf "#%02X%02X%02X\n", r, g, b
    }
  '
}

cache_key_for_image() {
  local path="$1"
  local sig

  sig="$(stat -c '%Y:%s' "$path" 2>/dev/null || printf '0:0')"
  printf '%s\0%s\n' "$path" "$sig" | sha1sum | cut -d' ' -f1
}

if [[ -z "$img_path" || ! -f "$img_path" ]]; then
  write_css "$default_accent"
  exit 0
fi

cache_key="$(cache_key_for_image "$img_path")"
cache_file="$accent_cache_dir/$cache_key"

if [[ -s "$cache_file" ]]; then
  cached_accent="$(<"$cache_file")"
  if [[ "$cached_accent" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    best_accent="$(clamp_luminance "$cached_accent")"
    write_css "$best_accent"
    if [[ "$best_accent" != "$cached_accent" ]]; then
      printf '%s\n' "$best_accent" > "$cache_file"
    fi
    exit 0
  fi
fi

mapfile -t extracted < <(
  timeout 2s wallust run -q -s -T -N --backend thumb --print-scheme "$img_path" 2>/dev/null \
    | sed -n 's/^#\([0-9A-Fa-f]\{6\}\)$/#\1/p'
)

if [[ ${#extracted[@]} -eq 0 ]]; then
  mapfile -t extracted < <(
    timeout 2s wallust run -q -s -T -N --backend fastresize --print-scheme "$img_path" 2>/dev/null \
      | sed -n 's/^#\([0-9A-Fa-f]\{6\}\)$/#\1/p'
  )
fi

if [[ ${#extracted[@]} -eq 0 ]]; then
  write_css "$default_accent"
  exit 0
fi

score_color() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  local max=$r
  local min=$r

  (( g > max )) && max=$g
  (( b > max )) && max=$b
  (( g < min )) && min=$g
  (( b < min )) && min=$b

  local sat=$((max - min))
  local luma=$(((30 * r + 59 * g + 11 * b) / 100))
  local luma_penalty=$((luma - 140))
  (( luma_penalty < 0 )) && luma_penalty=$((-luma_penalty))

  # Prioritize vivid mid-tone colors.
  printf '%d\n' $((sat * 3 - luma_penalty))
}

best_src="$default_accent"
best_src_score=-999999
for c in "${extracted[@]}"; do
  s="$(score_color "$c")"
  if (( s > best_src_score )); then
    best_src="$c"
    best_src_score=$s
  fi
done

best_accent="$(clamp_luminance "$best_src")"

write_css "$best_accent"
printf '%s\n' "$best_accent" > "$cache_file"
