--!strict
--[=[
	NativeWeaponConfig

	Canonical parameter-key contract for Void Hunters weapon behavior.
	Numeric values are resolved from NativeParameterResolver, whose backing
	table is the complete 235-row native configuration attestation.
	Units remain native until an explicitly verified consumer conversion exists.
]=]

local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local NativeWeaponConfig = {}

-- Native fixed-point angle encoding recovered from the original client:
-- 1024 units = half turn; 2048 units = full turn.
NativeWeaponConfig.ANGLE_UNITS_PER_TURN = 2048
NativeWeaponConfig.ANGLE_UNITS_PER_HALF_TURN = 1024

export type ParameterKey = {
	NativeKey: string,
	Unit: string,
	Value: any,
	Status: "RESOLVED" | "MISSING_NATIVE_VALUE",
}

export type WeaponContract = {
	Name: string,
	SpawnOffset: number?,
	Parameters: { [string]: ParameterKey },
}

local function parameter(nativeKey: string, unit: string): ParameterKey
	local resolved = NativeParameterResolver.Resolve(nativeKey)
	return {
		NativeKey = nativeKey,
		Unit = unit,
		Value = resolved.Value,
		Status = resolved.Status,
	}
end

NativeWeaponConfig.Contracts = {
	MachineGun = {
		Name = "Machine Gun",
		SpawnOffset = -10,
		Parameters = {
			AimArc = parameter("MACHINE_GUN_AIMARC", "native angle units"),
			AimSpeed = parameter("MACHINE_GUN_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("MACHINE_GUN_ENERGY_USED", "native energy units"),
			FireForce = parameter("MACHINE_GUN_FIRE_FORCE", "native force units"),
			ProjectileDamage = parameter("MACHINE_GUN_PROJECTILE_DAMAGE", "native damage units"),
			PulseTime = parameter("MACHINE_GUN_PULSETIME", "native time units"),
			Reload = parameter("MACHINE_GUN_RELOAD", "native time units"),
		},
	},

	MassDriver = {
		Name = "Mass Driver",
		SpawnOffset = -5,
		Parameters = {
			AimArc = parameter("MASS_DRIVER_AIMARC", "native angle units"),
			AimSpeed = parameter("MASS_DRIVER_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("MASS_DRIVER_ENERGY_USED", "native energy units"),
			FireForce = parameter("MASS_DRIVER_FIRE_FORCE", "native force units"),
			Projectiles = parameter("MASS_DRIVER_PROJECTILES", "count"),
			ProjectileDamage = parameter("MASS_DRIVER_PROJECTILE_DAMAGE", "native damage units"),
			ProjectileLife = parameter("MASS_DRIVER_PROJECTILE_LIFE", "native time units"),
			ProjectileOnDamageParticles = parameter("MASS_DRIVER_PROJECTILE_ONDAMAGE_PARTICLES", "resource identifier"),
			Randomness = parameter("MASS_DRIVER_RANDOMNESS", "native randomization units"),
			Reload = parameter("MASS_DRIVER_RELOAD", "native time units"),
		},
	},

	Laser = {
		Name = "Laser Beam",
		SpawnOffset = -10,
		Parameters = {
			AimArc = parameter("LASER_AIMARC", "native angle units"),
			AimSpeed = parameter("LASER_AIMSPEED", "native angle-rate units"),
			ProjectileDamage = parameter("LASER_BEAM_PROJECTILE_DAMAGE", "native damage units"),
			EnergyUsed = parameter("LASER_ENERGY_USED", "native energy units"),
			FireForce = parameter("LASER_FIRE_FORCE", "native force units"),
			Projectiles = parameter("LASER_PROJECTILES", "count"),
			Randomness = parameter("LASER_RANDOMNESS", "native randomization units"),
			Reload = parameter("LASER_RELOAD", "native time units"),
		},
	},

	BombletSpray = {
		Name = "Bomblet Spray",
		SpawnOffset = -3,
		Parameters = {
			AimArc = parameter("BOMBLET_SPRAY_AIMARC", "native angle units"),
			AimSpeed = parameter("BOMBLET_SPRAY_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("BOMBLET_SPRAY_ENERGY_USED", "native energy units"),
			Projectiles = parameter("BOMBLET_SPRAY_PROJECTILES", "count"),
			ProjectileDamage = parameter("BOMBLET_SPRAY_PROJECTILE_DAMAGE", "native damage units"),
			ProjectileLife = parameter("BOMBLET_SPRAY_PROJECTILE_LIFE", "native time units"),
			PushMultiplier = parameter("BOMBLET_SPRAY_PUSH_MULTIPLIER", "native multiplier"),
			Randomness = parameter("BOMBLET_SPRAY_RANDOMNESS", "native randomization units"),
			Reload = parameter("BOMBLET_SPRAY_RELOAD", "native time units"),
		},
	},

	Torpedo = {
		Name = "Torpedo",
		SpawnOffset = -4,
		Parameters = {
			AimArc = parameter("TORPEDO_AIMARC", "native angle units"),
			AimSpeed = parameter("TORPEDO_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("TORPEDO_ENERGY_USED", "native energy units"),
			FireForce = parameter("TORPEDO_FIRE_FORCE", "native force units"),
			Projectiles = parameter("TORPEDO_PROJECTILES", "count"),
			ProjectileDamage = parameter("TORPEDO_PROJECTILE_DAMAGE", "native damage units"),
			ProjectileLife = parameter("TORPEDO_PROJECTILE_LIFE", "native time units"),
			Acceleration = parameter("TORPEDO_ACCELERATION", "native acceleration units"),
			Randomness = parameter("TORPEDO_RANDOMNESS", "native randomization units"),
			Reload = parameter("TORPEDO_RELOAD", "native time units"),
		},
	},

	SniperCannon = {
		Name = "Sniper Cannon",
		SpawnOffset = -8,
		Parameters = {
			AimArc = parameter("SNIPER_CANNON_AIMARC", "native angle units"),
			AimSpeed = parameter("SNIPER_CANNON_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("SNIPER_CANNON_ENERGY_USED", "native energy units"),
			FireForce = parameter("SNIPER_CANNON_FIRE_FORCE", "native force units"),
			Projectiles = parameter("SNIPER_CANNON_PROJECTILES", "count"),
			ProjectileDamage = parameter("SNIPER_CANNON_PROJECTILE_DAMAGE", "native damage units"),
			ProjectileLife = parameter("SNIPER_CANNON_PROJECTILE_LIFE", "native time units"),
			FiringLeeway = parameter("SNIPER_CANNON_FIRING_LEEWAY", "native distance/aim units"),
			Randomness = parameter("SNIPER_CANNON_RANDOMNESS", "native randomization units"),
			Reload = parameter("SNIPER_CANNON_RELOAD", "native time units"),
		},
	},

	PointDefenceLaser = {
		Name = "Point Defence Laser",
		SpawnOffset = -2,
		Parameters = {
			AimArc = parameter("POINT_DEFENCE_LASER_AIMARC", "native angle units"),
			AimSpeed = parameter("POINT_DEFENCE_LASER_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("POINT_DEFENCE_LASER_ENERGY_USED", "native energy units"),
			Projectiles = parameter("POINT_DEFENCE_LASER_PROJECTILES", "count"),
			ProjectileDamage = parameter("POINT_DEFENCE_LASER_PROJECTILE_DAMAGE", "native damage units"),
			InterceptDamage = parameter("POINT_DEFENCE_LASER_PROJECTILE_INTERCEPT_DAMAGE", "native damage units"),
			PulseTime = parameter("POINT_DEFENCE_LASER_PULSETIME", "native time units"),
			Randomness = parameter("POINT_DEFENCE_LASER_RANDOMNESS", "native randomization units"),
			Reload = parameter("POINT_DEFENCE_LASER_RELOAD", "native time units"),
		},
	},

	Plasma = {
		Name = "Plasma",
		SpawnOffset = -3,
		Parameters = {},
	},

	MissileLauncher = {
		Name = "Missile Launcher",
		SpawnOffset = -8,
		Parameters = {
			AimArc = parameter("MISSILE_LAUNCHER_AIMARC", "native angle units"),
			AimSpeed = parameter("MISSILE_LAUNCHER_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("MISSILE_LAUNCHER_ENERGY_USED", "native energy units"),
			FireForce = parameter("MISSILE_LAUNCHER_FIRE_FORCE", "native force units"),
			Projectiles = parameter("MISSILE_LAUNCHER_PROJECTILES", "count"),
			ProjectileLife = parameter("MISSILE_LAUNCHER_PROJECTILE_LIFE", "native time units"),
			Randomness = parameter("MISSILE_LAUNCHER_RANDOMNESS", "native randomization units"),
			Acceleration = parameter("MISSILES_ACCELERATION", "native acceleration units"),
			Cooldown = parameter("MISSILES_COOLDOWN", "native time units"),
			ExplosionPower = parameter("MISSILES_EXPLOSION_POWER", "native explosion-power units"),
			TopSpeed = parameter("MISSILES_TOP_SPEED", "native speed units"),
		},
	},

	CountermeasureLauncher = {
		Name = "Countermeasure/Scrambler",
		SpawnOffset = -3,
		Parameters = {
			AimArc = parameter("COUNTERMEASURE_LAUNCHER_AIMARC", "native angle units"),
			AimSpeed = parameter("COUNTERMEASURE_LAUNCHER_AIMSPEED", "native angle-rate units"),
			EnergyUsed = parameter("COUNTERMEASURE_LAUNCHER_ENERGY_USED", "native energy units"),
			FireForce = parameter("COUNTERMEASURE_LAUNCHER_FIRE_FORCE", "native force units"),
			Projectiles = parameter("COUNTERMEASURE_LAUNCHER_PROJECTILES", "count"),
			ProjectileLife = parameter("COUNTERMEASURE_LAUNCHER_PROJECTILE_LIFE", "native time units"),
			Randomness = parameter("COUNTERMEASURE_LAUNCHER_RANDOMNESS", "native randomization units"),
			PulseTime = parameter("COUNTERMEASURES_PULSETIME", "native time units"),
			Cooldown = parameter("COUNTERMEASURES_COOLDOWN", "native time units"),
			PulseRadius = parameter("COUNTERMEASURES_PULSE_RADIUS", "native distance units"),
		},
	},

	GrapplingHook = {
		Name = "Grappling Hook",
		Parameters = {
			AimArc = parameter("GRAPPLING_HOOK_AIMARC", "native angle units"),
			AimSpeed = parameter("GRAPPLING_HOOK_AIMSPEED", "native angle-rate units"),
			Cooldown = parameter("GRAPPLING_HOOK_COOLDOWN", "native time units"),
			FireForce = parameter("GRAPPLING_HOOK_FIRE_FORCE", "native force units"),
			MaxLength = parameter("GRAPPLING_HOOK_MAX_LENGTH", "native distance units"),
			MinLength = parameter("GRAPPLING_HOOK_MIN_LENGTH", "native distance units"),
			SpringConstant = parameter("GRAPPLING_HOOK_SPRING_CONSTANT", "native spring units"),
			MaxExtensionForce = parameter("GRAPPLING_HOOK_MAX_EXTENSION8_FORCE", "native force units"),
			RopeChangeRate = parameter("GRAPPLING_HOOK_ROPE_CHANGE_RATE", "native distance-rate units"),
			RopeBreakLength = parameter("GRAPPLING_HOOK_ROPE_BREAK_LENGTH", "native distance units"),
			DebrisMode = parameter("GRAPPLE_DEBRIS", "native enum/flag"),
		},
	},
}

function NativeWeaponConfig.GetContract(name: string): WeaponContract?
	return NativeWeaponConfig.Contracts[name]
end

function NativeWeaponConfig.GetValue(nativeKey: string): any
	return NativeParameterResolver.Get(nativeKey)
end

return NativeWeaponConfig
