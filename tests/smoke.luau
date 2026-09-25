--!nocheck
-- Lune script (not Roblox): Roblox type definitions do not apply here.
--[[
	Runtime smoke tests, executed with Lune (https://lune-org.github.io/docs) against the place
	built by Rojo:

	  rojo build default.project.json -o Titanbound.rbxlx
	  lune run tests/smoke.luau Titanbound.rbxlx

	Covers what static analysis cannot: every ModuleScript loads, shared utilities behave, and the
	Movement Lab builds with valid instance properties and a sound layout (gate order and facing,
	floors under checkpoints, slide clearance, ramp continuity).
	Lune has no physics, networking or player, so services are loaded but not started.
]]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local task = require("@lune/task")

local placePath = process.args[1] or "Titanbound.rbxlx"
local game = roblox.deserializePlace(fs.readFile(placePath))
local workspace = game:GetService("Workspace")

local failures = 0
local passes = 0
local function check(name: string, condition: any, detail: any?)
	if condition then
		passes += 1
	else
		failures += 1
		print("FAIL: " .. name .. (if detail ~= nil then " -> " .. tostring(detail) else ""))
	end
end

local cache = {}
local function customRequire(moduleScript)
	if cache[moduleScript] ~= nil then
		return cache[moduleScript]
	end
	local source = moduleScript.Source
	local env = {
		game = game,
		workspace = workspace,
		script = moduleScript,
		require = customRequire,
		task = task,
		warn = function(...)
			print("[warn]", ...)
		end,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		-- Lune's CFrame.lookAt points the opposite way; use Roblox's documented semantics.
		CFrame = setmetatable({
			lookAt = function(at, target, up)
				local look = (target - at).Unit
				local right = look:Cross(up or roblox.Vector3.yAxis).Unit
				return roblox.CFrame.fromMatrix(at, right, right:Cross(look))
			end,
		}, { __index = roblox.CFrame }),
		Color3 = roblox.Color3,
		ColorSequence = roblox.ColorSequence,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Instance = roblox.Instance,
		-- Lune has no spatial queries; plain tables are enough for module load tests.
		RaycastParams = {
			new = function()
				return {}
			end,
		},
		OverlapParams = {
			new = function()
				return {}
			end,
		},
		UserSettings = function()
			error("UserSettings is not available in Lune")
		end,
		Enum = roblox.Enum,
		-- Lune's font table predates Builder Sans; fall back so the rest of the code still runs.
		Font = setmetatable({
			fromEnum = function(enumItem)
				local ok, font = pcall(roblox.Font.fromEnum, enumItem)
				return if ok then font else roblox.Font.new("rbxasset://fonts/families/BuilderSans.json")
			end,
		}, { __index = roblox.Font }),
	}
	local chunk = luau.load(luau.compile(source), { debugName = moduleScript:GetFullName(), environment = env })
	local result = chunk()
	cache[moduleScript] = result
	return result
end

local Shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local function sharedModule(path: { string })
	local node = Shared
	for _, name in path do
		node = node:FindFirstChild(name)
		assert(node, "missing " .. name)
	end
	return customRequire(node)
end

-- Configs ------------------------------------------------------------------------------------
local MovementConfig = sharedModule({ "Config", "MovementConfig" })
check("config frozen", table.isfrozen(MovementConfig) and table.isfrozen(MovementConfig.Dash))
check("config mutation errors", not pcall(function()
	MovementConfig.Dash.Speed = 1
end))
check("jump height matches project", MovementConfig.Jump.Height == 8)
for _, name in { "InputConfig", "GraphicsConfig", "WorldConfig", "TimeTrialConfig" } do
	check("config loads " .. name, type(sharedModule({ "Config", name })) == "table")
end
local GraphicsConfig = sharedModule({ "Config", "GraphicsConfig" })
check("10 quality levels", #GraphicsConfig.QualityLevelToTier == 10)
for _, tierName in GraphicsConfig.QualityLevelToTier do
	check("tier exists " .. tierName, GraphicsConfig.Tiers[tierName] ~= nil)
end
local Protocol = sharedModule({ "Net", "MovementProtocol" })
for name in Protocol.Sustained do
	check("sustained is server action " .. name, Protocol.ServerActions[name] == true)
end

-- MathUtil -----------------------------------------------------------------------------------
local MathUtil = sharedModule({ "Util", "MathUtil" })
local V3 = roblox.Vector3
check("damp converges", math.abs(MathUtil.damp(0, 10, 6, 10) - 10) < 1e-6)
check(
	"damp frame-rate independent",
	math.abs(MathUtil.damp(MathUtil.damp(0, 10, 5, 0.1), 10, 5, 0.1) - MathUtil.damp(0, 10, 5, 0.2)) < 1e-9
)
check("flat", MathUtil.flat(V3.new(1, 5, 2)) == V3.new(1, 0, 2))
check("safeUnit fallback", MathUtil.safeUnit(V3.zero, V3.xAxis) == V3.xAxis)
local rotated = MathUtil.rotateTowards(V3.new(0, 0, -1), V3.new(1, 0, 0), math.rad(45))
check("rotateTowards limited", math.abs(rotated:Dot(V3.new(0, 0, -1)) - math.cos(math.rad(45))) < 1e-4, rotated)
check("rotateTowards direction", rotated.X > 0, rotated)
local rotatedLeft = MathUtil.rotateTowards(V3.new(0, 0, -1), V3.new(-1, 0, 0), math.rad(30))
check("rotateTowards other side", rotatedLeft.X < 0, rotatedLeft)
check(
	"rotateTowards snaps",
	MathUtil.rotateTowards(V3.new(0, 0, -1), V3.new(0.1, 0, -1).Unit, 1) == V3.new(0.1, 0, -1).Unit
)
check("projectOnPlane", MathUtil.projectOnPlane(V3.new(1, 1, 0), V3.yAxis) == V3.new(1, 0, 0))
check("jumpVelocity", math.abs(MathUtil.jumpVelocity(8, 196.2) - 56.03) < 0.05)
check("inverseLerp clamps", MathUtil.inverseLerp(0, 10, 20) == 1)

-- Validate -----------------------------------------------------------------------------------
local Validate = sharedModule({ "Util", "Validate" })
check("NaN rejected", not Validate.isFiniteNumber(0 / 0))
check("inf rejected", not Validate.isFiniteNumber(math.huge))
check("number ok", Validate.isFiniteNumber(3))
check("vector NaN rejected", not Validate.isFiniteVector3(V3.new(0 / 0, 0, 0)))
check("vector ok", Validate.isFiniteVector3(V3.one))
check("smallTable limit", Validate.smallTable({ 1, 2, 3 }, 2) == nil and Validate.smallTable({ 1 }, 2) ~= nil)
local loosePart = roblox.Instance.new("Part")
check("detached part rejected", not Validate.isWorkspacePart(loosePart))

-- RateLimiter --------------------------------------------------------------------------------
local RateLimiter = sharedModule({ "Util", "RateLimiter" })
local limiter = RateLimiter.new(1, 3)
local allowed = 0
for _ = 1, 10 do
	if limiter:Allow("player") then
		allowed += 1
	end
end
check("rate limiter burst", allowed == 3, allowed)

-- Signal & Trove -----------------------------------------------------------------------------
local Signal = sharedModule({ "Util", "Signal" })
local signal = Signal.new()
local received = {}
local connection = signal:Connect(function(value)
	table.insert(received, value)
end)
signal:Once(function(value)
	table.insert(received, "once" .. value)
end)
signal:Fire(1)
signal:Fire(2)
connection:Disconnect()
signal:Fire(3)
check("signal delivery", table.concat(received, ",") == "1,once1,2", table.concat(received, ","))
-- The next Fire prints one "boom" error from a handler thread: that is the expected output.
local erroring = Signal.new()
local afterError = false
erroring:Connect(function()
	error("boom")
end)
erroring:Connect(function()
	afterError = true
end)
pcall(function()
	erroring:Fire()
end)
check("signal isolates errors", afterError)

local Trove = sharedModule({ "Util", "Trove" })
local trove = Trove.new()
local cleaned = {}
trove:Add(function()
	table.insert(cleaned, "a")
end)
trove:Add(function()
	table.insert(cleaned, "b")
end)
local folder = trove:Add(roblox.Instance.new("Folder"))
folder.Parent = workspace
trove:Clean()
check("trove reverse order", table.concat(cleaned, ",") == "b,a", table.concat(cleaned, ","))
check("trove destroys instances", folder.Parent == nil)

-- Test course --------------------------------------------------------------------------------
local builderModule = game:GetService("ServerScriptService").Server.World.TestCourseBuilder
local Builder = customRequire(builderModule)
local ok, err = pcall(Builder.Build, workspace)
-- Lune has no physics, so the final SetNetworkOwner call is the only expected error.
check("builder only fails at SetNetworkOwner", ok or string.find(tostring(err), "SetNetworkOwner") ~= nil, err)
local lab = workspace:FindFirstChild("MovementLab")
check("lab built", lab ~= nil)
if lab then
	local tagCounts = {}
	local partCount = 0
	for _, descendant in lab:GetDescendants() do
		if descendant:IsA("BasePart") then
			partCount += 1
		end
		for _, tag in descendant:GetTags() do
			tagCounts[tag] = (tagCounts[tag] or 0) + 1
		end
	end
	check("grapple points", tagCounts.GrapplePoint == 4, tagCounts.GrapplePoint)
	check("trial gates", tagCounts.TimeTrialGate == 7, tagCounts.TimeTrialGate)
	check("trial spawn", tagCounts.TimeTrialSpawn == 1, tagCounts.TimeTrialSpawn)
	check("reset plane", tagCounts.ResetPlane == 1, tagCounts.ResetPlane)
	check("part budget", partCount < 250, partCount)
	print("lab parts: " .. partCount)

	local indexes = {}
	local finishCount = 0
	for _, descendant in lab:GetDescendants() do
		if descendant:HasTag("TimeTrialGate") then
			local index = descendant:GetAttribute("Index")
			indexes[index] = true
			if descendant:GetAttribute("IsFinish") then
				finishCount += 1
				check("finish is last gate", index == 6, index)
			end
			check("gate trial id", descendant:GetAttribute("TrialId") == "MovementLab")
			check("gate non-collidable", descendant.CanCollide == false and descendant.CanQuery == true)
			-- Gates must face down the course (-Z).
			check("gate faces course", descendant.CFrame.LookVector.Z < -0.99, descendant.Name)
		end
	end
	for index = 0, 6 do
		check("gate index " .. index, indexes[index] == true)
	end
	check("one finish", finishCount == 1)

	-- Every checkpoint needs floor under its respawn point (gate bottom).
	local floors = {}
	for _, descendant in lab:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.CanCollide and descendant.Transparency < 1 then
			table.insert(floors, descendant)
		end
	end
	local function supported(position)
		for _, part in floors do
			local localPos = part.CFrame:PointToObjectSpace(position)
			local half = part.Size / 2
			if
				math.abs(localPos.X) <= half.X
				and math.abs(localPos.Z) <= half.Z
				and localPos.Y >= half.Y - 0.2
				and localPos.Y <= half.Y + 0.6
			then
				return true
			end
		end
		return false
	end
	for _, descendant in lab:GetDescendants() do
		if descendant:HasTag("TimeTrialGate") then
			local bottom = descendant.CFrame.Position - V3.new(0, descendant.Size.Y / 2, 0)
			check("gate has floor " .. descendant.Name, supported(bottom), bottom)
		end
	end
	local spawnPart = lab:FindFirstChild("LabSpawn")
	check("spawn exists", spawnPart ~= nil and spawnPart.Neutral == true)

	-- Chimney floor regression: the chimney interior must have a floor.
	check("chimney floor", supported(V3.new(0, 200, -706)))
	-- Slide barrier gap: 3.6 studs of clearance above the floor.
	local barrier = lab:FindFirstChild("SlideBarrier")
	check(
		"slide barrier clearance",
		barrier and math.abs((barrier.CFrame.Position.Y - barrier.Size.Y / 2) - 203.6) < 1e-3
	)

	for _, descendant in lab:GetDescendants() do
		if descendant.Name == "Sign" then
			check("sign faces the approaching player", descendant.CFrame.LookVector.Z > 0.99)
		end
	end
	check("spawn faces the course", spawnPart and spawnPart.CFrame.LookVector.Z < -0.99)
	local ramp = lab:FindFirstChild("SlideRamp")
	if ramp then
		local topStart = ramp.CFrame * roblox.CFrame.new(0, ramp.Size.Y / 2, ramp.Size.Z / 2)
		local topEnd = ramp.CFrame * roblox.CFrame.new(0, ramp.Size.Y / 2, -ramp.Size.Z / 2)
		check(
			"ramp starts flush with floor",
			(topStart.Position - V3.new(0, 200, -330)).Magnitude < 1e-3,
			topStart.Position
		)
		check("ramp ends flush with runout", (topEnd.Position - V3.new(0, 182, -390)).Magnitude < 1e-3, topEnd.Position)
	end

	local titan = lab:FindFirstChild("GreyboxTitan")
	check("titan persistent", titan and titan.ModelStreamingMode == roblox.Enum.ModelStreamingMode.Persistent)
end

-- Every ModuleScript must load without top-level errors ----------------------------------------
for _, root in
	{ game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"), game:GetService("StarterPlayer") }
do
	for _, descendant in root:GetDescendants() do
		if descendant.ClassName == "ModuleScript" then
			local loaded, result = pcall(customRequire, descendant)
			check("module loads " .. descendant:GetFullName(), loaded, result)
			if loaded then
				check("module returns a value " .. descendant.Name, result ~= nil)
			end
		end
	end
end

print(string.format("%d passed, %d failed", passes, failures))
if failures > 0 then
	error("smoke tests failed")
end
