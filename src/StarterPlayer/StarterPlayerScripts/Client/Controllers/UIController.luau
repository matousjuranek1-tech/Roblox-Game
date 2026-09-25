--!strict
--[[
	UIController
	Phase 1 HUD, built in code so it lives in version control:
	  * stamina bar with dash / air dash / grapple readiness (fades out when everything is full),
	  * grapple reticle on the auto-selected target,
	  * time-trial panel (server-timed) with medals and personal best,
	  * controls help (H) that adapts to keyboard, gamepad or touch,
	  * debug overlay (F3, on by default in Studio): state, speeds, stamina, FPS, ping, VFX tier.
	The PHASE 8 HUD (health, Titan Energy, abilities, boss bar) extends this controller.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TimeTrialConfig = require(ReplicatedStorage.Shared.Config.TimeTrialConfig)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local Create = require(script.Parent.Parent.UI.Create)
local Theme = require(script.Parent.Parent.UI.Theme)

local InputController = require(script.Parent.InputController)
local MovementController = require(script.Parent.MovementController)
local QualityController = require(script.Parent.QualityController)

local Colors = Theme.Colors

local STAMINA_HIDE_DELAY = 1.2
local FADE_RATE = 8
local LOW_STAMINA = 0.25
local RESULT_DURATION = 6
local TOAST_DURATION = 2
local FPS_SMOOTHING = 4

local HELP_TEXT: { [string]: string } = {
	KeyboardMouse = "WASD move · Space jump / wall jump · Shift sprint\nQ dash (air dash in the air) · C slide · E grapple\nR restart trial · F3 debug · H hide help",
	Gamepad = "Left stick move · A jump / wall jump · L3 sprint\nB dash (air dash in the air) · R3 slide · LB grapple\nD-pad down restart trial · D-pad up hide help",
	Touch = "Joystick move · Jump / wall jump\nSPRINT toggle · DASH · SLIDE · HOOK grapple",
}

local UIController = {}

type Pip = {
	Label: TextLabel,
	Fill: Frame,
}

local staminaGroup: CanvasGroup
local staminaFill: Frame
local dashPip: Pip
local airPip: Pip
local grapplePip: Pip
local reticle: BillboardGui
local reticleDiamond: Frame
local reticleStroke: UIStroke
local reticleDistance: TextLabel
local trialPanel: Frame
local trialTitle: TextLabel
local trialTimer: TextLabel
local trialDetail: TextLabel
local helpPanel: TextLabel
local debugLabel: TextLabel
local toastLabel: TextLabel

local staminaVisibility = 1
local lastStaminaActivity = 0
local runActive = false
local runStart = 0
local resultShownAt = 0
local toastShownAt = -math.huge
local smoothedFps = 60

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	return string.format("%d:%05.2f", minutes, seconds - minutes * 60)
end

local function makePip(parent: Instance, text: string, order: number): Pip
	local container = Create("Frame", {
		Name = text,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(64, 18),
		LayoutOrder = order,
		Parent = parent,
	})
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 12),
		Text = text,
		TextColor3 = Colors.Muted,
		TextSize = 11,
		FontFace = Theme.Fonts.Bold,
		Parent = container,
	}) :: TextLabel
	local track = Create("Frame", {
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		Parent = container,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local fill = Create("Frame", {
		BackgroundColor3 = Colors.Ivory,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) :: Frame
	return { Label = label, Fill = fill }
end

local function setPip(pip: Pip, readiness: number, active: boolean)
	local ratio = math.clamp(readiness, 0, 1)
	pip.Fill.Size = UDim2.fromScale(ratio, 1)
	local ready = ratio >= 1 and active
	pip.Fill.BackgroundColor3 = if ready then Colors.Ivory else Colors.Muted
	pip.Label.TextColor3 = if ready then Colors.Ivory else Colors.Muted
end

local function buildStamina(gui: ScreenGui)
	staminaGroup = Create("CanvasGroup", {
		Name = "Stamina",
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 1, -56),
		Size = UDim2.fromOffset(260, 34),
		Parent = gui,
	}) :: CanvasGroup
	local track = Create("Frame", {
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 6),
		Parent = staminaGroup,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	staminaFill = Create("Frame", {
		BackgroundColor3 = Colors.Ivory,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) }) :: Frame

	local pips = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = staminaGroup,
	}, {
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	dashPip = makePip(pips, "DASH", 1)
	airPip = makePip(pips, "AIR", 2)
	grapplePip = makePip(pips, "HOOK", 3)
end

local function buildReticle(playerGui: Instance)
	reticle = Create("BillboardGui", {
		Name = "GrappleReticle",
		AlwaysOnTop = true,
		LightInfluence = 0,
		Size = UDim2.fromOffset(56, 72),
		ResetOnSpawn = false,
		Enabled = false,
		Parent = playerGui,
	}) :: BillboardGui
	reticleDiamond = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 28),
		Rotation = 45,
		Size = UDim2.fromOffset(30, 30),
		Parent = reticle,
	}) :: Frame
	reticleStroke = Create("UIStroke", {
		Color = Colors.Cyan,
		Thickness = 2,
		Parent = reticleDiamond,
	}) :: UIStroke
	Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Colors.Ember,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		Parent = reticleDiamond,
	})
	reticleDistance = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 16),
		TextColor3 = Colors.Ivory,
		TextStrokeTransparency = 0.5,
		TextSize = 13,
		FontFace = Theme.Fonts.Bold,
		Parent = reticle,
	}) :: TextLabel
