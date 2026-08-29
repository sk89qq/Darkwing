--[[
	RigidBody2D: Core 2D Rigid Body Kinematics & Dynamics Engine.
	Sourced from AlterOrb / FunOrb Client Engine Decompile & Tuned for Roblox X-Z Plane.

	Coordinate Space:
	  - 2D Logical Space: Vector2(X, Z) where X is lateral/starboard and Z is forward/longitudinal.
	  - Rotation: Radians (Yaw angle around world Y-axis).
	  - World 3D Translation: Vector3(Position.X, FIXED_Y, Position.Y).
]]

local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)
local MassPoint = require(game.ReplicatedStorage.Shared.Physics.MassPoint)
local NativeVelocityOperator = require(game.ReplicatedStorage.Shared.Physics.NativeVelocityOperator)

local RigidBody2D = {}
RigidBody2D.__index = RigidBody2D

local function rotate2D(vec: Vector2, angle: number): Vector2
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	return Vector2.new(
		vec.X * cos - vec.Y * sin,
		vec.X * sin + vec.Y * cos
	)
end

local function cross2D(a: Vector2, b: Vector2): number
	return (a.X * b.Y) - (a.Y * b.X)
end

function RigidBody2D.new(initialPos: Vector2?, initialRot: number?, id: string?)
	local self = setmetatable({}, RigidBody2D)

	self.Id = id or ("rb2d_" .. tostring(math.random(100000, 999999)))
	self.IsStatic = false
	self.IsActive = true
	self.CollisionGroup = "Default"
	self.Restitution = PhysicsConfig.DEFAULT_RESTITUTION

	self.Position = initialPos or Vector2.zero
	self.Velocity = Vector2.zero
	self.Rotation = initialRot or 0
	self.AngularVelocity = 0

	self.MassPoints = {} :: { any }
	self.Mass = PhysicsConfig.BASE_CHASSIS_MASS
	self.InverseMass = 1 / self.Mass
	self.CenterOfMass = Vector2.zero
	self.MomentOfInertia = PhysicsConfig.BASE_CHASSIS_INERTIA
	self.InverseMomentOfInertia = 1 / self.MomentOfInertia
	self.BoundingRadius = 10.0

	self.ForceAccumulator = Vector2.zero
	self.TorqueAccumulator = 0

	self.BoundModel = nil :: Model?
	self.BoundPart = nil :: BasePart?
	self.FixedY = PhysicsConfig.FIXED_Y_ELEVATION

	return self
end

function RigidBody2D:AddMassPoint(mass: number, localPosition: Vector2?, localInertia: number?, pieceType: string?, id: string?)
	local mp = MassPoint.new(mass, localPosition, localInertia, pieceType, id)
	table.insert(self.MassPoints, mp)
	self:RecalculateMassProperties()
	return mp
end

function RigidBody2D:RemoveMassPointById(id: string): boolean
	for i, mp in ipairs(self.MassPoints) do
		if mp.Id == id then
			table.remove(self.MassPoints, i)
			self:RecalculateMassProperties()
			return true
		end
	end
	return false
end

function RigidBody2D:ClearMassPoints()
	self.MassPoints = {}
	self:RecalculateMassProperties()
end

function RigidBody2D:RecalculateMassProperties()
	if self.IsStatic then
		self.Mass = math.huge
		self.InverseMass = 0
		self.MomentOfInertia = math.huge
		self.InverseMomentOfInertia = 0
		self.CenterOfMass = Vector2.zero
		return
	end

	local count = #self.MassPoints
	if count == 0 then
		self.Mass = PhysicsConfig.BASE_CHASSIS_MASS
		self.InverseMass = 1 / self.Mass
		self.CenterOfMass = Vector2.zero
		self.MomentOfInertia = PhysicsConfig.BASE_CHASSIS_INERTIA
		self.InverseMomentOfInertia = 1 / self.MomentOfInertia
		self.BoundingRadius = 8.0
		return
	end

	local totalMass = 0
	local weightedPos = Vector2.zero
	for _, mp in ipairs(self.MassPoints) do
		totalMass += mp.Mass
		weightedPos += mp.Mass * mp.LocalPosition
	end

	self.Mass = math.max(0.1, totalMass)
	self.InverseMass = 1 / self.Mass
	self.CenterOfMass = weightedPos / self.Mass

	local totalInertia = 0
	local maxRadiusSq = 0
	for _, mp in ipairs(self.MassPoints) do
		totalInertia += mp:CalculateInertiaContribution(self.CenterOfMass)
		local distSq = (mp.LocalPosition - self.CenterOfMass).MagnitudeSq
		if distSq > maxRadiusSq then
			maxRadiusSq = distSq
		end
	end

	self.MomentOfInertia = math.max(PhysicsConfig.MIN_MOMENT_OF_INERTIA, totalInertia)
	self.InverseMomentOfInertia = 1 / self.MomentOfInertia
	self.BoundingRadius = math.max(6.0, math.sqrt(maxRadiusSq) + 4.0)
