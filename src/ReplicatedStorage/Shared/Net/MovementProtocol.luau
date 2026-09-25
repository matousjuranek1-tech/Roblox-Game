--!strict
--[[
	MovementProtocol
	Contract for the MovementAction remote, shared by MovementController (client) and
	MovementService (server).

	Client -> server:
	  ("Start", action, payload?)  an ability started locally (client predicts, server validates)
	  ("End", action)              a sustained ability ended

	Payloads:
	  WallRun  { Side: number }        -1 = wall on the left, 1 = wall on the right
	  Grapple  { Target: BasePart }    the tagged grapple point
	  others   nil
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

export type ServerAction = "Dash" | "AirDash" | "Slide" | "WallRun" | "WallJump" | "Mantle" | "Grapple"
export type MessageKind = "Start" | "End"
export type CorrectionKind = "Rejected" | "Corrected"

local MovementProtocol = {
	-- Actions the server validates. Launch (momentum carry) is implied by the others.
	ServerActions = {
		Dash = true,
		AirDash = true,
		Slide = true,
		WallRun = true,
		WallJump = true,
		Mantle = true,
		Grapple = true,
	} :: { [string]: boolean },

	-- Actions that last until the client sends "End".
	Sustained = {
		Slide = true,
		WallRun = true,
		Grapple = true,
	} :: { [string]: boolean },

	-- Actions other clients pose the character for (via the MoveState attribute).
	Posable = {
		Dash = true,
		AirDash = true,
		Slide = true,
		WallRun = true,
		Mantle = true,
		Grapple = true,
	} :: { [string]: boolean },
}

return deepFreeze(MovementProtocol)
