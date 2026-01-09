# load all gifs in the wallpaper folder (./gifs)

wallpapers=(~/.home-manager/wallpapers/*)

swww-daemon &

CMD_PREFIX="swww img " 
SETTINGS=" --filter Nearest --transition-type none"

while true; do
  for img in $(shuf -e "${wallpapers[@]}"); do
    $CMD_PREFIX"$img" $SETTINGS &
    PID=$!
    sleep 300 # wallpaper duration (in seconds) 
    kill $PID 2>/dev/null
  done
done