end

function RigidBody2D:SetStatic(isStatic: boolean)
	self.IsStatic = isStatic
	self:RecalculateMassProperties()
	if isStatic then
		self.Velocity = Vector2.zero
		self.AngularVelocity = 0
	end
end

function RigidBody2D:ClearAccumulators()
	self.ForceAccumulator = Vector2.zero
	self.TorqueAccumulator = 0
end

function RigidBody2D:AddForce(worldForce: Vector2)
	if self.IsStatic then return end
	self.ForceAccumulator += worldForce
end

function RigidBody2D:AddTorque(torque: number)
	if self.IsStatic then return end
	self.TorqueAccumulator += torque
end

function RigidBody2D:AddForceAtLocalPoint(localForce: Vector2, localPoint: Vector2)
	if self.IsStatic then return end
	local worldForce = rotate2D(localForce, self.Rotation)
	self.ForceAccumulator += worldForce

	local rLocal = localPoint - self.CenterOfMass
	local rWorld = rotate2D(rLocal, self.Rotation)
	local torque = cross2D(rWorld, worldForce)
	self.TorqueAccumulator += torque
end

function RigidBody2D:AddForceAtWorldPoint(worldForce: Vector2, worldPoint: Vector2)
	if self.IsStatic then return end
	self.ForceAccumulator += worldForce

	local worldCOM = self:GetWorldCenterOfMass()
	local rWorld = worldPoint - worldCOM
	local torque = cross2D(rWorld, worldForce)
	self.TorqueAccumulator += torque
end

function RigidBody2D:ApplyThrust(localThrusterPos: Vector2, localThrustDirection: Vector2, magnitude: number)
	if self.IsStatic or magnitude <= 0 then return end
	local localThrustVector = localThrustDirection.Unit * magnitude
	self:AddForceAtLocalPoint(localThrustVector, localThrusterPos)
end

function RigidBody2D:ApplyImpulseAtWorldPoint(worldImpulse: Vector2, worldContactPoint: Vector2)
	if self.IsStatic then return end
	self.Velocity += worldImpulse * self.InverseMass

	local worldCOM = self:GetWorldCenterOfMass()
	local rWorld = worldContactPoint - worldCOM
	local angularImpulse = cross2D(rWorld, worldImpulse)
	self.AngularVelocity += angularImpulse * self.InverseMomentOfInertia
end

-- Returns the instantaneous world-point velocity implied by this rigid body.
-- This is the correct kinematic seed for a component that becomes independent
-- at a known local position; no arbitrary detachment impulse is introduced.
function RigidBody2D:GetWorldPointVelocity(localPoint: Vector2): Vector2
	local rWorld = rotate2D(localPoint - self.CenterOfMass, self.Rotation)
	local angularVelocity = Vector2.new(-self.AngularVelocity * rWorld.Y, self.AngularVelocity * rWorld.X)
	return self.Velocity + angularVelocity
end

-- Copies the parent's instantaneous rigid-body kinematics into a detached body.
-- The returned body still requires its own mass points to be populated by the
-- structural layer before it is registered with PhysicsWorld.
function RigidBody2D:CreateDetachedBody(localOrigin: Vector2, newId: string?): any
	local worldPosition = self:LocalToWorld(localOrigin)
	local detached = RigidBody2D.new(worldPosition, self.Rotation, newId)
	detached.Velocity = self:GetWorldPointVelocity(localOrigin)
	detached.AngularVelocity = self.AngularVelocity
	detached.Restitution = self.Restitution
	detached.FixedY = self.FixedY
	return detached
end

