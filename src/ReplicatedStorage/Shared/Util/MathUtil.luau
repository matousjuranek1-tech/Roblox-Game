--!strict
--[[
	MathUtil
	Small, allocation-free helpers used by movement, camera and validation code.
	All smoothing is frame-rate independent (exponential decay), so the feel is identical at
	30 FPS on a phone and 240 FPS on a PC.
]]

local MathUtil = {}

local UP = Vector3.yAxis

-- Exponential smoothing toward `target`. `rate` is "how many e-folds per second".
function MathUtil.damp(current: number, target: number, rate: number, dt: number): number
	return target + (current - target) * math.exp(-rate * dt)
end

function MathUtil.dampVector3(current: Vector3, target: Vector3, rate: number, dt: number): Vector3
	return target + (current - target) * math.exp(-rate * dt)
end

-- Removes the vertical component.
function MathUtil.flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

-- Unit vector, or `fallback` when the input is (near) zero length.
function MathUtil.safeUnit(vector: Vector3, fallback: Vector3): Vector3
	local magnitude = vector.Magnitude
	if magnitude < 1e-4 then
		return fallback
	end
	return vector / magnitude
end

-- Horizontal unit direction, or `fallback`.
function MathUtil.flatUnit(vector: Vector3, fallback: Vector3): Vector3
	return MathUtil.safeUnit(Vector3.new(vector.X, 0, vector.Z), fallback)
end

-- Rotates the horizontal unit vector `from` toward `to` by at most `maxRadians`.
function MathUtil.rotateTowards(from: Vector3, to: Vector3, maxRadians: number): Vector3
	local dot = math.clamp(from:Dot(to), -1, 1)
	local angle = math.acos(dot)
	if angle <= maxRadians or angle < 1e-4 then
		return to
	end
	-- Sign of the rotation around the world up axis.
	local sign = if from:Cross(to):Dot(UP) >= 0 then 1 else -1
	local rotation = CFrame.fromAxisAngle(UP, maxRadians * sign)
	return rotation:VectorToWorldSpace(from)
end

-- Projects `vector` onto the plane with the given unit normal.
function MathUtil.projectOnPlane(vector: Vector3, normal: Vector3): Vector3
	return vector - normal * vector:Dot(normal)
end

-- Launch speed needed to reach `height` studs under `gravity`.
function MathUtil.jumpVelocity(height: number, gravity: number): number
	return math.sqrt(2 * gravity * height)
end

-- Smooth 0..1 ease-out curve.
function MathUtil.easeOutQuad(alpha: number): number
	local t = math.clamp(alpha, 0, 1)
	return 1 - (1 - t) * (1 - t)
end

function MathUtil.lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

-- Maps `value` from [inMin, inMax] to [0, 1], clamped.
function MathUtil.inverseLerp(inMin: number, inMax: number, value: number): number
	if inMax == inMin then
		return 0
	end
	return math.clamp((value - inMin) / (inMax - inMin), 0, 1)
end

return MathUtil
