--[=[
	CapacitorSystem: Power Distribution & Capacitor Management Engine.

	STATUS: IMPLEMENTED / FORENSIC PARITY PARTIAL
	The client exposes energy/power configuration keys, but exact component-to-power
	formulas are not yet fully reconciled. Current numeric values are prototype values.

	Prefer explicit component Attributes when available; keep compatibility name
	matching only as a temporary fallback.
]=]

local CapacitorSystem = {}
CapacitorSystem.__index = CapacitorSystem

function CapacitorSystem.new(maxEnergy: number?, baseRegen: number?)
	local self = setmetatable({}, CapacitorSystem)
	self.MaxEnergy = maxEnergy or 100.0 -- [INFERRED]
	self.CurrentEnergy = self.MaxEnergy
	self.BaseRegen = baseRegen or 8.0 -- [INFERRED]
	self.OverchargeCapacity = self.MaxEnergy * 1.25 -- [INFERRED]
	return self
end

function CapacitorSystem:CalculateFromShip(shipModel: Model)
	local totalCap = 0.0
	local totalRegen = 0.0

	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local capacity = part:GetAttribute("EnergyCapacity")
			local regen = part:GetAttribute("EnergyRegen")
			if typeof(capacity) == "number" then totalCap += capacity end
			if typeof(regen) == "number" then totalRegen += regen end
		end
	end

	if totalCap <= 0 then
		-- Compatibility fallback for existing prototype content. This is not
		-- considered original-code-verified and must be removed once the exact
		-- power-plant behavior is ported.
		totalCap = 100.0
		totalRegen = 8.0
		for _, part in ipairs(shipModel:GetDescendants()) do
			if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
				local name = part.Name
				if string.find(name, "Reactor") then
					totalCap += 50.0
					totalRegen += 12.0
				elseif string.find(name, "Capacitor") or string.find(name, "Battery") then
					totalCap += 75.0
					totalRegen += 4.0
				end
			end
		end
	end

	self.MaxEnergy = totalCap
	self.BaseRegen = totalRegen
	self.CurrentEnergy = math.min(self.CurrentEnergy, totalCap)
end

function CapacitorSystem:Consume(amount: number): boolean
	if typeof(amount) ~= "number" or amount < 0 or self.CurrentEnergy < amount then
		return false
	end
	self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
	return true
end

function CapacitorSystem:Recharge(dt: number)
	if dt <= 0 then return end
	self.CurrentEnergy = math.min(self.MaxEnergy, self.CurrentEnergy + self.BaseRegen * dt)
end

function CapacitorSystem:Drain(amount: number)
	if typeof(amount) ~= "number" or amount <= 0 then return end
	self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
end

function CapacitorSystem:GetEnergyPercent(): number
	return self.MaxEnergy > 0 and self.CurrentEnergy / self.MaxEnergy or 0
end

function CapacitorSystem:IsBrownout(): boolean
	return self.CurrentEnergy <= 5.0 -- [INFERRED prototype threshold]
end

return CapacitorSystem
