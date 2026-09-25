--!strict
--[[
	CharacterService
	Owns character-level setup that every other system relies on:
	  * collision group so characters never collide with each other,
	  * a CharacterReady signal other services use instead of wiring CharacterAdded themselves,
	  * safe accessors for a player's root part and humanoid.
]]

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)

local CHARACTER_GROUP = WorldConfig.CollisionGroups.Characters
local CHARACTER_LOAD_TIMEOUT = 10

local CharacterService = {
	-- (player, character, humanoid, root) fired once the character is spawned in the Workspace.
	CharacterReady = Signal.new() :: Signal.Signal<Player, Model, Humanoid, BasePart>,
}

local characterTroves: { [Player]: Trove.Trove } = {}

local function assignGroup(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = CHARACTER_GROUP
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local previous = characterTroves[player]
	if previous then
		previous:Clean()
	end
	local trove = Trove.new()
	characterTroves[player] = trove

	for _, descendant in character:GetDescendants() do
		assignGroup(descendant)
	end
	trove:Connect(character.DescendantAdded, assignGroup)

	local humanoid = character:WaitForChild("Humanoid", CHARACTER_LOAD_TIMEOUT)
	local root = character:WaitForChild("HumanoidRootPart", CHARACTER_LOAD_TIMEOUT)
	if not (humanoid and humanoid:IsA("Humanoid") and root and root:IsA("BasePart")) then
		warn(`[CharacterService] {player.Name}'s character is missing Humanoid/HumanoidRootPart`)
		return
	end
	-- CharacterAdded can fire before the character is parented and moved to its spawn point;
	-- listeners anchor validation at the root position, so wait until it is really placed.
	while player.Character == character and not character:IsDescendantOf(workspace) do
		character.AncestryChanged:Wait()
	end
	task.wait()
	if player.Character ~= character or not character:IsDescendantOf(workspace) then
		-- Respawned again (or removed) while we were waiting.
		return
	end
	CharacterService.CharacterReady:Fire(player, character, humanoid, root)
end

function CharacterService:Init()
	PhysicsService:RegisterCollisionGroup(CHARACTER_GROUP)
	PhysicsService:CollisionGroupSetCollidable(CHARACTER_GROUP, CHARACTER_GROUP, false)
end

function CharacterService:Start()
	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local trove = characterTroves[player]
		if trove then
			trove:Clean()
			characterTroves[player] = nil
		end
	end)
end

-- Returns the root part of a living character, or nil.
function CharacterService:GetRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function CharacterService:GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

return CharacterService
