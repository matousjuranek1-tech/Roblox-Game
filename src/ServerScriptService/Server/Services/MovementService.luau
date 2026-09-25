--!strict
--[[
	MovementService
	Server authority for movement. Characters are physically simulated by their owning client
	(Roblox network ownership), so the server cannot run the movement itself. Instead it:

	  1. Validates every ability the client reports (MovementAction remote): known action,
	     rate limit, cooldown, unlock, stamina (server-side mirror), and action-specific checks
	     (grapple target must be a real tagged point in range, a slide must start grounded and
	     moving, a wall-run side must be +-1).
	  2. Opens a speed "allowance" for each accepted ability (dash, grapple, launch momentum...).
	     Sustained abilities close on "End" or, if it never arrives, after their longest honest
	     duration, and closing shortens the allowance to the launch window.
	  3. Samples every character at 5 Hz against the envelope. Repeated or severe violations
	     rubber-band the character to its last valid grounded spot.
	  4. Publishes accepted actions to other clients: the MoveState/MoveSide character attributes
	     (for poses) and the MovementFx unreliable remote (for rope, trail and dust effects).

	Every server-side teleport (spawn, correction, checkpoint) re-anchors validation at the new
	position; while settling, only positions reachable from that anchor are accepted.
	Rejections are reported back through MovementCorrection so the client cancels its prediction.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MovementProtocol = require(ReplicatedStorage.Shared.Net.MovementProtocol)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local Validate = require(ReplicatedStorage.Shared.Util.Validate)

local CharacterService = require(script.Parent.CharacterService)

local Validation = MovementConfig.Validation
local Attributes = WorldConfig.Attributes

local GROUND_PROBE_LENGTH = 6
local WARN_INTERVAL = 5
-- Displacement below this between samples counts as "no movement replicated".
local STALL_EPSILON = 0.05
-- A slide may also start right out of a dash, before the sampler has seen the speed.
local DASH_TO_SLIDE_WINDOW = 0.8

type Rule = {
	StaminaCost: number,
	-- Nominal seconds between two starts of this action.
	MinInterval: number,
	-- Speed envelope (studs/s) while the action and its momentum last.
	Horizontal: number,
	Up: number,
	-- Seconds the envelope stays open after the start.
	Window: number,
	-- Clears the MoveState attribute after this many seconds (non-sustained actions).
	AutoClear: number?,
	-- Longest honest duration of a sustained action (it is closed after this plus a grace).
	MaxDuration: number?,
	-- Name of the "Unlock_<Name>" player attribute required to use the action.
	Unlock: string?,
}

type PlayerState = {
	-- Character whose spawn was anchored; others (mid-respawn) are not sampled or trusted.
	Character: Model?,
	StaminaAtSpend: number,
	LastSpend: number,
	LastStart: { [string]: number },
	ActiveSustained: { [string]: number },
	SustainedDeadline: { [string]: number },
	AllowedHorizontal: number,
	AllowedUp: number,
	AllowanceExpires: number,
	StateToken: number,
	-- Baseline of the speed measurement: last accepted position that actually moved.
	LastSamplePosition: Vector3?,
	LastSampleTime: number,
	NextSampleTime: number,
	LastHorizontalSpeed: number,
	LastValidCFrame: CFrame?,
	Violations: { number },
	SettleAnchor: Vector3?,
	SettleStart: number,
	SettleUntil: number,
	LastWarn: number,
}

local JUMP_VELOCITY = MathUtil.jumpVelocity(MovementConfig.Jump.Height, workspace.Gravity)
local BASE_HORIZONTAL = MovementConfig.Sprint.Speed
local BASE_UP = JUMP_VELOCITY

local function buildRules(): { [string]: Rule }
	local c = MovementConfig
	local launch = Validation.LaunchWindow
	local wallRunTop = c.WallRun.Speed * c.WallRun.MaxSpeedFactor
	return {
		Dash = {
			StaminaCost = c.Dash.StaminaCost,
			MinInterval = c.Dash.Duration + c.Dash.Cooldown,
			Horizontal = c.Dash.Speed,
			Up = JUMP_VELOCITY,
			Window = c.Dash.Duration + launch,
			AutoClear = c.Dash.Duration,
		},
		AirDash = {
			StaminaCost = c.AirDash.StaminaCost,
			MinInterval = c.AirDash.Duration,
			Horizontal = c.AirDash.Speed,
			Up = c.AirDash.UpVelocity,
			Window = c.AirDash.Duration + launch,
			AutoClear = c.AirDash.Duration,
			Unlock = "AirDash",
		},
		Slide = {
			StaminaCost = 0,
			MinInterval = c.Slide.Cooldown,
			-- Flat slides never exceed StartSpeed (faster entries come from a dash, which has its own
			-- allowance). Slide.MaxSpeed is granted only while the sampler sees the player descend.
			Horizontal = c.Slide.StartSpeed,
			-- Slide-hop jumps out of the slide.
			Up = JUMP_VELOCITY,
			Window = c.Slide.MaxDownhillDuration + launch,
			MaxDuration = c.Slide.MaxDownhillDuration,
		},
		WallRun = {
			-- Drained when the wall run closes, from its real duration.
			StaminaCost = 0,
			MinInterval = c.WallRun.Cooldown,
			Horizontal = wallRunTop,
			Up = c.WallRun.InitialUpVelocity + JUMP_VELOCITY * 0.3,
			Window = c.WallRun.MaxDuration + launch,
			MaxDuration = c.WallRun.MaxDuration,
		},
		WallJump = {
			StaminaCost = c.WallJump.StaminaCost,
			MinInterval = c.WallJump.Debounce,
			Horizontal = c.WallJump.OutVelocity + wallRunTop * c.WallJump.TangentCarry,
			Up = c.WallJump.UpVelocity,
			Window = launch,
		},
		Mantle = {
			StaminaCost = 0,
			MinInterval = c.Mantle.Cooldown,
			Horizontal = (c.Mantle.ForwardReach + c.Mantle.ForwardDistance) / c.Mantle.ForwardDuration,
			Up = c.Mantle.UpSpeed * 1.4,
			Window = c.Mantle.MaxUpDuration + c.Mantle.ForwardDuration + 0.3,
			AutoClear = c.Mantle.MaxUpDuration + c.Mantle.ForwardDuration,
		},
		Grapple = {
			StaminaCost = 0,
			MinInterval = c.Grapple.Cooldown,
			Horizontal = c.Grapple.PullSpeed,
			Up = c.Grapple.PullSpeed,
			-- Window and MaxDuration are replaced per request by the real distance-based duration.
			Window = c.Grapple.Range / c.Grapple.PullSpeed + c.Grapple.FireTime + c.Grapple.TimeoutPadding + launch,
			MaxDuration = c.Grapple.Range / c.Grapple.PullSpeed + c.Grapple.FireTime + c.Grapple.TimeoutPadding,
		},
	}
end

local RULES = buildRules()

local MovementService = {}

local states: { [Player]: PlayerState } = {}
local limiter = RateLimiter.new(Validation.ActionRate, Validation.ActionBurst)
local groundParams: RaycastParams
local correctionRemote: RemoteEvent
local fxRemote: UnreliableRemoteEvent

local function newState(): PlayerState
	return {
		Character = nil,
		StaminaAtSpend = MovementConfig.Stamina.Max,
		LastSpend = 0,
		LastStart = {},
		ActiveSustained = {},
		SustainedDeadline = {},
		AllowedHorizontal = BASE_HORIZONTAL,
		AllowedUp = BASE_UP,
		AllowanceExpires = 0,
		StateToken = 0,
		LastSamplePosition = nil,
		LastSampleTime = 0,
		NextSampleTime = 0,
		LastHorizontalSpeed = 0,
		LastValidCFrame = nil,
		Violations = {},
		SettleAnchor = nil,
		SettleStart = 0,
		SettleUntil = 0,
		LastWarn = 0,
	}
end

local function staminaNow(state: PlayerState, now: number): number
	local regenStart = state.LastSpend + MovementConfig.Stamina.RegenDelay
	if now <= regenStart then
		return state.StaminaAtSpend
	end
	local regenerated = (now - regenStart) * MovementConfig.Stamina.RegenPerSecond
	return math.min(MovementConfig.Stamina.Max, state.StaminaAtSpend + regenerated)
end

local function spendStamina(state: PlayerState, now: number, amount: number)
	-- Debt below zero is kept (bounded) so a client that ignores stamina keeps getting rejected.
	state.StaminaAtSpend = math.max(staminaNow(state, now) - amount, -Validation.StaminaTolerance)
	state.LastSpend = now
end

local function allowanceGrace(ping: number): number
	return Validation.AllowanceGrace + ping * 2
end

local function grantAllowance(
	state: PlayerState,
	horizontal: number,
	up: number,
	window: number,
	now: number,
	ping: number
)
	local expires = now + window + allowanceGrace(ping)
	if now > state.AllowanceExpires then
		state.AllowedHorizontal = horizontal
		state.AllowedUp = up
	else
		state.AllowedHorizontal = math.max(state.AllowedHorizontal, horizontal)
		state.AllowedUp = math.max(state.AllowedUp, up)
	end
	state.AllowanceExpires = math.max(state.AllowanceExpires, expires)
end

local function warnThrottled(player: Player, state: PlayerState, message: string)
	local now = os.clock()
	if now - state.LastWarn >= WARN_INTERVAL then
		state.LastWarn = now
		warn(`[MovementService] {player.Name}: {message}`)
	end
end

local function reject(player: Player, state: PlayerState, action: string, reason: string)
	correctionRemote:FireClient(player, "Rejected", action)
	warnThrottled(player, state, `rejected {action} ({reason})`)
end

local function isGrounded(root: BasePart): boolean
	return workspace:Raycast(root.Position, Vector3.new(0, -GROUND_PROBE_LENGTH, 0), groundParams) ~= nil
end

-- Re-anchors validation at a position the server itself placed the character at.
local function anchorAt(state: PlayerState, cframe: CFrame, now: number)
	state.LastValidCFrame = cframe
	state.LastSamplePosition = cframe.Position
	state.LastSampleTime = now
	state.LastHorizontalSpeed = 0
	state.SettleAnchor = cframe.Position
	state.SettleStart = now
	state.SettleUntil = now + Validation.SettleTime
	table.clear(state.Violations)
end

local function correct(player: Player, state: PlayerState, root: BasePart, reason: string)
	local now = os.clock()
	local target = state.LastValidCFrame
	correctionRemote:FireClient(player, "Corrected")
	warnThrottled(player, state, `corrected ({reason})`)
	local character = player.Character
	if not character or not target then
		-- No trusted position to return to: respawn rather than trust the current one.
		task.spawn(function()
			player:LoadCharacterAsync()
		end)
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(target)
	anchorAt(state, target, now)
end

-- Ends a sustained action: charges wall-run stamina, clears its pose and shortens the
-- allowance to the momentum it can legitimately leave behind.
local function closeSustained(player: Player, state: PlayerState, action: string, now: number)
	local started = state.ActiveSustained[action]
	if not started then
		return
	end
	state.ActiveSustained[action] = nil
	state.SustainedDeadline[action] = nil
	if action == "WallRun" then
		local duration = math.min(now - started, MovementConfig.WallRun.MaxDuration)
		spendStamina(state, now, duration * MovementConfig.WallRun.StaminaPerSecond)
	end
	local launchEnd = now + Validation.LaunchWindow + allowanceGrace(player:GetNetworkPing())
	state.AllowanceExpires = math.min(state.AllowanceExpires, launchEnd)
	local character = player.Character
	if character and character:GetAttribute(Attributes.MoveState) == action then
		state.StateToken += 1
		character:SetAttribute(Attributes.MoveState, nil)
	end
end

local function checkPlayer(player: Player, state: PlayerState, now: number)
	state.NextSampleTime = now + Validation.SampleInterval

	for action, deadline in state.SustainedDeadline do
		if now > deadline then
			closeSustained(player, state, action, now)
		end
	end

	if player.Character ~= state.Character then
		return
	end
	local root = CharacterService:GetRoot(player)
	local humanoid = CharacterService:GetHumanoid(player)
	if not root or not humanoid or humanoid.SeatPart ~= nil then
		return
	end
	local position = root.Position
	local previous = state.LastSamplePosition
	if previous == nil then
		state.LastSamplePosition = position
		state.LastSampleTime = now
		return
	end

	local allowedHorizontal = BASE_HORIZONTAL
	local allowedUp = BASE_UP
	if now <= state.AllowanceExpires then
		allowedHorizontal = math.max(allowedHorizontal, state.AllowedHorizontal)
		allowedUp = math.max(allowedUp, state.AllowedUp)
	end

	if now < state.SettleUntil then
		-- Stale positions from before the teleport are ignored; only reachable ones move the
		-- baseline, and nothing seen while settling can become the rubber-band target.
		local anchor = state.SettleAnchor
		local reach = allowedHorizontal * Validation.SpeedTolerance * (now - state.SettleStart)
			+ Validation.SettleMargin
		if anchor and (position - anchor).Magnitude <= reach then
			state.LastSamplePosition = position
			state.LastSampleTime = now
		end
		return
	end

	local delta = position - previous
	if delta.Magnitude < STALL_EPSILON then
		-- Idle or a replication stall: keep the baseline so the next movement is measured over the
		-- whole gap instead of looking like one huge jump in a single sample.
		state.LastHorizontalSpeed = 0
		if isGrounded(root) then
			state.LastValidCFrame = root.CFrame
		end
		return
	end

	local elapsed = math.clamp(now - state.LastSampleTime, Validation.SampleInterval, Validation.MaxStallCompensation)
	local horizontalSpeed = Vector3.new(delta.X, 0, delta.Z).Magnitude / elapsed
	local upSpeed = math.max(delta.Y, 0) / elapsed
	state.LastSamplePosition = position
	state.LastSampleTime = now
	state.LastHorizontalSpeed = horizontalSpeed

	if state.ActiveSustained.Slide and delta.Y < -Validation.DownhillDescent then
		-- Sliding downhill legitimately reaches Slide.MaxSpeed and may carry it into a slide-hop.
		local slideTop = MovementConfig.Slide.MaxSpeed
		state.AllowedHorizontal = math.max(state.AllowedHorizontal, slideTop)
		allowedHorizontal = math.max(allowedHorizontal, slideTop)
	end

	local limitHorizontal = allowedHorizontal * Validation.SpeedTolerance + Validation.FlatTolerance
	local limitUp = allowedUp * Validation.SpeedTolerance + Validation.FlatTolerance
	if horizontalSpeed <= limitHorizontal and upSpeed <= limitUp then
		if isGrounded(root) then
			state.LastValidCFrame = root.CFrame
		end
		return
	end

	local severe = horizontalSpeed > allowedHorizontal * Validation.SevereMultiplier + Validation.SevereFlat
		or upSpeed > allowedUp * Validation.SevereMultiplier + Validation.SevereFlat

	local violations = state.Violations
	table.insert(violations, now)
	while violations[1] and now - violations[1] > Validation.ViolationWindow do
		table.remove(violations, 1)
	end

	if severe or #violations >= Validation.ViolationsToCorrect then
		local detail = string.format(
			"horizontal %.1f/%.1f, up %.1f/%.1f studs/s",
			horizontalSpeed,
			limitHorizontal,
			upSpeed,
			limitUp
		)
		correct(player, state, root, detail)
	end
end

local function relayFx(source: Player, sourceRoot: BasePart, action: string, payload: { [string]: any }?)
	local origin = sourceRoot.Position
	for _, other in Players:GetPlayers() do
		if other ~= source then
			local otherRoot = CharacterService:GetRoot(other)
			if otherRoot and (otherRoot.Position - origin).Magnitude <= Validation.FxRelayDistance then
				fxRemote:FireClient(other, source, action, payload)
			end
		end
	end
end

local function setMoveState(character: Model, state: PlayerState, action: string, side: number, clearAfter: number)
	if not MovementProtocol.Posable[action] then
		return
	end
	state.StateToken += 1
	local token = state.StateToken
	character:SetAttribute(Attributes.MoveState, action)
	character:SetAttribute(Attributes.MoveSide, side)
	-- Safety net: never leave a stale pose if the matching "End" never arrives.
	task.delay(clearAfter, function()
		if state.StateToken == token and character.Parent then
			character:SetAttribute(Attributes.MoveState, nil)
		end
	end)
end

-- Returns the validated grapple target and its distance, or nil.
local function validateGrapple(root: BasePart, payload: unknown): (BasePart?, number)
	local data = Validate.smallTable(payload, 4)
	if not data then
		return nil, 0
	end
	local target = data.Target
	if not Validate.isWorkspacePart(target) then
		return nil, 0
	end
	local part = target :: BasePart
	if not CollectionService:HasTag(part, WorldConfig.Tags.GrapplePoint) then
		return nil, 0
	end
	local distance = (part.Position - root.Position).Magnitude
	if distance > MovementConfig.Grapple.Range + Validation.GrappleRangeTolerance then
		return nil, 0
	end
	return part, distance
end

local function handleStart(
	player: Player,
	state: PlayerState,
	character: Model,
	root: BasePart,
	action: string,
	payload: unknown,
	now: number
)
	local rule = RULES[action]

	local last = state.LastStart[action]
	if last and now - last < rule.MinInterval * Validation.CooldownTolerance then
		reject(player, state, action, "cooldown")
		return
	end
	if rule.Unlock and player:GetAttribute(Attributes.UnlockPrefix .. rule.Unlock) ~= true then
		reject(player, state, action, "locked")
		return
	end
	if rule.StaminaCost > 0 and staminaNow(state, now) + Validation.StaminaTolerance < rule.StaminaCost then
		reject(player, state, action, "stamina")
		return
	end

	-- Relay payloads are rebuilt from validated values; raw client tables are never forwarded.
	local relayPayload: { [string]: any }? = nil
	local window = rule.Window
	local maxDuration = rule.MaxDuration
	local side = 0
	if action == "Grapple" then
		local target, distance = validateGrapple(root, payload)
		if not target then
			reject(player, state, action, "invalid target")
			return
		end
		relayPayload = { Target = target }
		local grapple = MovementConfig.Grapple
		local pullDuration = distance / grapple.PullSpeed + grapple.FireTime + grapple.TimeoutPadding
		maxDuration = pullDuration
		window = pullDuration + Validation.LaunchWindow
	elseif action == "Slide" then
		local lastDash = state.LastStart.Dash
		local fromDash = lastDash ~= nil and now - lastDash <= DASH_TO_SLIDE_WINDOW
		-- The last sample can be up to 0.2 s old; the replicated velocity covers a fresh sprint.
		local speed = math.max(state.LastHorizontalSpeed, MathUtil.flat(root.AssemblyLinearVelocity).Magnitude)
		if not isGrounded(root) or (speed < Validation.SlideEntrySpeed and not fromDash) then
			reject(player, state, action, "not grounded or too slow")
			return
		end
	elseif action == "WallRun" then
		local data = Validate.smallTable(payload, 2)
		local requestedSide = if data then data.Side else nil
		if requestedSide ~= 1 and requestedSide ~= -1 then
			reject(player, state, action, "invalid side")
			return
		end
		side = requestedSide
		relayPayload = { Side = side }
	end

	if MovementProtocol.Sustained[action] then
		-- A new start implicitly closes (and charges) a previous one that never sent "End".
		closeSustained(player, state, action, now)
	end
	state.LastStart[action] = now
	if rule.StaminaCost > 0 then
		spendStamina(state, now, rule.StaminaCost)
	end
	grantAllowance(state, rule.Horizontal, rule.Up, window, now, player:GetNetworkPing())
	if MovementProtocol.Sustained[action] and maxDuration then
		state.ActiveSustained[action] = now
		state.SustainedDeadline[action] = now + maxDuration + Validation.SustainedGrace
	end
	setMoveState(character, state, action, side, rule.AutoClear or window)
	relayFx(player, root, action, relayPayload)
end

local function onMovementAction(player: Player, kind: unknown, action: unknown, payload: unknown)
	local state = states[player]
	if not state or not limiter:Allow(player) then
		return
	end
	if kind ~= "Start" and kind ~= "End" then
		return
	end
	if type(action) ~= "string" or not MovementProtocol.ServerActions[action] then
		return
	end
	local character = player.Character
	local root = CharacterService:GetRoot(player)
	if not character or not root or character ~= state.Character then
		return
	end

	local now = os.clock()
	if kind == "End" then
		closeSustained(player, state, action, now)
	else
		handleStart(player, state, character, root, action, payload, now)
	end
end

local function onPlayerAdded(player: Player)
	states[player] = newState()
	for name, unlocked in MovementConfig.DefaultUnlocks do
		player:SetAttribute(Attributes.UnlockPrefix .. name, unlocked)
	end
end

function MovementService:Init()
	correctionRemote = Remotes.Event("MovementCorrection")
	fxRemote = Remotes.UnreliableEvent("MovementFx")
end

function MovementService:Start()
	groundParams = RaycastParams.new()
	groundParams.CollisionGroup = WorldConfig.CollisionGroups.Characters
	groundParams.RespectCanCollide = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		limiter:Remove(player)
	end)

	CharacterService.CharacterReady:Connect(function(player, character, _humanoid, root)
		local state = states[player]
		if not state then
			return
		end
		state.Character = character
		table.clear(state.ActiveSustained)
		table.clear(state.SustainedDeadline)
		state.AllowanceExpires = 0
		anchorAt(state, root.CFrame, os.clock())
	end)

	Remotes.Event("MovementAction").OnServerEvent:Connect(onMovementAction)

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, state in states do
			if now >= state.NextSampleTime then
				checkPlayer(player, state, now)
			end
		end
	end)
end

-- Call right before any scripted teleport (checkpoints, restarts) with its destination, so
-- validation re-anchors there instead of flagging the jump or trusting stale positions.
function MovementService:NotifyTeleport(player: Player, destination: CFrame)
	local state = states[player]
	if state then
		anchorAt(state, destination, os.clock())
	end
end

-- Server time (os.clock) of the last validated start of `action`, used by combat for dodge i-frames.
function MovementService:GetLastActionTime(player: Player, action: string): number?
	local state = states[player]
	return if state then state.LastStart[action] else nil
end

return MovementService
