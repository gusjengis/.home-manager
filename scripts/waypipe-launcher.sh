#!/usr/bin/env bash
set -euo pipefail
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need tailscale
need jq
need wofi
need waypipe
ts_json="$(tailscale status --json)"

# Build menu entries.
# Display: just the short name (before first '.') and latency if online.
# Use full MagicDNS name for the actual ssh target.
mapfile -t peers < <(
  jq -r '
    .Peer
    | to_entries
    | map(.value)
    | map({
        dns: ((.DNSName // "") | sub("\\.$";"")),
        online: (.Online // false)
      })
    | map(select(.dns != ""))
    | sort_by(.dns | ascii_downcase)
    | .[]
    | (.dns + "\t" + (if .online then "true" else "false" end))
  ' <<<"$ts_json"
)

(( ${#peers[@]} > 0 )) || exit 0

tmp_root="${XDG_RUNTIME_DIR:-/tmp}"
tmp_dir="$(mktemp -d "$tmp_root/waypipe-launcher.XXXXXX")"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

declare -A count_for_short
for row in "${peers[@]}"; do
  IFS=$'\t' read -r dns _online_flag <<<"$row"
  short="${dns%%.*}"
  (( count_for_short[$short] = ${count_for_short[$short]:-0} + 1 ))
done

declare -A ssh_host_for_key
declare -A online_for_key

# Ping online hosts in parallel, store latency per displayed key.
for row in "${peers[@]}"; do
  IFS=$'\t' read -r dns online_flag <<<"$row"
  short="${dns%%.*}"
  key="$short"
  if (( ${count_for_short[$short]:-0} > 1 )); then
    key="$dns" # avoid ambiguity if short names collide
  fi

  ssh_host_for_key[$key]="$dns"
  online_for_key[$key]="$online_flag"

  if [[ "$online_flag" == "true" ]]; then
    safe_key="${key//[^A-Za-z0-9_.-]/_}"
    (
      out="$(tailscale ping --c 1 --timeout 800ms "$dns" 2>/dev/null || true)"
      latency="?"
      if [[ "$out" =~ in[[:space:]]+([0-9.]+ms) ]]; then
        latency="${BASH_REMATCH[1]}"
      fi
      printf '%s\n' "$latency" >"$tmp_dir/ping.$safe_key"
    ) &
  fi
done

wait || true

menu=""
for row in "${peers[@]}"; do
  IFS=$'\t' read -r dns online_flag <<<"$row"
  short="${dns%%.*}"
  key="$short"
  if (( ${count_for_short[$short]:-0} > 1 )); then
    key="$dns"
  fi

  if [[ "$online_flag" == "true" ]]; then
    safe_key="${key//[^A-Za-z0-9_.-]/_}"
    latency="?"
    [[ -f "$tmp_dir/ping.$safe_key" ]] && latency="$(<"$tmp_dir/ping.$safe_key")"
    menu+="$key\t<span foreground=\"#999999\">$latency</span>\n"
  else
    menu+="$key\t<span foreground=\"#777777\">offline</span>\n"
  fi
done

sel="$(
  printf '%b' "$menu" \
    | GDK_BACKEND=wayland wofi --dmenu --prompt "Remote machine" --allow-markup --insensitive
)" || exit 0

[[ -n "${sel// }" ]] || exit 0

key="${sel%%$'\t'*}"
[[ -n "$key" ]] || exit 0

host="${ssh_host_for_key[$key]:-$key}"

# Refuse offline selection (still shows in menu, but won't run).
online="$(
  jq -r --arg h "$host" '
    .Peer
    | to_entries
    | map(.value)
    | map(select(((.DNSName // "") | sub("\\.$";"")) == $h))
    | .[0].Online // false
  ' <<<"$ts_json"
)"

if [[ "$online" != "true" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Remote Launcher" "'$key' is offline"
  exit 1
fi
# Run remote wofi (drun), get the printed command, eval it remotely.
# Use stdin (bash -s) to avoid ssh/quote parsing issues.
waypipe --no-gpu --xwls ssh "$host" bash -s <<'REMOTE'
set -euo pipefail

cmd="$(GDK_BACKEND=wayland wofi --show drun --define drun-print_command=true)"
[[ -n "${cmd// }" ]] || exit 0
eval "$cmd"
REMOTE
