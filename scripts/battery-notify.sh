#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.cache/battery-notify-15pct"

acpi_output=$(acpi -b 2>/dev/null || exit 0)

capacity=$(echo "$acpi_output" | grep -oP '\d+(?=%)' | head -1)
status=$(echo "$acpi_output" | grep -oP '(Charging|Discharging|Full)' | head -1)

if [ "$status" != "Discharging" ]; then
    rm -f "$STATE_FILE"
    exit 0
fi

if [ "$capacity" -le 15 ]; then
    if [ ! -f "$STATE_FILE" ]; then
        $HOME/.nix-profile/bin/notify-send --urgency=critical "Battery Low" "Battery at ${capacity}% - please charge"
        touch "$STATE_FILE"
    fi
else
    rm -f "$STATE_FILE"
fi
