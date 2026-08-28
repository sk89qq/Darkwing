--!strict
--[[
	NativeResourceProfile

	Native-only grouping for the recovered shield, energy, and repair resource
	families. This module does not convert units or supply fallback tuning.
	Consumers may use GetRaw to keep the native source domain intact until an
	explicit execution adapter is introduced.
]]

local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local NativeResourceProfile = {}

local profiles: { [string]: { [string]: string } } = {
	Shield = {
		DirectionalRadius = "SHIELDS_DIRECTIONAL_RADIUS",
		DirectionalArc = "SHIELDS_DIRECTIONAL_ARC",
		EnergyUsed = "SHIELDS_ENERGY_USED",
		EnergyConversion = "SHIELDS_ENERGY_CONVERSION",
	},
	Repair = {
		ModeCooldown = "REPAIR_MODE_COOLDOWN",
		ModeActiveTime = "REPAIR_MODE_ACTIVE_TIME",
		ModeRadius = "REPAIR_MODE_RADIUS",
		ModePower = "REPAIR_MODE_POWER",
		PlayerTime = "PLAYER_REPAIR_TIME",
		PlayerAmount = "PLAYER_REPAIR_AMOUNT",
		AITime = "AI_REPAIR_TIME",
		AIAmount = "AI_REPAIR_AMOUNT",
		FighterTime = "FIGHTER_REPAIR_TIME",
		FighterAmount = "FIGHTER_REPAIR_AMOUNT",
	},
	Combat = {
		BurstFireMaxEnergy = "BURST_FIRE_MAX_ENERGY",
		BurstFireRegenerationRate = "BURST_FIRE_REGENERATION_RATE",
		BurstFireReload = "BURST_FIRE_RELOAD",
	},
}

local function getKey(group: string, field: string): string?
	local profile = profiles[group]
	return profile and profile[field] or nil
end

function NativeResourceProfile.GetRaw(group: string, field: string): number?
	local key = getKey(group, field)
	if not key then
		return nil
	end
	local value = NativeParameterResolver.Get(key)
	return typeof(value) == "number" and value or nil
end

function NativeResourceProfile.GetKey(group: string, field: string): string?
	return getKey(group, field)
end

function NativeResourceProfile.Has(group: string, field: string): boolean
	return getKey(group, field) ~= nil
end

function NativeResourceProfile.GetAll(group: string): { [string]: number }?
	local profile = profiles[group]
	if not profile then
		return nil
	end
	local result: { [string]: number } = {}
	for field, key in pairs(profile) do
		local value = NativeParameterResolver.Get(key)
		if typeof(value) ~= "number" then
			return nil
		end
		result[field] = value
	end
	return result
end

return NativeResourceProfile
