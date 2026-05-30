#!/usr/bin/env bash
set -u
set -o pipefail

hm_repo="$HOME/.home-manager"
modules_repo="/etc/nix-modules"
sync_script="$hm_repo/scripts/sync-repos.sh"

state_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}/home-manager-notifications"
log_file="$state_dir/update.log"

notify() {
  local urgency="normal"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --urgency=*) urgency="${1#--urgency=}"; shift ;;
      -u|--urgency) urgency="${2:-normal}"; shift 2 ;;
      *) break ;;
    esac
  done

  mkdir -p "$state_dir"
  printf '%s\t%s\t%s\t%s\n' "$(date --iso-8601=seconds)" "$urgency" "${1:-update}" "${2:-}" >>"$log_file"
}

notify "update" "starting sync and rebuild checks"

hm_before="$(git -C "$hm_repo" rev-parse HEAD)"
modules_before="$(git -C "$modules_repo" rev-parse HEAD)"

bash "$sync_script" || true

hm_after="$(git -C "$hm_repo" rev-parse HEAD)"
modules_after="$(git -C "$modules_repo" rev-parse HEAD)"

if [[ "$modules_before" != "$modules_after" ]]; then
  if ! rebuild; then
    notify --urgency=critical "nixos-rebuild" "nix-modules changed, rebuild failed"
  else
    notify "nixos-rebuild" "rebuild succeeded"
  fi
fi

if [[ "$hm_before" != "$hm_after" ]]; then
  if ! rehome; then
    notify --urgency=critical "home-manager" "home-manager changed, switch failed"
  else
    notify "home-manager" "rehome succeeded"
  fi
fi

if [[ "$modules_before" == "$modules_after" && "$hm_before" == "$hm_after" ]]; then
  notify "update" "no repository changes found"
fi
    notify "update" "update complete"
