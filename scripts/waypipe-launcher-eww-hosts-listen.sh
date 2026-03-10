#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_error() {
  local msg="$1"
  if ! debug; then
    return 0
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || { dbg_error "Missing dependency: $1"; exit 1; }; }
need tailscale
need jq

interval="${WAYPIPE_LAUNCHER_PING_INTERVAL:-2}"
timeout="${WAYPIPE_LAUNCHER_PING_TIMEOUT:-800ms}"

while true; do
  ts_json="$(tailscale status --json 2>/dev/null || printf '{"Peer":{}}')"

  mapfile -t peers < <(
    jq -r '
      .Peer
      | to_entries
      | map(.value)
      | map({
          dns: ((.DNSName // "") | sub("\\.$";"")),
          host: (.HostName // ""),
          online: (.Online // false)
        })
      | map(select(.dns != ""))
      | map(select((.host | ascii_downcase) == "nixos"))
      | sort_by(.dns | ascii_downcase)
      | .[]
      | (.dns + "\t" + (if .online then "true" else "false" end))
    ' <<<"$ts_json"
  )

  if (( ${#peers[@]} == 0 )); then
    printf '[]\n'
    sleep "$interval"
    continue
  fi

  tmp_root="${XDG_RUNTIME_DIR:-/tmp}"
  tmp_dir="$(mktemp -d "$tmp_root/waypipe-launcher-ping.XXXXXX")"

  declare -A count_for_short=()
  for row in "${peers[@]}"; do
    IFS=$'\t' read -r dns _online_flag <<<"$row"
    short="${dns%%.*}"
    (( count_for_short[$short] = ${count_for_short[$short]:-0} + 1 ))
  done

  for row in "${peers[@]}"; do
    IFS=$'\t' read -r dns online_flag <<<"$row"
    [[ "$online_flag" == "true" ]] || continue

    safe_dns="${dns//[^A-Za-z0-9_.-]/_}"
    (
      out="$(tailscale ping --c 1 --timeout "$timeout" "$dns" 2>/dev/null || true)"
      latency="?"
      if [[ "$out" =~ in[[:space:]]+([0-9.]+ms) ]]; then
        latency="${BASH_REMATCH[1]}"
      fi
      printf '%s\n' "$latency" >"$tmp_dir/ping.$safe_dns"
    ) &
  done

  wait || true

  {
    i=0
    for row in "${peers[@]}"; do
      IFS=$'\t' read -r dns online_flag <<<"$row"
      short="${dns%%.*}"
      display="$short"
      if (( ${count_for_short[$short]:-0} > 1 )); then
        display="$dns"
      fi

      latency=""
      if [[ "$online_flag" == "true" ]]; then
        safe_dns="${dns//[^A-Za-z0-9_.-]/_}"
        latency="?"
        [[ -f "$tmp_dir/ping.$safe_dns" ]] && latency="$(<"$tmp_dir/ping.$safe_dns")"
      fi

      jq -nc \
        --argjson idx "$i" \
        --arg ssh "$dns" \
        --arg short "$short" \
        --arg display "$display" \
        --arg latency "$latency" \
        --argjson online "$online_flag" \
        '{idx:$idx, ssh:$ssh, short:$short, display:$display, online:$online, latency:$latency}'

      i=$((i + 1))
    done
  } | jq -cs '.'

  rm -rf "$tmp_dir"

  sleep "$interval"
done