end

local function buildTrialPanel(gui: ScreenGui)
	trialPanel = Create("Frame", {
		Name = "TimeTrial",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(300, 84),
		Visible = false,
		Parent = gui,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) }) :: Frame
	trialTitle = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 14),
		TextColor3 = Colors.Muted,
		TextSize = 13,
		FontFace = Theme.Fonts.Bold,
		Parent = trialPanel,
	}) :: TextLabel
	trialTimer = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 36),
		TextColor3 = Colors.Ivory,
		TextSize = 34,
		FontFace = Theme.Fonts.Title,
		Parent = trialPanel,
	}) :: TextLabel
	trialDetail = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 16),
		TextColor3 = Colors.Ivory,
		TextSize = 14,
		FontFace = Theme.Fonts.Body,
		Parent = trialPanel,
	}) :: TextLabel
end

local function buildInfoPanels(gui: ScreenGui)
	helpPanel = Create("TextLabel", {
		Name = "Help",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.fromOffset(0, 0),
		TextColor3 = Colors.Ivory,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Theme.Fonts.Body,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}) :: TextLabel

	debugLabel = Create("TextLabel", {
		Name = "Debug",
		AnchorPoint = Vector2.new(1, 0.5),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(0, 0),
		TextColor3 = Colors.Ivory,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Theme.Fonts.Mono,
		Visible = RunService:IsStudio(),
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}) :: TextLabel

	toastLabel = Create("TextLabel", {
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 156),
		Size = UDim2.fromOffset(400, 24),
		TextColor3 = Colors.Ember,
		TextStrokeTransparency = 0.4,
		TextSize = 18,
		FontFace = Theme.Fonts.Bold,
		Visible = false,
		Parent = gui,
	}) :: TextLabel
end

local function showToast(text: string)
	toastLabel.Text = text
	toastLabel.Visible = true
	toastShownAt = os.clock()
end

local function refreshHelp()
	helpPanel.Text = HELP_TEXT[InputController:GetInputKind()] or HELP_TEXT.KeyboardMouse
end

local function medalFor(trialId: string, elapsed: number): (string?, Color3)
	local trial = TimeTrialConfig.Trials[trialId]
	if not trial then
		return nil, Colors.Ivory
	end
	if elapsed <= trial.Gold then
		return "GOLD", Colors.Gold
	elseif elapsed <= trial.Silver then
		return "SILVER", Colors.Silver
	elseif elapsed <= trial.Bronze then
		return "BRONZE", Colors.Bronze
	end
	return nil, Colors.Ivory
end

local function onTrialEvent(kind: unknown, a: unknown, b: unknown, c: unknown, d: unknown)
	if kind == "Started" and type(a) == "string" then
		local trial = TimeTrialConfig.Trials[a]
		runActive = true
		runStart = os.clock()
		resultShownAt = 0
		trialPanel.Visible = true
		trialTitle.Text = string.upper(if trial then trial.DisplayName else a)
		trialTimer.TextColor3 = Colors.Ivory
		trialDetail.Text = if trial then `GOLD {formatTime(trial.Gold)}` else ""
	elseif kind == "Checkpoint" and type(b) == "number" and type(c) == "number" then
		runStart = os.clock() - c
		trialDetail.Text = `CHECKPOINT {b} · {formatTime(c)}`
	elseif kind == "Finished" and type(a) == "string" and type(b) == "number" and type(c) == "number" then
		runActive = false
		resultShownAt = os.clock()
		local medal, color = medalFor(a, b)
		trialTimer.Text = formatTime(b)
		trialTimer.TextColor3 = color
		local parts = {}
		if medal then
			table.insert(parts, medal)
		end
		table.insert(parts, if d == true then "NEW BEST" else `BEST {formatTime(c)}`)
		trialDetail.Text = table.concat(parts, " · ")
	elseif kind == "Reset" then
		showToast("Back to checkpoint")
	elseif kind == "Cancelled" then
		runActive = false
		trialPanel.Visible = false
	elseif kind == "Invalid" then
		runActive = false
		trialPanel.Visible = false
		showToast("Run invalid")
	end
