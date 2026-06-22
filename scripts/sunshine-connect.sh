#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"

debug() { [[ "${SUNSHINE_CONNECT_DEBUG:-0}" == "1" ]]; }

notify_info() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Sunshine Remote" -t 3000 "Sunshine Remote" "$msg" >/dev/null 2>&1 || true
    elif debug; then
        printf 'Sunshine Remote: %s\n' "$msg" >&2
    fi
}

notify_error() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Sunshine Remote" -u critical -t 8000 "Sunshine Remote" "$msg" >/dev/null 2>&1 || true
    else
        printf 'Sunshine Remote: %s\n' "$msg" >&2
    fi
}

need() {
    command -v "$1" >/dev/null 2>&1 || {
        notify_error "Missing dependency: $1"
        exit 127
    }
}

with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    else
        "$@"
    fi
}

if [[ "$#" -eq 0 ]]; then
    exec sunshine-launcher
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    printf 'Usage: sunshine-connect HOST\n' >&2
    printf 'Set SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS/SCALE to override the client display mode.\n' >&2
    exit 0
fi

host="$1"
shift || true

need jq
need moonlight
need ssh

width="${SUNSHINE_CLIENT_WIDTH:-}"
height="${SUNSHINE_CLIENT_HEIGHT:-}"
fps="${SUNSHINE_CLIENT_FPS:-}"
scale="${SUNSHINE_CLIENT_SCALE:-}"

if [[ -z "$width" || -z "$height" || -z "$fps" || -z "$scale" ]]; then
    if command -v hyprctl >/dev/null 2>&1; then
        monitors_json="$(hyprctl monitors -j 2>/dev/null || printf '[]')"
        monitor_json="$(jq -c 'map(select(.focused == true))[0] // .[0] // {}' <<<"$monitors_json")"
        width="${width:-$(jq -r '.width // empty' <<<"$monitor_json")}"
        height="${height:-$(jq -r '.height // empty' <<<"$monitor_json")}"
        fps="${fps:-$(jq -r '(.refreshRate // 60) | floor' <<<"$monitor_json")}"
        scale="${scale:-$(jq -r '.scale // 1' <<<"$monitor_json")}"
    fi
fi

width="${width:-1920}"
height="${height:-1080}"
fps="${fps:-60}"
scale="${scale:-1}"

if [[ ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ || ! "$fps" =~ ^[0-9]+$ ]]; then
    notify_error "Invalid client mode: ${width}x${height}@${fps}"
    exit 64
fi

if (( fps < 1 )); then
    fps=60
fi

bitrate="${SUNSHINE_MOONLIGHT_BITRATE:-}"
if [[ -z "$bitrate" ]]; then
    pixels_per_second=$(( width * height * fps ))
    if (( pixels_per_second >= 800000000 )); then
        bitrate=120000
    elif (( pixels_per_second >= 450000000 )); then
        bitrate=80000
    elif (( pixels_per_second >= 220000000 )); then
        bitrate=50000
    else
        bitrate=30000
    fi
fi

ssh_opts=(
    -o BatchMode=yes
    -o StrictHostKeyChecking=accept-new
    -o ConnectTimeout=5
    -o ServerAliveInterval=5
    -o ServerAliveCountMax=1
)

remote_prepare='set -euo pipefail
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
if command -v sunshine-stream-host >/dev/null 2>&1; then
    exec sunshine-stream-host "$@"
fi
if [[ -x "$HOME/.home-manager/scripts/sunshine-stream-host.sh" ]]; then
    exec bash "$HOME/.home-manager/scripts/sunshine-stream-host.sh" "$@"
fi
printf "sunshine-stream-host was not found on remote host\\n" >&2
exit 127
'

if debug; then
    notify_info "Preparing $host at ${width}x${height}@${fps} scale ${scale}"
fi

if ! ssh "${ssh_opts[@]}" "$host" bash -s -- "$width" "$height" "$fps" "$scale" <<<"$remote_prepare"; then
    notify_error "Failed to start Sunshine on $host"
    exit 1
fi

stop_remote() {
    ssh "${ssh_opts[@]}" "$host" bash -s -- <<'REMOTE' >/dev/null 2>&1 || true
set -euo pipefail
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
if command -v sunshine-stream-host >/dev/null 2>&1; then
    exec sunshine-stream-host --stop
fi
if [[ -x "$HOME/.home-manager/scripts/sunshine-stream-host.sh" ]]; then
    exec bash "$HOME/.home-manager/scripts/sunshine-stream-host.sh" --stop
fi
REMOTE
}

