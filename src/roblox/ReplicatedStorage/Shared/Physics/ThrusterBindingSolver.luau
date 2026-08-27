--!strict
-- ThrusterBindingSolver
--
-- Source-shaped transcription of ml.VA(): thruster-binding direction
-- classification. Pure calculation only; no Instance or physics mutation.
--
-- SOURCE:
--   voidhunters_decompiled/ml.java, ml.VA()
--   voidhunters_decompiled/fc.java
--   voidhunters_decompiled/eu.java
--   voidhunters_decompiled/rrb.java

local NativeTrigTable = require(script.Parent.NativeTrigTable)

local ThrusterBindingSolver = {}

export type BindingResult = {
	Flags: number,
	DeltaX: number,
	DeltaZ: number,
	ForwardProjection: number,
	TurnProjection: number,
	ForwardScaled: number,
	TurnScaled: number,
	DistanceSquared: number,
}

local TURN_OFFSET_UNITS = -2048
local PROJECTION_SCALE = 256
local THRESHOLD = 128

function ThrusterBindingSolver.Compute(
	currentAngleUnits: number,
	currentPosition: Vector2,
	targetPosition: Vector2
): BindingResult
	-- Exact ml.VA() fixed-point coordinate shifts.
	local deltaX = bit32.arshift(targetPosition.X - currentPosition.X, 8)
	local deltaZ = bit32.arshift(targetPosition.Y - currentPosition.Y, 8)

	local forwardX = bit32.arshift(NativeTrigTable.GetForceXComponent(currentAngleUnits), 8)
	local forwardZ = bit32.arshift(NativeTrigTable.GetForceZComponent(currentAngleUnits), 8)

	local offsetAngle = currentAngleUnits + TURN_OFFSET_UNITS
	local offsetX = bit32.arshift(NativeTrigTable.GetForceXComponent(offsetAngle), 8)
	local offsetZ = bit32.arshift(NativeTrigTable.GetForceZComponent(offsetAngle), 8)

	local forwardProjection = forwardX * deltaX + deltaZ * forwardZ
	local turnProjection = deltaZ * offsetZ + offsetX * deltaX
	local distanceSquared = math.max(deltaZ * deltaZ + deltaX * deltaX, 1)

	local forwardScaled = PROJECTION_SCALE * forwardProjection / distanceSquared
	local turnScaled = PROJECTION_SCALE * turnProjection / distanceSquared

	local flags = 0

	-- ml.VA(): n15 is the native longitudinal sign term.
	if deltaZ < 0 then
		flags += 4
	else
		flags += 8
	end

	-- Exact threshold structure from n9/n10/n4.
	if forwardProjection > 1 and forwardScaled > THRESHOLD then
		flags += 1
	elseif forwardProjection < 0 and forwardScaled < -THRESHOLD then
		flags += 2
	end

	-- Exact threshold structure from n5/n6/n4.
	if turnProjection > 0 and turnScaled > THRESHOLD then
		flags += 0x20
	elseif turnProjection < 0 and turnScaled < -THRESHOLD then
		flags += 0x40
	end

	return {
		Flags = flags,
		DeltaX = deltaX,
		DeltaZ = deltaZ,
		ForwardProjection = forwardProjection,
		TurnProjection = turnProjection,
		ForwardScaled = forwardScaled,
		TurnScaled = turnScaled,
		DistanceSquared = distanceSquared,
	}
end

return ThrusterBindingSolver
