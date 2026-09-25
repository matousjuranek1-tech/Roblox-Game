--!strict
--[[
	Remotes
	Every RemoteEvent in the game is declared in DEFINITIONS, so the full network surface can be
	audited in one place. The server creates them at boot (Remotes.Setup); clients wait for them.

	Rules:
	  * Reliable RemoteEvent for gameplay state (actions, results).
	  * UnreliableRemoteEvent for cosmetic, high-frequency data that may be dropped (FX replays).
	  * Every server handler validates its arguments (Shared/Util/Validate) and is rate-limited.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

type RemoteKind = "RemoteEvent" | "UnreliableRemoteEvent"

local FOLDER_NAME = "Remotes"
local CLIENT_WAIT_TIMEOUT = 60

local DEFINITIONS: { [string]: RemoteKind } = {
	-- client -> server: ("Start" | "End", actionName, payload?)
	MovementAction = "RemoteEvent",
	-- server -> client: (kind, actionName?) when the server rejects an action or rubber-bands
	MovementCorrection = "RemoteEvent",
	-- server -> other clients: (player, actionName, payload?) cosmetic replay of a validated action
	MovementFx = "UnreliableRemoteEvent",
	-- client -> server: ("Restart"); server -> client: (kind, ...) trial progress
	TimeTrial = "RemoteEvent",
}

local Remotes = {}

local folder: Folder? = nil

-- Server only: creates the Remotes folder and every declared remote.
function Remotes.Setup()
	assert(RunService:IsServer(), "Remotes.Setup can only run on the server")
	if folder then
		return
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	for name, kind in DEFINITIONS do
		local remote = Instance.new(kind)
		remote.Name = name
		remote.Parent = newFolder
	end
	newFolder.Parent = ReplicatedStorage
	folder = newFolder
end

local function getRemote(name: string, kind: RemoteKind): Instance
	assert(DEFINITIONS[name] == kind, `Remote "{name}" is not declared as {kind}`)
	local container = folder
	if not container then
		assert(not RunService:IsServer(), "Remotes.Setup must run before remotes are used on the server")
		local found = ReplicatedStorage:WaitForChild(FOLDER_NAME, CLIENT_WAIT_TIMEOUT)
		assert(found and found:IsA("Folder"), "Remotes folder did not replicate")
		folder = found
		container = found
	end
	local remote = (container :: Folder):WaitForChild(name, CLIENT_WAIT_TIMEOUT)
	assert(remote, `Remote "{name}" did not replicate`)
	return remote
end

function Remotes.Event(name: string): RemoteEvent
	return getRemote(name, "RemoteEvent") :: RemoteEvent
end

function Remotes.UnreliableEvent(name: string): UnreliableRemoteEvent
	return getRemote(name, "UnreliableRemoteEvent") :: UnreliableRemoteEvent
end

return Remotes
