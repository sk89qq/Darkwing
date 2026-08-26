--[[
	NativeDebrisPhysics
	Source-faithful mapping of the recovered Void Hunters debris-launch operators.

	RAW-DIRECT:
	- ml.DA derives a component-relative debris launch offset.
	- ar.a(...) resolves the native fixed-point offset magnitude.
	- ecb.a(...) resolves the native integer launch magnitude helper.
	- hob.a(random, 200, 118) supplies an unbiased integer in [0, 199].
	- rrb.a(22433, angle) wraps the launch angle into the native signed turn domain.
	- anb.e(false) returns the body mass field `s`.
	- ml.DA therefore computes launch force as `n2 * debrisMass / offsetLength`.
	- The launch is applied through the native body force operator `anb.a(...)`.

	ROBLOX-MAPPING:
	- Vector2 uses X/Z logical space.
	- Native turn units use 8192 units per full revolution.
	- Logical launch computation is kept separate from Roblox assembly projection.
	- No arbitrary Newton/stud conversion is introduced.
]]

local NativeDebrisPhysics = {}

local FULL_TURN_UNITS = 8192
local HALF_TURN_UNITS = 4096
local RANDOM_RANGE = 200
local RANDOM_OFFSET = 100

local function wrapNativeAngle(angleUnits: number): number
	return -HALF_TURN_UNITS + bit32.band(4096 + angleUnits, 8191)
end

local function nativeAngleToRadians(angleUnits: number): number
	return (angleUnits / FULL_TURN_UNITS) * (math.pi * 2)
end

local function unbiasedRandom200(rng: Random): number
	return rng:NextInteger(0, RANDOM_RANGE - 1)
end

local function nativeVectorMagnitude(x: number, z: number): number
	return math.sqrt((x * x) + (z * z))
end

export type LaunchResult = {
	Offset: Vector2,
	OffsetLength: number,
	DebrisMass: number,
	LaunchScale: number,
	ForceMagnitude: number,
	AngleUnits: number,
	AngleRadians: number,
	ForceDirection: Vector2,
}

function NativeDebrisPhysics.ComputeLaunch(
	offset: Vector2,
	launchScale: number,
	debrisMass: number,
	rng: Random?
): LaunchResult
	assert(typeof(offset) == "Vector2", "NativeDebrisPhysics.ComputeLaunch expects a Vector2 offset")
	assert(type(launchScale) == "number", "NativeDebrisPhysics.ComputeLaunch expects numeric launchScale")
	assert(type(debrisMass) == "number", "NativeDebrisPhysics.ComputeLaunch expects numeric debrisMass")

	local random = rng or Random.new()
	local offsetLength = math.max(nativeVectorMagnitude(offset.X, offset.Y), 1)

	local offsetAngleRadians = math.atan2(offset.Y, offset.X)
	local offsetAngleUnits = math.floor((offsetAngleRadians / (math.pi * 2)) * FULL_TURN_UNITS)
	local randomizedAngleUnits = offsetAngleUnits - RANDOM_OFFSET + unbiasedRandom200(random)
	local angleUnits = wrapNativeAngle(randomizedAngleUnits)
	local angleRadians = nativeAngleToRadians(angleUnits)

	local forceMagnitude = launchScale * debrisMass / offsetLength
	local forceDirection = Vector2.new(math.cos(angleRadians), math.sin(angleRadians))

	return {
		Offset = offset,
		OffsetLength = offsetLength,
		DebrisMass = debrisMass,
		LaunchScale = launchScale,
		ForceMagnitude = forceMagnitude,
		AngleUnits = angleUnits,
		AngleRadians = angleRadians,
		ForceDirection = forceDirection,
	}
end

return NativeDebrisPhysics
