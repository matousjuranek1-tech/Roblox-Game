--!strict
--[[
	Slide
	Low, fast ground slide started from a sprint (or out of a dash).
	  * Lowers Humanoid.HipHeight; AnimationController tilts the body back, so head and torso
	    physically fit under 3.6-stud barriers.
	  * Gains speed downhill, loses it uphill (gravity projected on the floor).
	  * Keeps sliding while there is no room to stand up.
	  * Jumping out (slide-hop) hands the speed to Launch.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

local Config = MovementConfig.Slide

local FLOOR_PROBE = 4
-- Downhill acceleration above this counts as "on a slope" (longer max duration).
local DOWNHILL_THRESHOLD = 5
local LEFT_GROUND_GRACE = 0.1

local state = {
	Direction = -Vector3.zAxis,
	Speed = 0,
	Elapsed = 0,
	AirTime = 0,
}

local Slide = {}

-- True when a standing character fits above the current root position.
function Slide.HasHeadroom(ctx: Context): boolean
	local root = ctx.Root
	-- Box from the top of the root part up to where a standing head (plus margin) would be.
	local rise = ctx.DefaultHipHeight - ctx.Humanoid.HipHeight
	local rootHalfHeight = root.Size.Y / 2
	local height = math.max(rise + Config.HeadClearance - rootHalfHeight, 0.5)
	local center = root.Position + Vector3.new(0, rootHalfHeight + height / 2, 0)
	local blockers = workspace:GetPartBoundsInBox(CFrame.new(center), Vector3.new(1.6, height, 1.2), ctx.OverlapParams)
	return #blockers == 0
end

local function floorSlopeAcceleration(ctx: Context): number
	local result = ctx:Raycast(ctx.Root.Position, Vector3.new(0, -FLOOR_PROBE, 0))
	if not result then
		return 0
	end
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local alongFloor = MathUtil.projectOnPlane(gravity, result.Normal)
	return MathUtil.flat(alongFloor):Dot(state.Direction) * Config.SlopeFactor
end

Slide.Ability = {
	Name = "Slide",
	InterruptibleBy = { Dash = true, Grapple = true },

	CanStart = function(ctx: Context, _request: any): boolean
		if not ctx.Grounded or not ctx:IsReady("Slide", os.clock()) then
			return false
		end
		return ctx.Sprinting or ctx:FlatVelocity().Magnitude >= Config.MinEntrySpeed
	end,

	Start = function(ctx: Context, _request: any): MovementContext.Payload?
		local flatVelocity = ctx:FlatVelocity()
		local fallback = if ctx:MoveDirection().Magnitude > 0.1 then ctx:MoveDirection().Unit else ctx:LookDirection()
		state.Direction = MathUtil.safeUnit(flatVelocity, fallback)
		state.Speed = math.clamp(math.max(flatVelocity.Magnitude, Config.StartSpeed), 0, Config.MaxSpeed)
		state.Elapsed = 0
		state.AirTime = 0
		ctx.Humanoid.HipHeight = Config.HipHeight
		ctx:FaceDirection(state.Direction)
		return nil
	end,

	Update = function(ctx: Context, dt: number): boolean
		state.Elapsed += dt
		if not ctx.Grounded then
			-- Slid off an edge: hand over to Launch once clearly airborne.
			state.AirTime += dt
			if state.AirTime > LEFT_GROUND_GRACE and Slide.HasHeadroom(ctx) then
				return false
			end
		else
			state.AirTime = 0
		end

		local slope = floorSlopeAcceleration(ctx)
		state.Speed = Config.EndSpeed + (state.Speed - Config.EndSpeed) * math.exp(-Config.Friction * dt)
		state.Speed = math.clamp(state.Speed + slope * dt, 0, Config.MaxSpeed)

		local input = ctx:MoveDirection()
		if input.Magnitude > 0.1 then
			state.Direction = MathUtil.rotateTowards(state.Direction, input.Unit, Config.TurnRate * dt)
		end

		local limit = if slope > DOWNHILL_THRESHOLD then Config.MaxDownhillDuration else Config.MaxDuration
		local finished = state.Elapsed >= limit or state.Speed <= Config.EndSpeed + 0.5
		if finished and not Slide.HasHeadroom(ctx) then
			-- Still under an obstacle: crawl out at the minimum slide speed.
			state.Speed = math.max(state.Speed, Config.EndSpeed)
			finished = false
		end

		ctx:SetPlanarVelocity(state.Direction * state.Speed)
		ctx:FaceDirection(state.Direction)
		return not finished
	end,

	Stop = function(ctx: Context, reason: string): (string?, any)
		ctx.Humanoid.HipHeight = ctx.DefaultHipHeight
		ctx:ReleaseFacing()
		ctx:ReleaseMover()
		ctx:SetCooldown("Slide", Config.Cooldown, os.clock())

		local exit = state.Direction * state.Speed
		local velocity = Vector3.new(exit.X, ctx:Velocity().Y, exit.Z)
		ctx.Root.AssemblyLinearVelocity = velocity

		if reason == "Jumped" or (reason == "Finished" and not ctx.Grounded) then
			return "Launch", velocity
		end
		return nil, nil
	end,
} :: MovementContext.Ability

return Slide
