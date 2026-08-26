--[[
	MassPoint: Represents a point mass contribution to a 2D rigid body.
	Sourced from AlterOrb / FunOrb component mass distribution.
	
	LocalPosition is relative to the rigid body's root transform (Chassis Core).
	LocalInertia accounts for the component's internal geometry resistance to spin.
]]

local MassPoint = {}
MassPoint.__index = MassPoint

export type MassPoint = {
	Id: string,
	Mass: number,
	LocalPosition: Vector2,
	LocalInertia: number,
	PieceType: string?,
	UserData: any?,
	
	GetDistanceToCOM: (self: MassPoint, com: Vector2) -> number,
	CalculateInertiaContribution: (self: MassPoint, com: Vector2) -> number,
}

function MassPoint.new(mass: number, localPosition: Vector2?, localInertia: number?, pieceType: string?, id: string?)
	local self = setmetatable({}, MassPoint)
	self.Id = id or ("mp_" .. tostring(math.random(100000, 999999)))
	self.Mass = math.max(0.1, mass or 10)
	self.LocalPosition = localPosition or Vector2.zero
	-- Baseline local inertia of a 1x1 block piece: I = 1/6 * m * s^2
	self.LocalInertia = localInertia or (self.Mass * 0.5)
	self.PieceType = pieceType or "GenericPiece"
	self.UserData = nil
	return self
end

-- Calculates the distance from this point mass to the aggregate Center of Mass
function MassPoint:GetDistanceToCOM(com: Vector2): number
	return (self.LocalPosition - com).Magnitude
end

-- Parallel Axis Theorem: I_contrib = I_local + Mass * d^2
function MassPoint:CalculateInertiaContribution(com: Vector2): number
	local distSq = (self.LocalPosition - com).MagnitudeSq
	return self.LocalInertia + (self.Mass * distSq)
end

return MassPoint
