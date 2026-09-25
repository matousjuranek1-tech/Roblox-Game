--!strict
--[[
	WallRun
	Starts automatically when the player is airborne, holding a direction, moving fast enough and
	roughly parallel to a vertical surface within reach. Runs along the wall on a gentle arc
	(reduced gravity), drains stamina, follows gently curved walls and ends when the wall ends,
	something blocks the path, stamina or time runs out, or the player steers away.
	Jumping from a wall run is handled by WallJump.

	Parts with the attribute NoWallRun = true are ignored (e.g. corridor side walls).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

export type Wall = {
	Normal: Vector3,
	Instance: BasePart,
	-- 1 = wall on the character's right, -1 = on the left.
	Side: number,
}

local Config = MovementConfig.WallRun

local FOLLOW_EXTRA_REACH = 0.6
local BLOCK_PROBE = 2.2
-- Share of the wall-run speed kept when falling off the end of a wall.
local EXIT_SPEED_FACTOR = 0.85
-- Share of the upward entry velocity converted into wall-run lift.
local ENTRY_LIFT_FACTOR = 0.3

local state = {
	Normal = Vector3.xAxis,
	Tangent = -Vector3.zAxis,
	Speed = 0,
	VerticalVelocity = 0,
	Elapsed = 0,
	Side = 1,
	Instance = nil :: BasePart?,
}

local WallRun = {}

-- True for a near-vertical surface that allows wall running.
function WallRun.IsWallSurface(result: RaycastResult): boolean
	if math.abs(result.Normal.Y) > Config.MaxNormalY then
		return false
	end
	return result.Instance:GetAttribute(WorldConfig.Attributes.NoWallRun) ~= true
end

function WallRun.Detect(ctx: Context): Wall?
	local now = os.clock()
	if ctx.Grounded or not ctx:IsReady("WallRun", now) or ctx.Stamina < Config.MinStamina then
		return nil
	end
	local input = ctx:MoveDirection()
	if input.Magnitude < 0.1 then
		return nil
	end
	local velocity = ctx:Velocity()
	if velocity.Y < -Config.MaxFallSpeed then
		return nil
	end
	local flatVelocity = MathUtil.flat(velocity)
	local speed = flatVelocity.Magnitude
	if speed < Config.MinEntrySpeed and not ctx.SprintInput then
		return nil
	end

	local travel = if speed > 1 then flatVelocity / speed else input.Unit
	local right = travel:Cross(Vector3.yAxis)
	local origin = ctx.Root.Position
	for _, side in { 1, -1 } do
		for _, forwardBias in { 0, 0.6 } do
			local direction = (right * side + travel * forwardBias).Unit * Config.DetectionDistance
			local result = ctx:Raycast(origin, direction)
			if result and WallRun.IsWallSurface(result) then
				local normal = MathUtil.flatUnit(result.Normal, -right * side)
				local approach = travel:Dot(normal)
				if
					math.abs(approach) < Config.MaxApproachDot
					and approach < 0.3
					and input.Unit:Dot(normal) < Config.DetachInputDot
					and not ctx:IsLastWall(result.Instance, normal)
				then
					return { Normal = normal, Instance = result.Instance, Side = side }
				end
			end
		end
	end
	return nil
end

-- The wall currently being run on (valid while the WallRun action is active).
function WallRun.CurrentWall(): Wall?
	local instance = state.Instance
	if not instance then
		return nil
	end
	return { Normal = state.Normal, Instance = instance, Side = state.Side }
end

-- Velocity along the wall, carried into a wall jump.
function WallRun.CurrentTangentVelocity(): Vector3
	return state.Tangent * state.Speed
end

WallRun.Ability = {
	Name = "WallRun",
	InterruptibleBy = { AirDash = true, Grapple = true, Mantle = true },

	CanStart = function(_ctx: Context, wall: Wall?): boolean
		return wall ~= nil
	end,

	Start = function(ctx: Context, wall: Wall): MovementContext.Payload?
		local velocity = ctx:Velocity()
		local flatVelocity = MathUtil.flat(velocity)
		local alongWall = MathUtil.projectOnPlane(flatVelocity, wall.Normal)
		if alongWall.Magnitude < 1 then
			alongWall = MathUtil.projectOnPlane(ctx:MoveDirection(), wall.Normal)
		end
		local fallbackTangent = wall.Normal:Cross(Vector3.yAxis) * -wall.Side
		state.Tangent = MathUtil.flatUnit(alongWall, fallbackTangent)
		state.Normal = wall.Normal
		state.Side = wall.Side
		state.Instance = wall.Instance
		state.Speed = math.clamp(flatVelocity.Magnitude, Config.Speed, Config.Speed * Config.MaxSpeedFactor)
		state.VerticalVelocity = Config.InitialUpVelocity + math.max(velocity.Y, 0) * ENTRY_LIFT_FACTOR
		state.Elapsed = 0
		ctx.AirDashCharges = MovementConfig.AirDash.Charges
		ctx:FaceDirection(state.Tangent)
		return { Side = wall.Side }
	end,

	Update = function(ctx: Context, dt: number): boolean
		state.Elapsed += dt
		if ctx.Grounded or state.Elapsed >= Config.MaxDuration then
			return false
		end
		if not ctx:DrainStamina(Config.StaminaPerSecond * dt, os.clock()) then
			return false
		end
		local input = ctx:MoveDirection()
		if input.Magnitude > 0.1 and input.Unit:Dot(state.Normal) > Config.DetachInputDot then
			return false
		end

		-- Follow the wall; stop when it ends or turns too sharply.
		local origin = ctx.Root.Position
		local result = ctx:Raycast(origin, -state.Normal * (Config.DetectionDistance + FOLLOW_EXTRA_REACH))
		if not result or not WallRun.IsWallSurface(result) then
			return false
		end
		local normal = MathUtil.flatUnit(result.Normal, state.Normal)
		if normal:Dot(state.Normal) < 0.8 then
			return false
		end
		state.Normal = normal
		state.Tangent = MathUtil.flatUnit(MathUtil.projectOnPlane(state.Tangent, normal), state.Tangent)
		state.Instance = result.Instance

		if ctx:Raycast(origin, state.Tangent * BLOCK_PROBE) then
			return false
		end

		state.VerticalVelocity -= Config.Gravity * dt
		ctx:SetVelocity(
			state.Tangent * state.Speed
				- state.Normal * Config.StickVelocity
				+ Vector3.new(0, state.VerticalVelocity, 0)
		)
		ctx:FaceDirection(state.Tangent)
		return true
	end,

	Stop = function(ctx: Context, reason: string): (string?, any)
		ctx:ReleaseFacing()
		ctx:ReleaseMover()
		ctx:SetCooldown("WallRun", Config.Cooldown, os.clock())
		ctx:RememberWall(state.Instance, state.Normal)
		state.Instance = nil

		if reason == "Jumped" or reason == "Interrupted" then
			-- WallJump or the interrupting action sets the velocity.
			return nil, nil
		end
		local exit = state.Tangent * state.Speed * EXIT_SPEED_FACTOR
		local velocity = Vector3.new(exit.X, math.max(state.VerticalVelocity, 0), exit.Z)
		ctx.Root.AssemblyLinearVelocity = velocity
		if not ctx.Grounded then
			return "Launch", velocity
		end
		return nil, nil
	end,
} :: MovementContext.Ability

return WallRun
