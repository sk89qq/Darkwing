--!strict
-- Authoritative recovered Void Hunters grappling-hook parameter vector.
-- Native values remain coherent; cooldown is the only explicit time-boundary conversion.
local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local TICKS_PER_SECOND = 50
local KEY = {
	AIMSPEED = "GRAPPLING_HOOK_AIMSPEED",
	AIMARC = "GRAPPLING_HOOK_AIMARC",
	COOLDOWN = "GRAPPLING_HOOK_COOLDOWN",
	FIRE_FORCE = "GRAPPLING_HOOK_FIRE_FORCE",
	SPRING_CONSTANT = "GRAPPLING_HOOK_SPRING_CONSTANT",
	MAX_EXTENSION8_FORCE = "GRAPPLING_HOOK_MAX_EXTENSION8_FORCE",
	MAX_LENGTH = "GRAPPLING_HOOK_MAX_LENGTH",
	MIN_LENGTH = "GRAPPLING_HOOK_MIN_LENGTH",
	ROPE_CHANGE_RATE = "GRAPPLING_HOOK_ROPE_CHANGE_RATE",
	ROPE_BREAK_LENGTH = "GRAPPLING_HOOK_ROPE_BREAK_LENGTH",
}

local function resolve(key: string): number
	local value = NativeParameterResolver.Get(key)
	assert(typeof(value) == "number", "Missing native grapple value: " .. key)
	return value
end

local Config = {
	AIMSPEED = resolve(KEY.AIMSPEED),
	AIMARC = resolve(KEY.AIMARC),
	COOLDOWN = resolve(KEY.COOLDOWN) / TICKS_PER_SECOND,
	FIRE_FORCE = resolve(KEY.FIRE_FORCE),
	SPRING_CONSTANT = resolve(KEY.SPRING_CONSTANT),
	MAX_EXTENSION8_FORCE = resolve(KEY.MAX_EXTENSION8_FORCE),
	MAX_LENGTH = resolve(KEY.MAX_LENGTH),
	MIN_LENGTH = resolve(KEY.MIN_LENGTH),
	ROPE_CHANGE_RATE = resolve(KEY.ROPE_CHANGE_RATE),
	ROPE_BREAK_LENGTH = resolve(KEY.ROPE_BREAK_LENGTH),
}

return Config
