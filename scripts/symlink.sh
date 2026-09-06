#!/usr/bin/env bash
set -euo pipefail

declare -a LINKS=(
    # handy
    "$HOME/.home-manager/config_files/local/share/com.pais.handy/settings_store.json -> $HOME/.local/share/com.pais.handy/settings_store.json"

    # wofi
    "$HOME/.home-manager/config_files/wofi/config -> $HOME/.config/wofi/config"
    "$HOME/.home-manager/config_files/wofi/style.css -> $HOME/.config/wofi/style.css"

    # hyprland
    "$HOME/.home-manager/config_files/hypr/hyprlog.conf -> $HOME/.config/hypr/hyprlog.conf"
    "$HOME/.home-manager/config_files/hypr/hypridle.conf -> $HOME/.config/hypr/hypridle.conf"
    "$HOME/.home-manager/config_files/hypr/hyprpaper.conf -> $HOME/.config/hypr/hyprpaper.conf"
    "$HOME/.home-manager/config_files/hypr/hyprsunset.conf -> $HOME/.config/hypr/hyprsunset.conf"

    "$HOME/.home-manager/config_files/hypr/autostart.lua -> $HOME/.config/hypr/autostart.lua"
    "$HOME/.home-manager/config_files/hypr/appearance.lua -> $HOME/.config/hypr/appearance.lua"
    "$HOME/.home-manager/config_files/hypr/hyprland.lua -> $HOME/.config/hypr/hyprland.lua"
    "$HOME/.home-manager/config_files/hypr/keybinds.lua -> $HOME/.config/hypr/keybinds.lua"
    "$HOME/.home-manager/config_files/hypr/monitors.lua -> $HOME/.config/hypr/monitors.lua"
    "$HOME/.home-manager/config_files/hypr/variables.lua -> $HOME/.config/hypr/variables.lua"
    "$HOME/.home-manager/config_files/hypr/workspaces.lua -> $HOME/.config/hypr/workspaces.lua"

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

unlink_managed_directory_contents() {
    local source_dir="$1"
    local destination_dir="$2"
    local pattern="$3"
    local source_path destination_path

    shopt -s nullglob
    for source_path in "$source_dir"/$pattern; do
        [[ -f "$source_path" ]] || continue
        destination_path="$destination_dir/$(basename "$source_path")"
        [[ -L "$destination_path" ]] || continue
        [[ "$(readlink "$destination_path")" == "$source_path" ]] || continue
        rm -f "$destination_path"
    done
    shopt -u nullglob
}

if [[ "${DESKTOP_ENV_ENABLED:-false}" == "true" ]]; then
    link_directory_contents "$HOME/.home-manager/config_files/local/share/applications" "$HOME/.local/share/applications" '*.desktop'
else
    link_directory_contents "$HOME/.home-manager/config_files/local/share/applications" "$HOME/.local/share/applications" '*.desktop'
    unlink_managed_directory_contents "$HOME/.home-manager/config_files/local/share/applications" "$HOME/.local/share/applications" 'webapp-*.desktop'
fi
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
link_directory_contents "$HOME/.home-manager/config_files/local/share/icons/hicolor/128x128/apps" "$HOME/.local/share/icons/hicolor/128x128/apps" '*.svg'

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi
