--!strict
--[[
	InputConfig
	Default bindings per input method. The gamepad layout already reserves buttons for the
	PHASE 2 combat kit (X light, Y heavy, RB block, RT/LT abilities), so movement never has to
	be rebound later.
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

export type ActionName = "Sprint" | "Dash" | "Slide" | "Grapple" | "RestartTrial" | "ToggleDebug" | "ToggleHelp"

export type Binding = {
	Keyboard: { Enum.KeyCode },
	Gamepad: { Enum.KeyCode },
	-- Label shown on the mobile touch button; nil means no touch button.
	Touch: string?,
}

local InputConfig = {
	-- ContextActionService priority. Above Enum.ContextActionPriority.Default so the
	-- default camera/gamepad bindings never swallow movement input.
	Priority = Enum.ContextActionPriority.High.Value,

	Actions = {
		Sprint = {
			Keyboard = { Enum.KeyCode.LeftShift },
			Gamepad = { Enum.KeyCode.ButtonL3 },
			Touch = "SPRINT",
		},
		Dash = {
			Keyboard = { Enum.KeyCode.Q },
			Gamepad = { Enum.KeyCode.ButtonB },
			Touch = "DASH",
		},
		Slide = {
			Keyboard = { Enum.KeyCode.C, Enum.KeyCode.LeftControl },
			Gamepad = { Enum.KeyCode.ButtonR3 },
			Touch = "SLIDE",
		},
		Grapple = {
			Keyboard = { Enum.KeyCode.E },
			Gamepad = { Enum.KeyCode.ButtonL1 },
			Touch = "HOOK",
		},
		RestartTrial = {
			Keyboard = { Enum.KeyCode.R },
			Gamepad = { Enum.KeyCode.DPadDown },
			Touch = nil,
		},
		ToggleDebug = {
			Keyboard = { Enum.KeyCode.F3 },
			Gamepad = {},
			Touch = nil,
		},
		ToggleHelp = {
			Keyboard = { Enum.KeyCode.H },
			Gamepad = { Enum.KeyCode.DPadUp },
			Touch = nil,
		},
	} :: { [ActionName]: Binding },

	-- Keyboard sprint is held; gamepad (stick click) and touch sprint are toggles.
	SprintToggleOnGamepad = true,
	SprintToggleOnTouch = true,
}

return deepFreeze(InputConfig)
