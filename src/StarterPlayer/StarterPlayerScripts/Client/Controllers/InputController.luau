--!strict
--[[
	InputController
	Turns raw input (keyboard, gamepad, touch) into named actions from InputConfig. Gameplay code
	listens to ActionBegan/ActionEnded and never checks key codes itself, so rebinding and new
	input methods only touch this file.

	  * Keyboard/gamepad go through ContextActionService (typing in chat never triggers actions).
	  * Touch gets custom buttons arranged around Roblox's jump button, shown only while the
	    player's preferred input is touch.
	  * Sprint is held on keyboard and toggled on gamepad/touch.
	  * JumpPressed fires once per physical press. Roblox's JumpRequest repeats while jump is
	    held, which would turn one held press into wall jumps or grapple releases.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputConfig = require(ReplicatedStorage.Shared.Config.InputConfig)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Create = require(script.Parent.Parent.UI.Create)
local Theme = require(script.Parent.Parent.UI.Theme)

export type InputKind = "KeyboardMouse" | "Gamepad" | "Touch"

local ACTION_PREFIX = "Titanbound_"
-- Touch button positions relative to the jump button center, in jump-button sizes.
local TOUCH_LAYOUT: { [string]: Vector2 } = {
	Dash = Vector2.new(-1.2, 0),
	Slide = Vector2.new(-0.95, -0.95),
	Grapple = Vector2.new(0, -1.25),
	Sprint = Vector2.new(-2.35, 0.05),
}
local TOUCH_BUTTON_SCALE = 0.72
-- Keyboard/gamepad keys that jump with Roblox's default controls.
local JUMP_KEYS: { [Enum.KeyCode]: boolean } = {
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.ButtonA] = true,
}
-- Touch jump presses are detected from JumpRequest; a gap this long means a new press.
local TOUCH_REPRESS_GAP = 0.12

local InputController = {
	ActionBegan = Signal.new() :: Signal.Signal<string>,
	ActionEnded = Signal.new() :: Signal.Signal<string>,
	-- A new jump press (not the repeats Roblox sends while jump is held).
	JumpPressed = Signal.new() :: Signal.Signal<>,
	InputKindChanged = Signal.new() :: Signal.Signal<InputKind>,
	SprintToggleChanged = Signal.new() :: Signal.Signal<boolean>,
}

local held: { [string]: boolean } = {}
local sprintToggled = false
local inputKind: InputKind = "KeyboardMouse"
local touchGui: ScreenGui? = nil
local touchButtons: { [string]: TextButton } = {}

local function setSprintToggle(value: boolean)
	if sprintToggled ~= value then
		sprintToggled = value
		InputController.SprintToggleChanged:Fire(value)
	end
end

local function begin(action: string)
	held[action] = true
	InputController.ActionBegan:Fire(action)
end

local function finish(action: string)
	if held[action] then
		held[action] = false
		InputController.ActionEnded:Fire(action)
	end
end

local function isGamepadInput(input: InputObject): boolean
	local inputType = input.UserInputType
	return inputType == Enum.UserInputType.Gamepad1
		or inputType == Enum.UserInputType.Gamepad2
		or inputType == Enum.UserInputType.Gamepad3
		or inputType == Enum.UserInputType.Gamepad4
end

local function handleAction(
	boundName: string,
	inputState: Enum.UserInputState,
	input: InputObject
): Enum.ContextActionResult
	local action = string.sub(boundName, #ACTION_PREFIX + 1)
	if inputState == Enum.UserInputState.Begin then
		if action == "Sprint" and isGamepadInput(input) and InputConfig.SprintToggleOnGamepad then
			setSprintToggle(not sprintToggled)
			InputController.ActionBegan:Fire(action)
		else
			begin(action)
		end
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		finish(action)
	end
	return Enum.ContextActionResult.Sink
end

local function resolveInputKind(): InputKind
	local preferred = UserInputService.PreferredInput
	if preferred == Enum.PreferredInput.Touch then
		return "Touch"
	elseif preferred == Enum.PreferredInput.Gamepad or preferred == Enum.PreferredInput.MicroGamepad then
		return "Gamepad"
	end
	return "KeyboardMouse"
end

local function layoutTouchButtons()
	local gui = touchGui
	local camera = workspace.CurrentCamera
	if not gui or not camera then
		return
	end
	-- Mirrors the sizing rules of Roblox's TouchJump module so our buttons hug its jump button.
	local viewport = camera.ViewportSize
	local minAxis = math.min(viewport.X, viewport.Y)
	local isSmallScreen = minAxis <= 500
	local jumpSize = if isSmallScreen then 70 else 120
	local jumpX = viewport.X - (jumpSize * 1.5 - 10) + jumpSize / 2
	local jumpY = viewport.Y - (if isSmallScreen then jumpSize + 20 else jumpSize * 1.75) + jumpSize / 2
	local buttonSize = jumpSize * TOUCH_BUTTON_SCALE
	for action, button in touchButtons do
		local offset = TOUCH_LAYOUT[action]
		button.Size = UDim2.fromOffset(buttonSize, buttonSize)
		button.Position = UDim2.fromOffset(jumpX + offset.X * jumpSize, jumpY + offset.Y * jumpSize)
	end
end

local function refreshSprintButton()
	local button = touchButtons.Sprint
	if button then
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if sprintToggled then Theme.Colors.Ember else Theme.Colors.Ivory
			stroke.Thickness = if sprintToggled then 3 else 1.5
		end
	end
end

local function createTouchButton(parent: ScreenGui, action: string, label: string): TextButton
	local button = Create("TextButton", {
		Name = action,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.PanelTransparency,
		AutoButtonColor = false,
		Text = label,
		TextColor3 = Theme.Colors.Ivory,
		TextScaled = true,
		FontFace = Theme.Fonts.Bold,
		Parent = parent,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Create("UIStroke", {
			Color = Theme.Colors.Ivory,
			Thickness = 1.5,
			Transparency = 0.2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Create("UIPadding", {
			PaddingLeft = UDim.new(0.18, 0),
			PaddingRight = UDim.new(0.18, 0),
			PaddingTop = UDim.new(0.3, 0),
			PaddingBottom = UDim.new(0.3, 0),
		}),
	}) :: TextButton

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		button.BackgroundColor3 = Theme.Colors.Ember
		if action == "Sprint" and InputConfig.SprintToggleOnTouch then
			setSprintToggle(not sprintToggled)
			InputController.ActionBegan:Fire(action)
		else
			begin(action)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		button.BackgroundColor3 = Theme.Colors.Panel
		finish(action)
	end)
	return button
end

local function buildTouchControls()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Create("ScreenGui", {
		Name = "TouchControls",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = inputKind == "Touch",
		Parent = playerGui,
	}) :: ScreenGui
	touchGui = gui
	for action, binding in InputConfig.Actions do
		if binding.Touch then
			touchButtons[action] = createTouchButton(gui, action, binding.Touch)
		end
	end
	layoutTouchButtons()
	refreshSprintButton()
end

function InputController:IsHeld(action: string): boolean
	return held[action] == true
end

-- Sprint intent: held key (keyboard) or active toggle (gamepad/touch).
function InputController:GetSprintInput(): boolean
	return held.Sprint == true or sprintToggled
end

function InputController:IsSprintToggled(): boolean
	return sprintToggled
end

function InputController:ClearSprintToggle()
	setSprintToggle(false)
end

function InputController:GetInputKind(): InputKind
	return inputKind
end

function InputController:Start()
	inputKind = resolveInputKind()

	for action, binding in InputConfig.Actions do
		local keys: { Enum.KeyCode } = table.clone(binding.Keyboard)
		for _, key in binding.Gamepad do
			table.insert(keys, key)
		end
		if #keys > 0 then
			ContextActionService:BindActionAtPriority(
				ACTION_PREFIX .. action,
				handleAction,
				false,
				InputConfig.Priority,
				table.unpack(keys)
			)
		end
	end

	-- The default ControlModule binds jump through ContextActionService, so these inputs arrive
	-- marked as game-processed; only a focused TextBox (chat) should suppress them.
	UserInputService.InputBegan:Connect(function(input)
		if JUMP_KEYS[input.KeyCode] and not UserInputService:GetFocusedTextBox() then
			InputController.JumpPressed:Fire()
		end
	end)
	local lastJumpRequest = 0
	UserInputService.JumpRequest:Connect(function()
		local now = os.clock()
		local isNewPress = now - lastJumpRequest > TOUCH_REPRESS_GAP
		lastJumpRequest = now
		if isNewPress and inputKind == "Touch" then
			InputController.JumpPressed:Fire()
		end
	end)

	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		local kind: InputKind = resolveInputKind()
		if kind ~= inputKind then
			inputKind = kind
			if touchGui then
				touchGui.Enabled = kind == "Touch"
			end
			InputController.InputKindChanged:Fire(kind)
		end
	end)

	if UserInputService.TouchEnabled then
		buildTouchControls()
		InputController.SprintToggleChanged:Connect(refreshSprintButton)
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutTouchButtons)
		end
	end
end

return InputController
