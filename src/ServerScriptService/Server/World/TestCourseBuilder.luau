--!strict
--[[
	TestCourseBuilder
	Builds the Phase 1 "Movement Lab": a greybox parkour course that exercises every movement
	ability in a fixed order and is timed by TimeTrialService.

	Greybox color code (so testers read the course at a glance):
	  light grey  floor            blue      gap edges            yellow  slide barriers
	  green       mantle ledges    purple    wall-run walls       cyan    grapple points
	  white gate  start            green     checkpoint           gold    finish

	The course runs along -Z. `s` below is the distance along the course (world Z = -s) and every
	height is relative to ORIGIN, which floats the lab above any baseplate the place may contain.

	Layout (s):
	  -45..0    spawn pad                    0..120    sprint strip (start gate at 4)
	  120..250  gaps of 10 / 14 / 18         250..330  slide barriers (gap 3.6 studs high)
	  330..390  downhill slide ramp          390..500  mantle steps +6 / +10 / +12
	  500..655  wall-run walls A / B / C     700..712  wall-jump chimney
	  760..905  grapple chasm                905..960  finish platform
	A rotating grapple arm beside the chasm previews moving Titan grapple points, and a greybox
	Titan stands in the haze beyond the finish for a sense of scale.
]]

local WorldConfig = require(game:GetService("ReplicatedStorage").Shared.Config.WorldConfig)

local Tags = WorldConfig.Tags

local ORIGIN = Vector3.new(0, 200, 0)
local TRIAL_ID = "MovementLab"

local Palette = {
	Floor = Color3.fromRGB(196, 198, 204),
	FloorAlt = Color3.fromRGB(172, 175, 183),
	Structure = Color3.fromRGB(92, 96, 108),
	GapEdge = Color3.fromRGB(70, 140, 255),
	Slide = Color3.fromRGB(255, 196, 45),
	Mantle = Color3.fromRGB(88, 196, 112),
	WallRun = Color3.fromRGB(150, 92, 255),
	Grapple = Color3.fromRGB(80, 222, 255),
	Pylon = Color3.fromRGB(40, 42, 50),
	GateStart = Color3.fromRGB(245, 245, 245),
	GateCheckpoint = Color3.fromRGB(90, 230, 140),
	GateFinish = Color3.fromRGB(255, 200, 70),
	SignBack = Color3.fromRGB(24, 26, 32),
	SignText = Color3.fromRGB(245, 238, 225),
	Basalt = Color3.fromRGB(48, 42, 44),
	Magma = Color3.fromRGB(255, 112, 32),
}

type PartSpec = {
	Name: string,
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3,
	Material: Enum.Material?,
	Transparency: number?,
	CanCollide: boolean?,
	CanQuery: boolean?,
	CastShadow: boolean?,
	Shape: Enum.PartType?,
}

local function makePart(parent: Instance, spec: PartSpec): Part
	local part = Instance.new("Part")
	part.Name = spec.Name
	part.Anchored = true
	part.Size = spec.Size
	part.CFrame = spec.CFrame
	part.Color = spec.Color
	part.Material = spec.Material or Enum.Material.SmoothPlastic
	part.Transparency = spec.Transparency or 0
	part.CanCollide = if spec.CanCollide == nil then true else spec.CanCollide
	part.CanQuery = if spec.CanQuery == nil then true else spec.CanQuery
	-- Nothing in the lab uses Touched; disabling it saves physics work.
	part.CanTouch = false
	part.CastShadow = if spec.CastShadow == nil then true else spec.CastShadow
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if spec.Shape then
		part.Shape = spec.Shape
	end
	part.Parent = parent
	return part
end

-- World position of a course-space point (x, height above ORIGIN, distance along the course).
local function at(x: number, y: number, s: number): Vector3
	return ORIGIN + Vector3.new(x, y, -s)
end

-- Axis-aligned block described in course space.
local function block(
	parent: Instance,
	name: string,
	xCenter: number,
	width: number,
	yBottom: number,
	height: number,
	sStart: number,
	sEnd: number,
	color: Color3
): Part
	local length = sEnd - sStart
	return makePart(parent, {
		Name = name,
		Size = Vector3.new(width, height, length),
		CFrame = CFrame.new(at(xCenter, yBottom + height / 2, (sStart + sEnd) / 2)),
		Color = color,
	})
