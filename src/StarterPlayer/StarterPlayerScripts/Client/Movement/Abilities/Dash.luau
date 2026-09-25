--!strict
--[[
	Dash / AirDash
	Short directional burst in the input direction (or forward with no input).
	Ground dash drives X/Z only, so dashing off a ledge or jumping mid-dash keeps gravity.
	Air dash (unlockable) drives all axes with a small upward hang and spends an air charge.
	The exit keeps part of the speed, so a dash flows into sprinting instead of stopping dead.
	PHASE 2 hooks the perfect-dodge window onto ActionStarted("Dash"/"AirDash").
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

type DashTuning = {
	Speed: number,
	Duration: number,
	ExitSpeedFactor: number,
	StaminaCost: number,
}

-- Ground and air dash share one cooldown, so they cannot be spammed back to back.
local COOLDOWN_NAME = "Dash"
-- Speed falls off quadratically to this share at the end of the dash.
local END_SPEED_LOSS = 0.35

local state = {
	Direction = -Vector3.zAxis,
	Elapsed = 0,
}

local function dashDirection(ctx: Context): Vector3
	local input = ctx:MoveDirection()
	if input.Magnitude > 0.1 then
		return input.Unit
	end
	local look = ctx:LookDirection()
	return if MovementConfig.Dash.NeutralDirection == "Backward" then -look else look
end

local function makeDash(air: boolean): MovementContext.Ability
	local tuning: DashTuning = if air then MovementConfig.AirDash else MovementConfig.Dash

	return {
		Name = if air then "AirDash" else "Dash",
		InterruptibleBy = if air then { Grapple = true, Mantle = true } else { Grapple = true, Slide = true },

		CanStart = function(ctx: Context, _request: any): boolean
			local now = os.clock()
			if not ctx:IsReady(COOLDOWN_NAME, now) or not ctx:HasStamina(tuning.StaminaCost) then
				return false
			end
			if air then
				return ctx:IsUnlocked("AirDash") and ctx.AirDashCharges > 0
			end
			return ctx:IsGroundedOrCoyote(now)
		end,

		Start = function(ctx: Context, _request: any): MovementContext.Payload?
			state.Direction = dashDirection(ctx)
			state.Elapsed = 0
			ctx:SpendStamina(tuning.StaminaCost, os.clock())
			if air then
				ctx.AirDashCharges -= 1
			end
			ctx:FaceDirection(state.Direction)
			return nil
		end,

		Update = function(ctx: Context, dt: number): boolean
			state.Elapsed += dt
			local alpha = math.min(state.Elapsed / tuning.Duration, 1)
			local speed = tuning.Speed * (1 - END_SPEED_LOSS * alpha * alpha)
			if air then
				ctx:SetVelocity(state.Direction * speed + Vector3.new(0, MovementConfig.AirDash.UpVelocity, 0))
			else
				ctx:SetPlanarVelocity(state.Direction * speed)
			end
			return state.Elapsed < tuning.Duration
		end,

		Stop = function(ctx: Context, reason: string): (string?, any)
			ctx:ReleaseFacing()
			ctx:ReleaseMover()
			ctx:SetCooldown(COOLDOWN_NAME, MovementConfig.Dash.Cooldown, os.clock())

			local exitSpeed = math.max(ctx.Humanoid.WalkSpeed, tuning.Speed * tuning.ExitSpeedFactor)
			local exit = state.Direction * exitSpeed
			local vertical = if air then 0 else ctx:Velocity().Y
			local velocity = Vector3.new(exit.X, vertical, exit.Z)
			ctx.Root.AssemblyLinearVelocity = velocity

			if reason ~= "Finished" then
				return nil, nil
			end
			if not ctx.Grounded then
				return "Launch", velocity
			end
			if not air and ctx.SlideHeld then
				return "Slide", nil
			end
			return nil, nil
		end,
	}
end

return {
	Ground = makeDash(false),
	Air = makeDash(true),
}
