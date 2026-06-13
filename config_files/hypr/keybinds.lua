local home = os.getenv("HOME")

local function bindd(keys, description, dispatcher, opts)
	opts = opts or {}
	opts.description = description
	hl.bind(keys, dispatcher, opts)
end

bindd(
	"SUPER + CTRL + ALT + SPACE",
	"Remote App Launcher",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/waypipe-launcher.sh")
)
bindd(
	"SUPER + CTRL + ALT + M",
	"Moonlight Remote Launcher",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/sunshine-launcher.sh")
)
bindd("SUPER + Q", "Launch Terminal", hl.dsp.exec_cmd(terminal))
bindd("SUPER + B", "Launch Browser", hl.dsp.exec_cmd(browser))
hl.bind("ALT + F4", hl.dsp.window.close())
bindd("SUPER + F11", "Fullscreen", hl.dsp.window.fullscreen({ mode = "maximized" }))
bindd("SUPER + F", "Launch File Manager", hl.dsp.exec_cmd(fileManager))
bindd("SUPER + V", "Toogle Floating", hl.dsp.window.float())
bindd(
	"SUPER + SHIFT + N",
	"Next Wallpaper",
	hl.dsp.exec_cmd("bash " .. home .. "/.home-manager/config_files/hypr/scripts/next-wallpaper.sh")
)
bindd("SUPER + CTRL + W", "Restart Waybar", hl.dsp.exec_cmd("pkill waybar; nohup waybar >/tmp/waybar.log 2>&1 &"))
bindd("SUPER + J", "Rotate Split", hl.dsp.layout("togglesplit"))

bindd("code:202", "Dictate", hl.dsp.exec_cmd("handy --toggle-transcription"))
hl.bind("code:202", hl.dsp.exec_cmd("handy --toggle-transcription"), { release = true })

bindd(
	"SUPER + SHIFT + S",
	"Screenshot",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh output ~/Pictures/Screenshots")
)
bindd(
	"SUPER + SHIFT + A",
	"Screenshot Area",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh region ~/Pictures/Screenshots")
)
bindd(
	"SUPER + SHIFT + W",
	"Screenshot Window",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh window ~/Pictures/Screenshots")
)

bindd("SUPER + SHIFT + left", "Swap Window Left", hl.dsp.window.swap({ direction = "left" }))
bindd("SUPER + SHIFT + right", "Swap Window Right", hl.dsp.window.swap({ direction = "right" }))
bindd("SUPER + SHIFT + up", "Swap Window Up", hl.dsp.window.swap({ direction = "up" }))
bindd("SUPER + SHIFT + down", "Swap Window Down", hl.dsp.window.swap({ direction = "down" }))

hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin({ action = "set" }))

for i = 1, 10 do
	local key = i % 10
	bindd("SUPER + " .. key, "Workspace " .. i, hl.dsp.focus({ workspace = tostring(i), on_current_monitor = true }))
	bindd("SUPER + SHIFT + " .. key, "Move to Workspace " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

bindd("SUPER + CTRL + ALT + SHIFT + E", "Exit Hyprland", hl.dsp.exit())
bindd("SUPER + CTRL + ALT + SHIFT + S", "Shutdown", hl.dsp.exec_cmd("alga power off; $systemctl poweroff"))
bindd("SUPER + CTRL + ALT + SHIFT + R", "Restart", hl.dsp.exec_cmd("$systemctl reboot"))

bindd("SUPER + mouse:272", "Move Window", hl.dsp.window.drag(), { mouse = true })
bindd("SUPER + mouse:273", "Resize Window", hl.dsp.window.resize(), { mouse = true })

bindd(
	"XF86AudioRaiseVolume",
	"Hidden",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
bindd(
	"XF86AudioLowerVolume",
	"Hidden",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
bindd(
	"XF86AudioMute",
	"Hidden",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)

bindd("XF86AudioNext", "Hidden", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bindd("XF86AudioPause", "Hidden", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bindd("XF86AudioPlay", "Hidden", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bindd("XF86AudioPrev", "Hidden", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

local xwaylandvideobridge = { class = "^(xwaylandvideobridge)$" }
hl.window_rule({ name = "xwaylandvideobridge-opacity", match = xwaylandvideobridge, opacity = "0.0 override" })
hl.window_rule({ name = "xwaylandvideobridge-no-anim", match = xwaylandvideobridge, no_anim = true })
hl.window_rule({ name = "xwaylandvideobridge-no-initial-focus", match = xwaylandvideobridge, no_initial_focus = true })
hl.window_rule({ name = "xwaylandvideobridge-max-size", match = xwaylandvideobridge, max_size = "1 1" })
hl.window_rule({ name = "xwaylandvideobridge-no-blur", match = xwaylandvideobridge, no_blur = true })
hl.window_rule({ name = "xwaylandvideobridge-no-focus", match = xwaylandvideobridge, no_focus = true })

bindd("SUPER + H", "Hop", hl.dsp.exec_cmd("pkill wl-kbptr || wl-kbptr -c ~/.home-manager/config_files/wl-kbptr/config"))

hl.define_submap("waypipe-launcher", function()
	hl.bind(
		"escape",
		hl.dsp.exec_cmd(
			"eww --config "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher close waypipe-hosts; hyprctl dispatch submap reset"
		)
	)
	hl.bind(
		"up",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/waypipe-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher up"
		)
	)
	hl.bind(
		"down",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/waypipe-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher down"
		)
	)
	hl.bind(
		"k",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/waypipe-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher up"
		)
	)
	hl.bind(
		"j",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/waypipe-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher down"
		)
	)
	hl.bind(
		"Return",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/waypipe-launcher-eww-activate.sh "
				.. home
				.. "/.home-manager/config_files/eww-waypipe-launcher; hyprctl dispatch submap reset"
		)
	)
end)

hl.define_submap("sunshine-launcher", function()
	hl.bind(
		"escape",
		hl.dsp.exec_cmd(
			"eww --config "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher close sunshine-hosts; hyprctl dispatch submap reset"
		)
	)
	hl.bind(
		"up",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/sunshine-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher up"
		)
	)
	hl.bind(
		"down",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/sunshine-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher down"
		)
	)
	hl.bind(
		"k",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/sunshine-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher up"
		)
	)
	hl.bind(
		"j",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/sunshine-launcher-eww-move.sh "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher down"
		)
	)
	hl.bind(
		"Return",
		hl.dsp.exec_cmd(
			home
				.. "/.home-manager/scripts/sunshine-launcher-eww-activate.sh "
				.. home
				.. "/.home-manager/config_files/eww-sunshine-launcher; hyprctl dispatch submap reset"
		)
	)
end)

hl.bind("SUPER + SHIFT + F4", hl.dsp.submap("focus_lock"))

hl.define_submap("focus_lock", function()
	hl.bind("CTRL + ESCAPE", hl.dsp.exec_cmd(home .. "/.home-manager/scripts/focus-lock.sh"))
end)