load_pairing_env() {
    local secrets_files=()
    if [[ -n "${SUNSHINE_PAIRING_ENV:-}" ]]; then
        secrets_files+=("$SUNSHINE_PAIRING_ENV")
    else
        secrets_files+=("$HOME/.config/secrets/api_keys/env_vars")
        secrets_files+=("$HOME/.config/secrets/sunshine/env")
    fi

    local secrets_file
    for secrets_file in "${secrets_files[@]}"; do
        if [[ -r "$secrets_file" ]]; then
            set -a
            source "$secrets_file"
            set +a
        fi
    done
}

ensure_paired() {
    if with_timeout 10s moonlight list "$host" >/dev/null 2>&1; then
        return 0
    fi

    if [[ "${SUNSHINE_AUTO_PAIR:-1}" != "1" ]]; then
        return 0
    fi

    load_pairing_env

    local api_user="${SUNSHINE_USERNAME:-${SUNSHINE_USER:-}}"
    local api_password="${SUNSHINE_PASSWORD:-}"
    if [[ -z "$api_user" || -z "$api_password" ]]; then
        notify_info "Moonlight is not paired with $host; set SUNSHINE_USERNAME and SUNSHINE_PASSWORD in local secrets to auto-pair"
        return 0
    fi

    need curl

    local pin="${SUNSHINE_PAIRING_PIN:-}"
    if [[ ! "$pin" =~ ^[0-9]{4}$ ]]; then
        printf -v pin '%04d' "$((RANDOM % 10000))"
    fi

    local client_name="${SUNSHINE_PAIRING_CLIENT_NAME:-${HOSTNAME:-moonlight}}"
    local payload
    payload="$(jq -cn --arg pin "$pin" --arg name "$client_name" '{pin: $pin, name: $name}')"

    local log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/sunshine-remote"
    mkdir -p "$log_dir"

    local pair_log
    pair_log="$(mktemp "$log_dir/pair-${host}.XXXXXX.log")"

    notify_info "Pairing Moonlight with $host"

    set +e
    moonlight pair "$host" --pin "$pin" >"$pair_log" 2>&1 &
    local pair_pid=$!
    set -e

    local accepted=0
    for _ in {1..80}; do
        if ! kill -0 "$pair_pid" 2>/dev/null; then
            break
        fi

        local pin_response
        pin_response="$(curl --fail --silent --show-error --insecure \
            --user "$api_user:$api_password" \
            --header 'Content-Type: application/json' \
            --data "$payload" \
            "https://$host:47990/api/pin" 2>/dev/null || true)"
        if jq -e '.status == true' >/dev/null 2>&1 <<<"$pin_response"; then
            accepted=1
            break
        fi

        sleep 0.25
    done

    for _ in {1..40}; do
        if ! kill -0 "$pair_pid" 2>/dev/null; then
            break
        fi
        sleep 0.25
    done

    if kill -0 "$pair_pid" 2>/dev/null; then
        kill "$pair_pid" 2>/dev/null || true
    fi

    set +e
    wait "$pair_pid"
    set -e

    if (( accepted == 1 )) && with_timeout 10s moonlight list "$host" >/dev/null 2>&1; then
        rm -f "$pair_log"
        return 0
    fi

    notify_error "Automatic Moonlight pairing failed for $host; see $pair_log"
    return 1
}

if ! ensure_paired; then
    stop_remote
    exit 1
fi

app="${SUNSHINE_MOONLIGHT_APP:-Desktop}"
pointer_speed_scale="${SUNSHINE_CLIENT_POINTER_SPEED_SCALE:-0.2}"
if [[ ! "$pointer_speed_scale" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    pointer_speed_scale="0.2"
fi

moonlight_env=()
if [[ "${SUNSHINE_MOONLIGHT_ABSOLUTE_MOUSE:-0}" != "1" ]]; then
    moonlight_env+=(SDL_MOUSE_RELATIVE_SPEED_SCALE="$pointer_speed_scale")
fi

moonlight_args=(
    stream
    --resolution "${width}x${height}"
    --fps "$fps"
    --bitrate "$bitrate"
    --display-mode fullscreen
    --capture-system-keys always
    --quit-after
    --keep-awake
)

if [[ "${SUNSHINE_MOONLIGHT_ABSOLUTE_MOUSE:-0}" == "1" ]]; then
    moonlight_args+=(--absolute-mouse)
else
    moonlight_args+=(--no-absolute-mouse)
fi

moonlight_args+=(--video-codec "${SUNSHINE_MOONLIGHT_CODEC:-H.264}")
moonlight_args+=(--video-decoder "${SUNSHINE_MOONLIGHT_DECODER:-software}")

if [[ "${SUNSHINE_MOONLIGHT_HDR:-0}" == "1" ]]; then
    moonlight_args+=(--hdr)
fi

set +e
env "${moonlight_env[@]}" moonlight "${moonlight_args[@]}" "$host" "$app"
rc=$?
set -e

stop_remote

if (( rc != 0 )); then
    notify_error "Moonlight failed for $host"
fi

exit "$rc"
