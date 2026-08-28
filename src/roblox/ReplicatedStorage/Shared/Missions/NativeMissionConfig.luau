--!strict
--[=[
	NativeMissionConfig

	Source-backed mission/game-mode inputs exposed through the authoritative
	NativeParameterResolver. This module contains no guessed mode sequencing.
	The recovered MissionCondition/MissionAction contract remains separate from
	these numeric/global inputs until the original MissionBuilder/MissionControl
	ordering is source-proven.
]=]

local NativeParameterResolver = require(script.Parent.Parent.Combat:WaitForChild("NativeParameterResolver"))

local NativeMissionConfig = {}

local KEYS = {
	MAX_SHIP_SIZE = "MAX_SHIP_SIZE",
	FIGHTERS_PER_PLAYER_MAXIMUM = "FIGHTERS_PER_PLAYER_MAXIMUM",
	WAIT_FOR_PLAYERS = "WAIT_FOR_PLAYERS",
	FULL_MISSION_SET = "FULL_MISSION_SET",
	MISSION_VOTES = "MISSION_VOTES",
	MUTATOR_VOTES = "MUTATOR_VOTES",
	MISSION_TIME_LIMIT = "MISSION_TIME_LIMIT",
	ARMAGEDDON_TIMER_START = "ARMAGEDDON_TIMER_START",
	ARMAGEDDON_WARNING = "ARMAGEDDON_WARNING",
	ARMAGEDDON_LENGTH = "ARMAGEDDON_LENGTH",
	MISSION_TERRAIN_NEBULA_PROBABILITY = "MISSION_TERRAIN_NEBULA_PROBABILITY",
	MISSION_TERRAIN_ASTEROID_PROBABILITY = "MISSION_TERRAIN_ASTEROID_PROBABILITY",
	MISSION_TERRAIN_DEBRIS_PROBABILITY = "MISSION_TERRAIN_DEBRIS_PROBABILITY",
	MISSION_TERRAIN_SPACE_PROBABILITY = "MISSION_TERRAIN_SPACE_PROBABILITY",
	MISSION_TERRAIN_VOTING_CHANCESTEP = "MISSION_TERRAIN_VOTING_CHANCESTEP",
	MISSION_DEBRIS_DEFAULT_PROBABILITY = "MISSION_DEBRIS_DEFAULT_PROBABILITY",
	MISSION_DEBRIS_VOTING_CHANCESTEP = "MISSION_DEBRIS_VOTING_CHANCESTEP",
	RESOURCE_NODE_CAPTURE_TIME = "RESOURCE_NODE_CAPTURE_TIME",
	MISSION_RESNET_RESOURCE_TICK_TIME = "MISSION_RESNET_RESOURCE_TICK_TIME",
	RESPAWN_TIME = "RESPAWN_TIME",
}

function NativeMissionConfig.Get(key: string): number
	assert(KEYS[key] ~= nil, "unknown native mission config key: " .. key)
	local value = NativeParameterResolver.Get(KEYS[key])
	assert(typeof(value) == "number", "native mission config must be numeric: " .. key)
	return value
end

function NativeMissionConfig.GetAll(): {[string]: number}
	local result: {[string]: number} = {}
	for publicKey, nativeKey in pairs(KEYS) do
		local value = NativeParameterResolver.Get(nativeKey)
		assert(typeof(value) == "number", "native mission config must be numeric: " .. publicKey)
		result[publicKey] = value
	end
	return result
end

function NativeMissionConfig.GetNativeKey(key: string): string
	assert(KEYS[key] ~= nil, "unknown native mission config key: " .. key)
	return KEYS[key]
end

return NativeMissionConfig
