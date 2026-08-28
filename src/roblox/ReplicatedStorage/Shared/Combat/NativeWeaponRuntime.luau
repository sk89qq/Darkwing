--!strict
--[=[
	NativeWeaponRuntime

	Bridges source-resolved native weapon parameters into runtime consumers.
	Native time uses oq.l = 50 ticks per native second, so time-valued weapon
	parameters are converted at this boundary only. Damage/force/speed conversion
	is intentionally not performed here because those native-to-Roblox mappings are
	not yet source-proven.
]=]

local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local NativeWeaponRuntime = {}

local NATIVE_TICKS_PER_SECOND = 50

local contracts: { [string]: { Reload: string?, Energy: string? } } = {
	MassDriver = {
		Reload = "MASS_DRIVER_RELOAD",
		Energy = "MASS_DRIVER_ENERGY_USED",
	},
	Laser = {
		Reload = "LASER_RELOAD",
		Energy = "LASER_ENERGY_USED",
	},
	MissileLauncher = {
		Reload = "MISSILES_COOLDOWN",
		Energy = "MISSILE_LAUNCHER_ENERGY_USED",
	},
	PointDefence = {
		Reload = "POINT_DEFENCE_LASER_RELOAD",
		Energy = "POINT_DEFENCE_LASER_ENERGY_USED",
	},
	ScramblerPulse = {
		Reload = "COUNTERMEASURES_COOLDOWN",
		Energy = "COUNTERMEASURE_LAUNCHER_ENERGY_USED",
	},
}

local function getNative(key: string): number
	local value = NativeParameterResolver.Get(key)
	assert(typeof(value) == "number", "native weapon parameter must be numeric: " .. key)
	return value
end

function NativeWeaponRuntime.GetReloadSeconds(typeName: string): number?
	local contract = contracts[typeName]
	if not contract or not contract.Reload then
		return nil
	end
	return getNative(contract.Reload) / NATIVE_TICKS_PER_SECOND
end

function NativeWeaponRuntime.GetEnergyCost(typeName: string): number?
	local contract = contracts[typeName]
	if not contract or not contract.Energy then
		return nil
	end
	return getNative(contract.Energy)
end

function NativeWeaponRuntime.GetRaw(typeName: string, parameter: "Reload" | "Energy"): number?
	local contract = contracts[typeName]
	if not contract then
		return nil
	end
	local key = contract[parameter]
	if not key then
		return nil
	end
	return getNative(key)
end

return NativeWeaponRuntime
