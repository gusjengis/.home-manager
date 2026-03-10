#!/usr/bin/env bash
set -euo pipefail

desktop_name="${1:?usage: launch-desktop-entry.sh <desktop-id>}"
desktop_name="${desktop_name%.desktop}"
desktop_id="${desktop_name}.desktop"

desktop_path="$HOME/.local/share/applications/$desktop_id"
if [[ ! -f "$desktop_path" ]]; then
    desktop_path="$HOME/.home-manager/config_files/local/share/applications/$desktop_id"
fi

if command -v gtk-launch >/dev/null 2>&1; then
    exec gtk-launch "$desktop_name"
fi

exec gio launch "$desktop_path"
