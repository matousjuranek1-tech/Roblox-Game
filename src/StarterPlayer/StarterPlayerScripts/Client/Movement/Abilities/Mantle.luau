--!strict
--[[
	Mantle
	Automatic ledge climb. While airborne and holding toward a wall, three queries look for:
	  1. a wall in front at chest height,
	  2. a flat top between MinHeight and MaxHeight above the feet,
	  3. enough free space on top for a standing character.
	The character is then driven in two phases: straight up past the edge, then forward onto it.
	No button press: missing a ledge by a few studs should never feel bad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

export type Ledge = {
	Top: Vector3,
	-- Horizontal normal of the wall face, pointing back toward the character.
	Normal: Vector3,
}

local Config = MovementConfig.Mantle

local CHEST_OFFSET = 0.5
-- How far past the wall face the top surface is probed.
local TOP_PROBE_INSET = 0.9
local STAND_HEIGHT = 5.4
local STAND_FOOTPRINT = 1.6
local MAX_DRIVE_SPEED = 80
local MIN_TOP_NORMAL_Y = 0.7
local MAX_WALL_NORMAL_Y = 0.3

local state = {
	LiftTarget = Vector3.zero,
	FinalTarget = Vector3.zero,
	Phase = 1,
	PhaseElapsed = 0,
	LiftDuration = Config.MinUpDuration,
	Direction = -Vector3.zAxis,
}

local Mantle = {}

function Mantle.Detect(ctx: Context): Ledge?
	if ctx.Grounded or not ctx:IsReady("Mantle", os.clock()) then
		return nil
	end
	local input = ctx:MoveDirection()
	if input.Magnitude < 0.1 then
		return nil
	end
	local forward = input.Unit
	local root = ctx.Root
	local feetY = ctx:FeetHeight()

	local wallHit = ctx:Raycast(root.Position + Vector3.new(0, CHEST_OFFSET, 0), forward * Config.ForwardReach)
	if not wallHit or math.abs(wallHit.Normal.Y) > MAX_WALL_NORMAL_Y then
		return nil
	end
	local normal = MathUtil.flatUnit(wallHit.Normal, -forward)

	local probe = wallHit.Position - normal * TOP_PROBE_INSET
	local topOrigin = Vector3.new(probe.X, feetY + Config.MaxHeight + 0.5, probe.Z)
	local topHit = ctx:Raycast(topOrigin, Vector3.new(0, -(Config.MaxHeight - Config.MinHeight + 0.5), 0))
	if not topHit or topHit.Normal.Y < MIN_TOP_NORMAL_Y then
		return nil
	end
	local top = topHit.Position

	local standCenter = top - normal * TOP_PROBE_INSET + Vector3.new(0, 0.2 + STAND_HEIGHT / 2, 0)
	local standSize = Vector3.new(STAND_FOOTPRINT, STAND_HEIGHT, STAND_FOOTPRINT)
	if #workspace:GetPartBoundsInBox(CFrame.new(standCenter), standSize, ctx.OverlapParams) > 0 then
		return nil
	end
	return { Top = top, Normal = normal }
end

Mantle.Ability = {
	Name = "Mantle",
	InterruptibleBy = {},

	CanStart = function(_ctx: Context, ledge: Ledge?): boolean
		return ledge ~= nil
	end,

	Start = function(ctx: Context, ledge: Ledge): MovementContext.Payload?
		local root = ctx.Root
		local hip = ctx:StandingHipOffset()
		state.LiftTarget = Vector3.new(root.Position.X, ledge.Top.Y + hip + 0.2, root.Position.Z) + ledge.Normal * 0.15
		state.FinalTarget = ledge.Top - ledge.Normal * Config.ForwardDistance + Vector3.new(0, hip + 0.1, 0)
		local rise = math.max(state.LiftTarget.Y - root.Position.Y, 0)
		state.LiftDuration = math.clamp(rise / Config.UpSpeed, Config.MinUpDuration, Config.MaxUpDuration)
		state.Phase = 1
		state.PhaseElapsed = 0
		state.Direction = -ledge.Normal
		ctx:FaceDirection(state.Direction)
		return nil
	end,

	Update = function(ctx: Context, dt: number): boolean
		state.PhaseElapsed += dt
		local duration = if state.Phase == 1 then state.LiftDuration else Config.ForwardDuration
		local remaining = duration - state.PhaseElapsed
		if remaining <= 0 then
			if state.Phase == 1 then
				state.Phase = 2
				state.PhaseElapsed = 0
				return true
			end
			return false
		end
		local target = if state.Phase == 1 then state.LiftTarget else state.FinalTarget
		local velocity = (target - ctx.Root.Position) / math.max(remaining, dt)
		if velocity.Magnitude > MAX_DRIVE_SPEED then
			velocity = velocity.Unit * MAX_DRIVE_SPEED
		end
		ctx:SetVelocity(velocity)
		return true
	end,

	Stop = function(ctx: Context, _reason: string): (string?, any)
		ctx:ReleaseFacing()
		ctx:ReleaseMover()
		ctx:SetCooldown("Mantle", Config.Cooldown, os.clock())
		local exit = state.Direction * math.min(ctx.Humanoid.WalkSpeed, MovementConfig.Walk.Speed)
		ctx.Root.AssemblyLinearVelocity = Vector3.new(exit.X, 0, exit.Z)
		return nil, nil
	end,
} :: MovementContext.Ability

return Mantle
