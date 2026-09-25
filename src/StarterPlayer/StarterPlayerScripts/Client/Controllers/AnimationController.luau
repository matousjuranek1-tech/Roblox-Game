--!strict
--[[
	AnimationController
	Procedural posing layered on top of Roblox's default animations: lean into sprint turns,
	recline in a slide, tilt toward the wall in a wall run, reach for the rope while grappling,
	arms up on a mantle. It offsets Motor6D.C0 (animations drive Motor6D.Transform), so both
	combine instead of fighting.

	The slide pose is gameplay-relevant for the local player: it physically lowers the head and
	torso so they fit under slide barriers. Other players are posed from the MoveState/MoveSide
	attributes the server writes on their characters. Authored animations (PHASE 9) can replace
	any pose here without touching movement code.

	R15 only (Game Settings > Avatar > R15); other rigs are simply not posed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)

local MovementController = require(script.Parent.MovementController)
local QualityController = require(script.Parent.QualityController)

type Pose = {
	Root: CFrame,
	RightArm: CFrame,
	LeftArm: CFrame,
}

type Rig = {
	Player: Player,
	Character: Model,
	Root: BasePart,
	RootJoint: Motor6D,
	RootC0: CFrame,
	RightShoulder: Motor6D?,
	RightShoulderC0: CFrame,
	LeftShoulder: Motor6D?,
	LeftShoulderC0: CFrame,
	Current: Pose,
	AtRest: boolean,
}

local BLEND_RATE = 14
local SPRINT_LEAN_SPEED = 22
local TURN_ROLL_FACTOR = 0.06
local MAX_TURN_ROLL = math.rad(12)
local REST_EPSILON = 1e-3
local RIG_LOAD_TIMEOUT = 10

local IDENTITY = CFrame.identity
local NEUTRAL: Pose = { Root = IDENTITY, RightArm = IDENTITY, LeftArm = IDENTITY }

local AnimationController = {}

local rigs: { [Model]: Rig } = {}
local rigTroves: { [Player]: Trove.Trove } = {}

local function angles(x: number, y: number, z: number): CFrame
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

-- Target pose for a movement state. `side`: 1 wall on the right, -1 left.
local function poseFor(state: string?, side: number, speed: number, grounded: boolean, turnRate: number): Pose
	if state == "Slide" then
		return { Root = angles(62, 0, 0), RightArm = angles(30, 0, 0), LeftArm = angles(30, 0, 0) }
	elseif state == "Dash" or state == "AirDash" then
		return { Root = angles(-18, 0, 0), RightArm = angles(-35, 0, 0), LeftArm = angles(-35, 0, 0) }
	elseif state == "WallRun" then
		local reach = angles(0, 0, 70 * side)
		return {
			Root = angles(-10, 0, -22 * side),
			RightArm = if side > 0 then reach else IDENTITY,
			LeftArm = if side < 0 then reach else IDENTITY,
		}
	elseif state == "Grapple" then
		return { Root = angles(-20, 0, 0), RightArm = angles(150, 0, 0), LeftArm = angles(20, 0, 0) }
	elseif state == "Mantle" then
		return { Root = angles(-25, 0, 0), RightArm = angles(110, 0, 0), LeftArm = angles(110, 0, 0) }
	elseif grounded and speed > SPRINT_LEAN_SPEED then
		local turnRoll = math.clamp(turnRate * TURN_ROLL_FACTOR, -MAX_TURN_ROLL, MAX_TURN_ROLL)
		return { Root = angles(-9, 0, 0) * CFrame.Angles(0, 0, turnRoll), RightArm = IDENTITY, LeftArm = IDENTITY }
	end
	return NEUTRAL
end

local function applyPose(rig: Rig)
	rig.RootJoint.C0 = rig.RootC0 * rig.Current.Root
	local right = rig.RightShoulder
	if right then
		right.C0 = rig.RightShoulderC0 * rig.Current.RightArm
	end
	local left = rig.LeftShoulder
	if left then
		left.C0 = rig.LeftShoulderC0 * rig.Current.LeftArm
	end
end

local function isNeutral(pose: Pose): boolean
	return pose.Root:FuzzyEq(IDENTITY, REST_EPSILON)
		and pose.RightArm:FuzzyEq(IDENTITY, REST_EPSILON)
		and pose.LeftArm:FuzzyEq(IDENTITY, REST_EPSILON)
end

local function findMotor(character: Model, partName: string, jointName: string): Motor6D?
	local part = character:FindFirstChild(partName)
	local joint = if part then part:FindFirstChild(jointName) else nil
	return if joint and joint:IsA("Motor6D") then joint else nil
end

local function addRig(player: Player, character: Model)
	local trove = rigTroves[player]
	if trove then
		trove:Clean()
	end
	trove = Trove.new()
	rigTroves[player] = trove

	local root = character:WaitForChild("HumanoidRootPart", RIG_LOAD_TIMEOUT)
	local lowerTorso = character:WaitForChild("LowerTorso", RIG_LOAD_TIMEOUT)
	if not (root and root:IsA("BasePart") and lowerTorso) or player.Character ~= character then
		return
	end
	local rootJoint = lowerTorso:FindFirstChild("Root")
	if not (rootJoint and rootJoint:IsA("Motor6D")) then
		return
	end
	local rightShoulder = findMotor(character, "RightUpperArm", "RightShoulder")
	local leftShoulder = findMotor(character, "LeftUpperArm", "LeftShoulder")
	local rig: Rig = {
		Player = player,
		Character = character,
		Root = root,
		RootJoint = rootJoint,
		RootC0 = rootJoint.C0,
		RightShoulder = rightShoulder,
		RightShoulderC0 = if rightShoulder then rightShoulder.C0 else IDENTITY,
		LeftShoulder = leftShoulder,
		LeftShoulderC0 = if leftShoulder then leftShoulder.C0 else IDENTITY,
		Current = { Root = IDENTITY, RightArm = IDENTITY, LeftArm = IDENTITY },
		AtRest = true,
	}
	rigs[character] = rig
	trove:Add(function()
		rigs[character] = nil
	end)
end

local function trackPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		addRig(player, character)
	end)
	player.CharacterRemoving:Connect(function(character)
		rigs[character] = nil
	end)
	if player.Character then
		task.spawn(addRig, player, player.Character)
	end
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local cameraPosition = camera.CFrame.Position
	local poseDistance = QualityController:GetTier().PoseDistance
	local alpha = 1 - math.exp(-BLEND_RATE * dt)
	local localPlayer = Players.LocalPlayer

	for _, rig in rigs do
		local isLocal = rig.Player == localPlayer
		if not isLocal and (rig.Root.Position - cameraPosition).Magnitude > poseDistance then
			if not rig.AtRest then
				rig.Current = { Root = IDENTITY, RightArm = IDENTITY, LeftArm = IDENTITY }
				applyPose(rig)
				rig.AtRest = true
			end
			continue
		end

		local target: Pose
		if isLocal then
			local state = MovementController:GetSnapshot()
			target = if state
				then poseFor(state.Action, state.WallSide, state.Speed, state.Grounded, state.TurnRate)
				else NEUTRAL
		else
			local moveState = rig.Character:GetAttribute(WorldConfig.Attributes.MoveState)
			local side = rig.Character:GetAttribute(WorldConfig.Attributes.MoveSide)
			local velocity = rig.Root.AssemblyLinearVelocity
			target = poseFor(
				if type(moveState) == "string" then moveState else nil,
				if type(side) == "number" then side else 0,
				MathUtil.flat(velocity).Magnitude,
				math.abs(velocity.Y) < 2,
				0
			)
		end

		if rig.AtRest and target == NEUTRAL then
			continue
		end
		local current = rig.Current
		current.Root = current.Root:Lerp(target.Root, alpha)
		current.RightArm = current.RightArm:Lerp(target.RightArm, alpha)
		current.LeftArm = current.LeftArm:Lerp(target.LeftArm, alpha)
		applyPose(rig)
		rig.AtRest = target == NEUTRAL and isNeutral(current)
	end
end

function AnimationController:Start()
	Players.PlayerAdded:Connect(trackPlayer)
	for _, player in Players:GetPlayers() do
		trackPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local trove = rigTroves[player]
		if trove then
			trove:Clean()
			rigTroves[player] = nil
		end
	end)
	-- Poses must be in place before physics so the slide pose affects collisions this frame.
	RunService.PreSimulation:Connect(update)
end

return AnimationController
