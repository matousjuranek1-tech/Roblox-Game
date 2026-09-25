--!strict
--[[
	TestCourseService
	Builds the Phase 1 Movement Lab when the server starts. Set the Workspace attribute
	"DisableMovementLab" = true in Studio to boot without it (e.g. when greyboxing a real region).
]]

local TestCourseBuilder = require(script.Parent.Parent.World.TestCourseBuilder)

local DISABLE_ATTRIBUTE = "DisableMovementLab"

local TestCourseService = {}

-- Built during Init (only this module's own builder is involved) so the lab and its
-- SpawnLocation exist before the first character can spawn.
function TestCourseService:Init()
	if workspace:GetAttribute(DISABLE_ATTRIBUTE) == true then
		return
	end
	TestCourseBuilder.Build(workspace)
end

return TestCourseService
