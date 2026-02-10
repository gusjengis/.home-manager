#!/usr/bin/env bash
set -euo pipefail
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need tailscale
need jq
need wofi
need waypipe
ts_json="$(tailscale status --json)"
# Build menu lines as: "<dnsname>\t<label...>"
# Keep dnsname as the first field (no markup) so we can parse selection reliably.
menu="$(
  jq -r '
    .Peer
    | to_entries
    | map(.value)
    | map({
        dns: ((.DNSName // "") | sub("\\.$";"")),
        name: (.HostName // ""),
        online: (.Online // false)
      })
    | map(select(.dns != ""))
    | sort_by(.name | ascii_downcase)
    | .[]
    | if .online then
        "\(.dns)\t\(.name)"
      else
        "\(.dns)\t<span foreground=\"#777777\">\(.name) (offline)</span>"
      end
  ' <<<"$ts_json"
)"
[ -n "$menu" ] || exit 0
sel="$(
  printf '%s\n' "$menu" \
    | GDK_BACKEND=wayland wofi --dmenu --prompt "Remote machine" --allow-markup --insensitive
)" || exit 0
[ -n "${sel// }" ] || exit 0
host="${sel%%$'\t'*}"
[ -n "$host" ] || exit 0
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
if [ "$online" != "true" ]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Remote Launcher" "'$host' is offline"
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
