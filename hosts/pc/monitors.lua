hl.monitor({
	output = "HDMI-A-1",
	mode = "3840x2160@144.00",
	position = "0x0",
	scale = 1.0,

	bitdepth = 10,
	cm = "hdr",
	sdr_max_luminance = 350,
	sdr_min_luminance = 0,
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
