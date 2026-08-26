--[[
	ShieldSystem: Tactical Shield Bubble & Deflection Engine.

	STATUS: IMPLEMENTED / FORENSIC PARITY PARTIAL
	The decompiled client confirms directional shield parameters, but the exact
	control flow and numerical absorption model are not fully recovered here.
	Therefore the values below are PROTOTYPE/INFERRED, not CODE_VERIFIED.

	Do not expand this model as if it were original behavior until the source
	shield behaviour/config consumers are traced.
]]

local CombatTypes = require(game.ReplicatedStorage.Shared.Combat.CombatTypes)

local ShieldSystem = {}
ShieldSystem.__index = ShieldSystem

-- [INFERRED] Prototype absorption matrix retained for current playability.
local SHIELD_DAMAGE_MODIFIERS = {
	Kinetic = 0.70,
	Thermal = 1.00,
	Energy = 1.25,
	Explosive = 0.85,
	EMP = 2.50,
}

function ShieldSystem.new(maxHP: number?, regenRate: number?, radius: number?)
	local self = setmetatable({}, ShieldSystem)
	self.MaxHP = maxHP or 150.0 -- [INFERRED]
	self.CurrentHP = self.MaxHP
	self.RegenRate = regenRate or 15.0 -- [INFERRED]
	self.RebootDelay = 3.5 -- [INFERRED]
	self.TimeSinceDamage = 0.0
	self.IsActive = true
	self.Radius = radius or 12.0 -- [INFERRED]
	self.VisualPart = nil :: BasePart?
	return self
end

function ShieldSystem:CalculateFromShip(shipModel: Model)
	local totalShield = 0.0
	local totalRegen = 0.0
	local maxRadius = 10.0

	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local typeName = part:GetAttribute("ComponentType")
			local definition = typeof(typeName) == "string"
				and shipModel:IsDescendantOf(game)
				and require(game.ReplicatedStorage:WaitForChild("VoidHunterComponents")).Types[typeName]
				or nil
			if type(definition) == "table" then
				local capacity = definition.ShieldCapacity
				local regen = definition.ShieldRegen
				local radius = definition.ShieldRadius
				if typeof(capacity) == "number" and capacity > 0 then totalShield += capacity end
				if typeof(regen) == "number" and regen > 0 then totalRegen += regen end
				if typeof(radius) == "number" and radius > maxRadius then maxRadius = radius end
			end
		end
	end

	if totalShield > 0 then
		self.MaxHP = totalShield
		self.RegenRate = totalRegen
		self.CurrentHP = math.min(self.CurrentHP, totalShield)
		self.Radius = math.max(12.0, maxRadius)
		self.IsActive = self.CurrentHP > 0
	else
		self.MaxHP = 0
		self.CurrentHP = 0
		self.IsActive = false
	end
end

function ShieldSystem:AbsorbDamage(rawDamage: number, damageType: CombatTypes.DamageType): number
	if not self.IsActive or self.CurrentHP <= 0 then
		return rawDamage
	end

	self.TimeSinceDamage = 0.0
	local modifier = SHIELD_DAMAGE_MODIFIERS[damageType] or 1.0
	local effectiveDamage = rawDamage * modifier

	if self.CurrentHP >= effectiveDamage then
		self.CurrentHP -= effectiveDamage
		return 0
	end

	local leftoverEffective = effectiveDamage - self.CurrentHP
	self.CurrentHP = 0
	self.IsActive = false
	return leftoverEffective / modifier
end

function ShieldSystem:Step(dt: number)
	self.TimeSinceDamage += dt

	if self.CurrentHP <= 0 then
		self.IsActive = false
		if self.TimeSinceDamage >= self.RebootDelay and self.MaxHP > 0 then
			self.CurrentHP = self.MaxHP * 0.20 -- [INFERRED]
			self.IsActive = true
		end
	elseif self.CurrentHP < self.MaxHP and self.TimeSinceDamage >= 1.5 then
		self.CurrentHP = math.min(self.MaxHP, self.CurrentHP + self.RegenRate * dt)
		self.IsActive = true
	end
end

function ShieldSystem:GetShieldPercent(): number
	return (self.MaxHP > 0) and (self.CurrentHP / self.MaxHP) or 0
end

return ShieldSystem
