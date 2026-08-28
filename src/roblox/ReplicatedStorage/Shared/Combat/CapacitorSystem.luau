--!strict
--[=[
	CapacitorSystem: Power distribution and capacitor runtime model.

	Native resource keys are resolved through NativeResourceProfile. No Roblox
	unit conversion is performed here; later execution mapping owns that step.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local NativeResourceProfile = require(script.Parent:WaitForChild("NativeResourceProfile"))

local CapacitorSystem = {}
CapacitorSystem.__index = CapacitorSystem

-- These are deliberately not presented as recovered native constants. They are
-- only compatibility defaults for ships that contain no explicit power data.
local DEFAULT_MAX_ENERGY = 100
local DEFAULT_BASE_REGEN = 8
local BROWNOUT_THRESHOLD = 5
local OVERCHARGE_MULTIPLIER = 1.25

local shipCapacitors: { [Model]: any } = setmetatable({}, { __mode = "k" })

local function getDefinition(part: Instance): any?
	if not part:IsA("BasePart") then return nil end
	local typeName = part:GetAttribute("ComponentType")
	if typeof(typeName) ~= "string" or typeName == "" then return nil end
	local definition = Components.Types[typeName]
	return type(definition) == "table" and definition or nil
end

function CapacitorSystem.NativeConfig(): { BurstFireMaxEnergy: number, BurstFireRegenerationRate: number, BurstFireReload: number }
	local maxEnergy = NativeResourceProfile.GetRaw("Combat", "BurstFireMaxEnergy")
	local regen = NativeResourceProfile.GetRaw("Combat", "BurstFireRegenerationRate")
	local reload = NativeResourceProfile.GetRaw("Combat", "BurstFireReload")
	assert(maxEnergy and regen and reload, "native capacitor configuration unavailable")
	return { BurstFireMaxEnergy = maxEnergy, BurstFireRegenerationRate = regen, BurstFireReload = reload }
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
	if not shipModel or not shipModel:IsA("Model") then return end
	local previousMax = self.MaxEnergy
	local totalRegen, totalCapacityBoost = 0, 0
	local hasPowerComponent = false
	for _, instance in ipairs(shipModel:GetDescendants()) do
		local definition = getDefinition(instance)
		if definition then
			local energyRegen = definition.EnergyRegen
			if typeof(energyRegen) == "number" and energyRegen > 0 then totalRegen += energyRegen; hasPowerComponent = true end
			local maxEnergyBoost = definition.MaxEnergyBoost
			if typeof(maxEnergyBoost) == "number" and maxEnergyBoost > 0 then totalCapacityBoost += maxEnergyBoost; hasPowerComponent = true end
			local energyCapacity = definition.EnergyCapacity
			if typeof(energyCapacity) == "number" and energyCapacity > 0 then totalCapacityBoost += energyCapacity; hasPowerComponent = true end
		end
	end
	if hasPowerComponent then
		self.MaxEnergy = DEFAULT_MAX_ENERGY + totalCapacityBoost
		self.BaseRegen = totalRegen > 0 and totalRegen or DEFAULT_BASE_REGEN
	else
		self.MaxEnergy, self.BaseRegen = DEFAULT_MAX_ENERGY, DEFAULT_BASE_REGEN
	end
	if previousMax > 0 and self.CurrentEnergy == previousMax then self.CurrentEnergy = self.MaxEnergy else self.CurrentEnergy = math.clamp(self.CurrentEnergy, 0, self.MaxEnergy) end
	self.OverchargeCapacity = self.MaxEnergy * OVERCHARGE_MULTIPLIER
	shipCapacitors[shipModel] = self
	shipModel:SetAttribute("EnergyPercent", self:GetEnergyPercent())
	shipModel:SetAttribute("EnergyCapacity", self.MaxEnergy)
end

function CapacitorSystem.RegisterShip(shipModel: Model): any
	assert(shipModel and shipModel:IsA("Model"), "CapacitorSystem.RegisterShip expects a ship Model")
	local existing = shipCapacitors[shipModel]
	if existing then return existing end
	local capacitor = CapacitorSystem.new()
	capacitor:CalculateFromShip(shipModel)
	return capacitor
end

function CapacitorSystem.GetForShip(shipModel: Model): any? return shipCapacitors[shipModel] end
function CapacitorSystem.UnregisterShip(shipModel: Model) shipCapacitors[shipModel] = nil end

function CapacitorSystem:Consume(amount: number): boolean
	if typeof(amount) ~= "number" or amount < 0 or amount ~= amount or amount == math.huge then return false end
	if self.CurrentEnergy < amount then return false end
	self.CurrentEnergy -= amount
	return true
end
function CapacitorSystem:Recharge(dt: number)
	if typeof(dt) ~= "number" or dt <= 0 or dt ~= dt or dt == math.huge then return end
	self.CurrentEnergy = math.min(self.MaxEnergy, self.CurrentEnergy + self.BaseRegen * dt)
end
function CapacitorSystem:Drain(amount: number)
	if typeof(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then return end
	self.CurrentEnergy = math.max(0, self.CurrentEnergy - amount)
end
function CapacitorSystem:GetEnergyPercent(): number
	if self.MaxEnergy <= 0 then return 0 end
	return math.clamp(self.CurrentEnergy / self.MaxEnergy, 0, 1)
end
function CapacitorSystem:IsBrownout(): boolean return self.CurrentEnergy <= BROWNOUT_THRESHOLD end

return CapacitorSystem
