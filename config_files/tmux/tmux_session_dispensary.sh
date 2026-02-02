#!/usr/bin/env bash

DIRS=(
  "$HOME/Documents/Code"
  # "$HOME/Documents/Code/Plinth"
  # "$HOME/Documents/Code/Mosaic"
  "$HOME/Documents/Obsidian"
  "$HOME/wkspaces/"
)

EXTRA_DIRS=(
  "$HOME/.config/nvim"
  "$HOME/.config/secrets"
  "$HOME/.home-manager/"
  "/etc/nixos"
  "/etc/nix-modules"

)

if [[ $# -eq 1 ]]; then
  selected=$1
else
  fd_entries=$(
    fd -t d -d 1 . --absolute-path "${DIRS[@]}" 2>/dev/null \
    | sed "s|^$HOME/||"
  )
  extra_entries=$(
    printf "%s\n" "${EXTRA_DIRS[@]}" \
    | sed "s|^$HOME/||"
  )
  selected=$(
    printf "%s\n" "$fd_entries" "$extra_entries" \
    | sk --color="bw" --tmux center,50%
  )
  [[ $selected ]] && [[ ! "$selected" =~ ^/ ]] && selected="$HOME/$selected"
fi

[[ -z ${selected:-} ]] && exit 0

selected_name=$(basename "$selected" | tr . _)
if ! tmux has-session -t "$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected" "nvim"
  tmux new-window -t "$selected_name" -n "opencode" -c "$selected" "opencode"
  tmux select-window -t "$selected_name:1"
fi

tmux switch-client -t "$selected_name"
