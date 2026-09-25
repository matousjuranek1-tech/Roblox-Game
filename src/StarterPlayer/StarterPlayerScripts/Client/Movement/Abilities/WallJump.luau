--!strict
--[[
	WallJump
	An instant impulse away from a wall, not a sustained action: the controller follows it with
	Launch so the momentum carries. Works out of a wall run (keeps part of the run speed) or when
	pressing jump in the air next to any wall. The same wall cannot be used twice in a row and the
	chain is capped until the character lands, which prevents climbing a single wall forever
	while still allowing chimney climbs between two walls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local MovementContext = require(script.Parent.Parent.MovementContext)
local WallRun = require(script.Parent.WallRun)

type Context = MovementContext.Context

local Config = MovementConfig.WallJump

local lastWallJump = 0

local WallJump = {}

-- Closest usable wall around an airborne character, or nil.
function WallJump.Detect(ctx: Context): WallRun.Wall?
	if ctx.Grounded or ctx.WallJumpChain >= Config.MaxChain then
		return nil
	end
	local origin = ctx.Root.Position
	local look = ctx:LookDirection()
	local right = look:Cross(Vector3.yAxis)
	local best: WallRun.Wall? = nil
	local bestDistance = math.huge
	local directions = { right, -right, look, -look }
	local sides = { 1, -1, 0, 0 }
	for index, direction in directions do
		local side = sides[index]
		local result = ctx:Raycast(origin, direction * Config.DetectionDistance)
		if result and WallRun.IsWallSurface(result) and result.Distance < bestDistance then
			local normal = MathUtil.flatUnit(result.Normal, -direction)
			if not ctx:IsLastWall(result.Instance, normal) then
				best = { Normal = normal, Instance = result.Instance, Side = side }
				bestDistance = result.Distance
			end
		end
	end
	return best
end

-- Applies the jump. `carry` is the along-wall velocity to keep. Returns the launch velocity,
-- or nil when the jump is not allowed (chain cap, debounce, stamina).
function WallJump.Execute(ctx: Context, wall: WallRun.Wall, carry: Vector3, now: number): Vector3?
	if ctx.WallJumpChain >= Config.MaxChain or now - lastWallJump < Config.Debounce then
		return nil
	end
	if not ctx:SpendStamina(Config.StaminaCost, now) then
		return nil
	end
	local velocity = wall.Normal * Config.OutVelocity
		+ Vector3.new(0, Config.UpVelocity, 0)
		+ MathUtil.flat(carry) * Config.TangentCarry
	ctx.Root.AssemblyLinearVelocity = velocity
	ctx.WallJumpChain += 1
	ctx.AirDashCharges = MovementConfig.AirDash.Charges
	ctx:RememberWall(wall.Instance, wall.Normal)
	lastWallJump = now
	return velocity
end

return WallJump
