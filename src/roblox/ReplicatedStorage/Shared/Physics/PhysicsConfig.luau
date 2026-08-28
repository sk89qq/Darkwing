--!strict
--[[
	PhysicsConfig: native-source configuration only.

	This module intentionally contains NO Roblox-unit tuning/mapping. Native
	values are preserved exactly as recovered from the original game. A later
	porting phase may add an explicit execution adapter once the unit boundary
	is established; it must not be mixed into this source-of-truth table.
]]

local PhysicsConfig = {
	-- Native propulsion / velocity
	THRUSTER_FORCE = 192,
	THRUSTER_BOOSTER_FORCE = 1024,
	THRUSTER_SMALL_FORCE = 16,
	VELOCITY_SUSTAIN = 508,
	VELOCITY_SUSTAIN_MAX = 512,
	ANGULAR_VELOCITY_SUSTAIN = 234,
	ANGULAR_VELOCITY_SUSTAIN_MAX = 256,

	-- Native operator shifts
	ANGULAR_FORCE_DOWNSHIFT = 4,
	TORQUE_DOWNSHIFT = 4,
	MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 12,
	MOMENT_OF_INERTIA_PERPOINT_CALC_DOWNSHIFT = 8,

	-- Native collision / detachment
	PHYSICS_COLLISION_FORCE_MULTIPLIER = 4096,
	PHYSICS_COLLISION_GRAPPLING_HOOK_FORCE_MULTIPLIER = 4096,
	PHYSICS_COLLISION_PHANTOM_FORCE_MULTIPLIER = 2048,
	DEBRIS_DETACHMENT_FORCE_MULTIPLIER = 256,
	COMPONENT_BREAKING_EXPLOSION_FORCE_MULTIPLIER = 32768,

	-- Native propulsion behavior
	THRUSTER_AUTOBALANCING = 1,
	THRUSTER_BINDING_BALANCE_THRESHOLD = 8,
	THRUSTER_BINDING_MOVE_AND_TURN_HAS_OPPOSITE_MOVE = 1,
	THRUSTER_PARTICLE_LIFE = 4,
	THRUSTER_PARTICLE_SPEED_DOWNSHIFT = 5,

	-- Native world / timing values
	WORLD_WIDTH_UPSHIFT = 20,
	AI_FIRING_RANGE_UPSHIFT = 18,
	WEAPON_PARTICLE_SPEED_DOWNSHIFT = 4,
	WEAPON_PROJECTILE_SPEED_MULTIPLY = 8,

	-- Native grapple / debris values
	GRAPPLE_DEBRIS = 0,
	DEBRIS_GRABBING_RANGE = 262144,
	GRAPPLING_HOOK_MAX_LENGTH = 65000,

	-- Native combat collision flags
	SHIP_TO_SHIP_RAM_DAMAGE = 0,
}

return PhysicsConfig
