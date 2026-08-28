--!strict
--[=[
	NativeWeaponRuntime

	Runtime authority for source-resolved weapon parameters. All recovered
	weapon values share the original native domain, so consumer relations are
	preserved rather than inventing per-value Roblox conversions.
]=]

local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local NativeWeaponRuntime = {}
local NATIVE_TICKS_PER_SECOND = 50

local contracts: { [string]: { Reload: string?, Energy: string?, Damage: string?, FireForce: string?, AimSpeed: string?, AimArc: string?, Projectiles: string?, ProjectileLife: string? } } = {
	MachineGun = { Reload = "MACHINE_GUN_RELOAD", Energy = "MACHINE_GUN_ENERGY_USED", Damage = "MACHINE_GUN_PROJECTILE_DAMAGE", FireForce = "MACHINE_GUN_FIRE_FORCE", AimSpeed = "MACHINE_GUN_AIMSPEED", AimArc = "MACHINE_GUN_AIMARC" },
	MassDriver = { Reload = "MASS_DRIVER_RELOAD", Energy = "MASS_DRIVER_ENERGY_USED", Damage = "MASS_DRIVER_PROJECTILE_DAMAGE", FireForce = "MASS_DRIVER_FIRE_FORCE", AimSpeed = "MASS_DRIVER_AIMSPEED", AimArc = "MASS_DRIVER_AIMARC", Projectiles = "MASS_DRIVER_PROJECTILES", ProjectileLife = "MASS_DRIVER_PROJECTILE_LIFE" },
	Laser = { Reload = "LASER_RELOAD", Energy = "LASER_ENERGY_USED", Damage = "LASER_BEAM_PROJECTILE_DAMAGE", FireForce = "LASER_FIRE_FORCE", AimSpeed = "LASER_AIMSPEED", AimArc = "LASER_AIMARC", Projectiles = "LASER_PROJECTILES" },
	PhasedEnergyBeam = { Reload = "PHASED_ENERGY_BEAM_RELOAD", Energy = "PHASED_ENERGY_BEAM_ENERGY_USED", FireForce = "PHASED_ENERGY_BEAM_FIRE_FORCE", AimSpeed = "PHASED_ENERGY_BEAM_AIMSPEED", AimArc = "PHASED_ENERGY_BEAM_AIMARC", Projectiles = "PHASED_ENERGY_BEAM_PROJECTILES", ProjectileLife = nil },
	BombletSpray = { Reload = "BOMBLET_SPRAY_RELOAD", Energy = "BOMBLET_SPRAY_ENERGY_USED", Damage = "BOMBLET_SPRAY_PROJECTILE_DAMAGE", FireForce = "BOMBLET_SPRAY_FIRE_FORCE", AimSpeed = "BOMBLET_SPRAY_AIMSPEED", AimArc = "BOMBLET_SPRAY_AIMARC", Projectiles = "BOMBLET_SPRAY_PROJECTILES", ProjectileLife = "BOMBLET_SPRAY_PROJECTILE_LIFE" },
	SniperCannon = { Reload = "SNIPER_CANNON_RELOAD", Energy = "SNIPER_CANNON_ENERGY_USED", Damage = "SNIPER_CANNON_PROJECTILE_DAMAGE", FireForce = "SNIPER_CANNON_FIRE_FORCE", AimSpeed = "SNIPER_CANNON_AIMSPEED", AimArc = "SNIPER_CANNON_AIMARC", Projectiles = "SNIPER_CANNON_PROJECTILES", ProjectileLife = "SNIPER_CANNON_PROJECTILE_LIFE" },
	Torpedo = { Reload = "TORPEDO_RELOAD", Energy = "TORPEDO_ENERGY_USED", Damage = "TORPEDO_PROJECTILE_DAMAGE", FireForce = "TORPEDO_FIRE_FORCE", AimSpeed = "TORPEDO_AIMSPEED", AimArc = "TORPEDO_AIMARC", Projectiles = "TORPEDO_PROJECTILES", ProjectileLife = "TORPEDO_PROJECTILE_LIFE" },
	FighterBay = { Reload = "FIGHTER_BAY_RELOAD", Energy = nil, Damage = nil, FireForce = nil, AimSpeed = "FIGHTER_BAY_AIMSPEED", AimArc = "FIGHTER_BAY_AIMARC" },
	MissileLauncher = { Reload = "MISSILES_COOLDOWN", Energy = "MISSILE_LAUNCHER_ENERGY_USED", FireForce = "MISSILE_LAUNCHER_FIRE_FORCE", AimSpeed = "MISSILE_LAUNCHER_AIMSPEED", AimArc = "MISSILE_LAUNCHER_AIMARC" },
	PointDefence = { Reload = "POINT_DEFENCE_LASER_RELOAD", Energy = "POINT_DEFENCE_LASER_ENERGY_USED", Damage = "POINT_DEFENCE_LASER_PROJECTILE_DAMAGE", FireForce = "POINT_DEFENCE_LASER_FIRE_FORCE", AimSpeed = "POINT_DEFENCE_LASER_AIMSPEED", AimArc = "POINT_DEFENCE_LASER_AIMARC", Projectiles = "POINT_DEFENCE_LASER_PROJECTILES" },
	ScramblerPulse = { Reload = "COUNTERMEASURES_COOLDOWN", Energy = "COUNTERMEASURE_LAUNCHER_ENERGY_USED", FireForce = "COUNTERMEASURE_LAUNCHER_FIRE_FORCE", AimSpeed = "COUNTERMEASURE_LAUNCHER_AIMSPEED", AimArc = "COUNTERMEASURE_LAUNCHER_AIMARC" },
}

local function getNative(key: string): number
	local value = NativeParameterResolver.Get(key)
	assert(typeof(value) == "number", "native weapon parameter must be numeric: " .. key)
	return value
end

local function get(typeName: string, field: string): number?
	local contract = contracts[typeName]
	if not contract then return nil end
	local key = contract[field]
	if not key then return nil end
	return getNative(key)
end

function NativeWeaponRuntime.HasContract(typeName: string): boolean return contracts[typeName] ~= nil end
function NativeWeaponRuntime.GetReloadSeconds(typeName: string): number?
	local value = get(typeName, "Reload")
	return value and value / NATIVE_TICKS_PER_SECOND or nil
end
function NativeWeaponRuntime.GetEnergyCost(typeName: string): number? return get(typeName, "Energy") end
function NativeWeaponRuntime.GetDamage(typeName: string): number? return get(typeName, "Damage") end
function NativeWeaponRuntime.GetFireForce(typeName: string): number? return get(typeName, "FireForce") end
function NativeWeaponRuntime.GetAimSpeed(typeName: string): number? return get(typeName, "AimSpeed") end
function NativeWeaponRuntime.GetAimArc(typeName: string): number? return get(typeName, "AimArc") end
function NativeWeaponRuntime.GetProjectileCount(typeName: string): number? return get(typeName, "Projectiles") end
function NativeWeaponRuntime.GetProjectileLifeSeconds(typeName: string): number?
	local value = get(typeName, "ProjectileLife")
	return value and value / NATIVE_TICKS_PER_SECOND or nil
end
function NativeWeaponRuntime.GetRaw(typeName: string, parameter: "Reload" | "Energy" | "Damage" | "FireForce" | "AimSpeed" | "AimArc" | "Projectiles" | "ProjectileLife"): number?
	return get(typeName, parameter)
end

return NativeWeaponRuntime
