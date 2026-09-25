--!strict
--[[
	QualityController
	Decides the VFX tier (Low/Medium/High/Ultra) for this device and keeps it honest:
	  * starts from the player's Roblox graphics quality (or a device default on "Automatic"),
	  * drops one tier when the average FPS stays below the target for a sustained period.
	Every effect reads its budget from GetTier() (see Shared/Config/GraphicsConfig).
]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GraphicsConfig = require(ReplicatedStorage.Shared.Config.GraphicsConfig)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

type TierName = GraphicsConfig.TierName

local ORDER: { TierName } = { "Low", "Medium", "High", "Ultra" }
-- After a downgrade, wait this long before judging the new tier.
local DOWNGRADE_COOLDOWN = 30

local QualityController = {
	TierChanged = Signal.new() :: Signal.Signal<TierName>,
}

local tierName: TierName = "High"
local manualOverride = false
local frameTimeSum = 0
local frameCount = 0
local lastDowngrade = 0

local function readSavedQualityLevel(): number?
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if ok and level and level ~= Enum.SavedQualitySetting.Automatic then
		return level.Value
	end
	return nil
end

local function detectTier(): TierName
	local level = readSavedQualityLevel()
	if level then
		return GraphicsConfig.QualityLevelToTier[math.clamp(level, 1, #GraphicsConfig.QualityLevelToTier)]
	end
	if GuiService:IsTenFootInterface() then
		return GraphicsConfig.AutomaticTier.Console
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return GraphicsConfig.AutomaticTier.Touch
	end
	return GraphicsConfig.AutomaticTier.Desktop
end

local function setTier(name: TierName)
	if name ~= tierName then
		tierName = name
		QualityController.TierChanged:Fire(name)
	end
end

function QualityController:GetTierName(): TierName
	return tierName
end

function QualityController:GetTier(): GraphicsConfig.Tier
	return GraphicsConfig.Tiers[tierName]
end

-- Explicit choice from a settings menu; disables automatic adjustments.
function QualityController:SetTier(name: TierName)
	manualOverride = true
	setTier(name)
end

function QualityController:Init()
	tierName = detectTier()
end

function QualityController:Start()
	local settingsOk, gameSettings = pcall(function()
		return UserSettings():GetService("UserGameSettings")
	end)
	if settingsOk and gameSettings then
		gameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			if not manualOverride then
				setTier(detectTier())
			end
		end)
	end

	local sampleSeconds = GraphicsConfig.AutoDowngrade.SampleSeconds
	local minFps = GraphicsConfig.AutoDowngrade.MinFps
	RunService.Heartbeat:Connect(function(dt)
		if manualOverride then
			return
		end
		frameTimeSum += dt
		frameCount += 1
		if frameTimeSum < sampleSeconds then
			return
		end
		local averageFps = frameCount / frameTimeSum
		frameTimeSum = 0
		frameCount = 0
		local now = os.clock()
		if averageFps < minFps and now - lastDowngrade > DOWNGRADE_COOLDOWN then
			local index = table.find(ORDER, tierName) or 1
			if index > 1 then
				lastDowngrade = now
				setTier(ORDER[index - 1])
			end
		end
	end)
end

return QualityController
