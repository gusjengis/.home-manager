#!/usr/bin/env bash

sleep 15

answer=$(printf "No\nYes" | wofi --dmenu --prompt "Leave focus lock?")

if [ "$answer" = "Yes" ]; then
    hyprctl dispatch submap reset
fi

