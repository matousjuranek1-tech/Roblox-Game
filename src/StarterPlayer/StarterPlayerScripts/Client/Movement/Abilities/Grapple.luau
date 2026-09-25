--!strict
--[[
	Grapple
	Fires a rope at the targeted grapple point (see GrappleTargeting), waits FireTime for the
	rope to land, then pulls the character toward the point with rising speed. The target
	position is re-read every frame, so points on moving objects (PHASE 4: Titan anchors) work
	without changes. Ends on arrival (pops the player up and forward), on jump (release with the
	current momentum), when blocked, or on timeout. Every ending hands over to Launch.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)

type Context = MovementContext.Context

local Config = MovementConfig.Grapple

-- Allow the pull to build speed before judging whether it is stuck.
local STUCK_CHECK_DELAY = 0.1

local state = {
	Target = nil :: BasePart?,
	Direction = -Vector3.zAxis,
	Speed = 0,
	Elapsed = 0,
	StuckTime = 0,
	Timeout = 0,
	Arrived = false,
}

local Grapple = {}

-- The point the rope is attached to (valid while the Grapple action is active).
function Grapple.CurrentTarget(): BasePart?
	return state.Target
end

Grapple.Ability = {
	Name = "Grapple",
	InterruptibleBy = { AirDash = true },

	CanStart = function(ctx: Context, target: BasePart?): boolean
		return target ~= nil and target:IsDescendantOf(workspace) and ctx:IsReady("Grapple", os.clock())
	end,

	Start = function(ctx: Context, target: BasePart): MovementContext.Payload?
		local toTarget = target.Position - ctx.Root.Position
		state.Target = target
		state.Direction = MathUtil.safeUnit(toTarget, ctx:LookDirection())
		state.Speed = math.max(ctx:Velocity():Dot(state.Direction), Config.InitialSpeed)
		state.Elapsed = 0
		state.StuckTime = 0
		state.Timeout = toTarget.Magnitude / Config.PullSpeed + Config.FireTime + Config.TimeoutPadding
		state.Arrived = false
		-- Grappling refreshes every air resource: it is the "reset" of an aerial chain.
		ctx.AirDashCharges = MovementConfig.AirDash.Charges
		ctx.WallJumpChain = 0
		ctx:ForgetWall()
		ctx:FaceDirection(state.Direction)
		return { Target = target }
	end,

	Update = function(ctx: Context, dt: number): boolean
		state.Elapsed += dt
		local target = state.Target
		if not target or not target:IsDescendantOf(workspace) then
			return false
		end
		local toTarget = target.Position - ctx.Root.Position
		local distance = toTarget.Magnitude
		if distance > 1e-3 then
			state.Direction = toTarget / distance
		end

		if state.Elapsed < Config.FireTime then
			-- Rope still travelling: keep the current momentum.
			return true
		end
		if distance <= Config.ArriveDistance then
			state.Arrived = true
			return false
		end
		if state.Elapsed > state.Timeout then
			return false
		end

		state.Speed = math.min(state.Speed + Config.PullAcceleration * dt, Config.PullSpeed)
		if state.Elapsed > Config.FireTime + STUCK_CHECK_DELAY then
			local progress = ctx:Velocity():Dot(state.Direction)
			if progress < state.Speed * Config.StuckSpeedRatio then
				state.StuckTime += dt
				if state.StuckTime >= Config.StuckTime then
					return false
				end
			else
				state.StuckTime = 0
			end
		end

		local pullDirection = (state.Direction + Vector3.new(0, Config.UpwardBias, 0)).Unit
		ctx:SetVelocity(pullDirection * state.Speed)
		ctx:FaceDirection(state.Direction)
		return true
	end,

	Stop = function(ctx: Context, reason: string): (string?, any)
		ctx:ReleaseFacing()
		ctx:ReleaseMover()
		ctx:SetCooldown("Grapple", Config.Cooldown, os.clock())
		state.Target = nil

		local velocity
		if state.Arrived then
			velocity = state.Direction * math.min(state.Speed, Config.ExitSpeedCap)
				+ Vector3.new(0, Config.ExitUpVelocity, 0)
		elseif reason == "Released" then
			velocity = ctx:Velocity() + Vector3.new(0, Config.ReleaseUpVelocity, 0)
		else
			velocity = ctx:Velocity()
		end
		if reason == "Interrupted" then
			return nil, nil
		end
		ctx.Root.AssemblyLinearVelocity = velocity
		return "Launch", velocity
	end,
} :: MovementContext.Ability

return Grapple
