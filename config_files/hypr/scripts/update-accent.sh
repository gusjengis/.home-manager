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

  cat > "$out_file" <<EOF
@define-color accent ${accent};
@define-color accent_soft rgba(${r}, ${g}, ${b}, 0.22);
EOF
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
    write_css "$cached_accent"
    exit 0
  fi
fi

declare -a github_accents=(
  "#58a6ff"
  "#3fb950"
  "#d29922"
  "#ff7b72"
  "#bc8cff"
  "#39c5cf"
)

mapfile -t extracted < <(
  timeout 3s wallust run -q -s -T -N --backend kmeans --print-scheme "$img_path" 2>/dev/null \
    | sed -n 's/^#\([0-9A-Fa-f]\{6\}\)$/#\1/p'
)

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

hex_dist() {
  local a="${1#\#}"
  local b="${2#\#}"
  local ar=$((16#${a:0:2}))
  local ag=$((16#${a:2:2}))
  local ab=$((16#${a:4:2}))
  local br=$((16#${b:0:2}))
  local bg=$((16#${b:2:2}))
  local bb=$((16#${b:4:2}))
  local dr=$((ar - br))
  local dg=$((ag - bg))
  local db=$((ab - bb))
  printf '%d\n' $((dr * dr + dg * dg + db * db))
}

best_accent="$default_accent"
best_dist=999999999
for a in "${github_accents[@]}"; do
  d="$(hex_dist "$best_src" "$a")"
  if (( d < best_dist )); then
    best_dist=$d
    best_accent="$a"
  fi
done

write_css "$best_accent"
printf '%s\n' "$best_accent" > "$cache_file"
