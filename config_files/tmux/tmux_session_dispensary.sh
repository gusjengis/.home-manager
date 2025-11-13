#!/usr/bin/env bash

DIRS=(
  "$HOME/Documents/Code"
  "$HOME/Documents/zed-forks/"
  "$HOME/Documents/Code/Plinth"
  "$HOME/Documents/Code/Mosaic"
  "$HOME/Documents/Obsidian"
  "$HOME/wkspaces/"
)

if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(
    fd -t d -d 1 . --absolute-path "${DIRS[@]}" \
    | sed "s|^$HOME/||" \
    | sk --margin 10% --color="bw"
  )
  [[ $selected ]] && selected="$HOME/$selected"
fi

[[ -z ${selected:-} ]] && exit 0

selected_name=$(basename "$selected" | tr . _)
if ! tmux has-session -t "$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
  tmux select-window -t "$selected_name:1"
fi

tmux switch-client -t "$selected_name"
