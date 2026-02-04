#!/usr/bin/env bash
while true; do
    ~/.home-manager/scripts/battery-notify.sh || true
    sleep 60
done
