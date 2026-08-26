--[[
	CombatTypes: Type definitions for the Tactical Combat, Ballistics, and Energy Systems.
	Sourced from AlterOrb / FunOrb Combat Decompile Mechanics.
]]

export type DamageType = "Kinetic" | "Thermal" | "Energy" | "Explosive" | "EMP"

export type ProjectileData = {
	Id: string,
	Type: string,
	DamageType: DamageType,
	BaseDamage: number,
	TickDamage: number?,
	SplashRadius: number?,
	Speed: number,
	Range: number,
	Position: Vector2, -- 2D X-Z plane
	Velocity: Vector2,
	Origin: Vector2,
	DistanceTraveled: number,
	ShooterId: string,
	ShooterTeam: string?,
	Color: Color3,
	Size: Vector3,
	Lifetime: number,
	VisualPart: BasePart?,
	HomingTarget: any?,
	HomingTurnRate: number?,
	ImpulseMagnitude: number,
}

export type ShieldState = {
	MaxHP: number,
	CurrentHP: number,
	RegenRate: number,
	RebootDelay: number,
	TimeSinceDamage: number,
	IsActive: boolean,
	Radius: number,
	VisualPart: BasePart?,
}

export type CapacitorState = {
	MaxEnergy: number,
	CurrentEnergy: number,
	BaseRegen: number,
	EffectiveRegen: number,
	Overcharged: boolean,
}

local CombatTypes = {}
return CombatTypes
