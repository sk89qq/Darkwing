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
	  accumulator path; ge.c = 4 and tua.a = 4.
	
	ROBLOX-MAPPING:
	- Vector2 uses X/Z logical space.
	- Native turn units are 8192 units per full revolution for rrb.a(...).
	- The native force magnitude is preserved as a logical scalar:
	    force = launchScale * debrisProperty / max(offsetLength, 1)
	- No Newton/stud conversion is invented here. The projection layer decides
	  how the recovered logical force is applied to the Roblox assembly.
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
	return math.floor(math.sqrt((x * x) + (z * z)))
end

local function unbiasedRandom200(rng: Random): number
	return rng:NextInteger(0, RANDOM_RANGE - 1)
end

local function radiansToNativeTurns(radians: number): number
	return math.floor((radians / (math.pi * 2)) * FULL_TURN_UNITS)
end

local function nativeAngleToRadians(angleUnits: number): number
	return (angleUnits / FULL_TURN_UNITS) * (math.pi * 2)
end

export type LaunchInput = {
	Offset: Vector2,
	LaunchScale: number,
	DebrisProperty: number,
}

export type LaunchResult = {
	Offset: Vector2,
	OffsetLength: number,
	AngleUnits: number,
	AngleRadians: number,
	ForceMagnitude: number,
	ForceDirection: Vector2,
}

function NativeDebrisPhysics.WrapAngleUnits(angleUnits: number): number
	return wrapNativeAngle(angleUnits)
end

function NativeDebrisPhysics.ComputeLaunch(input: LaunchInput, rng: Random?): LaunchResult
	assert(typeof(input.Offset) == "Vector2", "NativeDebrisPhysics.ComputeLaunch expects a Vector2 offset")
	assert(type(input.LaunchScale) == "number", "NativeDebrisPhysics.ComputeLaunch expects numeric LaunchScale")
	assert(type(input.DebrisProperty) == "number", "NativeDebrisPhysics.ComputeLaunch expects numeric DebrisProperty")

	local random = rng or Random.new()
	local nativeOffsetX = input.Offset.X
	local nativeOffsetZ = input.Offset.Y
	local offsetLength = math.max(integerVectorMagnitude(nativeOffsetX, nativeOffsetZ), 1)
	local offsetAngleRadians = math.atan2(nativeOffsetZ, nativeOffsetX)
	local baseAngleUnits = radiansToNativeTurns(offsetAngleRadians)
	local randomizedAngleUnits = baseAngleUnits - 100 + unbiasedRandom200(random)
	local wrappedAngleUnits = wrapNativeAngle(randomizedAngleUnits)
	local angleRadians = nativeAngleToRadians(wrappedAngleUnits)

	local forceMagnitude = input.LaunchScale * input.DebrisProperty / offsetLength
	local forceDirection = Vector2.new(math.cos(angleRadians), math.sin(angleRadians))

	return {
		Offset = input.Offset,
		OffsetLength = offsetLength,
		AngleUnits = wrappedAngleUnits,
		AngleRadians = angleRadians,
		ForceMagnitude = forceMagnitude,
		ForceDirection = forceDirection,
	}
end

return NativeDebrisPhysics
