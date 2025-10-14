#!/usr/bin/env bash
# wallpaper_cycle.sh

if ! command -v linux-wallpaperengine &>/dev/null; then
  exit 1
fi

# Wallpaper IDs
wallpapers=(
  1130661944
  2347484937
  2500069318
  2994110411
  2995358277
  3006959414
  3007837944
  3016047975
  3019470510
  3029865244
  3030685386
  3036895455
  3077334064
  3094852179
  3123321641
)

# Wallpaper command prefix
CMD_PREFIX="env XDG_SESSION_TYPE=wayland linux-wallpaperengine /home/gusjengis/.home-manager/wallpapers/wallpaper_engine/"
SETTINGS="--assets-dir /home/gusjengis/.home-manager/wallpapers/wallpaper_engine/assets --screen-root HDMI-A-1 -v 0"

while true; do
  for id in $(shuf -e "${wallpapers[@]}"); do
    $CMD_PREFIX"$id"/ $SETTINGS &
    PID=$!
    sleep 300 # wallpaper duration (in seconds) 
    kill $PID 2>/dev/null
  done
done
