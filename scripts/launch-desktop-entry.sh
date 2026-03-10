#!/usr/bin/env bash
set -euo pipefail

desktop_id="${1:?usage: launch-desktop-entry.sh <desktop-id>}"
desktop_id="${desktop_id%.desktop}.desktop"

desktop_path="$HOME/.local/share/applications/$desktop_id"
if [[ ! -f "$desktop_path" ]]; then
    desktop_path="$HOME/.home-manager/config_files/local/share/applications/$desktop_id"
fi

exec gio launch "$desktop_path"
