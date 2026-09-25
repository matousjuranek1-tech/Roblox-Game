--!strict
--[[
	Launch
	Momentum carry after a wall jump, grapple exit, slide-hop, air dash or a dash off a ledge.
	The Humanoid alone would brake any airborne speed down to WalkSpeed almost instantly; Launch
	keeps the horizontal speed and lets it decay smoothly while the player steers. This is what
	makes chaining abilities always faster than simply running.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

local Config = MovementConfig.Launch

-- Carried speed below this share of the commanded speed means we hit something.
local BLOCKED_RATIO = 0.3
local BLOCKED_GRACE = 0.1

local state = {
	Direction = -Vector3.zAxis,
	Speed = 0,
	Elapsed = 0,
}

local Launch: MovementContext.Ability = {
	Name = "Launch",
	InterruptibleBy = {
		Dash = true,
		AirDash = true,
		Slide = true,
		WallRun = true,
		Mantle = true,
		Grapple = true,
		Launch = true,
	},

	CanStart = function(ctx: Context, velocity: Vector3): boolean
		return MathUtil.flat(velocity).Magnitude > ctx.Humanoid.WalkSpeed + Config.MinExtraSpeed
	end,

	Start = function(ctx: Context, velocity: Vector3): MovementContext.Payload?
		local flat = MathUtil.flat(velocity)
		state.Speed = flat.Magnitude
		state.Direction = MathUtil.safeUnit(flat, ctx:LookDirection())
		state.Elapsed = 0
		ctx:SetPlanarVelocity(state.Direction * state.Speed)
		return nil
	end,

	Update = function(ctx: Context, dt: number): boolean
		state.Elapsed += dt
		if ctx.Grounded and state.Elapsed > Config.GroundGrace then
			return false
		end
		if state.Elapsed > BLOCKED_GRACE and ctx:FlatVelocity().Magnitude < state.Speed * BLOCKED_RATIO then
			return false
		end

		local decay = Config.Decay
		local input = ctx:MoveDirection()
		if input.Magnitude > 0.1 then
			local inputDirection = input.Unit
			if inputDirection:Dot(state.Direction) < -0.3 then
				decay *= Config.BrakeMultiplier
			end
			state.Direction = MathUtil.rotateTowards(state.Direction, inputDirection, Config.AirTurnRate * dt)
		end

		local baseSpeed = ctx.Humanoid.WalkSpeed
		state.Speed = MathUtil.damp(state.Speed, baseSpeed, decay, dt)
		if state.Speed <= baseSpeed + 0.5 then
			return false
		end
		ctx:SetPlanarVelocity(state.Direction * state.Speed)
		return true
	end,

	Stop = function(ctx: Context, _reason: string): (string?, any)
		ctx:ReleaseMover()
		return nil, nil
	end,
}

return Launch
