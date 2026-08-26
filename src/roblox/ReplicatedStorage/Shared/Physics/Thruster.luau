--[[
	Thruster: Modular ship thruster component model.
	Sourced from AlterOrb / FunOrb Client Engine Decompile.
	
	Calculates directional propulsion and torque moment relative to the ship's Center of Mass.
	Asymmetric placement generates rotational torque, reproducing authentic Void Hunters physics.
]]

local Thruster = {}
Thruster.__index = Thruster

export type Thruster = {
	Id: string,
	LocalPosition: Vector2,
	Direction: Vector2,       -- Local unit direction vector (e.g. Vector2.new(0, 1) = Forward Thrust)
	ThrustMagnitude: number,  -- Maximum thrust force in Newtons/studs
	EnergyDrainPerSec: number,
	IsActive: boolean,
	ThrusterType: string,     -- "Main", "Vector", "Booster", "Retro"
	
	ApplyToBody: (self: Thruster, body: any, throttle: number) -> number,
}

function Thruster.new(localPosition: Vector2, direction: Vector2?, thrustMagnitude: number?, thrusterType: string?, id: string?)
	local self = setmetatable({}, Thruster)
	
	self.Id = id or ("th_" .. tostring(math.random(100000, 999999)))
	self.LocalPosition = localPosition or Vector2.zero
	self.Direction = direction and direction.Unit or Vector2.new(0, 1) -- Defaults to forward propulsion
	self.ThrusterType = thrusterType or "Main"
	
	if self.ThrusterType == "Booster" then
		self.ThrustMagnitude = thrustMagnitude or 850.0
		self.EnergyDrainPerSec = 25.0
	elseif self.ThrusterType == "Vector" then
		self.ThrustMagnitude = thrustMagnitude or 250.0
		self.EnergyDrainPerSec = 8.0
	else
		self.ThrustMagnitude = thrustMagnitude or 450.0
		self.EnergyDrainPerSec = 12.0
	end
	
	self.IsActive = false
	return self
end

-- Applies propulsion force and induced torque to the parent RigidBody2D
-- Returns the energy consumed during this tick
function Thruster:ApplyToBody(body: any, throttle: number, dt: number): number
	if not self.IsActive or throttle <= 0 or not body then return 0 end
	
	local clampedThrottle = math.clamp(throttle, 0, 1)
	local effectiveForce = self.ThrustMagnitude * clampedThrottle
	
	-- Apply force at the thruster's local position on the hull
	body:ApplyThrust(self.LocalPosition, self.Direction, effectiveForce)
	
	return self.EnergyDrainPerSec * clampedThrottle * dt
end

return Thruster
