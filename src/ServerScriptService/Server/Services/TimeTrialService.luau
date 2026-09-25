--!strict
--[[
	TimeTrialService
	Server-timed parkour trials. They are the Phase 1 benchmark for movement feel, and later
	they power the Training Grounds leaderboard in the Hunter Citadel.

	Gates are parts tagged WorldConfig.Tags.TimeTrialGate with attributes:
	  TrialId (string), Index (number, 0 = start), IsFinish (boolean)
	A gate counts when the character's path crosses it in the gate's LookVector direction.
	Crossings are detected with a segment raycast between consecutive server positions, so a
	player moving at grapple speed can never tunnel through a thin gate.

	Parts tagged ResetPlane send the player back to their last checkpoint.
	Timing is fully server-side: the client only displays what the server reports.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local TimeTrialConfig = require(ReplicatedStorage.Shared.Config.TimeTrialConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)

local CharacterService = require(script.Parent.CharacterService)
local MovementService = require(script.Parent.MovementService)

local Tags = WorldConfig.Tags

local MAX_CROSSINGS_PER_STEP = 3
local MIN_SEGMENT = 0.05
-- Height of the character root above the floor when placed on a checkpoint.
local RESPAWN_HEIGHT = 3

type Run = {
	TrialId: string,
	StartTime: number,
	NextIndex: number,
}

type PlayerTrialState = {
	-- Character that finished spawning; positions of any other one are not scanned.
	Character: Model?,
	Run: Run?,
	LastPosition: Vector3?,
	CheckpointCFrame: CFrame?,
	Best: { [string]: number },
	LastRestart: number,
}

local TimeTrialService = {}

local states: { [Player]: PlayerTrialState } = {}
local crossingParams = RaycastParams.new()
local trialRemote: RemoteEvent

local function refreshCrossingFilter()
	local parts: { Instance } = {}
	for _, gate in CollectionService:GetTagged(Tags.TimeTrialGate) do
		table.insert(parts, gate)
	end
	for _, plane in CollectionService:GetTagged(Tags.ResetPlane) do
		table.insert(parts, plane)
	end
	crossingParams.FilterDescendantsInstances = parts
end

-- Standing position on the floor below a gate, facing through it.
local function gateRespawnCFrame(gate: BasePart): CFrame
	local bottom = gate.Position - gate.CFrame.UpVector * (gate.Size.Y / 2)
	local position = bottom + Vector3.new(0, RESPAWN_HEIGHT, 0)
	local look = gate.CFrame.LookVector
	return CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z))
end

local function findTrialSpawn(trialId: string): CFrame?
	for _, spawnPart in CollectionService:GetTagged(Tags.TimeTrialSpawn) do
		if spawnPart:IsA("BasePart") and spawnPart:GetAttribute("TrialId") == trialId then
			return spawnPart.CFrame * CFrame.new(0, spawnPart.Size.Y / 2 + RESPAWN_HEIGHT, 0)
		end
	end
	return nil
end

local function teleport(player: Player, state: PlayerTrialState, target: CFrame)
	local character = player.Character
	local root = CharacterService:GetRoot(player)
	if not character or not root then
		return
	end
	MovementService:NotifyTeleport(player, target)
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(target)
	-- The jump from the old to the new position must not count as a gate crossing.
	state.LastPosition = target.Position
end

