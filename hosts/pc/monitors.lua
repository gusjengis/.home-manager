hl.monitor({
	output = "HDMI-A-1",
	mode = "3840x2160@144.00",
	position = "0x0",
	scale = 1.0,

	-- 10-bit/HDR is disabled: with this Hyprland build the GBM allocator
	-- cannot allocate XR30 on the NVIDIA primary ("format XR30 isn't
	-- supported by primary backend") and the compositor aborts inside
	-- applyMonitorRule, which crash-loops the session at login.
	-- bitdepth = 10,
	-- cm = "hdr",
	-- sdr_max_luminance = 350,
	-- sdr_min_luminance = 0,
})

local wideGaps = {
	top = 200,
	right = 747,
	bottom = 200,
	left = 747,
}

local wideGapsEnabled = false

hl.config({
	general = {
		gaps_out = wideGaps,
	},
})

hl.bind("SUPER + F12", function()
	wideGapsEnabled = not wideGapsEnabled

	hl.config({
		general = {
			gaps_out = wideGapsEnabled and wideGaps or 0,
		},
	})
end, {
	description = "Toggle Outer Gaps",
})