end

local function updateDebug(dt: number)
	if not debugLabel.Visible then
		return
	end
	smoothedFps = MathUtil.damp(smoothedFps, 1 / math.max(dt, 1e-3), FPS_SMOOTHING, dt)
	local state = MovementController:GetSnapshot()
	local ping = Players.LocalPlayer:GetNetworkPing() * 1000
	local lines = {
		string.format("FPS %d · ping %d ms · VFX %s", smoothedFps, ping, QualityController:GetTierName()),
	}
	if state then
		table.insert(lines, `STATE {state.Action or (if state.Grounded then "Ground" else "Air")}`)
		table.insert(lines, string.format("SPEED %5.1f  VY %6.1f", state.Speed, state.VerticalSpeed))
		table.insert(lines, string.format("STAMINA %3d / %d", state.Stamina, state.StaminaMax))
		table.insert(
			lines,
			`SPRINT {state.Sprinting} · AIR DASH {state.AirDashCharges} · WALL CHAIN {state.WallJumpChain}`
		)
	end
	debugLabel.Text = table.concat(lines, "\n")
end

local function update(dt: number)
	local now = os.clock()
	local state = MovementController:GetSnapshot()

	-- Stamina group: visible while anything is draining or recharging.
	if state then
		local ratio = state.Stamina / state.StaminaMax
		staminaFill.Size = UDim2.fromScale(ratio, 1)
		staminaFill.BackgroundColor3 = if ratio < LOW_STAMINA then Colors.Danger else Colors.Ivory
		setPip(dashPip, state.DashReadiness, true)
		setPip(airPip, if state.AirDashCharges > 0 then 1 else 0, state.AirDashUnlocked)
		setPip(grapplePip, state.GrappleReadiness, true)
		local busy = ratio < 1 or state.DashReadiness < 1 or state.GrappleReadiness < 1 or state.Action ~= nil
		if busy then
			lastStaminaActivity = now
		end
	end
	local targetVisibility = if now - lastStaminaActivity < STAMINA_HIDE_DELAY then 1 else 0
	staminaVisibility = MathUtil.damp(staminaVisibility, targetVisibility, FADE_RATE, dt)
	staminaGroup.GroupTransparency = 1 - staminaVisibility

	-- Grapple reticle.
	local target = if state then state.GrappleTarget else nil
	if state and target then
		reticle.Adornee = target
		reticle.Enabled = true
		local ready = state.GrappleReadiness >= 1
		reticleStroke.Color = if ready then Colors.Cyan else Colors.Muted
		reticleDiamond.Rotation = 45 + (if ready then 0 else 45 * (1 - state.GrappleReadiness))
		local context = MovementController:GetContext()
		if context then
			reticleDistance.Text = `{math.floor((target.Position - context.Root.Position).Magnitude)}`
		end
	else
		reticle.Enabled = false
		reticle.Adornee = nil :: any
	end

	if runActive then
		trialTimer.Text = formatTime(now - runStart)
	elseif resultShownAt > 0 and now - resultShownAt > RESULT_DURATION then
		resultShownAt = 0
		trialPanel.Visible = false
	end

	if toastLabel.Visible and now - toastShownAt > TOAST_DURATION then
		toastLabel.Visible = false
	end

	updateDebug(dt)
end

function UIController:Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Create("ScreenGui", {
		Name = "HUD",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	}) :: ScreenGui

	buildStamina(gui)
	buildReticle(playerGui)
	buildTrialPanel(gui)
	buildInfoPanels(gui)
	refreshHelp()

	local trialRemote = Remotes.Event("TimeTrial")
	trialRemote.OnClientEvent:Connect(onTrialEvent)

	InputController.InputKindChanged:Connect(refreshHelp)
	InputController.ActionBegan:Connect(function(action)
		if action == "RestartTrial" then
			trialRemote:FireServer("Restart")
		elseif action == "ToggleHelp" then
			helpPanel.Visible = not helpPanel.Visible
		elseif action == "ToggleDebug" then
			debugLabel.Visible = not debugLabel.Visible
		end
	end)
	MovementController.Corrected:Connect(function(kind)
		if kind == "Corrected" and RunService:IsStudio() then
			showToast("Movement corrected by server")
		end
	end)

	RunService.RenderStepped:Connect(update)
end

return UIController
