--!strict
--[[
	Server entry point. The only Script on the server: everything else is a ModuleScript
	booted by the Loader (Init on all services, then Start on all services).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

-- Remotes must exist before any client script asks for them and before services bind handlers.
Remotes.Setup()

local services = Loader.RequireChildren(script.Parent.Services)
Loader.Boot(services, "Server")
