local vars = require("platform-variables")
local home = os.getenv("HOME")

local function bind(keys, dispatcher, description, flags)
	flags = flags or {}
	flags.description = description
	hl.bind(keys, dispatcher, flags)
end

local function execAndReset(command)
	return function()
		hl.dispatch(hl.dsp.exec_cmd(command))
		hl.dispatch(hl.dsp.submap("reset"))
	end
end

bind("SUPER + SPACE", hl.dsp.exec_cmd("ambxst run launcher"), "App Launcher")
bind(
	"SUPER + CTRL + ALT + SPACE",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/waypipe-launcher.sh"),
	"Remote App Launcher"
)
bind(
	"SUPER + CTRL + ALT + M",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/sunshine-launcher.sh"),
	"Moonlight Remote Launcher"
)
bind("SUPER + Q", hl.dsp.exec_cmd(vars.terminal), "Launch Terminal")
bind("SUPER + B", hl.dsp.exec_cmd(vars.browser), "Launch Browser")
bind("ALT + F4", hl.dsp.window.close(), "Close Program")
bind("SUPER + F11", hl.dsp.window.fullscreen(), "Fullscreen")
bind("SUPER + F", hl.dsp.exec_cmd(vars.fileManager), "Launch File Manager")
bind("SUPER + V", hl.dsp.window.float(), "Toggle Floating")
bind(
	"SUPER + SHIFT + N",
	hl.dsp.exec_cmd("bash " .. home .. "/.home-manager/config_files/hypr/scripts/next-wallpaper.sh"),
	"Next Wallpaper"
)
bind("SUPER + CTRL + W", hl.dsp.exec_cmd("pkill waybar; nohup waybar >/tmp/waybar.log 2>&1 &"), "Restart Waybar")
bind("SUPER + J", hl.dsp.layout("togglesplit"), "Rotate Split")

bind("code:202", hl.dsp.exec_cmd("handy --toggle-transcription"), "Dictate")
hl.bind("code:202", hl.dsp.exec_cmd("handy --toggle-transcription"), { release = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("handy --toggle-transcription"), "Dictate")
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("handy --toggle-transcription"), { release = true })

bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh output " .. home .. "/Pictures/Screenshots"),
	"Screenshot"
)
bind(
	"SUPER + SHIFT + A",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh region " .. home .. "/Pictures/Screenshots"),
	"Screenshot Area"
)
bind(
	"SUPER + SHIFT + W",
	hl.dsp.exec_cmd(home .. "/.home-manager/scripts/hdr-safe-screenshot.sh window " .. home .. "/Pictures/Screenshots"),
	"Screenshot Window"
)

for _, direction in ipairs({ "left", "right", "up", "down" }) do
	bind(
		"SUPER + " .. direction,
		hl.dsp.focus({ direction = direction }),
		"Focus " .. direction:gsub("^%l", string.upper)
	)
end

for _, direction in ipairs({ "left", "right", "up", "down" }) do
	bind(
		"SUPER + SHIFT + " .. direction,
		hl.dsp.window.swap({ direction = direction }),
		"Swap Window " .. direction:gsub("^%l", string.upper)
	)
end

hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin({ action = "enable" }))

for workspace = 1, 10 do
	local key = workspace % 10
	bind(
		"SUPER + " .. key,
		hl.dsp.focus({ workspace = workspace, on_current_monitor = true }),
		"Workspace " .. workspace
	)
	bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }), "Move to Workspace " .. workspace)
end

bind("SUPER + CTRL + ALT + SHIFT + E", hl.dsp.exit(), "Exit Hyprland")
bind("SUPER + CTRL + ALT + SHIFT + S", hl.dsp.exec_cmd("alga power off; systemctl poweroff"), "Shutdown")
bind("SUPER + CTRL + ALT + SHIFT + R", hl.dsp.exec_cmd("systemctl reboot"), "Restart")

bind("SUPER + mouse:272", hl.dsp.window.drag(), "Move Window", { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Resize Window", { mouse = true })

bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	"Hidden",
	{ locked = true, repeating = true }
)
bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	"Hidden",
	{ locked = true, repeating = true }
)
bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	"Hidden",
	{ locked = true, repeating = true }
)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), "Hidden", { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Hidden", { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), "Hidden", { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), "Hidden", { locked = true })

bind(
	"SUPER + H",
	hl.dsp.exec_cmd("pkill wl-kbptr || wl-kbptr -c " .. home .. "/.home-manager/config_files/wl-kbptr/config"),
	"Hop"
)

local function definePickerSubmap(name, configDir, closeCommand, moveScript, activateScript)
	local configPath = home .. "/.home-manager/config_files/" .. configDir

	hl.define_submap(name, function()
		hl.bind("escape", execAndReset(closeCommand))
		hl.bind("up", hl.dsp.exec_cmd(moveScript .. " " .. configPath .. " up"))
		hl.bind("down", hl.dsp.exec_cmd(moveScript .. " " .. configPath .. " down"))
		hl.bind("k", hl.dsp.exec_cmd(moveScript .. " " .. configPath .. " up"))
		hl.bind("j", hl.dsp.exec_cmd(moveScript .. " " .. configPath .. " down"))
		hl.bind("return", execAndReset(activateScript .. " " .. configPath))
		hl.bind("KP_Enter", execAndReset(activateScript .. " " .. configPath))
	end)
end

definePickerSubmap(
	"waypipe-launcher",
	"eww-waypipe-launcher",
	"eww --config " .. home .. "/.home-manager/config_files/eww-waypipe-launcher close waypipe-hosts",
	home .. "/.home-manager/scripts/waypipe-launcher-eww-move.sh",
	home .. "/.home-manager/scripts/waypipe-launcher-eww-activate.sh"
)

definePickerSubmap(
	"sunshine-launcher",
	"eww-sunshine-launcher",
	"eww --config " .. home .. "/.home-manager/config_files/eww-sunshine-launcher close sunshine-hosts",
	home .. "/.home-manager/scripts/sunshine-launcher-eww-move.sh",
	home .. "/.home-manager/scripts/sunshine-launcher-eww-activate.sh"
)

hl.bind("SUPER + SHIFT + F4", hl.dsp.submap("focus_lock"))
hl.define_submap("focus_lock", function()
	hl.bind("CTRL + ESCAPE", hl.dsp.exec_cmd(home .. "/.home-manager/scripts/focus-lock.sh"))
end)

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "hide-xwayland-video-bridge",
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override",
	no_anim = true,
	no_initial_focus = true,
	max_size = { 1, 1 },
	no_blur = true,
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})