end

-- Floor slab whose top surface sits at `top`.
local function floor(
	parent: Instance,
	name: string,
	width: number,
	top: number,
	sStart: number,
	sEnd: number,
	color: Color3?
): Part
	return block(parent, name, 0, width, top - 2, 2, sStart, sEnd, color or Palette.Floor)
end

local function sign(parent: Instance, text: string, x: number, y: number, s: number)
	local board = makePart(parent, {
		Name = "Sign",
		Size = Vector3.new(18, 4.5, 0.4),
		-- Front face points back toward the approaching player (+Z).
		CFrame = CFrame.lookAt(at(x, y + 6, s), at(x, y + 6, s - 1)),
		Color = Palette.SignBack,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	})
	makePart(parent, {
		Name = "SignPost",
		Size = Vector3.new(0.6, 4, 0.6),
		CFrame = CFrame.new(at(x, y + 2, s)),
		Color = Palette.Pylon,
		CanCollide = false,
		CanQuery = false,
	})

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Palette.SignText
	label.TextScaled = true
	label.TextWrapped = true
	label.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.1, 0)
	padding.PaddingBottom = UDim.new(0.1, 0)
	padding.Parent = label
end

local function gate(
	parent: Instance,
	index: number,
	isFinish: boolean,
	y: number,
	s: number,
	width: number,
	height: number
)
	local color = if index == 0
		then Palette.GateStart
		elseif isFinish then Palette.GateFinish
		else Palette.GateCheckpoint
	local pane = makePart(parent, {
		Name = if index == 0 then "StartGate" elseif isFinish then "FinishGate" else `Checkpoint{index}`,
		Size = Vector3.new(width, height, 1),
		-- LookVector points down the course: crossings count in that direction only.
		CFrame = CFrame.lookAt(at(0, y + height / 2, s), at(0, y + height / 2, s + 1)),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.85,
		CanCollide = false,
		CastShadow = false,
	})
	pane:SetAttribute("TrialId", TRIAL_ID)
	pane:SetAttribute("Index", index)
	pane:SetAttribute("IsFinish", isFinish)
	pane:AddTag(Tags.TimeTrialGate)

	for _, side in { -1, 1 } do
		makePart(parent, {
			Name = "GatePost",
			Size = Vector3.new(1, height, 1),
			CFrame = CFrame.new(at(side * (width / 2 + 0.5), y + height / 2, s)),
			Color = color,
			Material = Enum.Material.Neon,
			CastShadow = false,
		})
	end
end

-- A tagged grapple point. Each lives in its own Persistent model so it is always streamed in
-- (targeting must see points up to Grapple.Range away).
local function grapplePoint(parent: Instance, position: Vector3, withPylon: boolean): Part
	local model = Instance.new("Model")
	model.Name = "GrapplePoint"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local point = makePart(model, {
		Name = "Point",
		Size = Vector3.new(3, 3, 3),
		CFrame = CFrame.new(position),
		Color = Palette.Grapple,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
		CastShadow = false,
	})
	point:AddTag(Tags.GrapplePoint)

	local light = Instance.new("PointLight")
	light.Color = Palette.Grapple
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = point

	if withPylon then
		-- Pylon stops well below the point so arriving players clear it.
		local pylonTop = position.Y - 6
		local pylonBottom = ORIGIN.Y - 45
		makePart(model, {
			Name = "Pylon",
			Size = Vector3.new(1.4, pylonTop - pylonBottom, 1.4),
			CFrame = CFrame.new(position.X, (pylonTop + pylonBottom) / 2, position.Z),
			Color = Palette.Pylon,
		})
	end

	model.Parent = parent
	return point
end

