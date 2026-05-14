local home = os.getenv("HOME")
local hypr = home .. "/.config/hypr/"

dofile(hypr .. "variables.lua")
dofile(hypr .. "platform-variables.lua")
dofile(hypr .. "appearance.lua")
dofile(hypr .. "autostart.lua")
dofile(hypr .. "keybinds.lua")
dofile(hypr .. "monitors.lua")
dofile(hypr .. "workspaces.lua")

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        initial_workspace_tracking = 0,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        repeat_delay = 190,
        repeat_rate = 50,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
    ecosystem = {
        no_update_news = true,
    },
})

hl.monitor({
    output = "_",
    mode = "preferred",
    position = "auto",
    scale = 1,
})
