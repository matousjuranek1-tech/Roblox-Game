--!strict
--[[
	Validate
	Type guards for data that arrives over the network. Every RemoteEvent handler on the server
	must run its arguments through these before touching them: exploiters can send any value,
	including NaN/inf numbers, huge strings, or instances they do not own.
]]

local Validate = {}

function Validate.isFiniteNumber(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Validate.isFiniteVector3(value: unknown): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end
	local vector = value :: Vector3
	return Validate.isFiniteNumber(vector.X) and Validate.isFiniteNumber(vector.Y) and Validate.isFiniteNumber(vector.Z)
end

function Validate.isShortString(value: unknown, maxLength: number): boolean
	return type(value) == "string" and #value > 0 and #value <= maxLength
end

-- True when `value` is a BasePart that currently lives in the Workspace.
function Validate.isWorkspacePart(value: unknown): boolean
	if typeof(value) ~= "Instance" then
		return false
	end
	local instance = value :: Instance
	return instance:IsA("BasePart") and instance:IsDescendantOf(workspace)
end

-- Returns `value` as a table when it is a plain table with at most `maxKeys` entries.
function Validate.smallTable(value: unknown, maxKeys: number): { [any]: any }?
	if type(value) ~= "table" then
		return nil
	end
	local count = 0
	for _ in value :: { [any]: any } do
		count += 1
		if count > maxKeys then
			return nil
		end
	end
	return value :: { [any]: any }
end

return Validate