-- A grapple point riding a motor-driven arm: the Phase 1 stand-in for grapple points on a
-- moving Titan. Returns the arm so ownership can be pinned to the server once it is in Workspace.
local function rotatingGrappleArm(parent: Instance, pivot: Vector3, armLength: number, angularSpeed: number): Part
	local model = Instance.new("Model")
	model.Name = "RotatingGrappleArm"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local base = makePart(model, {
		Name = "Base",
		Size = Vector3.new(4, pivot.Y - (ORIGIN.Y - 45), 4),
		CFrame = CFrame.new(pivot.X, (pivot.Y + ORIGIN.Y - 45) / 2, pivot.Z),
		Color = Palette.Pylon,
	})

	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Anchored = false
	arm.CanCollide = false
	arm.CanTouch = false
	arm.Size = Vector3.new(1.2, 1.2, armLength)
	arm.CFrame = CFrame.new(pivot + Vector3.new(0, 1.5, -armLength / 2))
	arm.Color = Palette.Pylon
	arm.Material = Enum.Material.SmoothPlastic
	arm.Parent = model

	-- Attachment X axis = hinge axis, pointing up.
	local hingeFrame = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.zAxis)
	local baseAttachment = Instance.new("Attachment")
	baseAttachment.CFrame = CFrame.new(0, base.Size.Y / 2 + 1.5, 0) * hingeFrame
	baseAttachment.Parent = base
	local armAttachment = Instance.new("Attachment")
	armAttachment.CFrame = CFrame.new(0, 0, armLength / 2) * hingeFrame
	armAttachment.Parent = arm

	local hinge = Instance.new("HingeConstraint")
	hinge.Attachment0 = baseAttachment
	hinge.Attachment1 = armAttachment
	hinge.ActuatorType = Enum.ActuatorType.Motor
	hinge.AngularVelocity = angularSpeed
	hinge.MotorMaxTorque = math.huge
	hinge.Parent = model

	local tip = Instance.new("Part")
	tip.Name = "Point"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(3, 3, 3)
	tip.Anchored = false
	tip.Massless = true
	tip.CanCollide = false
	tip.CanTouch = false
	tip.CastShadow = false
	tip.Color = Palette.Grapple
	tip.Material = Enum.Material.Neon
	tip.CFrame = arm.CFrame * CFrame.new(0, 0, -armLength / 2)
	tip:AddTag(Tags.GrapplePoint)
	tip.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = tip
	weld.Parent = tip

	model.Parent = parent
	return arm
end

-- Distant greybox Titan: silhouette and scale reference for art direction (see docs/ART.md #02).
local function greyboxTitan(parent: Instance, footing: Vector3)
	local model = Instance.new("Model")
	model.Name = "GreyboxTitan"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	-- The Titan faces +Z (toward the course).
	local base = CFrame.lookAt(footing, footing + Vector3.zAxis)
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, neon: boolean?)
		makePart(model, {
			Name = name,
			Size = size,
			CFrame = base * offset,
			Color = color,
			Material = if neon then Enum.Material.Neon else Enum.Material.Slate,
			CastShadow = not neon,
			CanCollide = false,
		})
	end

	local basalt = Palette.Basalt
	local magma = Palette.Magma
	for _, side in { -1, 1 } do
		piece("Leg", Vector3.new(30, 72, 30), CFrame.new(side * 24, 36, 0), basalt)
		piece(
			"Shoulder",
			Vector3.new(44, 36, 44),
			CFrame.new(side * 70, 150, -6) * CFrame.Angles(0, 0, side * math.rad(-12)),
			basalt
		)
		piece(
			"Arm",
			Vector3.new(26, 96, 26),
			CFrame.new(side * 80, 96, -18) * CFrame.Angles(math.rad(-10), 0, side * math.rad(6)),
			basalt
		)
		piece("Fist", Vector3.new(36, 34, 36), CFrame.new(side * 84, 40, -30), basalt)
		piece(
			"ArmCrack",
			Vector3.new(2, 70, 2),
			CFrame.new(side * 80, 98, -32) * CFrame.Angles(math.rad(-10), 0, 0),
			magma,
			true
		)
		piece(
			"ShoulderCrystal",
			Vector3.new(12, 22, 12),
			CFrame.new(side * 72, 176, -6) * CFrame.Angles(0, 0, side * math.rad(-20)),
			magma,
			true
		)
		piece("Eye", Vector3.new(5, 3, 2), CFrame.new(side * 8, 184, -34), magma, true)
	end
	piece("Pelvis", Vector3.new(84, 26, 44), CFrame.new(0, 82, 0), basalt)
	piece("Torso", Vector3.new(104, 76, 64), CFrame.new(0, 128, -8) * CFrame.Angles(math.rad(14), 0, 0), basalt)
	piece(
		"ChestArmor",
		Vector3.new(60, 40, 8),
		CFrame.new(0, 130, -44) * CFrame.Angles(math.rad(14), 0, 0),
		Color3.fromRGB(20, 18, 22)
	)
	piece("MagmaHeart", Vector3.new(22, 22, 22), CFrame.new(0, 128, -46), magma, true)
	piece("Head", Vector3.new(38, 30, 36), CFrame.new(0, 180, -20), basalt)
	for index, angle in { -30, -15, 0, 15, 30 } do
		local height = if index == 3 then 40 else 28
		piece(
			"CrownSpire",
			Vector3.new(7, height, 7),
			CFrame.new(angle * 0.55, 196 + height / 2 - 6, -14) * CFrame.Angles(0, 0, math.rad(-angle)),
			basalt
		)
	end

	model.Parent = parent
