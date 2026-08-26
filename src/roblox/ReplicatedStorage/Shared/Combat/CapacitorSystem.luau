--[[
	CapacitorSystem: Power Distribution & Capacitor Management Engine.
	Sourced from AlterOrb / FunOrb Ship Power Systems.
	
	Features:
	  - Base power capacity scaled with core hull & reactor mass
	  - Dynamic energy drain from weapons, thrusters, and active shields
	  - Brown-out states when energy falls below critical thresholds
	  - Step-based energy regeneration
]]

local CombatTypes = require(game.ReplicatedStorage.Shared.Combat.CombatTypes)

local CapacitorSystem = {}
CapacitorSystem.__index = CapacitorSystem

function CapacitorSystem.new(maxEnergy: number?, baseRegen: number?)
	local self = setmetatable({}, CapacitorSystem)

	self.MaxEnergy = maxEnergy or 100.0
	self.CurrentEnergy = self.MaxEnergy
	self.BaseRegen = baseRegen or 8.0 -- Energy per second
	self.OverchargeCapacity = self.MaxEnergy * 1.25

	return self
end

function CapacitorSystem:CalculateFromShip(shipModel: Model)
	local totalCap = 100.0
	local totalRegen = 8.0

	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local pName = part.Name
			if string.find(pName, "Reactor") then
				totalCap += 50.0
				totalRegen += 12.0
			elseif string.find(pName, "Capacitor") or string.find(pName, "Battery") then
				totalCap += 75.0
				totalRegen += 4.0
			elseif string.find(pName, "Heavy") then
				totalCap += 20.0
			end
		end
	end

	self.MaxEnergy = totalCap
	self.BaseRegen = totalRegen
	self.CurrentEnergy = math.min(self.CurrentEnergy, totalCap)
end

function CapacitorSystem:Consume(amount: number): boolean
	if self.CurrentEnergy >= amount then
		self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
		return true
	end
	return false
end

function CapacitorSystem:Recharge(dt: number)
	self.CurrentEnergy = math.min(self.MaxEnergy, self.CurrentEnergy + self.BaseRegen * dt)
end

function CapacitorSystem:Drain(amount: number)
	self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
end

function CapacitorSystem:GetEnergyPercent(): number
	return (self.MaxEnergy > 0) and (self.CurrentEnergy / self.MaxEnergy) or 0
end

function CapacitorSystem:IsBrownout(): boolean
	return self.CurrentEnergy <= 5.0
end

return CapacitorSystem
