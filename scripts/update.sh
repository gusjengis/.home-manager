#!/usr/bin/env bash
set -u
set -o pipefail

hm_repo="$HOME/.home-manager"
modules_repo="/etc/nix-modules"
sync_script="$hm_repo/scripts/sync-repos.sh"

dunstify_bin="$HOME/.nix-profile/bin/dunstify"

hm_before="$(git -C "$hm_repo" rev-parse HEAD)"
modules_before="$(git -C "$modules_repo" rev-parse HEAD)"

bash "$sync_script" || true

hm_after="$(git -C "$hm_repo" rev-parse HEAD)"
modules_after="$(git -C "$modules_repo" rev-parse HEAD)"

if [[ "$modules_before" != "$modules_after" ]]; then
  if ! sudo nixos-rebuild switch --impure --flake /etc/nixos/; then
    "$dunstify_bin" --urgency=critical "nixos-rebuild" "nix-modules changed, rebuild failed"
  else
    "$dunstify_bin" "nixos-rebuild" "rebuild succeeded" || true
  fi
fi

if [[ "$hm_before" != "$hm_after" ]]; then
  if ! home-manager switch --impure --flake ~/.home-manager/; then
    "$dunstify_bin" --urgency=critical "home-manager" "home-manager changed, switch failed"
  else
    "$dunstify_bin" "home-manager" "rehome succeeded" || true
  fi
fi
