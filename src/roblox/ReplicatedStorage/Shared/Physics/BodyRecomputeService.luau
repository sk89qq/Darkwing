--[=[
	BodyRecomputeService
	Single Roblox-side boundary for rigid-body property recomputation.

	This service intentionally delegates all mass/COM/inertia mathematics to the
	existing canonical RigidBody2D implementation. It does not create a second
	physics model.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RigidBody2D = require(ReplicatedStorage.Shared.Physics:WaitForChild("RigidBody2D"))

local BodyRecomputeService = {}

export type RecomputeResult = {
	Mass: number,
	InverseMass: number,
	CenterOfMass: Vector2,
	MomentOfInertia: number,
	InverseMomentOfInertia: number,
	BoundingRadius: number,
}

function BodyRecomputeService.Recompute(body: any): RecomputeResult?
	if typeof(body) ~= "table" or type(body.RecalculateMassProperties) ~= "function" then
		return nil
	end

	body:RecalculateMassProperties()

	return {
		Mass = body.Mass,
		InverseMass = body.InverseMass,
		CenterOfMass = body.CenterOfMass,
		MomentOfInertia = body.MomentOfInertia,
		InverseMomentOfInertia = body.InverseMomentOfInertia,
		BoundingRadius = body.BoundingRadius,
	}
end

function BodyRecomputeService.RemoveMassPoint(body: any, id: string): RecomputeResult?
	if typeof(body) ~= "table" or type(body.RemoveMassPointById) ~= "function" then
		return nil
	end
	if not body:RemoveMassPointById(id) then
		return nil
	end
	return BodyRecomputeService.Recompute(body)
end

function BodyRecomputeService.AddMassPoint(body: any, mass: number, localPosition: Vector2?, localInertia: number?, pieceType: string?, id: string?): (any?, RecomputeResult?)
	if typeof(body) ~= "table" or type(body.AddMassPoint) ~= "function" then
		return nil, nil
	end
	local massPoint = body:AddMassPoint(mass, localPosition, localInertia, pieceType, id)
	return massPoint, BodyRecomputeService.Recompute(body)
end

function BodyRecomputeService.IsCanonical(body: any): boolean
	return typeof(body) == "table" and getmetatable(body) == RigidBody2D
end

return BodyRecomputeService
