#!/usr/bin/env bash

sleep 15

answer=$(printf "No\nYes" | wofi --dmenu --prompt "Leave focus lock?")

if [ "$answer" = "Yes" ]; then
    if hyprctl dispatch 'hl.dsp.submap("reset")'; then
        exit 0
    fi

    for socket in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/hypr/*/.socket.sock; do
        [ -S "$socket" ] || continue

        instance=${socket%/.socket.sock}
        instance=${instance##*/}
        HYPRLAND_INSTANCE_SIGNATURE="$instance" hyprctl dispatch 'hl.dsp.submap("reset")' && exit 0
    done
fi
