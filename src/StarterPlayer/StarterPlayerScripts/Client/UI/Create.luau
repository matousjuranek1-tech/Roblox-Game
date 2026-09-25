--!strict
--[[
	Create
	Declarative Instance construction for UI built in code:
	  local label = Create("TextLabel", { Text = "Hi", Parent = frame }) :: TextLabel
	`Parent` is always assigned last, so the instance is fully configured before it replicates
	into the rendered tree (one layout pass instead of many).
]]

local function Create(className: string, properties: { [string]: any }, children: { Instance }?): Instance
	local instance = Instance.new(className :: any)
	local parent: Instance? = nil
	for key, value in properties do
		if key == "Parent" then
			parent = value
		else
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

return Create
