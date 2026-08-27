--!strict
-- NativeThrusterOperator
--
-- Source-faithful transcription of the recovered `aqa` force operator.
-- Native force values remain separate from Roblox execution mappings.
--
-- SOURCE:
--   voidhunters_decompiled/aqa.java
--   voidhunters_decompiled/fc.java
--   voidhunters_decompiled/eu.java
--   voidhunters_decompiled/rrb.java
--   voidhunters_decompiled/clb.java
--   voidhunters_decompiled/pwa.java
--   voidhunters_decompiled/enb.java

local NativeTrigTable = require(script.Parent.NativeTrigTable)

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

local HALF_TURN_UNITS = 4096
local FORCE_SHIFT = 8

function NativeThrusterOperator.GetForceScale(componentType: number): number
	return FORCE_SCALE_BY_COMPONENT[componentType] or 0
end

function NativeThrusterOperator.NormalizeAngleUnits(angleUnits: number): number
	return -HALF_TURN_UNITS + bit32.band(HALF_TURN_UNITS + angleUnits, 0x1FFF)
end

export type TrigLookup = (angleUnits: number) -> number

-- Exact recovered `aqa` operator. Optional lookup arguments are retained for
-- deterministic tests; normal callers use the recovered native table.
function NativeThrusterOperator.Compute(
	componentType: number,
	nativeMagnitude: number,
	angleUnits: number,
	forceXLookup: TrigLookup?,
	forceZLookup: TrigLookup?
): NativeThrusterForce
	assert(type(componentType) == "number", "componentType must be numeric")
	assert(type(nativeMagnitude) == "number", "nativeMagnitude must be numeric")
	assert(type(angleUnits) == "number", "angleUnits must be numeric")

	local forceScale = NativeThrusterOperator.GetForceScale(componentType)
	local magnitude = bit32.arshift(forceScale * nativeMagnitude, FORCE_SHIFT)
	local normalized = NativeThrusterOperator.NormalizeAngleUnits(angleUnits)

	local xLookup = forceXLookup or NativeTrigTable.GetForceXComponent
	local zLookup = forceZLookup or NativeTrigTable.GetForceZComponent
	local xValue = xLookup(normalized)
	local zValue = zLookup(normalized)
	local forceX = bit32.arshift(magnitude * xValue, FORCE_SHIFT)
	local forceZ = bit32.arshift(magnitude * zValue, FORCE_SHIFT)

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
