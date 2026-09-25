--!strict
--[[
	TimeTrialConfig
	Medal thresholds per trial. The Movement Lab trial is the Phase 1 feel benchmark: after any
	movement tuning change, a tester runs it and compares splits against these targets.
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

export type Trial = {
	DisplayName: string,
	Gold: number,
	Silver: number,
	Bronze: number,
	-- Finishing faster than this is physically impossible and is rejected as an exploit.
	MinValidTime: number,
}

local TimeTrialConfig = {
	Trials = {
		MovementLab = {
			DisplayName = "Movement Lab",
			Gold = 42,
			Silver = 58,
			Bronze = 80,
			MinValidTime = 18,
		},
	} :: { [string]: Trial },

	-- Seconds between two restart requests from one player.
	RestartCooldown = 1,
}

return deepFreeze(TimeTrialConfig)
