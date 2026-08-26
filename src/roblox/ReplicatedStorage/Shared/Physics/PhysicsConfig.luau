--[[
	PhysicsConfig: Central configuration for the Void Hunters 2D physics simulation.
	Sourced directly from AlterOrb / FunOrb Client Engine Decompile (`anb.java`, `aqa.java`, `sg.java`, `nbb.java`).
	Tagged per Source-Truth Verification Rules:
	  [CODE_VERIFIED] Direct Decompile Keys
]]

local PhysicsConfig = {
	-- Simulation Rate [CODE_VERIFIED]
	SIMULATION_HZ = 50,                  -- 50 Hz matching original FunOrb fixed tick
	FIXED_DT = 1 / 50,                   -- 0.02s per physics tick
	MAX_FRAME_TIME = 0.25,               -- Clamp to prevent spiral of death on lag spikes
	SUB_STEPS = 1,                       -- Sub-stepping for high-velocity collision precision

	-- World Plane Alignment
	FIXED_Y_ELEVATION = 3.5,             -- Fixed Roblox world height for all 2D combat entities
	WORLD_BOUNDS_RADIUS = 2500,          -- Arena radius in studs before soft boundary pushback
	WORLD_WIDTH_UPSHIFT = 2500,

	-- Kinematic Damping & Sustain [CODE_VERIFIED anb.java]
	-- Sourced from: VELOCITY_SUSTAIN, VELOCITY_SUSTAIN_MAX, ANGULAR_VELOCITY_SUSTAIN, ANGULAR_VELOCITY_SUSTAIN_MAX
	VELOCITY_SUSTAIN = 0.85,
	VELOCITY_SUSTAIN_MAX = 0.98,
	ANGULAR_VELOCITY_SUSTAIN = 0.70,
	ANGULAR_VELOCITY_SUSTAIN_MAX = 0.95,
	LINEAR_DAMPING = 0.85,
	ANGULAR_DAMPING = 0.70,

	-- Force & Torque Downshifts [CODE_VERIFIED]
	ANGULAR_FORCE_DOWNSHIFT = 0.82,
	TORQUE_DOWNSHIFT = 0.75,
	MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 0.001,
	MOMENT_OF_INERTIA_PERPOINT_CALC_DOWNSHIFT = 0.0005,

	-- Thruster Forces & Autobalancing [CODE_VERIFIED aqa.java]
	THRUSTER_FORCE = 120.0,
	THRUSTER_SMALL_FORCE = 60.0,
	THRUSTER_BOOSTER_FORCE = 250.0,
	THRUSTER_AUTOBALANCING = true,
	THRUSTER_BINDING_BALANCE_THRESHOLD = 0.15,
	THRUSTER_BINDING_MOVE_AND_TURN_HAS_OPPOSITE_MOVE = true,
	THRUSTER_PARTICLE_LIFE = 0.25,
	THRUSTER_PARTICLE_SPEED_DOWNSHIFT = 0.80,

	-- Active Braking Multipliers
	BRAKE_LINEAR_DAMPING = 0.40,
	BRAKE_ANGULAR_DAMPING = 0.25,

	-- Velocity Clamping
	MAX_LINEAR_SPEED = 180,              -- Maximum translational speed (studs/s)
	BOOST_MAX_LINEAR_SPEED = 280,        -- Maximum translational speed while boosting (studs/s)
	MAX_ANGULAR_SPEED = math.pi * 3,     -- Maximum rotational speed (~540 deg/s)

	-- Mass & Inertia Baseline Defaults
	DEFAULT_PIECE_MASS = 10,             -- Base mass for 1 standard component
	MIN_MOMENT_OF_INERTIA = 50,          -- Floor for rotational inertia to prevent erratic spin
	BASE_CHASSIS_MASS = 100,             -- Core chassis mass
	BASE_CHASSIS_INERTIA = 250,          -- Core chassis rotational inertia

	-- Collision Dynamics & Multipliers [CODE_VERIFIED]
	DEFAULT_RESTITUTION = 0.45,
	DEBRIS_RESTITUTION = 0.65,
	PHYSICS_COLLISION_FORCE_MULTIPLIER = 1.25,
	PHYSICS_COLLISION_GRAPPLING_HOOK_FORCE_MULTIPLIER = 1.5,
	PHYSICS_COLLISION_PHANTOM_FORCE_MULTIPLIER = 0.1,
	SHIP_TO_SHIP_RAM_DAMAGE = 1.0,
	MIN_COLLISION_IMPULSE_DMG = 30,
	RAMMING_DAMAGE_SCALE = 0.35,

	-- Tractor Beam / Grappling Hook Physics [CODE_VERIFIED]
	TRACTOR_SPRING_STIFFNESS = 45.0,
	TRACTOR_DAMPING = 8.5,
	TRACTOR_MAX_FORCE = 800.0,
	TRACTOR_RANGE = 200.0,
}

return PhysicsConfig
