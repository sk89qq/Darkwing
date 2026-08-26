--[=[
	RepairSystem

	Roblox-first repair authority based on the recovered Void Hunters repair
	semantics. ComponentAuthority remains the sole owner of component health.

	Confirmed source behavior:
	- ml.a(boolean, boolean, int) adds health.
	- Health is capped by the component definition maximum (`wfb.p`).
	- Child components may receive overflow depending on flags.

	Known configuration family:
	- REPAIR_MODE_COOLDOWN
	- REPAIR_MODE_ACTIVE_TIME
	- REPAIR_MODE_RADIUS
	- REPAIR_MODE_POWER
	- PLAYER_REPAIR_TIME
	- PLAYER_REPAIR_AMOUNT
	- AI_REPAIR_TIME
	- AI_REPAIR_AMOUNT
	- FIGHTER_REPAIR_TIME
	- FIGHTER_REPAIR_AMOUNT

	Numeric values and exact overflow-selection flags are supplied by the
	caller until their native consumers are recovered.
]=]

local ComponentAuthority = require(script.Parent:WaitForChild("ComponentAuthority"))

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

local RepairSystem = {}
RepairSystem.__index = RepairSystem

function RepairSystem.new(ship: Model, config: Config, resolveTargets: TargetResolver)
	assert(ship and ship:IsA("Model"), "RepairSystem.new expects ship Model")
	assert(type(resolveTargets) == "function", "RepairSystem.new expects target resolver")

	return setmetatable({
		Ship = ship,
		Config = config,
		ResolveTargets = resolveTargets,
		Mode = "Idle" :: Mode,
		StartedAt = 0,
		LastUsedAt = -math.huge,
		Elapsed = 0,
	}, RepairSystem)
end

function RepairSystem:CanActivate(now: number?): boolean
	now = now or os.clock()
	return self.Mode == "Idle" and now - self.LastUsedAt >= self.Config.REPAIR_MODE_COOLDOWN
end

function RepairSystem:Activate(now: number?): (boolean, string?)
	now = now or os.clock()
	if not self:CanActivate(now) then
		return false, "Repair mode unavailable"
	end

	self.Mode = "Active"
	self.StartedAt = now
	self.Elapsed = 0
	self.LastUsedAt = now
	return true, nil
end

function RepairSystem:Deactivate()
	if self.Mode == "Active" then
		self.Mode = "Cooldown"
		self.Elapsed = 0
	end
end

function RepairSystem:Step(dt: number)
	if dt <= 0 or dt ~= dt or dt == math.huge then
		return
	end
	if self.Mode == "Active" then
		self.Elapsed += dt
		if self.Elapsed >= self.Config.REPAIR_MODE_ACTIVE_TIME then
			self:Deactivate()
		end
	elseif self.Mode == "Cooldown" then
		self.Elapsed += dt
		if self.Elapsed >= self.Config.REPAIR_MODE_COOLDOWN then
			self.Mode = "Idle"
			self.Elapsed = 0
		end
	end
end

function RepairSystem:RepairTargets(amount: number): number
	if self.Mode ~= "Active" then
		return 0
	end
	if amount <= 0 or amount ~= amount or amount == math.huge or amount == -math.huge then
		return 0
	end

	local repaired = 0
	for _, part in ipairs(self.ResolveTargets(self.Ship, self.Config.REPAIR_MODE_RADIUS)) do
		if part.Parent and ComponentAuthority.IsComponent(part) then
			local _, applied = ComponentAuthority.Repair(part, amount)
			repaired += applied
		end
	end
	return repaired
end

function RepairSystem:GetMode(): Mode
	return self.Mode
end

return RepairSystem
