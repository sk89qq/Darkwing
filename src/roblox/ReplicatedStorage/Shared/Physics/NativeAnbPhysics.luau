--[[
	NativeAnbPhysics

	Source-faithful integer-domain reconstruction of the recovered `anb` body
	mass/COM/inertia and accumulator equations.

	This module intentionally does NOT convert native fixed-point quantities into
	Roblox studs/Newtons. It is a semantic bridge for the recovered equations;
	callers must supply values in the native integer domains recovered from the
	original JAR.

	VERIFIED FROM ORIGINAL JAR:
	- ge.c = 4
	- tua.a = 4
	- wf.e = 12
	- ou.r = 8
]]

local NativeAnbPhysics = {}

local POSITION_SHIFT = 4
local TORQUE_SHIFT = 4
local INERTIA_SHIFT = 12
local VERTEX_SHIFT = 8
local INT32_MAX = 2147483647
local INT32_MIN = -2147483648

local function clampInt32(value: number): number
	if value > INT32_MAX then
		return INT32_MAX
	elseif value < INT32_MIN then
		return INT32_MIN
	end
	return value
end

export type CenterOfMassAccumulator = {
	X: number,
	Y: number,
	Mass: number,
}

export type AccumulatorState = {
	LinearX: number,
	LinearY: number,
	Torque: number,
}

-- Direct equivalent of ml's mass-weighted COM accumulator.
-- Native component position is multiplied by mass after the recovered >>4
-- fixed-point normalization. The caller may aggregate children independently.
function NativeAnbPhysics.AccumulateCenterOfMass(
	acc: CenterOfMassAccumulator,
	positionX: number,
	positionY: number,
	mass: number
): CenterOfMassAccumulator
	acc.X += bit32.arshift(positionX * mass, POSITION_SHIFT)
	acc.Y += bit32.arshift(positionY * mass, POSITION_SHIFT)
	acc.Mass += mass
	return acc
end

-- Direct equivalent of anb.e(byte)'s final COM division.
function NativeAnbPhysics.ResolveCenterOfMass(acc: CenterOfMassAccumulator): Vector2
	local divisor = math.max(1, bit32.arshift(acc.Mass, POSITION_SHIFT))
	return Vector2.new(
		acc.X / divisor,
		acc.Y / divisor
	)
end

-- Direct equivalent of ml.a(int,int,int)'s per-vertex inertia contribution.
-- `vertices` contains native integer X/Y pairs in alternating entries.
function NativeAnbPhysics.ComputePolygonInertia(
	vertices: {number},
	componentMass: number,
	centerOfMassX: number,
	centerOfMassY: number
): number
	local vertexCount = bit32.arshift(#vertices, 1)
	if vertexCount <= 0 then
		return 1
	end

	local massPerVertex = componentMass / vertexCount
	local inertia = 1
	local comX = bit32.arshift(centerOfMassX, VERTEX_SHIFT)
	local comY = bit32.arshift(centerOfMassY, VERTEX_SHIFT)

	for i = 1, #vertices - 1, 2 do
		local x = bit32.arshift(vertices[i], VERTEX_SHIFT)
		local y = bit32.arshift(vertices[i + 1], VERTEX_SHIFT)
		local dx = x - comX
		local dy = y - comY
		inertia = inertia + massPerVertex * (dx * dx + dy * dy)
		if inertia > INT32_MAX then
			return INT32_MAX
		end
	end

	return inertia
end

-- Direct equivalent of anb.a(int n2,int n3,int n4,byte by,int n5).
-- Force/point values are native integer-domain quantities.
function NativeAnbPhysics.AccumulateForceAtPoint(
	state: AccumulatorState,
	forceY: number,
	pointX: number,
	pointY: number,
	bodyX: number,
	bodyY: number,
	forceX: number
): AccumulatorState
	state.LinearY += forceY
	state.LinearX += forceX

	local dx = bit32.arshift(pointX - bodyX, POSITION_SHIFT)
	local dy = bit32.arshift(bodyY - pointY, POSITION_SHIFT)
	local torqueNumerator = dy * forceX - forceY * dx
	state.Torque = clampInt32(state.Torque + bit32.arshift(torqueNumerator, TORQUE_SHIFT))
	return state
end

-- Direct equivalent of anb.b(int,int) after the surrounding guard logic.
-- `integrationDivisor` is the native call-site divisor; its semantic mapping
-- to Roblox dt remains intentionally unresolved.
function NativeAnbPhysics.Integrate(
	state: AccumulatorState,
	linearVelocity: Vector2,
	angularVelocity: number,
	inertia: number,
	integrationDivisor: number
): (Vector2, number, AccumulatorState)
	assert(integrationDivisor ~= 0, "NativeAnbPhysics integration divisor must be non-zero")

	local nextLinear = Vector2.new(
		linearVelocity.X + state.LinearY / integrationDivisor,
		linearVelocity.Y + state.LinearX / integrationDivisor
	)

	local effectiveInertia = math.max(1, bit32.arshift(inertia, INERTIA_SHIFT))
	local nextAngular = angularVelocity + state.Torque / effectiveInertia

	state.LinearX = 0
	state.LinearY = 0
	state.Torque = 0

	return nextLinear, nextAngular, state
end

function NativeAnbPhysics.Constants(): {[string]: number}
	return {
		POSITION_SHIFT = POSITION_SHIFT,
		TORQUE_SHIFT = TORQUE_SHIFT,
		INERTIA_SHIFT = INERTIA_SHIFT,
		VERTEX_SHIFT = VERTEX_SHIFT,
	}
end

return NativeAnbPhysics
