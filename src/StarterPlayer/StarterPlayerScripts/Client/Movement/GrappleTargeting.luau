--!strict
--[[
	GrappleTargeting
	Picks the grapple point the player most likely means: inside a cone in front of the camera,
	within range, preferring points near the screen center and close by, with clear line of
	sight. Auto-targeting is essential on touch and gamepad, where precise aiming is not possible.

	Candidates come from CollectionService, so points that stream in or out (StreamingEnabled)
	are tracked automatically. Only the best few candidates get a line-of-sight raycast.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local MovementContext = require(script.Parent.MovementContext)

type Context = MovementContext.Context

type Candidate = {
	Part: BasePart,
	Score: number,
}

local Config = MovementConfig.Grapple

-- Weight of distance against screen-center alignment in the score.
local DISTANCE_WEIGHT = 0.35
-- LOS rays stop this short of the point so the point's own geometry never blocks it.
local LOS_MARGIN = 2

local points: { BasePart } = {}
local scratch: { Candidate } = {}
local minDot = math.cos(math.rad(Config.AimConeDegrees))

local GrappleTargeting = {}

local function onAdded(instance: Instance)
	if instance:IsA("BasePart") and not table.find(points, instance) then
		table.insert(points, instance)
	end
end

local function onRemoved(instance: Instance)
	local index = table.find(points, instance :: any)
	if index then
		table.remove(points, index)
	end
end

function GrappleTargeting.Init()
	local tag = WorldConfig.Tags.GrapplePoint
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemoved)
	for _, instance in CollectionService:GetTagged(tag) do
		onAdded(instance)
	end
end

local function byScore(a: Candidate, b: Candidate): boolean
	return a.Score > b.Score
end

function GrappleTargeting.FindBest(ctx: Context, camera: Camera): BasePart?
	local rootPosition = ctx.Root.Position
	local cameraFrame = camera.CFrame
	local cameraPosition = cameraFrame.Position
	local cameraLook = cameraFrame.LookVector

	table.clear(scratch)
	for _, part in points do
		local position = part.Position
		local distance = (position - rootPosition).Magnitude
		if distance >= Config.MinRange and distance <= Config.Range then
			local alignment = cameraLook:Dot((position - cameraPosition).Unit)
			if alignment >= minDot then
				table.insert(scratch, {
					Part = part,
					Score = alignment - (distance / Config.Range) * DISTANCE_WEIGHT,
				})
			end
		end
	end
	if #scratch == 0 then
		return nil
	end
	table.sort(scratch, byScore)

	for index = 1, math.min(#scratch, Config.LineOfSightCandidates) do
		local part = scratch[index].Part
		local toPoint = part.Position - rootPosition
		local distance = toPoint.Magnitude
		if ctx:Raycast(rootPosition, toPoint.Unit * math.max(distance - LOS_MARGIN, 0.1)) == nil then
			return part
		end
	end
	return nil
end

return GrappleTargeting
