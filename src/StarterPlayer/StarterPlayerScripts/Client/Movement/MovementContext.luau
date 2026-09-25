--!strict
--[[
	MovementContext
	Per-character movement state shared by MovementController and every ability module.

	Physics model: the Humanoid keeps doing what it does best (walking, jumping, stairs, slopes).
	Abilities take over by enabling one LinearVelocity ("mover") on the root:
	  * Vector mode drives all three axes (wall run, grapple, mantle, air dash),
	  * Plane mode drives only X/Z and leaves gravity alone (dash, slide, launch momentum).
	An AlignOrientation ("facing") turns the character while Humanoid.AutoRotate is off.
	Both constraints are created on the client, so they only exist for the owning player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)

local UP = Vector3.yAxis
local UNUSABLE_STATES: { [Enum.HumanoidStateType]: boolean } = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.PlatformStanding] = true,
	[Enum.HumanoidStateType.Physics] = true,
}

export type Payload = { [string]: any }

export type ActiveAction = {
	Name: string,
	StartTime: number,
}

type ContextFields = {
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Attachment: Attachment,
	Mover: LinearVelocity,
	Facing: AlignOrientation,
	RayParams: RaycastParams,
	OverlapParams: OverlapParams,
	DefaultHipHeight: number,

	Stamina: number,
	LastStaminaSpend: number,
	SprintInput: boolean,
	Sprinting: boolean,
	SlideHeld: boolean,
	Grounded: boolean,
	LastGroundedTime: number,
	JumpedSinceGrounded: boolean,
	MinAirVelocityY: number,
	AirDashCharges: number,
	WallJumpChain: number,
	LastWallInstance: Instance?,
	LastWallNormal: Vector3?,
	Cooldowns: { [string]: number },
	Action: ActiveAction?,
	GrappleTarget: BasePart?,
}

local Context = {}
Context.__index = Context

export type Context = typeof(setmetatable({} :: ContextFields, Context))

-- Contract every ability module implements. MovementController owns the state machine.
export type Ability = {
	Name: string,
	-- Actions allowed to cut this one short while it is running.
	InterruptibleBy: { [string]: boolean },
	CanStart: (ctx: Context, request: any) -> boolean,
	-- Returns the payload sent to the server (and to local listeners), if any.
	Start: (ctx: Context, request: any) -> Payload?,
	-- Returns false when the action has finished.
	Update: (ctx: Context, dt: number) -> boolean,
	-- Returns an optional follow-up action and its request (e.g. "Launch" with a velocity).
	Stop: (ctx: Context, reason: string) -> (string?, any),
}

function Context.new(character: Model, humanoid: Humanoid, root: BasePart): Context
	local attachment = Instance.new("Attachment")
	attachment.Name = "MovementAttachment"
	attachment.Parent = root

	local mover = Instance.new("LinearVelocity")
	mover.Name = "MovementMover"
	mover.Attachment0 = attachment
	mover.RelativeTo = Enum.ActuatorRelativeTo.World
	mover.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	mover.MaxForce = math.huge
	mover.PrimaryTangentAxis = Vector3.xAxis
	mover.SecondaryTangentAxis = Vector3.zAxis
	mover.Enabled = false
	mover.Parent = root

	local facing = Instance.new("AlignOrientation")
	facing.Name = "MovementFacing"
	facing.Mode = Enum.OrientationAlignmentMode.OneAttachment
	facing.Attachment0 = attachment
	facing.RigidityEnabled = false
	facing.Responsiveness = 60
	facing.MaxTorque = math.huge
	facing.MaxAngularVelocity = math.huge
	facing.Enabled = false
	facing.Parent = root

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	-- Rays behave like a character: other characters and non-collidable parts are ignored.
	rayParams.CollisionGroup = WorldConfig.CollisionGroups.Characters
	rayParams.RespectCanCollide = true

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }
	overlapParams.CollisionGroup = WorldConfig.CollisionGroups.Characters
	overlapParams.RespectCanCollide = true

	local fields: ContextFields = {
		Player = Players.LocalPlayer,
		Character = character,
		Humanoid = humanoid,
		Root = root,
		Attachment = attachment,
		Mover = mover,
		Facing = facing,
		RayParams = rayParams,
		OverlapParams = overlapParams,
		DefaultHipHeight = humanoid.HipHeight,

		Stamina = MovementConfig.Stamina.Max,
		LastStaminaSpend = 0,
		SprintInput = false,
		Sprinting = false,
		SlideHeld = false,
		Grounded = true,
		LastGroundedTime = 0,
		JumpedSinceGrounded = false,
		MinAirVelocityY = 0,
		AirDashCharges = MovementConfig.AirDash.Charges,
		WallJumpChain = 0,
		LastWallInstance = nil,
		LastWallNormal = nil,
		Cooldowns = {},
		Action = nil,
		GrappleTarget = nil,
	}
	return setmetatable(fields, Context)
end

-- State ---------------------------------------------------------------------------------------

function Context.IsUsable(self: Context): boolean
	return self.Humanoid.Health > 0 and not UNUSABLE_STATES[self.Humanoid:GetState()]
end