end

local TestCourseBuilder = {}

TestCourseBuilder.TrialId = TRIAL_ID

-- Builds the lab into a new Model parented to `parent` and returns it.
function TestCourseBuilder.Build(parent: Instance): Model
	local course = Instance.new("Model")
	course.Name = "MovementLab"

	-- Spawn pad -----------------------------------------------------------------------------
	floor(course, "SpawnPad", 40, 0, -45, 0, Palette.Structure)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LabSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(12, 1, 12)
	spawnLocation.CFrame = CFrame.lookAt(at(0, 0.5, -25), at(0, 0.5, -24))
	spawnLocation.Color = Palette.GateStart
	spawnLocation.Material = Enum.Material.SmoothPlastic
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.CanTouch = true
	spawnLocation:SetAttribute("TrialId", TRIAL_ID)
	spawnLocation:AddTag(Tags.TimeTrialSpawn)
	spawnLocation.Parent = course
	sign(course, "MOVEMENT LAB · PHASE 1\nR restart · H help · F3 debug", 0, 0, -8)

	-- 1. Sprint strip -----------------------------------------------------------------------
	gate(course, 0, false, 0, 4, 22, 18)
	for tile = 0, 11 do
		local color = if tile % 2 == 0 then Palette.Floor else Palette.FloorAlt
		floor(course, "SprintTile", 24, 0, tile * 10, tile * 10 + 10, color)
	end
	sign(course, "SPRINT\nhold Shift · L3 · SPRINT button", 15, 0, 12)

	-- 2. Gaps 10 / 14 / 18 --------------------------------------------------------------------
	sign(course, "GAPS 10 · 14 · 18\nsprint jump · dash (Q) · air dash", 15, 0, 108)
	local gapFloors = { { 130, 160 }, { 174, 200 }, { 218, 250 } }
	for _, range in gapFloors do
		floor(course, "GapFloor", 24, 0, range[1], range[2])
	end
	for _, edge in { 120, 130, 160, 174, 200, 218 } do
		block(course, "GapEdge", 0, 24, -0.05, 0.1, edge - 0.6, edge + 0.6, Palette.GapEdge)
	end
	gate(course, 1, false, 0, 240, 22, 18)

	-- 3. Slide barriers ---------------------------------------------------------------------
	floor(course, "SlideFloor", 24, 0, 250, 330)
	for _, x in { -12.5, 12.5 } do
		local wall = block(course, "SlideSideWall", x, 1, 0, 14, 250, 330, Palette.Structure)
		wall:SetAttribute(WorldConfig.Attributes.NoWallRun, true)
	end
	for _, s in { 268, 292, 316 } do
		-- Solid from 3.6 studs up: standing players (5+ studs) cannot pass, sliders can.
		block(course, "SlideBarrier", 0, 24, 3.6, 10.4, s - 1.5, s + 1.5, Palette.Slide)
	end
	sign(course, "SLIDE\nC / Ctrl while sprinting · R3 · SLIDE", 15, 0, 256)

	-- 4. Downhill slide ramp ------------------------------------------------------------------
	do
		local startPoint = at(0, 0, 330)
		local endPoint = at(0, -18, 390)
		local direction = (endPoint - startPoint).Unit
		local length = (endPoint - startPoint).Magnitude
		local frame = CFrame.lookAt((startPoint + endPoint) / 2, (startPoint + endPoint) / 2 + direction)
		makePart(course, {
			Name = "SlideRamp",
			Size = Vector3.new(24, 2, length),
			CFrame = frame * CFrame.new(0, -1, 0),
			Color = Palette.Slide,
		})
		sign(course, "RAMP\nslide downhill to gain speed", 15, 0, 326)
	end
	floor(course, "RampRunout", 24, -18, 390, 425)
	gate(course, 2, false, -18, 415, 22, 18)

	-- 5. Mantle steps +6 / +10 / +12 ----------------------------------------------------------
	sign(course, "MANTLE\njump at a ledge, hold forward", 15, -18, 420)
	block(course, "MantleStep6", 0, 24, -30, 18, 425, 440, Palette.Mantle)
	block(course, "MantleStep10", 0, 24, -30, 28, 440, 455, Palette.Mantle)
	block(course, "MantleStep12", 0, 30, -30, 40, 455, 500, Palette.Mantle)
	gate(course, 3, false, 10, 490, 26, 18)

	-- 6. Wall-run walls A / B / C -------------------------------------------------------------
	sign(course, "WALL RUN\njump along a wall · Space to wall jump", 16, 10, 494)
	block(course, "WallRunA", -12, 2, -20, 50, 505, 550, Palette.WallRun)
	block(course, "WallRunB", 12, 2, -20, 50, 560, 605, Palette.WallRun)
	block(course, "WallRunC", -12, 2, -20, 50, 615, 650, Palette.WallRun)
	-- Runs under the chimney too, so the chimney has a floor.
	floor(course, "WallRunLanding", 32, 0, 655, 712)
	gate(course, 4, false, 0, 680, 30, 18)

	-- 7. Wall-jump chimney --------------------------------------------------------------------
	sign(course, "CHIMNEY\nalternate wall jumps, mantle the top", 16, 0, 690)
	block(course, "ChimneyLeft", -4.5, 2, 0, 36, 700, 712, Palette.WallRun)
	block(course, "ChimneyRight", 4.5, 2, 0, 36, 700, 712, Palette.WallRun)
	block(course, "ChimneyExit", 0, 32, -10, 40, 712, 760, Palette.Mantle)
	gate(course, 5, false, 30, 745, 30, 18)

	-- 8. Grapple chasm ------------------------------------------------------------------------
	sign(course, "GRAPPLE\naim at a point, E · L1 · HOOK", 17, 30, 750)
	grapplePoint(course, at(0, 44, 795), true)
	grapplePoint(course, at(-12, 50, 835), true)
	grapplePoint(course, at(6, 44, 875), true)
	local arm = rotatingGrappleArm(course, at(42, 44, 835), 30, 0.35)

	-- 9. Finish --------------------------------------------------------------------------------
	floor(course, "FinishPlatform", 36, 20, 905, 960, Palette.Structure)
	gate(course, 6, true, 20, 915, 34, 18)
	sign(course, "FINISH\nR to run it again", 0, 20, 950)

	-- Safety net below the whole lab: crossing it returns the player to the last checkpoint.
	local resetPlane = makePart(course, {
		Name = "ResetPlane",
		Size = Vector3.new(400, 1, 1200),
		CFrame = CFrame.new(at(0, -45, 450)),
		Color = Palette.Pylon,
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
	})
	resetPlane:AddTag(Tags.ResetPlane)

	greyboxTitan(course, at(-150, -80, 1300))

	course.Parent = parent
	-- Server owns the moving arm: a nearby client must never gain physics authority over it.
	arm:SetNetworkOwner(nil)
	return course
end

return TestCourseBuilder
