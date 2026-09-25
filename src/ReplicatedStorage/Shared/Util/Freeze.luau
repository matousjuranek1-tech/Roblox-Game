--!strict
--[[
	Freeze
	Recursively freezes a config table so nothing can mutate shared tuning at runtime
	(a mutated config on the client would silently desync it from server validation).
]]

local function deepFreeze<T>(value: T): T
	if type(value) == "table" and not table.isfrozen(value :: any) then
		for _, child in value :: any do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

return deepFreeze
