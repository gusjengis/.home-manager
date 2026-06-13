#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

debug() { [[ "${SUNSHINE_LAUNCHER_DEBUG:-0}" == "1" ]]; }

dbg_notify() {
    local msg="$1"
    if ! debug; then
        return 0
    fi

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Sunshine Launcher" -u normal -t 2500 "Sunshine Launcher" "$msg" || true
    else
        printf 'Sunshine Launcher: %s\n' "$msg" >&2
    fi
}

dbg_error() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Sunshine Launcher" -u critical -t 8000 "Sunshine Launcher" "$msg" || true
    elif debug; then
        printf 'Sunshine Launcher: %s\n' "$msg" >&2
    fi
}

need() { command -v "$1" >/dev/null 2>&1 || { dbg_error "Missing dependency: $1"; exit 1; }; }

need eww
need jq

eww_cfg="$HOME/.home-manager/config_files/eww-sunshine-launcher"
if [[ ! -d "$eww_cfg" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    eww_cfg="$script_dir/../config_files/eww-sunshine-launcher"
fi

if [[ ! -f "$eww_cfg/eww.yuck" ]]; then
    dbg_error "Missing eww config: $eww_cfg/eww.yuck"
    exit 1
fi

tmp_root="${XDG_RUNTIME_DIR:-/tmp}"
tmp_dir="$(mktemp -d "$tmp_root/sunshine-launcher.XXXXXX")"
sel_file="$tmp_dir/selected"

cleanup() {
    if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
        hyprctl dispatch submap reset >/dev/null 2>&1 || true
    fi
    eww --config "$eww_cfg" close sunshine-hosts >/dev/null 2>&1 || true
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

if ! eww --config "$eww_cfg" ping >/dev/null 2>&1; then
    eww --config "$eww_cfg" daemon >/dev/null 2>&1 &
    disown || true
fi

eww --config "$eww_cfg" update sl_sel_file="$sel_file" cursor=0 >/dev/null 2>&1 || true

use_hypr_submap=0
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
    if hyprctl binds -j 2>/dev/null | jq -e '.[] | select(.submap == "sunshine-launcher")' >/dev/null 2>&1; then
        hyprctl dispatch submap sunshine-launcher >/dev/null 2>&1 || true
        use_hypr_submap=1
    fi
fi

screen_arg=()
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
    focused_monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -n1)"
    if [[ -n "${focused_monitor:-}" && "$focused_monitor" != "null" ]]; then
        screen_arg=(--arg screen="$focused_monitor")
    fi
fi

eww --config "$eww_cfg" open sunshine-hosts --arg selFile="$sel_file" --arg configDir="$eww_cfg" "${screen_arg[@]}" >/dev/null

host=""
while true; do
    if [[ -s "$sel_file" ]]; then
        host="$(<"$sel_file")"
        break
    fi

    if ! eww --config "$eww_cfg" active-windows 2>/dev/null | grep -q "sunshine-hosts"; then
        exit 0
    fi

    sleep 0.05
done

host="${host//$'\n'/}"
[[ -n "${host// }" ]] || exit 0
dbg_notify "selected $host"

if [[ "${use_hypr_submap:-0}" == "1" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch submap reset >/dev/null 2>&1 || true
    use_hypr_submap=0
fi

exec sunshine-connect "$host"
