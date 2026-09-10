hl.monitor({
	output = "HDMI-A-1",
	mode = "3840x2160@60.0",
	scale = 1.6,
	transform = 0,
	position = "0x0",

	-- Disabled for the same reason as hosts/pc/monitors.lua: this Hyprland
	-- build aborts in applyMonitorRule when the GBM allocator cannot provide
	-- XR30, which crash-loops the session at login. Legion has not been seen
	-- crashing yet, it is still on the old compositor, so re-enable these four
	-- lines once the fork handles the fallback.
	-- supports_wide_color = 1,
	-- supports_hdr = 1,
	-- bitdepth = 10,
	-- cm = "hdr",
	-- sdrbrightness = 1.4,
	-- sdr_min_luminance = 0.0,
})

hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@143.99899",
	scale = 1.0,
	transform = 0,
	position = "0x2160",
})
