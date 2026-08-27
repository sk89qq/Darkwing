--!strict
--[[
	PhysicsConfig: Central configuration for the Void Hunters 2D physics simulation.

	SOURCE AUTHORITY:
	The native defaults below are recovered from the exact user-supplied
	voidhunters.jar census and bytecode/operator recovery.

	Native values remain separate from Roblox execution mappings. Native values
	must NOT be blindly substituted for Roblox-unit values when the native
	consumer/unit conversion is unresolved.
]]

local PhysicsConfig = {
	-- Native source defaults [SOURCE-VERIFIED]
	-- Source: native_configuration_values.csv / native operator bytecode.
	NATIVE_THRUSTER_FORCE = 192,
	NATIVE_THRUSTER_BOOSTER_FORCE = 1024,
	NATIVE_THRUSTER_SMALL_FORCE = 16,
	NATIVE_VELOCITY_SUSTAIN = 508,
	NATIVE_VELOCITY_SUSTAIN_MAX = 512,
	NATIVE_ANGULAR_VELOCITY_SUSTAIN = 234,
	NATIVE_ANGULAR_FORCE_DOWNSHIFT = 4,
	NATIVE_ANGULAR_VELOCITY_SUSTAIN_MAX = 256,
	NATIVE_TORQUE_DOWNSHIFT = 4,
	NATIVE_MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 12,
	NATIVE_MOMENT_OF_INERTIA_PERPOINT_CALC_DOWNSHIFT = 8,
	NATIVE_PHYSICS_COLLISION_FORCE_MULTIPLIER = 4096,
	NATIVE_PHYSICS_COLLISION_GRAPPLING_HOOK_FORCE_MULTIPLIER = 4096,
	NATIVE_PHYSICS_COLLISION_PHANTOM_FORCE_MULTIPLIER = 2048,
	NATIVE_DEBRIS_DETACHMENT_FORCE_MULTIPLIER = 256,
	NATIVE_COMPONENT_BREAKING_EXPLOSION_FORCE_MULTIPLIER = 32768,

	-- Native fixed-point/operator constants [BYTECODE-VERIFIED]
	-- Recovered from the native operator chain used by anb force/torque update.
	NATIVE_FORCE_POINT_SHIFT = 4,
	NATIVE_TORQUE_POINT_SHIFT = 4,
	NATIVE_ANGULAR_VELOCITY_DENOMINATOR_SHIFT = 12,

	-- Simulation Rate [ROBLOX-MAPPING]
	-- The native census establishes the operators/settings, but does not by
	-- itself establish Roblox's scheduler unit conversion.
	SIMULATION_HZ = 50,
	FIXED_DT = 1 / 50,
	MAX_FRAME_TIME = 0.25,
	SUB_STEPS = 1,

	-- World Plane Alignment [ROBLOX-MAPPING]
	FIXED_Y_ELEVATION = 3.5,
	WORLD_BOUNDS_RADIUS = 2500,
	WORLD_WIDTH_UPSHIFT = 2500,

	-- Kinematic Damping [ROBLOX-MAPPING]
	-- These factors remain execution mappings until the complete native anb
	-- update/unit conversion is recovered.
	VELOCITY_SUSTAIN = 0.85,
	VELOCITY_SUSTAIN_MAX = 0.98,
	ANGULAR_VELOCITY_SUSTAIN = 0.70,
	ANGULAR_VELOCITY_SUSTAIN_MAX = 0.95,
	LINEAR_DAMPING = 0.85,
	ANGULAR_DAMPING = 0.70,

	-- Force & Torque Downshifts [ROBLOX-MAPPING]
	ANGULAR_FORCE_DOWNSHIFT = 0.82,
	TORQUE_DOWNSHIFT = 0.75,
	MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 0.001,
	MOMENT_OF_INERTIA_PERPOINT_CALC_DOWNSHIFT = 0.0005,

	-- Thruster Forces [ROBLOX-MAPPING]
	-- These are not asserted to be native-unit values. Native source values are
	-- available above and must be mapped at the native consumer boundary.
	THRUSTER_FORCE = 120.0,
	THRUSTER_SMALL_FORCE = 60.0,
	THRUSTER_BOOSTER_FORCE = 250.0,
	THRUSTER_AUTOBALANCING = true,
	THRUSTER_BINDING_BALANCE_THRESHOLD = 0.15,
	THRUSTER_BINDING_MOVE_AND_TURN_HAS_OPPOSITE_MOVE = true,
	THRUSTER_PARTICLE_LIFE = 0.25,
	THRUSTER_PARTICLE_SPEED_DOWNSHIFT = 0.80,

	-- Active Braking [ROBLOX-MAPPING]
	BRAKE_LINEAR_DAMPING = 0.40,
	BRAKE_ANGULAR_DAMPING = 0.25,

	-- Velocity Clamping [ROBLOX-MAPPING]
	MAX_LINEAR_SPEED = 180,
	BOOST_MAX_LINEAR_SPEED = 280,
	MAX_ANGULAR_SPEED = math.pi * 3,

	-- Mass & Inertia Baseline Defaults [ROBLOX-MAPPING]
	DEFAULT_PIECE_MASS = 10,
	MIN_MOMENT_OF_INERTIA = 50,
	BASE_CHASSIS_MASS = 100,
	BASE_CHASSIS_INERTIA = 250,

	-- Collision Dynamics [ROBLOX-MAPPING]
	DEFAULT_RESTITUTION = 0.45,
	DEBRIS_RESTITUTION = 0.65,
	PHYSICS_COLLISION_FORCE_MULTIPLIER = 1.25,
	PHYSICS_COLLISION_GRAPPLING_HOOK_FORCE_MULTIPLIER = 1.5,
	PHYSICS_COLLISION_PHANTOM_FORCE_MULTIPLIER = 0.1,
	SHIP_TO_SHIP_RAM_DAMAGE = 1.0,
	MIN_COLLISION_IMPULSE_DMG = 30,
	RAMMING_DAMAGE_SCALE = 0.35,

	-- Tractor Beam / Grappling Hook [ROBLOX-MAPPING]
	TRACTOR_SPRING_STIFFNESS = 45.0,
	TRACTOR_DAMPING = 8.5,
	TRACTOR_MAX_FORCE = 800.0,
	TRACTOR_RANGE = 200.0,
}

return PhysicsConfig
