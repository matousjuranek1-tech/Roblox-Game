--!strict
--[[
	VFXController
	Movement effects for the local player and for everyone else:
	  * dash / air dash trail, wall-jump and hard-landing dust bursts,
	  * continuous dust while sliding or wall running,
	  * grapple rope (Beam) that shoots out, then follows the target even if it moves.

	Local effects react to MovementController signals instantly. Remote effects come from the
	server's MovementFx relay (already distance-filtered) plus the MoveState attribute for
	continuous states. Every effect is budgeted by the QualityController tier: particle counts
	scale with ParticleMultiplier and remote effects beyond RemoteFxDistance are skipped.
	Each character gets exactly one pooled trail, dust emitter and rope, created on first use.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Theme = require(script.Parent.Parent.UI.Theme)

local MovementController = require(script.Parent.MovementController)
local QualityController = require(script.Parent.QualityController)

type FxRig = {
	Character: Model,
	Root: BasePart,
	Trail: Trail,
	Dust: ParticleEmitter,
	DustAttachment: Attachment,
	Rope: Beam,
	RopeStart: Attachment,
	RopeEnd: Attachment,
	RopeTarget: BasePart?,
	RopeFired: number,
	TrailToken: number,
}

local DUST_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local DUST_INTERVAL = 0.05
local CONTINUOUS_DUST = 2
local BURST_DUST = 10
local LANDING_DUST = 14
local ROPE_TIMEOUT = 4
-- Remote MoveState arrives about a ping after the relayed Grapple event.
local REMOTE_STATE_GRACE = 0.4
local FEET_OFFSET = -2.8
local WALL_OFFSET = 1.2

local VFXController = {}

local rigs: { [Model]: FxRig } = {}
local dustClock = 0

local function scaledCount(base: number): number
	return math.max(math.round(base * QualityController:GetTier().ParticleMultiplier), 1)
end

local function createRig(character: Model): FxRig?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end

	local trailTop = Instance.new("Attachment")
	trailTop.Name = "FxTrailTop"
	trailTop.Position = Vector3.new(0, 1.1, 0)
	trailTop.Parent = root
	local trailBottom = Instance.new("Attachment")
	trailBottom.Name = "FxTrailBottom"
	trailBottom.Position = Vector3.new(0, -1.1, 0)
	trailBottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailTop
	trail.Attachment1 = trailBottom
	trail.Color = ColorSequence.new(Theme.Colors.Ivory, Theme.Colors.Ember)
	trail.Transparency = NumberSequence.new(0.25, 1)
	trail.LightEmission = 0.6
	trail.FaceCamera = true
	trail.MinLength = 0.05
	trail.Enabled = false
	trail.Parent = root

	local dustAttachment = Instance.new("Attachment")
	dustAttachment.Name = "FxDust"
	dustAttachment.Position = Vector3.new(0, FEET_OFFSET, 0)
	dustAttachment.Parent = root

	local dust = Instance.new("ParticleEmitter")
	dust.Texture = DUST_TEXTURE
	dust.Rate = 0
	dust.Lifetime = NumberRange.new(0.35, 0.7)
	dust.Speed = NumberRange.new(3, 8)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2.4),
	})
	dust.Transparency = NumberSequence.new(0.45, 1)
	dust.Color = ColorSequence.new(Color3.fromRGB(205, 196, 182))
	dust.LightInfluence = 1
	dust.Drag = 3
	dust.Parent = dustAttachment

	local hand = character:FindFirstChild("RightGripAttachment", true)
	local ropeStart = if hand and hand:IsA("Attachment") then hand else trailTop
	local ropeEnd = Instance.new("Attachment")
	ropeEnd.Name = "FxRopeEnd"
	ropeEnd.Parent = workspace.Terrain

	local rope = Instance.new("Beam")
	rope.Attachment0 = ropeStart
	rope.Attachment1 = ropeEnd
	rope.Width0 = 0.22
	rope.Width1 = 0.12
	rope.Color = ColorSequence.new(Theme.Colors.Ember, Theme.Colors.Cyan)
	rope.LightEmission = 0.7
	rope.Segments = 12
	rope.FaceCamera = true
	rope.Enabled = false
	rope.Parent = root

	local rig: FxRig = {
		Character = character,
		Root = root,
		Trail = trail,
		Dust = dust,
		DustAttachment = dustAttachment,
		Rope = rope,
		RopeStart = ropeStart,
		RopeEnd = ropeEnd,
		RopeTarget = nil,
		RopeFired = 0,
		TrailToken = 0,
	}
	rigs[character] = rig
	local function release()
		if rigs[character] == rig then
			rigs[character] = nil
			ropeEnd:Destroy()
		end
	end
	character.Destroying:Connect(release)
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(game) then
			release()
		end
	end)
	return rig
end

local function getRig(character: Model?): FxRig?
	if not character then
		return nil
	end
	return rigs[character] or createRig(character)
end

local function withinBudget(rig: FxRig): boolean
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	local distance = (rig.Root.Position - camera.CFrame.Position).Magnitude
	return distance <= QualityController:GetTier().RemoteFxDistance
end

