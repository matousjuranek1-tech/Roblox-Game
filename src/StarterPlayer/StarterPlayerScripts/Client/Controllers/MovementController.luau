--!strict
--[[
	MovementController
	Client-side movement state machine. At most one ability is active at a time; abilities hand
	over to each other (dash -> slide, wall run -> wall jump -> launch -> grapple...).

	Frame order (RunService.PreSimulation, before physics):
	  ground state -> stamina -> sprint -> active ability Update -> automatic abilities (mantle,
	  wall run) -> grapple target search.

	The client predicts everything immediately for responsiveness and reports each ability to
	the server (MovementAction). The server validates and may reply with MovementCorrection,
	which cancels the prediction. Other controllers (camera, VFX, animation, UI) only observe
	this controller through its signals and GetSnapshot().
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MovementProtocol = require(ReplicatedStorage.Shared.Net.MovementProtocol)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)

local Movement = script.Parent.Parent.Movement
local Dash = require(Movement.Abilities.Dash)
local Grapple = require(Movement.Abilities.Grapple)
local GrappleTargeting = require(Movement.GrappleTargeting)
local Launch = require(Movement.Abilities.Launch)
local Mantle = require(Movement.Abilities.Mantle)
local MovementContext = require(Movement.MovementContext)
local Slide = require(Movement.Abilities.Slide)
local WallJump = require(Movement.Abilities.WallJump)
local WallRun = require(Movement.Abilities.WallRun)

local InputController = require(script.Parent.InputController)

type Context = MovementContext.Context

export type Snapshot = {
	Action: string?,
	Stamina: number,
	StaminaMax: number,
	-- Horizontal speed in studs/s.
	Speed: number,
	VerticalSpeed: number,
	Grounded: boolean,
	Sprinting: boolean,
	-- 0 = just used, 1 = ready.
	DashReadiness: number,
	GrappleReadiness: number,
	AirDashCharges: number,
	AirDashUnlocked: boolean,
	WallJumpChain: number,
	-- 1 = wall on the right, -1 = left, 0 = not wall running.
	WallSide: number,
	GrappleTarget: BasePart?,
	-- Point the rope is attached to while grappling.
	GrappleAnchor: BasePart?,
	TurnRate: number,
}

local ABILITIES: { [string]: MovementContext.Ability } = {
	Dash = Dash.Ground,
	AirDash = Dash.Air,
	Slide = Slide.Ability,
	WallRun = WallRun.Ability,
	Mantle = Mantle.Ability,
	Grapple = Grapple.Ability,
	Launch = Launch,
}

-- JumpRequest can fire repeatedly while the jump input is held.
local JUMP_REPEAT_GUARD = 0.1
local CHARACTER_LOAD_TIMEOUT = 10

local MovementController = {
	-- (actionName, payload) after an ability started locally.
	ActionStarted = Signal.new() :: Signal.Signal<string, MovementContext.Payload?>,
	-- (actionName, reason) after an ability ended.
	ActionEnded = Signal.new() :: Signal.Signal<string, string>,
	-- (fallSpeed) when the character touches the ground after being airborne.
	Landed = Signal.new() :: Signal.Signal<number>,
	-- (launchVelocity)
	WallJumped = Signal.new() :: Signal.Signal<Vector3>,
	-- (kind) "Rejected" or "Corrected" from the server.
	Corrected = Signal.new() :: Signal.Signal<string>,
}

local context: Context? = nil
local characterTrove = Trove.new()
local actionRemote: RemoteEvent
local lastJumpHandled = 0
local lastTargetRefresh = 0
local sprintIdleTime = 0
local jumpVelocity = MathUtil.jumpVelocity(MovementConfig.Jump.Height, workspace.Gravity)

local snapshot: Snapshot = {
	Action = nil,
	Stamina = MovementConfig.Stamina.Max,
	StaminaMax = MovementConfig.Stamina.Max,
	Speed = 0,
	VerticalSpeed = 0,
	Grounded = true,
	Sprinting = false,
	DashReadiness = 1,
	GrappleReadiness = 1,
	AirDashCharges = 0,
	AirDashUnlocked = false,
	WallJumpChain = 0,
	WallSide = 0,
	GrappleTarget = nil,
	GrappleAnchor = nil,
	TurnRate = 0,
}

local startAction: (ctx: Context, name: string, request: any) -> boolean

local function canInterrupt(current: string?, incoming: string): boolean
	if current == nil then
		return true
	end
	if current == incoming then
		return false
	end
	return ABILITIES[current].InterruptibleBy[incoming] == true
end

local function endAction(ctx: Context, reason: string, suppressFollowUp: boolean?)
	local action = ctx.Action
	if not action then
		return
	end
	ctx.Action = nil
	local nextName, nextRequest = ABILITIES[action.Name].Stop(ctx, reason)
	if MovementProtocol.Sustained[action.Name] then
		actionRemote:FireServer("End", action.Name)
	end
	MovementController.ActionEnded:Fire(action.Name, reason)
	if nextName and not suppressFollowUp then
		startAction(ctx, nextName, nextRequest)
	end
end

function startAction(ctx: Context, name: string, request: any): boolean
	local ability = ABILITIES[name]
	local current = ctx.Action
	if current and not canInterrupt(current.Name, name) then
		return false
	end
	if not ability.CanStart(ctx, request) then
		return false
	end
	if current then
		endAction(ctx, "Interrupted", true)
	end
	ctx.Action = { Name = name, StartTime = os.clock() }
	local payload = ability.Start(ctx, request)
	if MovementProtocol.ServerActions[name] then
		actionRemote:FireServer("Start", name, payload)
	end
	MovementController.ActionStarted:Fire(name, payload)
	return true
end

local function performWallJump(ctx: Context, wall: WallRun.Wall, carry: Vector3, now: number)
	local velocity = WallJump.Execute(ctx, wall, carry, now)
	if not velocity then
		-- Not allowed (stamina, chain cap): keep whatever momentum we have.
		startAction(ctx, "Launch", ctx:Velocity())
		return
	end
	actionRemote:FireServer("Start", "WallJump")
	MovementController.WallJumped:Fire(velocity)
	startAction(ctx, "Launch", velocity)
end

local function onJumpRequested()
	local ctx = context
	if not ctx or not ctx:IsUsable() then
		return
	end
	local now = os.clock()
	if now - lastJumpHandled < JUMP_REPEAT_GUARD then
		return
	end

	local current = ctx.Action
	local name = if current then current.Name else nil
	if name == "WallRun" then
		local wall = WallRun.CurrentWall()
		local carry = WallRun.CurrentTangentVelocity()
		endAction(ctx, "Jumped", true)
		if wall then
			performWallJump(ctx, wall, carry, now)
		end
	elseif name == "Grapple" then
		endAction(ctx, "Released")
	elseif name == "Slide" then
		-- The Humanoid performs the jump itself (still grounded); Slide hands its speed to Launch.
		if not Slide.HasHeadroom(ctx) then
			return
		end
		endAction(ctx, "Jumped")
	elseif name == "Mantle" or name == "Dash" or name == "AirDash" then
		return
	elseif not ctx.Grounded then
		local wall = WallJump.Detect(ctx)
		if wall then
			if name == "Launch" then
				endAction(ctx, "Interrupted", true)
			end
			performWallJump(ctx, wall, Vector3.zero, now)
		elseif ctx:IsGroundedOrCoyote(now) then
			-- Coyote jump: walked off a ledge a moment ago.
			local velocity = ctx:Velocity()
			ctx.Root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpVelocity, velocity.Z)
			ctx.JumpedSinceGrounded = true
		else
			return
		end
	else
		return
	end
	lastJumpHandled = now
