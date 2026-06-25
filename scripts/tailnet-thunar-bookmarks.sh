set -euo pipefail

probe_timeout="${TAILNET_THUNAR_PROBE_TIMEOUT:-10}"
refresh_interval="${TAILNET_THUNAR_REFRESH_INTERVAL:-5}"
full_refresh_interval="${TAILNET_THUNAR_FULL_REFRESH_INTERVAL:-60}"

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
bookmarks_file="$config_home/gtk-3.0/bookmarks"
state_dir="$state_home/tailnet-thunar-bookmarks"
managed_file="$state_dir/managed-bookmarks"
status_hash_file="$state_dir/status-hash"

bookmark_label() {
  local host="$1"
  host="${host%%.*}"
  printf '%s (Tailnet)' "$host"
}

peer_lines() {
  local status_json="$1"

  jq -r '
    .Self.DNSName as $self |
    .Peer[]? |
    select(.DNSName != null and .DNSName != "" and .DNSName != $self) |
    .DNSName |
    sub("[.]$"; "")
  ' "$status_json" | sort -u
}

probe_peer() {
  local host="$1"

  if nc -z -w "$probe_timeout" "$host" 22 >/dev/null 2>&1; then
    printf 'sftp://%s/ %s\n' "$host" "$(bookmark_label "$host")"
  fi
}

write_bookmarks() {
  local new_managed="$1"
  local tmp_preserved tmp_next

  mkdir -p "$(dirname "$bookmarks_file")" "$state_dir"
  touch "$bookmarks_file" "$managed_file"

  tmp_preserved="$(mktemp)"
  tmp_next="$(mktemp)"

  if [ -s "$managed_file" ]; then
    grep -F -x -v -f "$managed_file" "$bookmarks_file" > "$tmp_preserved" || true
  else
    cp "$bookmarks_file" "$tmp_preserved"
  fi

  {
    cat "$tmp_preserved"
    if [ -s "$tmp_preserved" ] && [ -s "$new_managed" ]; then
      printf '\n'
    fi
    cat "$new_managed"
  } > "$tmp_next"

  if ! cmp -s "$tmp_next" "$bookmarks_file"; then
    install -m 0644 "$tmp_next" "$bookmarks_file"
  fi

  install -m 0644 "$new_managed" "$managed_file"
  rm -f "$tmp_preserved" "$tmp_next"
}

refresh_once() {
  local status_json peers_file new_managed host

  mkdir -p "$state_dir"
  status_json="$(mktemp)"
  peers_file="$(mktemp)"
  new_managed="$(mktemp)"

  if ! tailscale status --json > "$status_json" 2>/dev/null; then
    write_bookmarks "$new_managed"
    rm -f "$status_json" "$peers_file" "$new_managed"
    return 0
  fi

  peer_lines "$status_json" > "$peers_file"

  while IFS= read -r host; do
    [ -n "$host" ] || continue
    probe_peer "$host" >> "$new_managed" &
  done < "$peers_file"
  wait

  sort -u -o "$new_managed" "$new_managed"
  write_bookmarks "$new_managed"
  rm -f "$status_json" "$peers_file" "$new_managed"
}

status_hash() {
  local status_json="$1"

  jq -r '
    [
      .Self.DNSName,
      (.Peer[]? | [.DNSName, .Online, .Active, .TailscaleIPs[0]] | @tsv)
    ] | @tsv
  ' "$status_json" | sha256sum | cut -d " " -f 1
}

watch() {
  local last_full now status_json current_hash previous_hash

  last_full=0
  while true; do
    mkdir -p "$state_dir"
    status_json="$(mktemp)"
    now="$(date +%s)"

    if tailscale status --json > "$status_json" 2>/dev/null; then
      current_hash="$(status_hash "$status_json")"
      previous_hash=""
      [ -f "$status_hash_file" ] && previous_hash="$(cat "$status_hash_file")"

      if [ "$current_hash" != "$previous_hash" ] || [ $((now - last_full)) -ge "$full_refresh_interval" ]; then
        refresh_once
        printf '%s\n' "$current_hash" > "$status_hash_file"
        last_full="$now"
      fi
    else
      refresh_once
      rm -f "$status_hash_file"
      last_full="$now"
    fi

    rm -f "$status_json"
    sleep "$refresh_interval"
  done
}

case "${1:-refresh}" in
  refresh)
    refresh_once
    ;;
  watch)
    watch
    ;;
  *)
    printf 'Usage: %s [refresh|watch]\n' "$0" >&2
    exit 2
    ;;
esac