local function pulseTrail(rig: FxRig, duration: number)
	rig.TrailToken += 1
	local token = rig.TrailToken
	rig.Trail.Lifetime = QualityController:GetTier().TrailLifetime
	rig.Trail.Enabled = true
	task.delay(duration, function()
		if rig.TrailToken == token then
			rig.Trail.Enabled = false
		end
	end)
end

local function burstDust(rig: FxRig, count: number)
	rig.DustAttachment.Position = Vector3.new(0, FEET_OFFSET, 0)
	rig.Dust:Emit(scaledCount(count))
end

local function attachRope(rig: FxRig, target: BasePart)
	rig.RopeTarget = target
	rig.RopeFired = os.clock()
	rig.RopeEnd.WorldPosition = rig.RopeStart.WorldPosition
	rig.Rope.Enabled = true
end

local function detachRope(rig: FxRig)
	rig.RopeTarget = nil
	rig.Rope.Enabled = false
end

local function playAction(rig: FxRig, action: string, payload: { [string]: any }?)
	if action == "Dash" then
		pulseTrail(rig, MovementConfig.Dash.Duration)
		burstDust(rig, BURST_DUST)
	elseif action == "AirDash" then
		pulseTrail(rig, MovementConfig.AirDash.Duration)
	elseif action == "WallJump" then
		burstDust(rig, BURST_DUST)
	elseif action == "Grapple" then
		local target = if payload then payload.Target else nil
		if typeof(target) == "Instance" and target:IsA("BasePart") then
			attachRope(rig, target)
		end
	end
end

-- Continuous effects and rope animation, every frame.
local function update(dt: number)
	dustClock += dt
	local emitDust = dustClock >= DUST_INTERVAL
	if emitDust then
		dustClock = 0
	end
	local localCharacter = Players.LocalPlayer.Character
	local localState = MovementController:GetSnapshot()
	local fireTime = MovementConfig.Grapple.FireTime

	for character, rig in rigs do
		local isLocal = character == localCharacter
		local moveState: string?
		local side = 0
		if isLocal then
			moveState = if localState then localState.Action else nil
			side = if localState then localState.WallSide else 0
		else
			local attribute = character:GetAttribute(WorldConfig.Attributes.MoveState)
			moveState = if type(attribute) == "string" then attribute else nil
			local sideAttribute = character:GetAttribute(WorldConfig.Attributes.MoveSide)
			side = if type(sideAttribute) == "number" then sideAttribute else 0
		end

		local target = rig.RopeTarget
		if target then
			local elapsed = os.clock() - rig.RopeFired
			local grace = if isLocal then fireTime else fireTime + REMOTE_STATE_GRACE
			local stillGrappling = moveState == "Grapple" or elapsed < grace
			if not stillGrappling or not target:IsDescendantOf(workspace) or elapsed > ROPE_TIMEOUT then
				detachRope(rig)
			else
				local progress = math.min(elapsed / fireTime, 1)
				rig.RopeEnd.WorldPosition = rig.RopeStart.WorldPosition:Lerp(target.Position, progress)
				rig.Rope.CurveSize0 = (1 - progress) * 3
			end
		end

		if emitDust and (moveState == "Slide" or moveState == "WallRun") and (isLocal or withinBudget(rig)) then
			rig.DustAttachment.Position = if moveState == "WallRun"
				then Vector3.new(WALL_OFFSET * side, -0.5, 0)
				else Vector3.new(0, FEET_OFFSET, 0)
			rig.Dust:Emit(scaledCount(CONTINUOUS_DUST))
		end
	end
end

function VFXController:Start()
	MovementController.ActionStarted:Connect(function(action, payload)
		local rig = getRig(Players.LocalPlayer.Character)
		if rig then
			playAction(rig, action, payload)
		end
	end)
	MovementController.WallJumped:Connect(function()
		local rig = getRig(Players.LocalPlayer.Character)
		if rig then
			playAction(rig, "WallJump", nil)
		end
	end)
	MovementController.Landed:Connect(function(fallSpeed)
		if fallSpeed > MovementConfig.Landing.HardLandingSpeed then
			local rig = getRig(Players.LocalPlayer.Character)
			if rig then
				burstDust(rig, LANDING_DUST)
			end
		end
	end)

	Remotes.UnreliableEvent("MovementFx").OnClientEvent
		:Connect(function(source: unknown, action: unknown, payload: unknown)
			if typeof(source) ~= "Instance" or not (source :: Instance):IsA("Player") or type(action) ~= "string" then
				return
			end
			local rig = getRig((source :: Player).Character)
			if rig and withinBudget(rig) then
				playAction(rig, action, if type(payload) == "table" then payload :: { [string]: any } else nil)
			end
		end)

	-- Remote characters need a rig for continuous effects even before their first relayed action.
	local function watch(player: Player)
		if player == Players.LocalPlayer then
			return
		end
		player.CharacterAdded:Connect(function(character)
			character:GetAttributeChangedSignal(WorldConfig.Attributes.MoveState):Connect(function()
				getRig(character)
			end)
		end)
		local character = player.Character
		if character then
			character:GetAttributeChangedSignal(WorldConfig.Attributes.MoveState):Connect(function()
				getRig(character)
			end)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	RunService.RenderStepped:Connect(update)
end

return VFXController
