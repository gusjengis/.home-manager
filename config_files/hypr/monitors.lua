hl.monitor({
    output = "HDMI-A-1",
    mode = "3840x2160@144.00",
    scale = 1.0,
    transform = 0,
    position = "0x0",
    bitdepth = 10,
    cm = "hdr",
    sdr_max_luminance = 500,
    sdr_min_luminance = 0.000,
})

hl.config({
    general = {
        gaps_out = { top = 200, right = 747, bottom = 200, left = 747 },
    },
})

hl.bind("SUPER + F12", function()
    local state_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-gaps-out-off"
    local file = io.open(state_file, "r")

    if file then
        file:close()
        hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out '200 747 200 747' && rm -f '" .. state_file .. "'"))
    else
        hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword general:gaps_out '0 0 0 0' && touch '" .. state_file .. "'"))
    end
end, { description = "Toggle Outer Gaps" })
