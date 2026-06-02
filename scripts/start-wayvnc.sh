#!/usr/bin/env bash
set -euo pipefail

mode="${VNC_OUTPUT_MODE:-1920x1080@60}"
position="${VNC_OUTPUT_POSITION:-3840x0}"
scale="${VNC_OUTPUT_SCALE:-1}"

headless_outputs() {
    hyprctl monitors | sed -n 's/^Monitor \(HEADLESS-[0-9][0-9]*\).*/\1/p'
}

output_name="$(headless_outputs | sort -V | sed -n '1p')"

if [ -z "$output_name" ]; then
    hyprctl output create headless >/dev/null
fi

for _ in {1..20}; do
    output_name="$(headless_outputs | sort -V | sed -n '1p')"
    if [ -n "$output_name" ]; then
        break
    fi
    sleep 0.1
done

if [ -z "$output_name" ]; then
    printf 'Unable to create a Hyprland headless output for wayvnc\n' >&2
    exit 1
fi

hyprctl keyword monitor "${output_name},${mode},${position},${scale}" >/dev/null
exec wayvnc --render-cursor --output="$output_name"