function RigidBody2D:ApplyInertialDamping(dt: number, linearDampingMult: number?, angularDampingMult: number?)
	if self.IsStatic then return end
	local linDamp = linearDampingMult or PhysicsConfig.LINEAR_DAMPING
	local angDamp = angularDampingMult or PhysicsConfig.ANGULAR_DAMPING

	local linFactor = math.pow(linDamp, dt)
	local angFactor = math.pow(angDamp, dt)
	self.Velocity *= linFactor
	self.AngularVelocity *= angFactor

	if self.Velocity.MagnitudeSq < 0.0001 then
		self.Velocity = Vector2.zero
	end
	if math.abs(self.AngularVelocity) < 0.0001 then
		self.AngularVelocity = 0
	end
end

function RigidBody2D:Integrate(dt: number, isBoosting: boolean?)
	if self.IsStatic or not self.IsActive then
		self:ClearAccumulators()
		return
	end

	local linearAccel = self.ForceAccumulator * self.InverseMass
	self.Velocity += linearAccel * dt

	local maxSpeed = isBoosting and PhysicsConfig.BOOST_MAX_LINEAR_SPEED or PhysicsConfig.MAX_LINEAR_SPEED
	if self.Velocity.Magnitude > maxSpeed then
		self.Velocity = self.Velocity.Unit * maxSpeed
	end

	self.Position += self.Velocity * dt

	local angularAccel = self.TorqueAccumulator * self.InverseMomentOfInertia
	self.AngularVelocity += angularAccel * dt
	self.AngularVelocity = math.clamp(self.AngularVelocity, -PhysicsConfig.MAX_ANGULAR_SPEED, PhysicsConfig.MAX_ANGULAR_SPEED)
	self.Rotation += self.AngularVelocity * dt
	self.Rotation = self.Rotation % (math.pi * 2)

	-- Native anb.a(boolean,boolean,pe) applies the recovered sustain operator
	-- after advancing position/angle. Keep generic solver integration above and
	-- perform only this game-specific native boundary here.
	self.Velocity, self.AngularVelocity = NativeVelocityOperator.Apply(self.Velocity, self.AngularVelocity)
	self:ClearAccumulators()

	if self.BoundModel or self.BoundPart then
		self:SyncToVisual(self.FixedY)
	end
end

function RigidBody2D:GetWorldCenterOfMass(): Vector2
	return self.Position + rotate2D(self.CenterOfMass, self.Rotation)
end

function RigidBody2D:LocalToWorld(localPoint: Vector2): Vector2
	return self.Position + rotate2D(localPoint, self.Rotation)
end

function RigidBody2D:WorldToLocal(worldPoint: Vector2): Vector2
	return rotate2D(worldPoint - self.Position, -self.Rotation)
end

function RigidBody2D:LocalDirectionToWorld(localDir: Vector2): Vector2
	return rotate2D(localDir, self.Rotation)
end

function RigidBody2D:WorldDirectionToLocal(worldDir: Vector2): Vector2
	return rotate2D(worldDir, -self.Rotation)
end

function RigidBody2D:GetForwardVector2D(): Vector2
	return rotate2D(Vector2.new(0, 1), self.Rotation)
end

function RigidBody2D:GetRightVector2D(): Vector2
	return rotate2D(Vector2.new(1, 0), self.Rotation)
end

function RigidBody2D:GetWorldCFrame(fixedY: number?): CFrame
	local y = fixedY or self.FixedY
	return CFrame.new(self.Position.X, y, self.Position.Y) * CFrame.Angles(0, -self.Rotation, 0)
end

function RigidBody2D:SetFromCFrame(cf: CFrame)
	self.Position = Vector2.new(cf.Position.X, cf.Position.Z)
	local _, yaw, _ = cf:ToEulerAnglesYXZ()
	self.Rotation = -yaw
end

function RigidBody2D:BindModel(model: Model, fixedY: number?)
	self.BoundModel = model
	if fixedY then self.FixedY = fixedY end
end

function RigidBody2D:BindPart(part: BasePart, fixedY: number?)
	self.BoundPart = part
	if fixedY then self.FixedY = fixedY end
end

function RigidBody2D:SyncToVisual(fixedY: number?)
	local cf = self:GetWorldCFrame(fixedY)
	if self.BoundModel and self.BoundModel.PrimaryPart then
		self.BoundModel:PivotTo(cf)
	elseif self.BoundPart then
		self.BoundPart.CFrame = cf
	end
end

return RigidBody2D