end

local function onActionBegan(action: string)
	local ctx = context
	if not ctx or not ctx:IsUsable() then
		return
	end
	if action == "Dash" then
		local ground = ctx:IsGroundedOrCoyote(os.clock())
		startAction(ctx, if ground then "Dash" else "AirDash", nil)
	elseif action == "Slide" then
		startAction(ctx, "Slide", nil)
	elseif action == "Grapple" then
		local target = ctx.GrappleTarget
		if target then
			startAction(ctx, "Grapple", target)
		end
	end
end

local function updateSprint(ctx: Context, dt: number)
	local moving = ctx:MoveDirection().Magnitude > 0.1
	if InputController:IsSprintToggled() then
		if moving then
			sprintIdleTime = 0
		else
			sprintIdleTime += dt
			if sprintIdleTime >= MovementConfig.Sprint.ToggleStopGrace then
				InputController:ClearSprintToggle()
			end
		end
	end
	ctx.SprintInput = InputController:GetSprintInput()
	ctx.Sprinting = ctx.SprintInput and moving
	local target = if ctx.Sprinting then MovementConfig.Sprint.Speed else MovementConfig.Walk.Speed
	ctx.Humanoid.WalkSpeed = MathUtil.damp(ctx.Humanoid.WalkSpeed, target, MovementConfig.Sprint.Acceleration, dt)
end

local function tryAutomaticActions(ctx: Context)
	local current = ctx.Action
	local name = if current then current.Name else nil
	if canInterrupt(name, "Mantle") then
		local ledge = Mantle.Detect(ctx)
		if ledge and startAction(ctx, "Mantle", ledge) then
			return
		end
	end
	if canInterrupt(name, "WallRun") then
		local wall = WallRun.Detect(ctx)
		if wall then
			startAction(ctx, "WallRun", wall)
		end
	end
end

local function refreshGrappleTarget(ctx: Context, now: number)
	if now - lastTargetRefresh < 1 / MovementConfig.Grapple.TargetRefreshRate then
		return
	end
	lastTargetRefresh = now
	local current = ctx.Action
	if current and current.Name == "Grapple" then
		ctx.GrappleTarget = nil
		return
	end
	local camera = workspace.CurrentCamera
	ctx.GrappleTarget = if camera then GrappleTargeting.FindBest(ctx, camera) else nil
end