function Context.UpdateGround(self: Context, now: number)
	local state = self.Humanoid:GetState()
	local grounded = self.Humanoid.FloorMaterial ~= Enum.Material.Air
		and state ~= Enum.HumanoidStateType.Jumping
		and state ~= Enum.HumanoidStateType.Freefall
	if grounded then
		self.LastGroundedTime = now
		self.JumpedSinceGrounded = false
		if not self.Grounded then
			self.AirDashCharges = MovementConfig.AirDash.Charges
			self.WallJumpChain = 0
			self:ForgetWall()
		end
	end
	self.Grounded = grounded
end

function Context.IsGroundedOrCoyote(self: Context, now: number): boolean
	return self.Grounded
		or (not self.JumpedSinceGrounded and now - self.LastGroundedTime <= MovementConfig.Jump.CoyoteTime)
end

function Context.IsUnlocked(self: Context, name: string): boolean
	return self.Player:GetAttribute(WorldConfig.Attributes.UnlockPrefix .. name) == true
end

-- Last wall used for a wall run or wall jump; it cannot be reused until the character lands.
function Context.RememberWall(self: Context, instance: Instance?, normal: Vector3)
	self.LastWallInstance = instance
	self.LastWallNormal = normal
end

function Context.ForgetWall(self: Context)
	self.LastWallInstance = nil
	self.LastWallNormal = nil
end

function Context.IsLastWall(self: Context, instance: Instance, normal: Vector3): boolean
	local lastNormal = self.LastWallNormal
	return self.LastWallInstance == instance and lastNormal ~= nil and lastNormal:Dot(normal) > 0.95
end

-- Stamina -------------------------------------------------------------------------------------

function Context.HasStamina(self: Context, amount: number): boolean
	return self.Stamina >= amount
end

function Context.SpendStamina(self: Context, amount: number, now: number): boolean
	if self.Stamina < amount then
		return false
	end
	self.Stamina -= amount
	self.LastStaminaSpend = now
	return true
end

-- Continuous drain. Returns false once stamina is empty.
function Context.DrainStamina(self: Context, amount: number, now: number): boolean
	self.Stamina = math.max(self.Stamina - amount, 0)
	self.LastStaminaSpend = now
	return self.Stamina > 0
end

function Context.RegenerateStamina(self: Context, dt: number, now: number)
	local config = MovementConfig.Stamina
	if now - self.LastStaminaSpend >= config.RegenDelay then
		self.Stamina = math.min(config.Max, self.Stamina + config.RegenPerSecond * dt)
	end
end

-- Cooldowns -----------------------------------------------------------------------------------

function Context.SetCooldown(self: Context, name: string, seconds: number, now: number)
	self.Cooldowns[name] = now + seconds
end

function Context.IsReady(self: Context, name: string, now: number): boolean
	local readyAt = self.Cooldowns[name]
	return readyAt == nil or now >= readyAt
end

function Context.CooldownRemaining(self: Context, name: string, now: number): number
	local readyAt = self.Cooldowns[name]
	return if readyAt then math.max(readyAt - now, 0) else 0
end

-- Kinematics ----------------------------------------------------------------------------------

function Context.Velocity(self: Context): Vector3
	return self.Root.AssemblyLinearVelocity
end

function Context.FlatVelocity(self: Context): Vector3
	return MathUtil.flat(self.Root.AssemblyLinearVelocity)
end

-- Camera-relative movement input from the default ControlModule (horizontal, length 0..1).
function Context.MoveDirection(self: Context): Vector3
	return MathUtil.flat(self.Humanoid.MoveDirection)
end

function Context.LookDirection(self: Context): Vector3
	return MathUtil.flatUnit(self.Root.CFrame.LookVector, -Vector3.zAxis)
end

-- Height of the root center above the feet while standing.
function Context.StandingHipOffset(self: Context): number
	return self.DefaultHipHeight + self.Root.Size.Y / 2
end

function Context.FeetHeight(self: Context): number
	return self.Root.Position.Y - (self.Humanoid.HipHeight + self.Root.Size.Y / 2)
end

function Context.Raycast(self: Context, origin: Vector3, direction: Vector3): RaycastResult?
	return workspace:Raycast(origin, direction, self.RayParams)
end

-- Drives all three axes.
function Context.SetVelocity(self: Context, velocity: Vector3)
	local mover = self.Mover
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	mover.VectorVelocity = velocity
	mover.Enabled = true
end

-- Drives X/Z only; gravity and jumping keep working.
function Context.SetPlanarVelocity(self: Context, velocity: Vector3)
	local mover = self.Mover
	mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	mover.PlaneVelocity = Vector2.new(velocity.X, velocity.Z)
	mover.Enabled = true
end

function Context.ReleaseMover(self: Context)
	self.Mover.Enabled = false
end

function Context.FaceDirection(self: Context, direction: Vector3)
	local flatDirection = MathUtil.flat(direction)
	if flatDirection.Magnitude < 1e-3 then
		return
	end
	self.Humanoid.AutoRotate = false
	self.Facing.CFrame = CFrame.lookAt(Vector3.zero, flatDirection.Unit, UP)
	self.Facing.Enabled = true
end

function Context.ReleaseFacing(self: Context)
	self.Facing.Enabled = false
	self.Humanoid.AutoRotate = true
end

function Context.Destroy(self: Context)
	self.Mover:Destroy()
	self.Facing:Destroy()
	self.Attachment:Destroy()
	if self.Humanoid.Parent then
		self.Humanoid.AutoRotate = true
		self.Humanoid.HipHeight = self.DefaultHipHeight
	end
end

return Context
