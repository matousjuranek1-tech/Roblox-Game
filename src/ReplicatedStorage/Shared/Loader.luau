--!strict
--[[
	Loader
	Boots every Service (server) or Controller (client) found in a folder.

	Lifecycle contract for each module:
	  Init()  - synchronous setup of the module's own state. Must not call other modules.
	  Start() - runs after every module finished Init. May use other modules, connect events,
	            and yield (each Start runs in its own thread).

	Modules reference each other with a plain `require(script.Parent.OtherModule)`, which returns
	the same table the Loader booted, so there is no service locator and types flow through.
]]

type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

local Loader = {}

local function sortedNames(modules: { [string]: Module }): { string }
	local names = {}
	for name in modules do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- Error handler for xpcall that keeps the stack trace of the failing lifecycle call.
local function reportError(label: string, name: string, phase: string): (unknown) -> ()
	return function(message: unknown)
		warn(`[{label}] {name}.{phase} failed:\n{debug.traceback(tostring(message), 2)}`)
	end
end

-- Requires every ModuleScript that is a direct child of `folder`.
function Loader.RequireChildren(folder: Instance): { [string]: Module }
	local modules: { [string]: Module } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			modules[child.Name] = (require :: any)(child)
		end
	end
	return modules
end

-- Runs Init on all modules (sorted by name, so the order is deterministic), then Start.
function Loader.Boot(modules: { [string]: Module }, label: string)
	local names = sortedNames(modules)

	for _, name in names do
		local module = modules[name]
		local init = module.Init
		if init then
			xpcall(init, reportError(label, name, "Init"), module)
		end
	end

	for _, name in names do
		local module = modules[name]
		local start = module.Start
		if start then
			task.spawn(xpcall, start, reportError(label, name, "Start"), module)
		end
	end
end

return Loader
