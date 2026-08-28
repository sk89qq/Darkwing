--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ComponentAuthority = require(script.Parent:WaitForChild("ComponentAuthority"))
local NativeResourceProfile = require(script.Parent:WaitForChild("NativeResourceProfile"))
local CombatTypes = require(ReplicatedStorage.Shared.Combat.CombatTypes)

local ShieldSystem = {}
ShieldSystem.__index = ShieldSystem

-- Damage absorption/reboot behavior remains source-unresolved. These modifiers
-- are retained as explicit inferred behavior rather than being mislabeled native.
local SHIELD_DAMAGE_MODIFIERS = {
	Kinetic = 0.70, Thermal = 1.00, Energy = 1.25, Explosive = 0.85, EMP = 2.50,
}

function ShieldSystem.new(maxHP: number?, regenRate: number?, radius: number?)
	local self = setmetatable({}, ShieldSystem)
	self.MaxHP = maxHP or 150.0
	self.CurrentHP = self.MaxHP
	self.RegenRate = regenRate or 15.0
	self.RebootDelay = 3.5
	self.TimeSinceDamage = 0.0
	self.IsActive = true
	self.Radius = radius or NativeResourceProfile.GetRaw("Shield", "DirectionalRadius") or 12.0
	self.DirectionalArc = NativeResourceProfile.GetRaw("Shield", "DirectionalArc")
	self.EnergyUsed = NativeResourceProfile.GetRaw("Shield", "EnergyUsed")
	self.EnergyConversion = NativeResourceProfile.GetRaw("Shield", "EnergyConversion")
	self.VisualPart = nil :: BasePart?
	return self
end

local function getDefinition(part: BasePart): any?
	local state = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
	if not state then return nil end
	local definition = Components.Types[state.TypeName]
	return type(definition) == "table" and definition or nil
end

function ShieldSystem:CalculateFromShip(shipModel: Model)
	local totalShield, totalRegen, maxRadius = 0.0, 0.0, 10.0
	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local definition = getDefinition(part)
			if definition then
				local capacity, regen, radius = definition.ShieldCapacity, definition.ShieldRegen, definition.ShieldRadius
				if typeof(capacity) == "number" and capacity > 0 then totalShield += capacity end
				if typeof(regen) == "number" and regen > 0 then totalRegen += regen end
				if typeof(radius) == "number" and radius > maxRadius then maxRadius = radius end
			end
		end
	end
	if totalShield > 0 then
		self.MaxHP = totalShield; self.RegenRate = totalRegen; self.CurrentHP = math.min(self.CurrentHP, totalShield)
		self.Radius = math.max(self.Radius, maxRadius); self.IsActive = self.CurrentHP > 0
	else
		self.MaxHP, self.CurrentHP, self.IsActive = 0, 0, false
	end
end

function ShieldSystem:AbsorbDamage(rawDamage: number, damageType: CombatTypes.DamageType): number
	if not self.IsActive or self.CurrentHP <= 0 then return rawDamage end
	self.TimeSinceDamage = 0.0
	local modifier = SHIELD_DAMAGE_MODIFIERS[damageType] or 1.0
	local effectiveDamage = rawDamage * modifier
	if self.CurrentHP >= effectiveDamage then self.CurrentHP -= effectiveDamage; return 0 end
	local leftoverEffective = effectiveDamage - self.CurrentHP
	self.CurrentHP = 0; self.IsActive = false
	return leftoverEffective / modifier
end

function ShieldSystem:Step(dt: number)
	self.TimeSinceDamage += dt
	if self.CurrentHP <= 0 then
		self.IsActive = false
		if self.TimeSinceDamage >= self.RebootDelay and self.MaxHP > 0 then self.CurrentHP = self.MaxHP * 0.20; self.IsActive = true end
	elseif self.CurrentHP < self.MaxHP and self.TimeSinceDamage >= 1.5 then
		self.CurrentHP = math.min(self.MaxHP, self.CurrentHP + self.RegenRate * dt); self.IsActive = true
	end
end

function ShieldSystem:GetShieldPercent(): number
	return (self.MaxHP > 0) and (self.CurrentHP / self.MaxHP) or 0
end

return ShieldSystem
