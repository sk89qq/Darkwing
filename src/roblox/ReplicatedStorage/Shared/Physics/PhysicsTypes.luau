--[[
	PhysicsTypes: Strict Luau type definitions for the Void Hunters 2D Physics Engine.
	Operates exclusively on the X-Z gameplay plane using Vector2, with conversion to 3D.
]]

export type MassPointData = {
	Id: string,
	Mass: number,
	LocalPosition: Vector2,
	LocalInertia: number,
	PieceType: string?,
	UserData: any?,
}

export type RaycastHit2D = {
	Hit: boolean,
	Position: Vector2,
	Normal: Vector2,
	Distance: number,
	Body: any?, -- RigidBody2D
	Part: BasePart?,
}

export type CollisionManifold = {
	BodyA: any, -- RigidBody2D
	BodyB: any, -- RigidBody2D
	ContactPoint: Vector2,
	Normal: Vector2, -- Points from BodyA to BodyB
	Penetration: number,
	RelativeVelocity: Vector2,
	Impulse: number,
}

export type ThrusterData = {
	Id: string,
	LocalPosition: Vector2,
	Direction: Vector2,     -- Unit direction vector in ship local space (e.g. Vector2.new(0, 1) = forward thrust)
	ThrustMagnitude: number,
	IsActive: boolean,
}

export type SpringConstraint2D = {
	BodyA: any,
	BodyB: any?, -- If nil, anchors to TargetPosition
	LocalAnchorA: Vector2,
	TargetPosition: Vector2, -- World coordinate target if BodyB is nil
	RestLength: number,
	Stiffness: number,
	Damping: number,
	MaxForce: number,
}

local PhysicsTypes = {}
return PhysicsTypes
