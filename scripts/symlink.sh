#!/usr/bin/env bash
set -euo pipefail

declare -a LINKS=(
    # tmux
    "$HOME/.home-manager/config_files/tmux/tmux.conf -> $HOME/.config/tmux/tmux.conf"

    # default apps
    "$HOME/.home-manager/config_files/xfce4/helpers.rc -> $HOME/.config/xfce4/helpers.rc"
    "$HOME/.home-manager/config_files/mimeapps.list -> $HOME/.config/mimeapps.list"
    "$HOME/.home-manager/config_files/local/share/applications/nvim.desktop -> $HOME/.local/share/applications/nvim.desktop"

    # opencode
    "$HOME/.home-manager/config_files/opencode/model.json -> $HOME/.local/state/opencode/model.json"
    "$HOME/.home-manager/config_files/opencode/kv.json -> $HOME/.local/state/opencode/kv.json"

    # ssh
    "$HOME/.home-manager/config_files/ssh/config -> $HOME/.ssh/config"
    "$HOME/.config/secrets/ssh/id_ed25519 -> $HOME/.ssh/id_ed25519"
    "$HOME/.home-manager/config_files/ssh/id_ed25519.pub -> $HOME/.ssh/id_ed25519.pub"

    # kitty
    "$HOME/.home-manager/config_files/kitty/kitty.conf -> $HOME/.config/kitty/kitty.conf"

    # pipes-rs
    "$HOME/.home-manager/config_files/pipes-rs/config.toml -> $HOME/.config/pipes-rs/config.toml"

    # dunst
    "$HOME/.home-manager/config_files/dunst/dunstrc -> $HOME/.config/dunst/dunstrc"

    # wofi
    "$HOME/.home-manager/config_files/wofi/config -> $HOME/.config/wofi/config"
    "$HOME/.home-manager/config_files/wofi/style.css -> $HOME/.config/wofi/style.css"

    # waybar
    "$HOME/.home-manager/config_files/waybar/style.css -> $HOME/.config/waybar/style.css"
    "$HOME/.home-manager/config_files/waybar/config.json -> $HOME/.config/waybar/config.json"

    # hyprland
    "$HOME/.home-manager/config_files/hypr/autostart.conf -> $HOME/.config/hypr/autostart.conf"
    "$HOME/.home-manager/config_files/hypr/hyprlog.conf -> $HOME/.config/hypr/hyprlog.conf"
    "$HOME/.home-manager/config_files/hypr/hypridle.conf -> $HOME/.config/hypr/hypridle.conf"
    "$HOME/.home-manager/config_files/hypr/hyprland.conf -> $HOME/.config/hypr/hyprland.conf"
    "$HOME/.home-manager/config_files/hypr/hyprpaper.conf -> $HOME/.config/hypr/hyprpaper.conf"
    "$HOME/.home-manager/config_files/hypr/hyprsunset.conf -> $HOME/.config/hypr/hyprsunset.conf"
    "$HOME/.home-manager/config_files/hypr/keybinds.conf -> $HOME/.config/hypr/keybinds.conf"
    "$HOME/.home-manager/config_files/hypr/workspaces.conf -> $HOME/.config/hypr/workspaces.conf"
    "$HOME/.home-manager/config_files/hypr/variables.conf -> $HOME/.config/hypr/variables.conf"

    # which-key
    "$HOME/.home-manager/config_files/hypr/scripts/which-key.sh -> $HOME/.config/hypr/scripts/which-key.sh"
    "$HOME/.home-manager/config_files/eww-which-key/eww.scss -> $HOME/.config/eww-which-key/eww.scss"
    "$HOME/.home-manager/config_files/eww-which-key/eww.yuck -> $HOME/.config/eww-which-key/eww.yuck"

    # wallpapers
    "$HOME/.home-manager/wallpapers/ -> $HOME/Wallpapers"
)

for item in "${LINKS[@]}"; do
    source="${item%% -> *}"
    destination="${item##* -> }"
    mkdir -p "$(dirname "$destination")"
    ln -sf "$source" "$destination" &
done
wait
