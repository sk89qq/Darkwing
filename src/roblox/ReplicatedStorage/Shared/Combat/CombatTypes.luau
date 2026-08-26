--[[
	CombatTypes: Type definitions for the Tactical Combat, Ballistics, and Energy Systems.
	Roblox runtime contract for the shared combat authorities.
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
	Position: Vector2,
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
	OverchargeCapacity: number,
}

local CombatTypes = {}
return CombatTypes
