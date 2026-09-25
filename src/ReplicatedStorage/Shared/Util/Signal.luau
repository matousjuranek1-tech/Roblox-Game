--!strict
--[[
	Signal
	Lightweight typed event used for communication between modules on the same machine
	(controller -> controller, service -> service). Network traffic always goes through Net/Remotes.

	Handlers run in their own thread (task.spawn), so a handler that errors or yields never
	blocks the code that fired the signal or the other handlers.
]]

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

type ConnectionImpl = {
	Connected: boolean,
	_handlers: { ConnectionImpl },
	_handler: (...any) -> (),
}

type SignalImpl = {
	_handlers: { ConnectionImpl },
}

local ConnectionMethods = {}
ConnectionMethods.__index = ConnectionMethods

function ConnectionMethods.Disconnect(self: ConnectionImpl)
	if not self.Connected then
		return
	end
	self.Connected = false
	local index = table.find(self._handlers, self)
	if index then
		table.remove(self._handlers, index)
	end
end

local SignalMethods = {}
SignalMethods.__index = SignalMethods

function SignalMethods.Connect(self: SignalImpl, handler: (...any) -> ()): ConnectionImpl
	local connection = setmetatable({
		Connected = true,
		_handlers = self._handlers,
		_handler = handler,
	}, ConnectionMethods) :: any
	table.insert(self._handlers, connection)
	return connection
end

function SignalMethods.Once(self: SignalImpl, handler: (...any) -> ()): ConnectionImpl
	local connection: ConnectionImpl
	connection = SignalMethods.Connect(self, function(...)
		ConnectionMethods.Disconnect(connection)
		handler(...)
	end)
	return connection
end

function SignalMethods.Fire(self: SignalImpl, ...: any)
	-- Iterate a snapshot so handlers may connect/disconnect while the signal is firing.
	local snapshot = table.clone(self._handlers)
	for _, connection in snapshot do
		if connection.Connected then
			task.spawn(connection._handler, ...)
		end
	end
end

function SignalMethods.DisconnectAll(self: SignalImpl)
	for _, connection in self._handlers do
		connection.Connected = false
	end
	table.clear(self._handlers)
end

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local self: SignalImpl = { _handlers = {} }
	return setmetatable(self, SignalMethods) :: any
end

return Signal