local function onGateCrossed(player: Player, state: PlayerTrialState, gate: BasePart, now: number)
	local trialId = gate:GetAttribute("TrialId")
	local index = gate:GetAttribute("Index")
	if type(trialId) ~= "string" or type(index) ~= "number" then
		return
	end
	local trial = TimeTrialConfig.Trials[trialId]
	if not trial then
		return
	end

	if index == 0 then
		state.Run = { TrialId = trialId, StartTime = now, NextIndex = 1 }
		state.CheckpointCFrame = gateRespawnCFrame(gate)
		trialRemote:FireClient(player, "Started", trialId)
		return
	end

	local run = state.Run
	if not run or run.TrialId ~= trialId or index ~= run.NextIndex then
		return
	end
	local elapsed = now - run.StartTime
	run.NextIndex += 1
	state.CheckpointCFrame = gateRespawnCFrame(gate)

	if gate:GetAttribute("IsFinish") ~= true then
		trialRemote:FireClient(player, "Checkpoint", trialId, index, elapsed)
		return
	end

	state.Run = nil
	if elapsed < trial.MinValidTime then
		warn(`[TimeTrialService] {player.Name} finished {trialId} in {elapsed}s (below MinValidTime), ignored`)
		trialRemote:FireClient(player, "Invalid", trialId, elapsed)
		return
	end
	local previousBest = state.Best[trialId]
	local isBest = previousBest == nil or elapsed < previousBest
	if isBest then
		state.Best[trialId] = elapsed
	end
	trialRemote:FireClient(player, "Finished", trialId, elapsed, state.Best[trialId], isBest)
end

local function onResetPlane(player: Player, state: PlayerTrialState)
	local target = state.CheckpointCFrame
	if not target then
		local run = state.Run
		target = findTrialSpawn(if run then run.TrialId else "MovementLab")
	end
	if target then
		teleport(player, state, target)
		trialRemote:FireClient(player, "Reset")
	end
end

local function scanSegment(player: Player, state: PlayerTrialState, from: Vector3, to: Vector3, now: number)
	local travel = to - from
	local origin = from
	local remaining = travel
	for _ = 1, MAX_CROSSINGS_PER_STEP do
		local result = workspace:Raycast(origin, remaining, crossingParams)
		if not result then
			return
		end
		local part = result.Instance
		if part:HasTag(Tags.ResetPlane) then
			onResetPlane(player, state)
			return
		end
		if travel:Dot(part.CFrame.LookVector) > 0 then
			onGateCrossed(player, state, part, now)
		end
		-- Continue just past this gate; a ray that starts inside a part ignores that part.
		origin = result.Position + remaining.Unit * MIN_SEGMENT
		remaining = to - origin
		if remaining.Magnitude < MIN_SEGMENT then
			return
		end
	end
end

local function onRestartRequest(player: Player, kind: unknown)
	local state = states[player]
	if not state or kind ~= "Restart" then
		return
	end
	local now = os.clock()
	if now - state.LastRestart < TimeTrialConfig.RestartCooldown then
		return
	end
	state.LastRestart = now
	local run = state.Run
	local target = findTrialSpawn(if run then run.TrialId else "MovementLab")
	if not target then
		return
	end
	state.Run = nil
	state.CheckpointCFrame = nil
	teleport(player, state, target)
	trialRemote:FireClient(player, "Cancelled")
end

function TimeTrialService:Init()
	crossingParams.FilterType = Enum.RaycastFilterType.Include
	crossingParams.RespectCanCollide = false
	trialRemote = Remotes.Event("TimeTrial")
end

function TimeTrialService:Start()
	for _, tag in { Tags.TimeTrialGate, Tags.ResetPlane } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(refreshCrossingFilter)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(refreshCrossingFilter)
	end
	refreshCrossingFilter()

	local function onPlayerAdded(player: Player)
		states[player] = {
			Character = nil,
			Run = nil,
			LastPosition = nil,
			CheckpointCFrame = nil,
			Best = {},
			LastRestart = 0,
		}
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	CharacterService.CharacterReady:Connect(function(player, character, _humanoid, root)
		local state = states[player]
		if not state then
			return
		end
		state.Character = character
		state.LastPosition = root.Position
		if state.Run then
			state.Run = nil
			trialRemote:FireClient(player, "Cancelled")
		end
	end)

	trialRemote.OnServerEvent:Connect(onRestartRequest)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, state in states do
			local root = if player.Character == state.Character then CharacterService:GetRoot(player) else nil
			if root then
				local position = root.Position
				local last = state.LastPosition
				state.LastPosition = position
				if last and (position - last).Magnitude > MIN_SEGMENT then
					scanSegment(player, state, last, position, now)
				end
			end
		end
	end)
end

return TimeTrialService
