#!/usr/bin/env bash
set -euo pipefail

find_bin() {
  local name="$1"
  local c
  for c in \
    "$name" \
    "$HOME/.nix-profile/bin/$name" \
    "/run/current-system/sw/bin/$name" \
    "/nix/var/nix/profiles/default/bin/$name" \
    "$HOME/.local/state/nix/profile/bin/$name"; do
    if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then
      command -v "$c" 2>/dev/null || printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

notify_err() {
  local msg="$1"
  local dunstify_bin notify_bin
  dunstify_bin="$(find_bin dunstify 2>/dev/null || true)"
  notify_bin="$(find_bin notify-send 2>/dev/null || true)"

  if [[ -n "${dunstify_bin:-}" ]]; then
    "$dunstify_bin" -a "Waypipe Launcher" -u critical -t 8000 "Waypipe Launcher" "$msg" || true
  elif [[ -n "${notify_bin:-}" ]]; then
    "$notify_bin" "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

notify_warn() {
  local msg="$1"
  local dunstify_bin notify_bin
  dunstify_bin="$(find_bin dunstify 2>/dev/null || true)"
  notify_bin="$(find_bin notify-send 2>/dev/null || true)"

  if [[ -n "${dunstify_bin:-}" ]]; then
    "$dunstify_bin" -a "Waypipe Launcher" -u normal -t 4000 "Waypipe Launcher" "$msg" || true
  elif [[ -n "${notify_bin:-}" ]]; then
    "$notify_bin" "Waypipe Launcher" "$msg" || true
  else
    printf 'Waypipe Launcher: %s\n' "$msg" >&2
  fi
}

trap 'notify_err "launcher error at line $LINENO: $BASH_COMMAND"' ERR

log_file="${XDG_RUNTIME_DIR:-/tmp}/waypipe-launcher.log"
log() {
  printf '%s %s\n' "$(date -Is 2>/dev/null || date)" "$*" >>"$log_file" 2>/dev/null || true
}

debug() { [[ "${WAYPIPE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

need() { command -v "$1" >/dev/null 2>&1 || { notify_err "Missing dependency: $1"; exit 1; }; }

need tailscale
need jq
need waypipe
need wofi
need eww

log "launcher start"

eww_cfg="$HOME/.home-manager/config_files/eww-waypipe-launcher"
if [[ ! -d "$eww_cfg" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  eww_cfg="$script_dir/../config_files/eww-waypipe-launcher"
fi

if [[ ! -f "$eww_cfg/eww.yuck" ]]; then
  notify_err "Missing eww config: $eww_cfg/eww.yuck"
  exit 1
fi

tmp_root="${XDG_RUNTIME_DIR:-/tmp}"
tmp_dir="$(mktemp -d "$tmp_root/waypipe-launcher.XXXXXX")"
sel_file="$tmp_dir/selected"

cleanup() {
  if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch submap reset >/dev/null 2>&1 || true
  fi
  eww --config "$eww_cfg" close waypipe-hosts >/dev/null 2>&1 || true
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if ! eww --config "$eww_cfg" ping >/dev/null 2>&1; then
  eww --config "$eww_cfg" daemon >/dev/null 2>&1 &
  disown || true
fi

# Let Hyprland keybinds (up/down/enter) know where to write the selection.
eww --config "$eww_cfg" update wp_sel_file="$sel_file" cursor=0 >/dev/null 2>&1 || true
log "picker open sel_file=$sel_file"

# Allow ESC to close the picker using a Hyprland submap (if configured).
use_hypr_submap=0
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl binds -j 2>/dev/null | jq -e '.[] | select(.submap == "waypipe-launcher")' >/dev/null 2>&1; then
    hyprctl dispatch submap waypipe-launcher >/dev/null 2>&1 || true
    use_hypr_submap=1
  fi
fi

eww --config "$eww_cfg" open waypipe-hosts --arg selFile="$sel_file" --arg configDir="$eww_cfg" >/dev/null

host=""
while true; do
  if [[ -s "$sel_file" ]]; then
    host="$(<"$sel_file")"
    break
  fi

  if ! eww --config "$eww_cfg" active-windows 2>/dev/null | grep -q "waypipe-hosts"; then
    exit 0
  fi

  sleep 0.05
done

host="${host//$'\n'/}"
[[ -n "${host// }" ]] || exit 0
log "selected host=$host"
if debug; then
  notify_warn "selected $host"
fi

if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch submap reset >/dev/null 2>&1 || true
  use_hypr_submap=0
fi

# Refuse offline selection (still shows in menu, but won't run).
ts_json="$(tailscale status --json)"
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
  # Tailscale's .Online can be stale; allow attempting anyway.
  notify_warn "'$host' marked offline; attempting anyway"
  log "host marked offline, attempting anyway"
fi
# Run remote wofi (drun), get the printed command, eval it remotely.
# Use stdin (bash -s) to avoid ssh/quote parsing issues.
# Capture output so we can differentiate:
# - failure before a command is executed (real error)
# - non-zero exit status after the selected command ran (not necessarily an error)
tmp_out="$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" waypipe-launcher.out.XXXXXX)"
tmp_err="$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}" waypipe-launcher.err.XXXXXX)"
trap 'rm -f "$tmp_out" "$tmp_err" 2>/dev/null || true' RETURN

set +e
waypipe --no-gpu --xwls ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  -o ConnectTimeout=4 \
  -o ServerAliveInterval=5 \
  -o ServerAliveCountMax=1 \
  "$host" bash -s <<'REMOTE' >"$tmp_out" 2>"$tmp_err"
set -euo pipefail

echo "__WP_LAUNCHER_STAGE=wofi" >&2
if ! command -v wofi >/dev/null 2>&1; then
  echo "wofi not found on remote host" >&2
  exit 127
fi

cmd="$(GDK_BACKEND=wayland wofi --show drun --define drun-print_command=true)"
[[ -n "${cmd// }" ]] || exit 0

echo "__WP_LAUNCHER_STAGE=exec" >&2
eval "$cmd"
rc=$?
echo "__WP_LAUNCHER_EXEC_RC=$rc" >&2
exit $rc
REMOTE
rc=$?
set -e

cat "$tmp_out" >>"$log_file" 2>/dev/null || true
cat "$tmp_err" >>"$log_file" 2>/dev/null || true

if (( rc != 0 )); then
  if rg -q "__WP_LAUNCHER_STAGE=exec" "$tmp_err" 2>/dev/null; then
    # A command was selected and executed; don't treat non-zero program exit as a launcher error.
    log "remote command exited rc=$rc (post-exec) host=$host"
  else
    log "waypipe/ssh failed for host=$host rc=$rc"
    tail_msg="$(tail -n 12 "$tmp_err" 2>/dev/null || true)"
    if rg -q "Host key verification failed" "$tmp_err" 2>/dev/null; then
      notify_err "SSH host key not trusted for '$host'.\nRun: ssh $host\nThen re-run the launcher."
    else
      notify_err "Remote launcher failed on '$host' (rc=$rc).\n${tail_msg}"
    fi
    rm -f "$tmp_out" "$tmp_err" 2>/dev/null || true
    exit 1
  fi
fi

rm -f "$tmp_out" "$tmp_err" 2>/dev/null || true

log "launcher done"
