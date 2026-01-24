chromium &
while true; do
	if [ -n "$(hyprctl clients | rg chromium)" ]; then
	    hyprctl dispatch movetoworkspacesilent special:browser
	    break
	fi
	sleep 0.1
done
