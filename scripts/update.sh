#!/usr/bin/env bash
set -u
set -o pipefail

hm_repo="$HOME/.home-manager"
modules_repo="/etc/nix-modules"
sync_script="$hm_repo/scripts/sync-repos.sh"

dunstify_bin="$(command -v dunstify || true)"

notify() {
  if [[ -n "$dunstify_bin" ]]; then
    "$dunstify_bin" "$@" || true
  fi
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
