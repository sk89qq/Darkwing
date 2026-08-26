--[=[
	CapacitorSystem: Power distribution and capacitor runtime model.

	Authority rules:
	- Component identity is explicit ComponentType metadata.
	- Component configuration comes from VoidHunterComponents.Types.
	- Instance.Name is never used as gameplay state or component identity.
	- Exact source numerical parity remains IMPLEMENTED / PARTIAL where the
	  decompiled power equations are not fully recovered.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))

local CapacitorSystem = {}
CapacitorSystem.__index = CapacitorSystem

local DEFAULT_MAX_ENERGY = 100
local DEFAULT_BASE_REGEN = 8
local BROWNOUT_THRESHOLD = 5
local OVERCHARGE_MULTIPLIER = 1.25

local function getDefinition(part: Instance): any?
	if not part:IsA("BasePart") then
		return nil
	end
	local typeName = part:GetAttribute("ComponentType")
	if typeof(typeName) ~= "string" or typeName == "" then
		return nil
	end
	local definition = Components.Types[typeName]
	return type(definition) == "table" and definition or nil
end

function CapacitorSystem.new(maxEnergy: number?, baseRegen: number?)
	local self = setmetatable({}, CapacitorSystem)
	self.MaxEnergy = maxEnergy or DEFAULT_MAX_ENERGY
	self.CurrentEnergy = self.MaxEnergy
	self.BaseRegen = baseRegen or DEFAULT_BASE_REGEN
	self.OverchargeCapacity = self.MaxEnergy * OVERCHARGE_MULTIPLIER
	return self
end

function CapacitorSystem:CalculateFromShip(shipModel: Model)
	if not shipModel or not shipModel:IsA("Model") then
		return
	end

	local totalRegen = 0
	local totalCapacityBoost = 0
	local hasPowerComponent = false

	for _, instance in ipairs(shipModel:GetDescendants()) do
		local definition = getDefinition(instance)
		if definition then
			local energyRegen = definition.EnergyRegen
			if typeof(energyRegen) == "number" and energyRegen > 0 then
				totalRegen += energyRegen
			hasPowerComponent = true
			end

			local maxEnergyBoost = definition.MaxEnergyBoost
			if typeof(maxEnergyBoost) == "number" and maxEnergyBoost > 0 then
				totalCapacityBoost += maxEnergyBoost
				hasPowerComponent = true
			end

			local energyCapacity = definition.EnergyCapacity
			if typeof(energyCapacity) == "number" and energyCapacity > 0 then
				totalCapacityBoost += energyCapacity
				hasPowerComponent = true
			end
		end
	end

	-- The base 100 energy pool is an existing prototype rule, not a component
	-- identity inference. Component definitions may explicitly extend it.
	if hasPowerComponent then
		self.MaxEnergy = DEFAULT_MAX_ENERGY + totalCapacityBoost
		self.BaseRegen = totalRegen > 0 and totalRegen or DEFAULT_BASE_REGEN
	else
		self.MaxEnergy = DEFAULT_MAX_ENERGY
		self.BaseRegen = DEFAULT_BASE_REGEN
	end

	self.CurrentEnergy = math.clamp(self.CurrentEnergy, 0, self.MaxEnergy)
	self.OverchargeCapacity = self.MaxEnergy * OVERCHARGE_MULTIPLIER
end

function CapacitorSystem:Consume(amount: number): boolean
	if typeof(amount) ~= "number" or amount < 0 or amount ~= amount or amount == math.huge then
		return false
	end
	if self.CurrentEnergy < amount then
		return false
	end
	self.CurrentEnergy -= amount
	return true
end

function CapacitorSystem:Recharge(dt: number)
	if typeof(dt) ~= "number" or dt <= 0 or dt ~= dt or dt == math.huge then
		return
	end
	self.CurrentEnergy = math.min(self.MaxEnergy, self.CurrentEnergy + self.BaseRegen * dt)
end

function CapacitorSystem:Drain(amount: number)
	if typeof(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
		return
	end
	self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
end

function CapacitorSystem:GetEnergyPercent(): number
	if self.MaxEnergy <= 0 then
		return 0
	end
	return math.clamp(self.CurrentEnergy / self.MaxEnergy, 0, 1)
end

function CapacitorSystem:IsBrownout(): boolean
	return self.CurrentEnergy <= BROWNOUT_THRESHOLD
end

return CapacitorSystem
