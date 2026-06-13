#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

usage() {
    printf 'Usage: sunshine-stream-host WIDTH HEIGHT FPS SCALE | sunshine-stream-host --stop\n' >&2
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing dependency on host: %s\n' "$1" >&2
        exit 127
    }
}

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
state_file="$XDG_RUNTIME_DIR/sunshine-stream-monitors.tsv"

restart_shell() {
    if command -v ambxst >/dev/null 2>&1; then
        while IFS= read -r env_line; do
            export "$env_line"
        done < <(
            systemctl --user show-environment 2>/dev/null \
                | grep -E '^(DISPLAY|WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|QT_QPA_PLATFORM|QT_WAYLAND_DISABLE_WINDOWDECORATION)='
        )

        export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
        export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
        export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
        export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
        export QT_QPA_PLATFORM="wayland"

        pkill -x qs >/dev/null 2>&1 || true
        pkill -x quickshell >/dev/null 2>&1 || true
        pkill -f 'ambxst-shell.*shell.qml' >/dev/null 2>&1 || true

        if command -v systemd-run >/dev/null 2>&1; then
            systemd-run --user --collect --quiet \
                --setenv="DISPLAY=${DISPLAY:-}" \
                --setenv="WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
                --setenv="XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
                --setenv="DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS" \
                --setenv="XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP" \
                --setenv="XDG_SESSION_TYPE=$XDG_SESSION_TYPE" \
                --setenv="HYPRLAND_INSTANCE_SIGNATURE=${HYPRLAND_INSTANCE_SIGNATURE:-}" \
                --setenv="QT_QPA_PLATFORM=$QT_QPA_PLATFORM" \
                ambxst >/tmp/ambxst-sunshine.log 2>&1 || true
        else
            nohup env \
                DISPLAY="${DISPLAY:-}" \
                WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
                XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
                DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
                XDG_CURRENT_DESKTOP="$XDG_CURRENT_DESKTOP" \
                XDG_SESSION_TYPE="$XDG_SESSION_TYPE" \
                HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-}" \
                QT_QPA_PLATFORM="$QT_QPA_PLATFORM" \
                ambxst >/tmp/ambxst-sunshine.log 2>&1 &
            disown || true
        fi

        for _ in {1..30}; do
            if pgrep -x qs >/dev/null 2>&1 || pgrep -x quickshell >/dev/null 2>&1; then
                return 0
            fi
            sleep 0.1
        done
    fi
}

restore_monitors() {
    systemctl --user stop sunshine.service >/dev/null 2>&1 || true

    if [[ -s "$state_file" ]]; then
        while IFS=$'\t' read -r name mode saved_position saved_scale; do
            [[ -n "${name:-}" && -n "${mode:-}" && -n "${saved_position:-}" && -n "${saved_scale:-}" ]] || continue
            hyprctl keyword monitor "${name},${mode},${saved_position},${saved_scale}" >/dev/null || true
        done <"$state_file"
        rm -f "$state_file"
    else
        hyprctl reload >/dev/null 2>&1 || true
    fi

    if hyprctl monitors -j | jq -e --arg output "$output" '.[] | select(.name == $output)' >/dev/null; then
        hyprctl output remove "$output" >/dev/null 2>&1 || true
    fi

    restart_shell
}

if [[ "${1:-}" == "--stop" || "${1:-}" == "stop" ]]; then
    restore_monitors
    printf 'sunshine=stopped output=%s restored=1\n' "$output"
    exit 0
fi

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

mode="${width}x${height}@${fps}"

output_exists() {
    hyprctl monitors -j | jq -e --arg output "$output" '.[] | select(.name == $output)' >/dev/null
}

if ! output_exists; then
    hyprctl output create headless "$output" >/dev/null
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
if [[ ! -e "$state_file" ]]; then
    jq -r --arg output "$output" '
      .[]
      | select(.name != $output and (.disabled | not))
      | [
          .name,
          ((.width | tostring) + "x" + (.height | tostring) + "@" + (.refreshRate | tostring)),
          ((.x | tostring) + "x" + (.y | tostring)),
          (.scale | tostring)
        ]
      | @tsv
    ' <<<"$monitors_json" >"$state_file"
fi

position="${SUNSHINE_OUTPUT_POSITION:-0x0}"

hyprctl keyword monitor "${output},${mode},${position},${scale}" >/dev/null
while IFS=$'\t' read -r name _mode _saved_position _saved_scale; do
    [[ -n "${name:-}" ]] || continue
    hyprctl keyword monitor "${name},disable" >/dev/null || true
done <"$state_file"

hyprctl dispatch focusmonitor "$output" >/dev/null || true
hyprctl dispatch workspace "${SUNSHINE_WORKSPACE:-99}" >/dev/null || true
hyprctl dispatch focusmonitor "$output" >/dev/null || true
restart_shell

if systemctl --user is-active --quiet sunshine.service; then
    systemctl --user restart sunshine.service
    state="restarted"
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
