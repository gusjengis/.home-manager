#!/usr/bin/env bash
set -u
set -o pipefail

hm_repo="$HOME/.home-manager"
sync_command="${SYNC_REPOS_COMMAND:-sync-repos}"
rebuild_command="${REBUILD_COMMAND:-rebuild}"
rehome_command="${REHOME_COMMAND:-rehome}"

state_dir="${XDG_RUNTIME_DIR:-/run/user/$UID}/home-manager-notifications"
log_file="$state_dir/update.log"
deployment_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/home-manager"
deployed_revision_file="$deployment_state_dir/deployed-revision"

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

if ! "$sync_command"; then
  notify --urgency=critical "sync" "one or more repositories failed to sync"
  failed=1
fi

hm_after="$(git -C "$hm_repo" rev-parse HEAD)"
deployed_revision=""
if [[ -r "$deployed_revision_file" ]]; then
  deployed_revision="$(<"$deployed_revision_file")"
fi

if [[ "$deployed_revision" != "$hm_after" ]]; then
  if ! "$rebuild_command"; then
    notify --urgency=critical "nixos-rebuild" "unified configuration changed, rebuild failed"
    failed=1
  else
    notify "nixos-rebuild" "rebuild succeeded"
    if ! "$rehome_command"; then
      notify --urgency=critical "home-manager" "home-manager changed, switch failed"
      failed=1
    else
      notify "home-manager" "rehome succeeded"
      mkdir -p "$deployment_state_dir"
      printf '%s\n' "$hm_after" >"$deployed_revision_file.tmp"
      mv "$deployed_revision_file.tmp" "$deployed_revision_file"
    fi
  fi
fi

if [[ "$deployed_revision" == "$hm_after" ]]; then
  notify "update" "no repository changes found"
fi

if [[ "$failed" -ne 0 ]]; then
  notify --urgency=critical "update" "update completed with errors"
  exit 1
fi

notify "update" "update complete"
