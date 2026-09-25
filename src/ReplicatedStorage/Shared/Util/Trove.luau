--!strict
--[[
	Trove
	Collects everything that must be cleaned up together (connections, instances, threads,
	callbacks) and releases it in one call. Every per-character or per-player setup owns a Trove,
	which is how we avoid leaking connections when characters respawn.
]]

type Cleanable = RBXScriptConnection | Instance | thread | () -> () | { Disconnect: (any) -> () }

export type Trove = {
	Add: <T>(self: Trove, item: T) -> T,
	Connect: (self: Trove, signal: RBXScriptSignal, handler: (...any) -> ()) -> RBXScriptConnection,
	Clean: (self: Trove) -> (),
}

type TroveImpl = {
	_items: { Cleanable },
}

local function cleanItem(item: Cleanable)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		(item :: RBXScriptConnection):Disconnect()
	elseif kind == "Instance" then
		(item :: Instance):Destroy()
	elseif kind == "thread" then
		local thread = item :: thread
		if coroutine.status(thread) ~= "dead" and thread ~= coroutine.running() then
			task.cancel(thread)
		end
	elseif kind == "function" then
		(item :: () -> ())()
	elseif kind == "table" then
		local disconnectable = item :: { Disconnect: (any) -> () }
		disconnectable:Disconnect()
	end
end

local TroveMethods = {}
TroveMethods.__index = TroveMethods

function TroveMethods.Add(self: TroveImpl, item: any): any
	table.insert(self._items, item)
	return item
end

function TroveMethods.Connect(self: TroveImpl, signal: RBXScriptSignal, handler: (...any) -> ()): RBXScriptConnection
	local connection = signal:Connect(handler)
	table.insert(self._items, connection)
	return connection
end

function TroveMethods.Clean(self: TroveImpl)
	-- Clean in reverse order of creation, mirroring how resources were acquired.
	local items = self._items
	self._items = {}
	for index = #items, 1, -1 do
		cleanItem(items[index])
	end
end

local Trove = {}

function Trove.new(): Trove
	local self: TroveImpl = { _items = {} }
	return setmetatable(self, TroveMethods) :: any
end

return Trove
