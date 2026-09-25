--!strict
--[[
	Client entry point. The only LocalScript: every controller is a ModuleScript in Controllers/
	booted by the Loader (Init on all controllers, then Start on all controllers).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

local controllers = Loader.RequireChildren(script.Parent.Controllers)
Loader.Boot(controllers, "Client")
