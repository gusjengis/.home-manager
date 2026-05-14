local special_workspaces = {
    { key = "T", desc = "Terminal", name = "terminal", command = terminal },
    { key = "C", desc = "Chromium", name = "browser", command = browser },
    { key = "SHIFT + C", desc = "Calendar", name = "calendar", command = calendar },
    { key = "G", desc = "ChatGPT", name = "gpt", command = gpt },
    { key = "S", desc = "Slack", name = "slack", command = slack },
    { key = "D", desc = "Discord", name = "discord", command = discord },
    { key = "P", desc = "Plastic", name = "plastic", command = "plasticgui" },
    { key = "N", desc = "Notes", name = "notes", command = "obsidian" },
    { key = "M", desc = "Music", name = "music", command = music },
    { key = "E", desc = "Email", name = "email", command = email },
    { key = "W", desc = "Whatsapp", name = "whatsapp", command = whatsapp },
}

for _, ws in ipairs(special_workspaces) do
    hl.bind(SUPER .. " + " .. ws.key, hl.dsp.workspace.toggle_special(ws.name), { description = ws.desc })
    hl.workspace_rule({ workspace = "special:" .. ws.name, on_created_empty = ws.command })
end

hl.bind("SUPER + L", hl.dsp.workspace.toggle_special("log"), { description = "Hyprlog" })
hl.workspace_rule({ workspace = "special:log", on_created_empty = terminal .. " -e sh -lc 'hyprlog; echo; read -p \"Press Enter to close...\"'" })

hl.bind("SUPER + SHIFT + H", hl.dsp.workspace.toggle_special("home"), { description = "Home Assistant" })
hl.workspace_rule({ workspace = "special:home", on_created_empty = homeAssistant })
