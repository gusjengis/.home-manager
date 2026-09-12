local M = {}

local hugeMarginsByMonitor = {}
local rulesByMonitor = {}
local statePath = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprland-monitor-modes.json"

local function writeState()
	local names = {}
	for name in pairs(hugeMarginsByMonitor) do
		table.insert(names, name)
	end
	table.sort(names)

	local entries = {}
	for _, name in ipairs(names) do
		local escaped = name:gsub("\\", "\\\\"):gsub('"', '\\"')
		table.insert(entries, string.format('"%s":%s', escaped, hugeMarginsByMonitor[name] and "true" or "false"))
	end

	local temporaryPath = statePath .. ".tmp"
	local file = assert(io.open(temporaryPath, "w"))
	file:write('{"hugeMargins":{', table.concat(entries, ","), "}}\n")
	file:close()
	assert(os.rename(temporaryPath, statePath))
end

function M.toggle()
	local monitor = hl.get_active_monitor()
	if not monitor or hugeMarginsByMonitor[monitor.name] == nil then
		return
	end

	hugeMarginsByMonitor[monitor.name] = not hugeMarginsByMonitor[monitor.name]
	rulesByMonitor[monitor.name]:set_enabled(hugeMarginsByMonitor[monitor.name])
	writeState()
end

function M.configure(monitors)
	for name, mode in pairs(monitors) do
		hugeMarginsByMonitor[name] = mode.enabled
		rulesByMonitor[name] = hl.workspace_rule({
			workspace = "m[" .. name .. "]",
			gaps_out = mode.margins,
			enabled = mode.enabled,
		})
	end

	writeState()

	hl.bind("SUPER + F12", M.toggle, {
		description = "Toggle Huge Margins on Active Monitor",
	})
end

return M
