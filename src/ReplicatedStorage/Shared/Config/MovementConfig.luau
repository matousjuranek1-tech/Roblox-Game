--!strict
--[[
	MovementConfig
	Single source of truth for movement tuning. The client simulates with these values and the
	server validates against the same values, so they can never drift apart.

	Units: studs, seconds, studs/second. Character is ~5.5 studs tall (R15).
	Tuning workflow: change values here -> play the Movement Lab time trial -> compare splits.
]]

local deepFreeze = require(script.Parent.Parent.Util.Freeze)

local MovementConfig = {
	Stamina = {
		Max = 100,
		RegenPerSecond = 32,
		-- Seconds after the last spend before regeneration starts.
		RegenDelay = 0.65,
	},

	Walk = {
		Speed = 16,
	},

	Sprint = {
		Speed = 28,
		-- Exponential rate used to blend WalkSpeed toward the sprint/walk target.
		Acceleration = 6,
		-- Toggle-sprint (gamepad/touch) switches off after standing still this long.
		ToggleStopGrace = 0.35,
	},

	Jump = {
		-- Must match StarterPlayer.CharacterJumpHeight in default.project.json.
		Height = 8,
		-- Jump still allowed this long after walking off a ledge.
		CoyoteTime = 0.12,
	},

	Dash = {
		Speed = 76,
		Duration = 0.19,
		-- Portion of dash speed kept when the dash ends, so a dash flows into running.
		ExitSpeedFactor = 0.45,
		Cooldown = 0.35,
		StaminaCost = 20,
		-- Direction when there is no movement input: "Forward" (exploration) or "Backward" (souls-like).
		NeutralDirection = "Forward",
	},

	AirDash = {
		Speed = 62,
		Duration = 0.17,
		ExitSpeedFactor = 0.6,
		StaminaCost = 25,
		-- Charges refill on landing, wall contact and grapple.
		Charges = 1,
		-- Small upward velocity during the dash so it reads as a "hang" instead of a drop.
		UpVelocity = 4,
	},

	Slide = {
		-- Horizontal speed required to start a slide (sprinting guarantees it).
		MinEntrySpeed = 20,
		StartSpeed = 48,
		MaxSpeed = 72,
		EndSpeed = 17,
		-- Exponential decay of the speed above EndSpeed on flat ground.
		Friction = 1.5,
		-- Multiplier on the gravity component along the floor (downhill boost, uphill brake).
		SlopeFactor = 1,
		MaxDuration = 0.9,
		-- A slide keeps going downhill up to this long while it is still fast.
		MaxDownhillDuration = 2.5,
		TurnRate = math.rad(110),
		Cooldown = 0.3,
		-- HumanoidRootPart height while sliding (default R15 HipHeight is ~2).
		HipHeight = 0.35,
		-- Space a standing character needs above its root center (head + margin); a slide
		-- continues under low ceilings until this much room is free.
		HeadClearance = 2.6,
	},

	WallRun = {
		Speed = 36,
		-- Entry speed above Speed is kept up to Speed * MaxSpeedFactor.
		MaxSpeedFactor = 1.25,
		MinEntrySpeed = 14,
		MaxDuration = 1.4,
		StaminaPerSecond = 16,
		MinStamina = 8,
		InitialUpVelocity = 9,
		-- Reduced gravity along the wall (world gravity is 196.2).
		Gravity = 24,
		-- Cannot start a wall run while falling faster than this.
		MaxFallSpeed = 40,
		-- Ray length from the root center to the wall.
		DetectionDistance = 2.8,
		-- Small velocity into the wall that keeps the character glued to it.
		StickVelocity = 3,
		Cooldown = 0.2,
		-- Surfaces with |normal.Y| above this are floors/ceilings, not walls.
		MaxNormalY = 0.25,
		-- |dot(travel, wallNormal)| must be below this (roughly parallel travel).
		MaxApproachDot = 0.8,
		-- Holding away from the wall (dot with normal) above this detaches.
		DetachInputDot = 0.6,
	},

	WallJump = {
		OutVelocity = 44,
		UpVelocity = 52,
		-- Share of the wall-run speed carried along the wall into the jump.
		TangentCarry = 0.5,
		StaminaCost = 10,
		-- Wall jumps allowed before touching the ground again.
		MaxChain = 4,
		DetectionDistance = 3.2,
		-- Minimum time between two wall jumps (JumpRequest can repeat while the key is held).
		Debounce = 0.15,
	},

	Mantle = {
		-- Ledge height above the feet that triggers a mantle.
		MinHeight = 1,
		MaxHeight = 4.5,
		ForwardReach = 2.6,
		UpSpeed = 38,
		MinUpDuration = 0.1,
		MaxUpDuration = 0.3,
		ForwardDuration = 0.12,
		-- How far past the edge the character ends up.
		ForwardDistance = 1.5,
		Cooldown = 0.15,
	},

	Grapple = {
		-- Targets are BaseParts tagged WorldConfig.Tags.GrapplePoint.
		Range = 150,
		MinRange = 8,
		-- Half-angle of the aim cone in front of the camera.
		AimConeDegrees = 38,
		PullSpeed = 100,
		PullAcceleration = 320,
		-- Pull starts at least this fast, even from a standstill.
		InitialSpeed = 30,
		ArriveDistance = 6,
		ExitUpVelocity = 26,
		ExitSpeedCap = 60,
		ReleaseUpVelocity = 18,
		-- Time for the rope to reach the target before the pull starts.
		FireTime = 0.12,
		Cooldown = 0.9,
		-- Extra time on top of distance / speed before the pull times out.
		TimeoutPadding = 0.6,
		-- Aim slightly above the target so the arc clears edges.
		UpwardBias = 0.12,
		-- The pull is "stuck" when moving slower than this share of the commanded speed.
		StuckSpeedRatio = 0.25,
		StuckTime = 0.2,
		-- Target search frequency and how many best candidates get a line-of-sight raycast.
		TargetRefreshRate = 20,
		LineOfSightCandidates = 3,
	},

	Launch = {
		-- Exponential decay of carried horizontal speed toward the current walk speed.
		Decay = 1.8,
		AirTurnRate = math.rad(150),
		-- Decay multiplier while steering against the carried direction.
		BrakeMultiplier = 3,
		-- Launch only starts when the carried speed exceeds the walk speed by this much.
		MinExtraSpeed = 2,
		-- Ignore ground contact for this long after starting (slide-hop still on the floor).
		GroundGrace = 0.15,
	},

	Landing = {
		HardLandingSpeed = 70,
		TraumaMin = 0.15,
		TraumaMax = 0.6,
		-- Fall speed above HardLandingSpeed that reaches TraumaMax.
		TraumaRange = 80,
	},

	Camera = {
		BaseFov = 70,
		MaxSpeedFov = 88,
		-- Horizontal speed range mapped onto BaseFov..MaxSpeedFov.
		FovSpeedMin = 18,
		FovSpeedMax = 95,
		FovDamping = 7,
		DashKick = 7,
		AirDashKick = 8,
		GrappleFovBonus = 6,
		WallRunRoll = 9,
		RollDamping = 9,
		TraumaDecay = 1.6,
		MaxShakeOffset = 0.35,
		MaxShakeRoll = 2.2,
		ShakeFrequency = 18,
	},

	-- Server-side anti-exploit envelope (see MovementService).
	Validation = {
		SampleInterval = 0.2,
		SpeedTolerance = 1.25,
		FlatTolerance = 8,
		-- Speeds above allowed * SevereMultiplier + SevereFlat are corrected immediately.
		SevereMultiplier = 2.5,
		SevereFlat = 20,
		ViolationsToCorrect = 3,
		ViolationWindow = 2,
		-- Extra envelope time on top of each action window (plus 2x the player's ping).
		AllowanceGrace = 0.4,
		-- How long momentum from a launch may legitimately exceed sprint speed.
		LaunchWindow = 2.2,
		-- Server accepts an action after this share of its nominal interval (network jitter).
		CooldownTolerance = 0.5,
		StaminaTolerance = 15,
		GrappleRangeTolerance = 25,
		-- After a correction, spawn or scripted teleport the owner may still stream positions from
		-- before it. For this long only positions reachable from the new anchor are accepted.
		SettleTime = 0.6,
		SettleMargin = 12,
		-- A sample without movement (idle or a replication stall) keeps the previous baseline, so
		-- the next movement is measured over the whole gap, up to this many seconds. Prevents a
		-- Wi-Fi hiccup from looking like a speed hack.
		MaxStallCompensation = 1.5,
		-- Server-measured horizontal speed needed to start a slide (lenient vs. the client rule).
		SlideEntrySpeed = 10,
		-- Descent per sample (studs) that counts as sliding downhill, unlocking Slide.MaxSpeed.
		DownhillDescent = 0.5,
		-- Sustained actions without an "End" are closed this long after their longest honest duration.
		SustainedGrace = 0.5,
		ActionRate = 15,
		ActionBurst = 25,
		-- Other players further away than this do not receive cosmetic movement FX.
		FxRelayDistance = 350,
	},

	-- Unlock state is stored as Player attributes named "Unlock_<Name>". Phase 1 unlocks
	-- everything so the Movement Lab covers every ability; from Phase 6 the Movement skill
	-- tree grants AirDash and this default becomes false.
	DefaultUnlocks = {
		AirDash = true,
	} :: { [string]: boolean },
}

return deepFreeze(MovementConfig)
