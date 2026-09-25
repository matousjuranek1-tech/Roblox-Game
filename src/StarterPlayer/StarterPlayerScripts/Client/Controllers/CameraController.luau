--!strict
--[[
	CameraController
	Layers feel on top of Roblox's default camera (it keeps handling zoom, occlusion and input):
	  * FOV widens with horizontal speed, plus short kicks on dash and wall jump,
	  * roll away from the wall while wall running,
	  * trauma-based shake (trauma^2 * noise) for hard landings, later for hits and Titans.

	Runs right after the default camera each frame. Only roll and a small positional offset are
	applied: neither changes the camera's look vector, which the default camera reads back next
	frame, so nothing accumulates or drifts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)

local MovementController = require(script.Parent.MovementController)

local Config = MovementConfig.Camera
local Landing = MovementConfig.Landing

local RENDER_STEP_NAME = "TitanboundCamera"
local KICK_DECAY = 6
local WALL_JUMP_KICK = 3
local WALL_JUMP_TRAUMA = 0.08
local GRAPPLE_TRAUMA = 0.05
-- Seeds keep the three noise channels independent.
local NOISE_SEED_X = 1.37
local NOISE_SEED_Y = 7.13
local NOISE_SEED_ROLL = 13.71

local CameraController = {}

local trauma = 0
local fovKick = 0
local roll = 0
local currentFov = Config.BaseFov
local noiseTime = 0
-- Accessibility: 0 disables shake entirely (settings menu in PHASE 8).
local shakeScale = 1

function CameraController:AddTrauma(amount: number)
	trauma = math.clamp(trauma + amount, 0, 1)
end

function CameraController:Kick(fovDegrees: number)
	fovKick += fovDegrees
end

function CameraController:SetShakeScale(scale: number)
	shakeScale = math.clamp(scale, 0, 1)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	if not camera or camera.CameraType ~= Enum.CameraType.Custom then
		return
	end

	local state = MovementController:GetSnapshot()
	local speed = if state then state.Speed else 0
	local action = if state then state.Action else nil

	local speedAlpha = MathUtil.inverseLerp(Config.FovSpeedMin, Config.FovSpeedMax, speed)
	local targetFov = Config.BaseFov + (Config.MaxSpeedFov - Config.BaseFov) * speedAlpha
	if action == "Grapple" then
		targetFov += Config.GrappleFovBonus
	end
	fovKick = MathUtil.damp(fovKick, 0, KICK_DECAY, dt)
	currentFov = MathUtil.damp(currentFov, targetFov, Config.FovDamping, dt)
	camera.FieldOfView = currentFov + fovKick

	-- Positive roll tilts the view left: tilt away from a wall on the right, and vice versa.
	local targetRoll = if state and action == "WallRun" then Config.WallRunRoll * state.WallSide else 0
	roll = MathUtil.damp(roll, targetRoll, Config.RollDamping, dt)

	trauma = math.max(trauma - Config.TraumaDecay * dt, 0)
	local shake = trauma * trauma * shakeScale
	noiseTime += dt * Config.ShakeFrequency

	if math.abs(roll) < 0.01 and shake <= 0 then
		return
	end
	local offset = Vector3.new(math.noise(noiseTime, NOISE_SEED_X), math.noise(noiseTime, NOISE_SEED_Y), 0)
		* (2 * Config.MaxShakeOffset * shake)
	local shakeRoll = math.noise(noiseTime, NOISE_SEED_ROLL) * 2 * Config.MaxShakeRoll * shake
	camera.CFrame = camera.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(roll + shakeRoll))
end

function CameraController:Start()
	MovementController.ActionStarted:Connect(function(action)
		if action == "Dash" then
			CameraController:Kick(Config.DashKick)
		elseif action == "AirDash" then
			CameraController:Kick(Config.AirDashKick)
		elseif action == "Grapple" then
			CameraController:AddTrauma(GRAPPLE_TRAUMA)
		end
	end)
	MovementController.WallJumped:Connect(function()
		CameraController:Kick(WALL_JUMP_KICK)
		CameraController:AddTrauma(WALL_JUMP_TRAUMA)
	end)
	MovementController.Landed:Connect(function(fallSpeed)
		if fallSpeed > Landing.HardLandingSpeed then
			local alpha = MathUtil.inverseLerp(0, Landing.TraumaRange, fallSpeed - Landing.HardLandingSpeed)
			CameraController:AddTrauma(MathUtil.lerp(Landing.TraumaMin, Landing.TraumaMax, alpha))
		end
	end)

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
