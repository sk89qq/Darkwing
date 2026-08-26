--[[
	ShieldSystem: Tactical Shield Bubble & Deflection Engine.
	Sourced from AlterOrb / FunOrb Shield Mechanics.
	
	Features:
	  - Absorption damage type matrix (Kinetic vs Thermal vs Energy vs EMP)
	  - Broken shield reboot delay & gradual recharge
	  - 2D perimeter bounds check before projectile reaches physical hull components
]]

local CombatTypes = require(game.ReplicatedStorage.Shared.Combat.CombatTypes)

local ShieldSystem = {}
ShieldSystem.__index = ShieldSystem

-- Multipliers applied to shield health when absorbing specific damage types
local SHIELD_DAMAGE_MODIFIERS = {
	Kinetic = 0.70,   -- Shields resist kinetic bullets moderately
	Thermal = 1.00,   -- Standard thermal absorption
	Energy = 1.25,    -- Lasers burn through shield faster
	Explosive = 0.85, -- Explosive blast partially absorbed
	EMP = 2.50,       -- EMP severely drains/overloads shields
}

function ShieldSystem.new(maxHP: number?, regenRate: number?, radius: number?)
	local self = setmetatable({}, ShieldSystem)

	self.MaxHP = maxHP or 150.0
	self.CurrentHP = self.MaxHP
	self.RegenRate = regenRate or 15.0 -- HP per second
	self.RebootDelay = 3.5             -- Seconds before recharge after breaking
	self.TimeSinceDamage = 0.0
	self.IsActive = true
	self.Radius = radius or 12.0
	self.VisualPart = nil :: BasePart?

	return self
end

function ShieldSystem:CalculateFromShip(shipModel: Model)
	local totalShield = 0.0
	local totalRegen = 0.0
	local maxRadius = 10.0

	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local pName = part.Name
			if string.find(pName, "Shield") or string.find(pName, "Deflector") then
				totalShield += 100.0
				totalRegen += 10.0
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
		return rawDamage -- Full damage passes directly to hull
	end

	self.TimeSinceDamage = 0.0
	local modifier = SHIELD_DAMAGE_MODIFIERS[damageType] or 1.0
	local effectiveDamage = rawDamage * modifier

	if self.CurrentHP >= effectiveDamage then
		self.CurrentHP -= effectiveDamage
		return 0 -- Completely absorbed
	else
		local leftoverEffective = effectiveDamage - self.CurrentHP
		self.CurrentHP = 0
		self.IsActive = false
		-- Convert leftover back to unabsorbed raw damage for hull penetration
		return leftoverEffective / modifier
	end
end

function ShieldSystem:Step(dt: number)
	self.TimeSinceDamage += dt

	if self.CurrentHP <= 0 then
		self.IsActive = false
		if self.TimeSinceDamage >= self.RebootDelay and self.MaxHP > 0 then
			self.CurrentHP = self.MaxHP * 0.20 -- Reboots with 20% integrity
			self.IsActive = true
		end
	elseif self.CurrentHP < self.MaxHP then
		if self.TimeSinceDamage >= 1.5 then
			self.CurrentHP = math.min(self.MaxHP, self.CurrentHP + self.RegenRate * dt)
			self.IsActive = true
		end
	end
end

function ShieldSystem:GetShieldPercent(): number
	return (self.MaxHP > 0) and (self.CurrentHP / self.MaxHP) or 0
end

return ShieldSystem
