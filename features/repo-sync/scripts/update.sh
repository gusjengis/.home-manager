#!/usr/bin/env bash
set -u
set -o pipefail

hm_repo="$HOME/.home-manager"
modules_repo="/etc/nix-modules"
sync_command="${SYNC_REPOS_COMMAND:-sync-repos}"
rebuild_command="${REBUILD_COMMAND:-rebuild}"
rehome_command="${REHOME_COMMAND:-rehome}"

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

failed=0

if [[ ! -d "$hm_repo/.git" ]]; then
  notify --urgency=critical "home-manager" "$hm_repo is not a Git repository"
  exit 1
fi

if [[ ! -d "$modules_repo/.git" ]]; then
  notify --urgency=critical "nixos-rebuild" "$modules_repo is not a Git repository"
  exit 1
fi

hm_before="$(git -C "$hm_repo" rev-parse HEAD)"
modules_before="$(git -C "$modules_repo" rev-parse HEAD)"

if ! "$sync_command"; then
  notify --urgency=critical "sync" "one or more repositories failed to sync"
  failed=1
fi

hm_after="$(git -C "$hm_repo" rev-parse HEAD)"
modules_after="$(git -C "$modules_repo" rev-parse HEAD)"

if [[ "$modules_before" != "$modules_after" ]]; then
  if ! "$rebuild_command"; then
    notify --urgency=critical "nixos-rebuild" "nix-modules changed, rebuild failed"
    failed=1
  else
    notify "nixos-rebuild" "rebuild succeeded"
  fi
fi

if [[ "$hm_before" != "$hm_after" ]]; then
  if ! "$rehome_command"; then
    notify --urgency=critical "home-manager" "home-manager changed, switch failed"
    failed=1
  else
    notify "home-manager" "rehome succeeded"
  fi
fi

if [[ "$modules_before" == "$modules_after" && "$hm_before" == "$hm_after" ]]; then
  notify "update" "no repository changes found"
fi

if [[ "$failed" -ne 0 ]]; then
  notify --urgency=critical "update" "update completed with errors"
  exit 1
fi

notify "update" "update complete"
