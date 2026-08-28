--[=[
	RepairSystem

	Recovered native configuration is authoritative. Values are supplied through
	NativeParameterResolver; no prototype tuning is used when a native key exists.
]=]

local ComponentAuthority = require(script.Parent:WaitForChild("ComponentAuthority"))
local NativeParameterResolver = require(script.Parent:WaitForChild("NativeParameterResolver"))

local RepairSystem = {}
RepairSystem.__index = RepairSystem

export type Config = {
	REPAIR_MODE_COOLDOWN: number,
	REPAIR_MODE_ACTIVE_TIME: number,
	REPAIR_MODE_RADIUS: number,
	REPAIR_MODE_POWER: number,
	PLAYER_REPAIR_TIME: number,
	PLAYER_REPAIR_AMOUNT: number,
	AI_REPAIR_TIME: number,
	AI_REPAIR_AMOUNT: number,
	FIGHTER_REPAIR_TIME: number,
	FIGHTER_REPAIR_AMOUNT: number,
}
export type Mode = "Idle" | "Active" | "Cooldown"
export type TargetResolver = (ship: Model, radius: number) -> { BasePart }

local function native(key: string): number
	local value = NativeParameterResolver.Get(key)
	assert(typeof(value) == "number", "native repair parameter must be numeric: " .. key)
	return value
end

function RepairSystem.NativeConfig(): Config
	return {
		REPAIR_MODE_COOLDOWN = native("REPAIR_MODE_COOLDOWN") / 50,
		REPAIR_MODE_ACTIVE_TIME = native("REPAIR_MODE_ACTIVE_TIME") / 50,
		REPAIR_MODE_RADIUS = native("REPAIR_MODE_RADIUS"),
		REPAIR_MODE_POWER = native("REPAIR_MODE_POWER"),
		PLAYER_REPAIR_TIME = native("PLAYER_REPAIR_TIME") / 50,
		PLAYER_REPAIR_AMOUNT = native("PLAYER_REPAIR_AMOUNT"),
		AI_REPAIR_TIME = native("AI_REPAIR_TIME") / 50,
		AI_REPAIR_AMOUNT = native("AI_REPAIR_AMOUNT"),
		FIGHTER_REPAIR_TIME = native("FIGHTER_REPAIR_TIME") / 50,
		FIGHTER_REPAIR_AMOUNT = native("FIGHTER_REPAIR_AMOUNT"),
	}
end

function RepairSystem.new(ship: Model, config: Config?, resolveTargets: TargetResolver)
	assert(ship and ship:IsA("Model"), "RepairSystem.new expects ship Model")
	assert(type(resolveTargets) == "function", "RepairSystem.new expects target resolver")
	return setmetatable({ Ship = ship, Config = config or RepairSystem.NativeConfig(), ResolveTargets = resolveTargets, Mode = "Idle" :: Mode, StartedAt = 0, LastUsedAt = -math.huge, Elapsed = 0 }, RepairSystem)
end
function RepairSystem:CanActivate(now: number?): boolean
	now = now or os.clock()
	return self.Mode == "Idle" and now - self.LastUsedAt >= self.Config.REPAIR_MODE_COOLDOWN
end
function RepairSystem:Activate(now: number?): (boolean, string?)
	now = now or os.clock()
	if not self:CanActivate(now) then return false, "Repair mode unavailable" end
	self.Mode = "Active"; self.StartedAt = now; self.Elapsed = 0; self.LastUsedAt = now
	return true, nil
end
function RepairSystem:Deactivate() if self.Mode == "Active" then self.Mode = "Cooldown"; self.Elapsed = 0 end end
function RepairSystem:Step(dt: number)
	if dt <= 0 or dt ~= dt or dt == math.huge then return end
	if self.Mode == "Active" then
		self.Elapsed += dt
		if self.Elapsed >= self.Config.REPAIR_MODE_ACTIVE_TIME then self:Deactivate() end
	elseif self.Mode == "Cooldown" then
		self.Elapsed += dt
		if self.Elapsed >= self.Config.REPAIR_MODE_COOLDOWN then self.Mode = "Idle"; self.Elapsed = 0 end
	end
end
function RepairSystem:RepairTargets(amount: number?): number
	if self.Mode ~= "Active" then return 0 end
	local repairAmount = amount or self.Config.REPAIR_MODE_POWER
	if repairAmount <= 0 or repairAmount ~= repairAmount or repairAmount == math.huge or repairAmount == -math.huge then return 0 end
	local repaired = 0
	for _, part in ipairs(self.ResolveTargets(self.Ship, self.Config.REPAIR_MODE_RADIUS)) do
		if part.Parent and ComponentAuthority.IsComponent(part) then
			local _, applied = ComponentAuthority.Repair(part, repairAmount)
			repaired += applied
		end
	end
	return repaired
end
function RepairSystem:GetMode(): Mode return self.Mode end
return RepairSystem
