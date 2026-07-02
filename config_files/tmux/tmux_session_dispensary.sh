#!/usr/bin/env bash

DIRS=(
  "$HOME/Documents/Code"
  "$HOME/Documents/Code/Plinth"
  "$HOME/Documents/Code/Mosaic"
  "$HOME/Documents/Obsidian"
  "$HOME/wkspaces/"
)

EXTRA_DIRS=(
  "$HOME/Wallpapers"
  "$HOME/.config/nvim"
  "$HOME/.config/secrets"
  "$HOME/.home-manager/"
  "/etc/nixos"
  "/etc/nix-modules"

)

IGNORE_DIRS=(
  "$HOME/wkspaces/Cross The Line/"
)

filter_ignored_dirs() {
  local entry

  while IFS= read -r entry; do
    [[ -z $entry ]] && continue

    if [[ " ${IGNORE_DIRS[*]} " == *" $entry "* ]]; then
      continue
    fi

    printf "%s\n" "$entry"
  done
}

if [[ $# -eq 1 ]]; then
  selected=$1
else
  fd_entries=$(
    fd -t d -d 1 . --absolute-path "${DIRS[@]}" 2>/dev/null \
    | filter_ignored_dirs \
    | sed "s|^$HOME/||"
  )
  extra_entries=$(
    printf "%s\n" "${EXTRA_DIRS[@]}" \
    | filter_ignored_dirs \
    | sed "s|^$HOME/||"
  )
  selected=$(
    printf "%s\n" "$fd_entries" "$extra_entries" \
    | sk --color="bg:#0d1117,fg:#c9d1d9,matched:#58a6ff,matched_bg:#0d1117,current:#c9d1d9,current_bg:#161b22,current_match:#79c0ff,current_match_bg:#161b22,prompt:#58a6ff,pointer:#58a6ff,marker:#3fb950,spinner:#58a6ff,info:#8b949e,header:#8b949e,border:#30363d" --tmux center,50%
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
