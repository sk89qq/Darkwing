--!strict
-- Native velocity sustain operator recovered directly from anb.a(boolean,boolean,pe).
-- The native body advances position/angle using the current velocities, then applies:
--   linear velocity *= 508 / 512
--   angular velocity *= 234 / 256
-- The source fields are native integers; Roblox velocities are already projected
-- into execution units, so this boundary preserves the exact recovered ratios
-- without applying native integer truncation to Roblox floating-point state.

local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)

local NativeVelocityOperator = {}

function NativeVelocityOperator.Apply(linearVelocity: Vector2, angularVelocity: number): (Vector2, number)
	local linearScale = PhysicsConfig.NATIVE_VELOCITY_SUSTAIN / PhysicsConfig.NATIVE_VELOCITY_SUSTAIN_MAX
	local angularScale = PhysicsConfig.NATIVE_ANGULAR_VELOCITY_SUSTAIN / PhysicsConfig.NATIVE_ANGULAR_VELOCITY_SUSTAIN_MAX

	return linearVelocity * linearScale, angularVelocity * angularScale
end

return NativeVelocityOperator