local function step(dt: number)
	local ctx = context
	if not ctx then
		return
	end
	local now = os.clock()

	local wasGrounded = ctx.Grounded
	ctx:UpdateGround(now)
	if ctx.Grounded and not wasGrounded then
		local fallSpeed = -ctx.MinAirVelocityY
		ctx.MinAirVelocityY = 0
		MovementController.Landed:Fire(fallSpeed)
	elseif not ctx.Grounded then
		ctx.MinAirVelocityY = math.min(ctx.MinAirVelocityY, ctx:Velocity().Y)
	end

	if not ctx:IsUsable() then
		endAction(ctx, "Interrupted", true)
		return
	end

	ctx:RegenerateStamina(dt, now)
	updateSprint(ctx, dt)
	ctx.SlideHeld = InputController:IsHeld("Slide")

	local current = ctx.Action
	if current and not ABILITIES[current.Name].Update(ctx, dt) then
		endAction(ctx, "Finished")
	end
	if not ctx.Grounded then
		tryAutomaticActions(ctx)
	end
	refreshGrappleTarget(ctx, now)
end

-- Cancels whatever is running without follow-ups, e.g. after a server teleport.
local function interrupt(reason: string)
	local ctx = context
	if not ctx then
		return
	end
	endAction(ctx, reason, true)
	ctx:ReleaseMover()
	ctx:ReleaseFacing()
	ctx.Root.AssemblyLinearVelocity = Vector3.zero
end

local function setupCharacter(character: Model)
	characterTrove:Clean()
	context = nil

	local humanoid = character:WaitForChild("Humanoid", CHARACTER_LOAD_TIMEOUT)
	local root = character:WaitForChild("HumanoidRootPart", CHARACTER_LOAD_TIMEOUT)
	if not (humanoid and humanoid:IsA("Humanoid") and root and root:IsA("BasePart")) then
		return
	end
	if Players.LocalPlayer.Character ~= character then
		return
	end

	local ctx = MovementContext.new(character, humanoid, root)
	-- Ragdoll/trip states fight the custom movement; the game has its own stagger in PHASE 2.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	characterTrove:Add(function()
		if context == ctx then
			context = nil
		end
		endAction(ctx, "Died", true)
		ctx:Destroy()
	end)
	characterTrove:Connect(humanoid.StateChanged, function(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
		-- A regular jump consumes coyote time, so holding jump cannot add a second jump.
		if new == Enum.HumanoidStateType.Jumping then
			ctx.JumpedSinceGrounded = true
		end
	end)
	characterTrove:Connect(humanoid.Died, function()
		characterTrove:Clean()
	end)
	context = ctx
end

function MovementController:GetContext(): Context?
	return context
end

-- Current movement state for camera/VFX/UI. The returned table is reused every call.
function MovementController:GetSnapshot(): Snapshot?
	local ctx = context
	if not ctx then
		return nil
	end
	local now = os.clock()
	local velocity = ctx:Velocity()
	local action = ctx.Action
	local actionName = if action then action.Name else nil
	local wallSide = 0
	if actionName == "WallRun" then
		local wall = WallRun.CurrentWall()
		wallSide = if wall then wall.Side else 0
	end
	snapshot.Action = actionName
	snapshot.Stamina = ctx.Stamina
	snapshot.Speed = MathUtil.flat(velocity).Magnitude
	snapshot.VerticalSpeed = velocity.Y
	snapshot.Grounded = ctx.Grounded
	snapshot.Sprinting = ctx.Sprinting
	snapshot.DashReadiness = 1 - ctx:CooldownRemaining("Dash", now) / MovementConfig.Dash.Cooldown
	snapshot.GrappleReadiness = 1 - ctx:CooldownRemaining("Grapple", now) / MovementConfig.Grapple.Cooldown
	snapshot.AirDashCharges = ctx.AirDashCharges
	snapshot.AirDashUnlocked = ctx:IsUnlocked("AirDash")
	snapshot.WallJumpChain = ctx.WallJumpChain
	snapshot.WallSide = wallSide
	snapshot.GrappleTarget = ctx.GrappleTarget
	snapshot.GrappleAnchor = if actionName == "Grapple" then Grapple.CurrentTarget() else nil
	snapshot.TurnRate = ctx.Root.AssemblyAngularVelocity.Y
	return snapshot
end

function MovementController:Start()
	actionRemote = Remotes.Event("MovementAction")
	GrappleTargeting.Init()

	Remotes.Event("MovementCorrection").OnClientEvent:Connect(function(kind: unknown, action: unknown)
		local ctx = context
		if not ctx or type(kind) ~= "string" then
			return
		end
		if kind == "Rejected" then
			local current = ctx.Action
			if current and current.Name == action then
				endAction(ctx, "Rejected", true)
			end
		elseif kind == "Corrected" then
			interrupt("Corrected")
		end
		MovementController.Corrected:Fire(kind)
	end)

	-- The server teleports the character on trial resets/restarts: drop local momentum.
	Remotes.Event("TimeTrial").OnClientEvent:Connect(function(kind: unknown)
		if kind == "Reset" or kind == "Cancelled" then
			interrupt("Teleported")
		end
	end)

	InputController.ActionBegan:Connect(onActionBegan)
	InputController.JumpRequested:Connect(onJumpRequested)

	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end

	RunService.PreSimulation:Connect(step)
end

return MovementController
