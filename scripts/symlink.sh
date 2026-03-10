#!/usr/bin/env bash
set -euo pipefail

declare -a LINKS=(
    # tmux
    "$HOME/.home-manager/config_files/tmux/tmux.conf -> $HOME/.config/tmux/tmux.conf"

    # default apps
    "$HOME/.home-manager/config_files/xfce4/helpers.rc -> $HOME/.config/xfce4/helpers.rc"
    "$HOME/.home-manager/config_files/mimeapps.list -> $HOME/.config/mimeapps.list"
    # opencode
    "$HOME/.home-manager/config_files/opencode/opencode.json -> $HOME/.config/opencode/opencode.json"
    "$HOME/.home-manager/config_files/opencode/model.json -> $HOME/.local/state/opencode/model.json"
    "$HOME/.home-manager/config_files/opencode/kv.json -> $HOME/.local/state/opencode/kv.json"

    # ambxst
    "$HOME/.home-manager/config_files/ambxst/binds.json -> $HOME/.config/ambxst/binds.json"
    "$HOME/.home-manager/config_files/ambxst/config/ai.json -> $HOME/.config/ambxst/config/ai.json"
    "$HOME/.home-manager/config_files/ambxst/config/bar.json -> $HOME/.config/ambxst/config/bar.json"
    "$HOME/.home-manager/config_files/ambxst/config/desktop.json -> $HOME/.config/ambxst/config/desktop.json"
    "$HOME/.home-manager/config_files/ambxst/config/dock.json -> $HOME/.config/ambxst/config/dock.json"
    "$HOME/.home-manager/config_files/ambxst/config/hyprland.json -> $HOME/.config/ambxst/config/hyprland.json"
    "$HOME/.home-manager/config_files/ambxst/config/lockscreen.json -> $HOME/.config/ambxst/config/lockscreen.json"
    "$HOME/.home-manager/config_files/ambxst/config/notch.json -> $HOME/.config/ambxst/config/notch.json"
    "$HOME/.home-manager/config_files/ambxst/config/overview.json -> $HOME/.config/ambxst/config/overview.json"
    "$HOME/.home-manager/config_files/ambxst/config/performance.json -> $HOME/.config/ambxst/config/performance.json"
    "$HOME/.home-manager/config_files/ambxst/config/prefix.json -> $HOME/.config/ambxst/config/prefix.json"
    "$HOME/.home-manager/config_files/ambxst/config/system.json -> $HOME/.config/ambxst/config/system.json"
    "$HOME/.home-manager/config_files/ambxst/config/theme.json -> $HOME/.config/ambxst/config/theme.json"
    "$HOME/.home-manager/config_files/ambxst/config/weather.json -> $HOME/.config/ambxst/config/weather.json"
    "$HOME/.home-manager/config_files/ambxst/config/workspaces.json -> $HOME/.config/ambxst/config/workspaces.json"
    "$HOME/.home-manager/config_files/ambxst/presets/active_preset -> $HOME/.config/ambxst/presets/active_preset"
    "$HOME/.home-manager/config_files/local/share/ambxst/pinnedapps.json -> $HOME/.local/share/ambxst/pinnedapps.json"

    # ssh
    "$HOME/.home-manager/config_files/ssh/config -> $HOME/.ssh/config"
    "$HOME/.home-manager/config_files/ssh/authorized_keys -> $HOME/.ssh/authorized_keys"

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
    "$HOME/.home-manager/config_files/waybar/config.json -> $HOME/.config/waybar/config.json"
    "$HOME/.home-manager/config_files/waybar/config.json -> $HOME/.config/waybar/config.jsonc"
    "$HOME/.home-manager/config_files/waybar/style.css -> $HOME/.config/waybar/style.css"

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
    "$HOME/.home-manager/config_files/hypr/monitors.conf -> $HOME/.config/hypr/monitors.conf"

    # which-key
    "$HOME/.home-manager/config_files/hypr/scripts/which-key.sh -> $HOME/.config/hypr/scripts/which-key.sh"
    "$HOME/.home-manager/config_files/eww-which-key/eww.scss -> $HOME/.config/eww-which-key/eww.scss"
    "$HOME/.home-manager/config_files/eww-which-key/eww.yuck -> $HOME/.config/eww-which-key/eww.yuck"

    # eww calendar
    "$HOME/.home-manager/config_files/eww-calendar/eww.scss -> $HOME/.config/eww-calendar/eww.scss"
    "$HOME/.home-manager/config_files/eww-calendar/eww.yuck -> $HOME/.config/eww-calendar/eww.yuck"

    # niri
    "$HOME/.home-manager/config_files/niri/config.kdl -> $HOME/.config/niri/config.kdl"
)

for item in "${LINKS[@]}"; do
    source="${item%% -> *}"
    destination="${item##* -> }"
    mkdir -p "$(dirname "$destination")"
    ln -sf "$source" "$destination" &
done
wait

link_directory_contents() {
    local source_dir="$1"
    local destination_dir="$2"
    local pattern="$3"
    local source_path destination_path

    mkdir -p "$destination_dir"

    shopt -s nullglob
    for source_path in "$source_dir"/$pattern; do
        [[ -f "$source_path" ]] || continue
        destination_path="$destination_dir/$(basename "$source_path")"
        ln -sf "$source_path" "$destination_path" &
    done
    wait
    shopt -u nullglob
}

link_directory_contents "$HOME/.home-manager/config_files/local/share/applications" "$HOME/.local/share/applications" '*.desktop'
mkdir -p "$HOME/.local/share/icons/hicolor"

link_hicolor_index_theme() {
    local destination="$HOME/.local/share/icons/hicolor/index.theme"
    local candidate

    for candidate in \
        "/run/current-system/sw/share/icons/hicolor/index.theme" \
        "$HOME/.nix-profile/share/icons/hicolor/index.theme"; do
        if [[ -f "$candidate" ]]; then
            ln -sf "$candidate" "$destination"
            return 0
        fi
    done

    shopt -s nullglob
    for candidate in /nix/store/*-hicolor-icon-theme-*/share/icons/hicolor/index.theme; do
        if [[ -f "$candidate" ]]; then
            ln -sf "$candidate" "$destination"
            shopt -u nullglob
            return 0
        fi
    done
    shopt -u nullglob
}

link_hicolor_index_theme
link_directory_contents "$HOME/.home-manager/config_files/local/share/icons/hicolor/128x128/apps" "$HOME/.local/share/icons/hicolor/128x128/apps" '*.png'

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

# SSH refuses to use private keys that are readable by group/others.
# Git does not reliably preserve file permissions for regular files, so if
# secrets are synced, they can end up as 0644 on checkout. Fix permissions
# here as a best-effort.
if [[ -d "$HOME/.config/secrets/ssh" ]]; then
    chmod 700 "$HOME/.config/secrets" "$HOME/.config/secrets/ssh" 2>/dev/null || true

    shopt -s nullglob
    for f in "$HOME/.config/secrets/ssh/"*; do
        [[ -f "$f" ]] || continue
        case "$f" in
            *.pub) chmod 644 "$f" 2>/dev/null || true ;;
            *) chmod 600 "$f" 2>/dev/null || true ;;
        esac
    done
fi
