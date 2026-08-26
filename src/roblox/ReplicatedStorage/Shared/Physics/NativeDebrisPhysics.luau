--[[
	NativeDebrisPhysics
	Source-faithful mapping of the recovered Void Hunters debris-launch operators.

	RAW-DIRECT:
	- ml.DA derives a debris spawn offset from component/body coordinates.
	- ar.a(...) resolves the offset length in native fixed-point space.
	- ecb.a(...) resolves the fast integer vector magnitude used for launch force.
	- hob.a(random, 200, 118) supplies an unbiased integer in [0, 199].
	- rrb.a(22433, angle) wraps the launch angle into the native signed turn domain.
	- anb.a(point, force) applies the launch force through the native body
	  accumulator path; the recovered shift constants are ge.c=4 and tua.a=4.

	ROBLOX-MAPPING:
	- Vector2 uses X/Z logical space.
	- Native turn units are 8192 units per full revolution for rrb.a(...).
	- The exact native-to-Assembly force scale remains source-dependent; this
	  module therefore returns the recovered logical launch vector and force
	  magnitude separately rather than inventing a Newton/stud conversion.
]]

local NativeDebrisPhysics = {}

local FULL_TURN_UNITS = 8192
local HALF_TURN_UNITS = 4096
local QUARTER_TURN_UNITS = 2048
local RANDOM_RANGE = 200

local function wrapNativeAngle(angleUnits: number): number
	return -HALF_TURN_UNITS + bit32.band(QUARTER_TURN_UNITS + angleUnits, 8191)
end

local function integerVectorMagnitude(x: number, z: number): number
	return math.sqrt((x * x) + (z * z))
end

local function unbiasedRandom200(rng: Random): number
	return rng:NextInteger(0, RANDOM_RANGE - 1)
end

local function nativeAngleToRadians(angleUnits: number): number
	return (angleUnits / FULL_TURN_UNITS) * (math.pi * 2)
end

export type LaunchResult = {
	Offset: Vector2,
	OffsetLength: number,
	ForceMagnitude: number,
	AngleUnits: number,
	AngleRadians: number,
	ForceDirection: Vector2,
}

function NativeDebrisPhysics.ComputeLaunch(offset: Vector2, scale: number, rng: Random?): LaunchResult
	assert(typeof(offset) == "Vector2", "NativeDebrisPhysics.ComputeLaunch expects a Vector2 offset")
	assert(type(scale) == "number", "NativeDebrisPhysics.ComputeLaunch expects a numeric scale")

	local random = rng or Random.new()
	local nativeOffsetX = offset.X
	local nativeOffsetZ = offset.Y
	local offsetLength = math.max(integerVectorMagnitude(nativeOffsetX, nativeOffsetZ), 1)

	local directionBaseUnits = nativeAngleToRadians(0)
	if offsetLength > 0 then
		directionBaseUnits = math.atan2(nativeOffsetZ, nativeOffsetX)
	end

	local baseAngleUnits = math.floor((directionBaseUnits / (math.pi * 2)) * FULL_TURN_UNITS)
	local randomizedAngleUnits = baseAngleUnits - 100 + unbiasedRandom200(random)
	local wrappedAngleUnits = wrapNativeAngle(randomizedAngleUnits)
	local angleRadians = nativeAngleToRadians(wrappedAngleUnits)

	local forceMagnitude = scale * offsetLength / offsetLength
	local direction = Vector2.new(math.cos(angleRadians), math.sin(angleRadians))

	return {
		Offset = offset,
		OffsetLength = offsetLength,
		ForceMagnitude = forceMagnitude,
		AngleUnits = wrappedAngleUnits,
		AngleRadians = angleRadians,
		ForceDirection = direction,
	}
end

return NativeDebrisPhysics
