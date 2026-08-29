--!strict
-- Native velocity sustain operator recovered directly from anb.a(boolean,boolean,pe).
-- The native body updates position/angle using the current velocities, then applies:
--   linear velocity *= VELOCITY_SUSTAIN / VELOCITY_SUSTAIN_MAX
--   angular velocity *= ANGULAR_VELOCITY_SUSTAIN / ANGULAR_VELOCITY_SUSTAIN_MAX
-- with native integer arithmetic (integer division after multiplication).
-- These are native execution inputs, not Roblox-unit speed caps.

local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)

local NativeVelocityOperator = {}

local function nativeDivide(numerator: number, denominator: number): number
	if denominator == 0 then
		return 0
	end
	-- Native fields are signed integers. Preserve truncation toward zero rather
	-- than silently introducing a floating-point damping curve.
	local quotient = numerator / denominator
	if quotient < 0 then
		return math.ceil(quotient)
	end
	return math.floor(quotient)
end

function NativeVelocityOperator.Apply(linearVelocity: Vector2, angularVelocity: number): (Vector2, number)
	local linearNumeratorX = linearVelocity.X * PhysicsConfig.NATIVE_VELOCITY_SUSTAIN
	local linearNumeratorY = linearVelocity.Y * PhysicsConfig.NATIVE_VELOCITY_SUSTAIN
	local angularNumerator = angularVelocity * PhysicsConfig.NATIVE_ANGULAR_VELOCITY_SUSTAIN

	local linear = Vector2.new(
		nativeDivide(linearNumeratorX, PhysicsConfig.NATIVE_VELOCITY_SUSTAIN_MAX),
		nativeDivide(linearNumeratorY, PhysicsConfig.NATIVE_VELOCITY_SUSTAIN_MAX)
	)
	local angular = nativeDivide(angularNumerator, PhysicsConfig.NATIVE_ANGULAR_VELOCITY_SUSTAIN_MAX)

	return linear, angular
end

return NativeVelocityOperator
