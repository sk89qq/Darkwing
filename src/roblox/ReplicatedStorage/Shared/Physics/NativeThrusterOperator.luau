--!strict
-- NativeThrusterOperator
--
-- Source-faithful Roblox-side transcription of the recovered `aqa` force
-- operator. This module intentionally does NOT decide what value is supplied
-- as the native magnitude parameter; that value is determined by the caller
-- chain in `ml` and remains separate from Roblox-unit tuning.
--
-- SOURCE:
--   voidhunters_decompiled/aqa.java
--   voidhunters_decompiled/fc.java
--   voidhunters_decompiled/eu.java
--   voidhunters_decompiled/rrb.java
--   voidhunters_decompiled/clb.java
--
-- RAW-DIRECT / RAW-STRUCTURED:
--   forceScale = aqa.a(componentType, false)
--   componentType 12 -> clb.a -> 16
--   componentType 13 -> pwa.b -> 192
--   componentType 46 -> enb.c -> 1024
--   magnitude = forceScale * nativeMagnitude >> 8
--   forceX = magnitude * fc.a(angleUnits) >> 8
--   forceZ = magnitude * eu.a(angleUnits) >> 8
--   fc/eu consume 13-bit turn units (mask 0x1FFF), with rrb.a defining
--   signed normalization over the same 8192-unit revolution.
--
-- The native trigonometric lookup table itself is not approximated with
-- math.sin/cos here. The caller may provide a Roblox direction projection,
-- but numerical native parity requires the original `kra.a[]` lookup table.

local NativeThrusterOperator = {}

export type NativeThrusterForce = {
	ComponentType: number,
	ForceScale: number,
	NativeMagnitude: number,
	Magnitude: number,
	AngleUnits: number,
	NormalizedAngleUnits: number,
	Direction: Vector2,
	Force: Vector2,
}

local FORCE_SCALE_BY_COMPONENT: { [number]: number } = {
	[12] = 16, -- RAW-DIRECT: clb.a
	[13] = 192, -- RAW-DIRECT: pwa.b
	[46] = 1024, -- RAW-DIRECT: enb.c
}

local FULL_TURN_UNITS = 8192
local TURN_MASK = 0x1FFF
local HALF_TURN_UNITS = 4096
local FORCE_SHIFT = 8

function NativeThrusterOperator.GetForceScale(componentType: number): number
	return FORCE_SCALE_BY_COMPONENT[componentType] or 0
end

function NativeThrusterOperator.NormalizeAngleUnits(angleUnits: number): number
	return -HALF_TURN_UNITS + bit32.band(HALF_TURN_UNITS + angleUnits, TURN_MASK)
end

-- The native `fc`/`eu` functions are table lookups into `kra.a[]`.
-- Keep the lookup injectable so the native table can be installed when its
-- complete literal table is recovered, rather than silently replacing it.
export type TrigLookup = (angleUnits: number) -> number

function NativeThrusterOperator.Compute(
	componentType: number,
	nativeMagnitude: number,
	angleUnits: number,
	sinLookup: TrigLookup,
	cosLookup: TrigLookup
): NativeThrusterForce
	assert(type(componentType) == "number", "componentType must be numeric")
	assert(type(nativeMagnitude) == "number", "nativeMagnitude must be numeric")
	assert(type(angleUnits) == "number", "angleUnits must be numeric")

	local forceScale = NativeThrusterOperator.GetForceScale(componentType)
	local magnitude = bit32.arshift(forceScale * nativeMagnitude, FORCE_SHIFT)
	local normalized = NativeThrusterOperator.NormalizeAngleUnits(angleUnits)

	local sinValue = sinLookup(normalized)
	local cosValue = cosLookup(normalized)
	local forceX = bit32.arshift(magnitude * sinValue, FORCE_SHIFT)
	local forceZ = bit32.arshift(magnitude * cosValue, FORCE_SHIFT)

	local force = Vector2.new(forceX, forceZ)
	local direction = if magnitude ~= 0 then force / magnitude else Vector2.zero

	return {
		ComponentType = componentType,
		ForceScale = forceScale,
		NativeMagnitude = nativeMagnitude,
		Magnitude = magnitude,
		AngleUnits = angleUnits,
		NormalizedAngleUnits = normalized,
		Direction = direction,
		Force = force,
	}
end

return NativeThrusterOperator
