--!strict
--[[
	GraphicsConfig
	Per-tier VFX budgets. Low-end devices must never pay for high-end effects: every effect
	asks the active tier how much it may spawn and how far away it may play.
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

export type TierName = "Low" | "Medium" | "High" | "Ultra"

export type Tier = {
	ParticleMultiplier: number,
	-- Other players' movement FX beyond this distance (studs) from the camera are skipped.
	RemoteFxDistance: number,
	TrailLifetime: number,
	-- Procedural character posing (lean/tilt) is skipped beyond this distance.
	PoseDistance: number,
	MaxDebris: number,
}

local GraphicsConfig = {
	Tiers = {
		Low = {
			ParticleMultiplier = 0.25,
			RemoteFxDistance = 80,
			TrailLifetime = 0.12,
			PoseDistance = 60,
			MaxDebris = 20,
		},
		Medium = {
			ParticleMultiplier = 0.5,
			RemoteFxDistance = 150,
			TrailLifetime = 0.18,
			PoseDistance = 110,
			MaxDebris = 60,
		},
		High = {
			ParticleMultiplier = 1,
			RemoteFxDistance = 260,
			TrailLifetime = 0.25,
			PoseDistance = 180,
			MaxDebris = 150,
		},
		Ultra = {
			ParticleMultiplier = 1.25,
			RemoteFxDistance = 400,
			TrailLifetime = 0.3,
			PoseDistance = 260,
			MaxDebris = 250,
		},
	} :: { [TierName]: Tier },

	-- Roblox graphics quality levels 1..10 mapped onto our tiers.
	QualityLevelToTier = {
		"Low",
		"Low",
		"Low",
		"Medium",
		"Medium",
		"Medium",
		"High",
		"High",
		"High",
		"Ultra",
	} :: { TierName },

	-- Tier used when the player leaves graphics on "Automatic".
	AutomaticTier = {
		Touch = "Medium",
		Desktop = "High",
		Console = "High",
	} :: { [string]: TierName },

	-- Auto-downgrade one tier when the average FPS stays below this for SampleSeconds.
	AutoDowngrade = {
		MinFps = 45,
		SampleSeconds = 10,
	},
}

return deepFreeze(GraphicsConfig)
