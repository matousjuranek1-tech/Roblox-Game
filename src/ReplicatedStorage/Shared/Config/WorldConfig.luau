--!strict
--[[
	WorldConfig
	Names shared by server and client: CollectionService tags, attributes and collision groups.
	Level designers tag parts in Studio with these exact strings.
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

local WorldConfig = {
	Tags = {
		-- BasePart the grapple can latch onto (see MovementConfig.Grapple.Tag).
		GrapplePoint = "GrapplePoint",
		-- Invisible gate crossed by a time trial. Attributes: TrialId, Index, IsFinish.
		TimeTrialGate = "TimeTrialGate",
		-- Where a restart of a trial places the player. Attribute: TrialId.
		TimeTrialSpawn = "TimeTrialSpawn",
		-- Crossing this sends the player back to their last checkpoint.
		ResetPlane = "ResetPlane",
	},

	Attributes = {
		-- Part attribute: wall running on this surface is disabled.
		NoWallRun = "NoWallRun",
		-- Character attributes written by the server for other clients' visuals.
		MoveState = "MoveState",
		MoveSide = "MoveSide",
		-- Player attribute prefix for movement unlocks, e.g. "Unlock_AirDash".
		UnlockPrefix = "Unlock_",
	},

	CollisionGroups = {
		-- Characters never collide with each other (hub crowds, co-op traversal).
		Characters = "Characters",
	},
}

return deepFreeze(WorldConfig)
