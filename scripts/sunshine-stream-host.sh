#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

usage() {
    printf 'Usage: sunshine-stream-host WIDTH HEIGHT FPS SCALE\n' >&2
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing dependency on host: %s\n' "$1" >&2
        exit 127
    }
}

width="${1:-}"
height="${2:-}"
fps="${3:-60}"
scale="${4:-1}"

if [[ ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ || ! "$fps" =~ ^[0-9]+$ ]]; then
    usage
    exit 64
fi

if [[ ! "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    scale=1
fi

need hyprctl
need jq
need systemctl

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

find_hyprland() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl monitors -j >/dev/null 2>&1; then
        return 0
    fi

    local sock sig
    shopt -s nullglob
    for sock in "$XDG_RUNTIME_DIR"/hypr/*/.socket.sock; do
        [[ -S "$sock" ]] || continue
        sig="$(basename "$(dirname "$sock")")"
        if HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl monitors -j >/dev/null 2>&1; then
            export HYPRLAND_INSTANCE_SIGNATURE="$sig"
            shopt -u nullglob
            return 0
        fi
    done
    shopt -u nullglob

    printf 'Unable to find an active Hyprland instance for %s\n' "$USER" >&2
    exit 1
}

find_hyprland

output="${SUNSHINE_OUTPUT_NAME:-sunshine-stream}"
mode="${width}x${height}@${fps}"
created=0

output_exists() {
    hyprctl monitors -j | jq -e --arg output "$output" '.[] | select(.name == $output)' >/dev/null
}

if ! output_exists; then
    hyprctl output create headless "$output" >/dev/null
    created=1
fi

for _ in {1..30}; do
    if output_exists; then
        break
    fi
    sleep 0.1
done

if ! output_exists; then
    printf 'Unable to create Hyprland headless output %s\n' "$output" >&2
    exit 1
fi

monitors_json="$(hyprctl monitors -j)"
position="${SUNSHINE_OUTPUT_POSITION:-auto}"
if [[ "$position" == "auto" ]]; then
    x="$(jq -r --arg output "$output" '[.[] | select(.name != $output and (.disabled | not)) | (.x + .width)] | max // 0' <<<"$monitors_json")"
    y="$(jq -r --arg output "$output" '[.[] | select(.name != $output and (.disabled | not)) | .y] | min // 0' <<<"$monitors_json")"
    position="${x}x${y}"
fi

hyprctl keyword monitor "${output},${mode},${position},${scale}" >/dev/null

if systemctl --user is-active --quiet sunshine.service; then
    if (( created )); then
        systemctl --user restart sunshine.service
        state="restarted"
    else
        state="already-running"
    fi
else
    systemctl --user start sunshine.service
    state="started"
fi

for _ in {1..40}; do
    if systemctl --user is-active --quiet sunshine.service; then
        printf 'sunshine=%s output=%s mode=%s position=%s scale=%s\n' "$state" "$output" "$mode" "$position" "$scale"
        exit 0
    fi
    sleep 0.25
done

systemctl --user status sunshine.service --no-pager >&2 || true
exit 1
