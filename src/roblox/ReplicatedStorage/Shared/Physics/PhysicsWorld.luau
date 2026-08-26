--[[
	PhysicsWorld: 2D Spatial & Dynamic Simulation World.
	Sourced from AlterOrb / FunOrb Client Engine Decompile & Optimized for Roblox X-Z Plane.
	
	Features:
	  - Fixed-timestep sub-stepped integration loop
	  - Circle-circle and convex contact impulse resolution
	  - Spring/Tether physics for Tractor Beams and Grappling Hooks
	  - Spatial raycasting for lasers, projectiles, and AI line-of-sight
	  - Soft arena boundary containment
]]

local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)
local PhysicsTypes = require(game.ReplicatedStorage.Shared.Physics.PhysicsTypes)
local RigidBody2D = require(game.ReplicatedStorage.Shared.Physics.RigidBody2D)

local PhysicsWorld = {}
PhysicsWorld.__index = PhysicsWorld

export type SpringConstraint = {
	Id: string,
	BodyA: any,
	BodyB: any?,
	LocalAnchorA: Vector2,
	TargetPosition: Vector2,
	RestLength: number,
	Stiffness: number,
	Damping: number,
	MaxForce: number,
}

function PhysicsWorld.new()
	local self = setmetatable({}, PhysicsWorld)

	self.Bodies = {} :: { [string]: any }
	self.BodyList = {} :: { any }
	self.Springs = {} :: { [string]: SpringConstraint }
	self.Accumulator = 0
	self.FixedDt = PhysicsConfig.FIXED_DT
	self.StepCount = 0
	self.OnCollisionSignal = nil :: ((any, any, any) -> ())?

	return self
end

-----------------------------------------------------------------------------
-- BODY MANAGEMENT
-----------------------------------------------------------------------------

function PhysicsWorld:RegisterBody(body: any)
	if not body or not body.Id then return end
	if self.Bodies[body.Id] then return end

	self.Bodies[body.Id] = body
	table.insert(self.BodyList, body)
end

function PhysicsWorld:UnregisterBody(body: any)
	if not body or not body.Id then return end
	self.Bodies[body.Id] = nil

	for i, b in ipairs(self.BodyList) do
		if b.Id == body.Id then
			table.remove(self.BodyList, i)
			break
		end
	end

	-- Clean up any associated springs
	for springId, spring in pairs(self.Springs) do
		if spring.BodyA == body or spring.BodyB == body then
			self.Springs[springId] = nil
		end
	end
end

function PhysicsWorld:GetBodyById(id: string): any?
	return self.Bodies[id]
end

-----------------------------------------------------------------------------
-- TRACTOR BEAM / SPRING CONSTRAINTS
-----------------------------------------------------------------------------

function PhysicsWorld:CreateTractorSpring(bodyA: any, targetWorldPos: Vector2, stiffness: number?, damping: number?, maxForce: number?): SpringConstraint
	local springId = "spring_" .. tostring(math.random(100000, 999999))
	local spring: SpringConstraint = {
		Id = springId,
		BodyA = bodyA,
		BodyB = nil,
		LocalAnchorA = Vector2.zero,
		TargetPosition = targetWorldPos,
		RestLength = 0,
		Stiffness = stiffness or PhysicsConfig.TRACTOR_SPRING_STIFFNESS,
		Damping = damping or PhysicsConfig.TRACTOR_DAMPING,
		MaxForce = maxForce or PhysicsConfig.TRACTOR_MAX_FORCE,
	}
	self.Springs[springId] = spring
	return spring
end

function PhysicsWorld:UpdateTractorTarget(springId: string, newTargetWorldPos: Vector2)
	local spring = self.Springs[springId]
	if spring then
		spring.TargetPosition = newTargetWorldPos
	end
end

function PhysicsWorld:RemoveSpring(springId: string)
	self.Springs[springId] = nil
end

-----------------------------------------------------------------------------
-- COLLISION DETECTION & IMPULSE RESOLUTION
-----------------------------------------------------------------------------

local function resolveCircleCollision(bodyA: any, bodyB: any)
	if bodyA.IsStatic and bodyB.IsStatic then return end
	if not bodyA.IsActive or not bodyB.IsActive then return end

	local posA = bodyA.Position
	local posB = bodyB.Position
	local delta = posB - posA
	local distSq = delta.MagnitudeSq
	local totalRadius = bodyA.BoundingRadius + bodyB.BoundingRadius

	if distSq >= totalRadius * totalRadius or distSq < 0.0001 then
		return
	end

	local distance = math.sqrt(distSq)
	local normal = delta / distance -- Unit normal pointing from A to B
	local penetration = totalRadius - distance

	-- 1. Positional correction (prevent sinking)
	local totalInvMass = bodyA.InverseMass + bodyB.InverseMass
	if totalInvMass <= 0 then return end

	local percent = 0.8 -- Penetration resolution factor
	local slop = 0.01
	local correction = normal * (math.max(penetration - slop, 0) / totalInvMass * percent)

	if not bodyA.IsStatic then
		bodyA.Position -= correction * bodyA.InverseMass
	end
	if not bodyB.IsStatic then
		bodyB.Position += correction * bodyB.InverseMass
	end

	-- 2. Relative velocity at contact
	local contactPoint = posA + normal * (bodyA.BoundingRadius - penetration * 0.5)
	local rA = contactPoint - bodyA:GetWorldCenterOfMass()
	local rB = contactPoint - bodyB:GetWorldCenterOfMass()

	local velA = bodyA.Velocity + Vector2.new(-bodyA.AngularVelocity * rA.Y, bodyA.AngularVelocity * rA.X)
	local velB = bodyB.Velocity + Vector2.new(-bodyB.AngularVelocity * rB.Y, bodyB.AngularVelocity * rB.X)
	local relVel = velB - velA

	local velAlongNormal = relVel:Dot(normal)
	if velAlongNormal > 0 then
		return -- Separating
	end

	-- Restitution
	local e = math.min(bodyA.Restitution or PhysicsConfig.DEFAULT_RESTITUTION, bodyB.Restitution or PhysicsConfig.DEFAULT_RESTITUTION)

	-- Impulse scalar: j = -(1 + e) * (relVel . n) / (invM_A + invM_B + (rA x n)^2 / I_A + (rB x n)^2 / I_B)
	local rAxN = (rA.X * normal.Y) - (rA.Y * normal.X)
	local rBxN = (rB.X * normal.Y) - (rB.Y * normal.X)

	local invMassTerm = totalInvMass + (rAxN * rAxN * bodyA.InverseMomentOfInertia) + (rBxN * rBxN * bodyB.InverseMomentOfInertia)
	if invMassTerm <= 0 then return end

	local j = -(1 + e) * velAlongNormal / invMassTerm
	local impulse = normal * j

	-- Apply impulses
	if not bodyA.IsStatic then
		bodyA:ApplyImpulseAtWorldPoint(-impulse, contactPoint)
	end
	if not bodyB.IsStatic then
		bodyB:ApplyImpulseAtWorldPoint(impulse, contactPoint)
	end
end

-----------------------------------------------------------------------------
-- WORLD BOUNDARY CONTAINMENT
-----------------------------------------------------------------------------

local function enforceWorldBounds(body: any)
	if body.IsStatic then return end
	local distFromOrigin = body.Position.Magnitude
	local maxRadius = PhysicsConfig.WORLD_BOUNDS_RADIUS

	if distFromOrigin > maxRadius then
		local pushDir = -body.Position.Unit
		local overshoot = distFromOrigin - maxRadius
		local pushForce = pushDir * (overshoot * 50.0 + 100.0)
		body:AddForce(pushForce)
		body.Velocity *= 0.95
	end
end

-----------------------------------------------------------------------------
-- SIMULATION STEPPING (Fixed-Timestep Accumulator)
-----------------------------------------------------------------------------

function PhysicsWorld:Step(dt: number)
	self.Accumulator += math.min(dt, PhysicsConfig.MAX_FRAME_TIME)

	while self.Accumulator >= self.FixedDt do
		self:FixedStep(self.FixedDt)
		self.Accumulator -= self.FixedDt
		self.StepCount += 1
	end
end

function PhysicsWorld:FixedStep(fixedDt: number)
	-- 1. Evaluate Springs & Tractor Beams
	for _, spring in pairs(self.Springs) do
		local bodyA = spring.BodyA
		if bodyA and not bodyA.IsStatic then
			local anchorAWorld = bodyA:LocalToWorld(spring.LocalAnchorA)
			local targetPos = spring.BodyB and spring.BodyB:LocalToWorld(Vector2.zero) or spring.TargetPosition
			
			local delta = targetPos - anchorAWorld
			local currentLength = delta.Magnitude
			if currentLength > 0.01 then
				local dir = delta / currentLength
				local displacement = currentLength - spring.RestLength
				
				-- Relative velocity
				local velA = bodyA.Velocity
				local velB = spring.BodyB and spring.BodyB.Velocity or Vector2.zero
				local relVel = velB - velA
				
				-- Spring + Damping force: F = k * x + c * v
				local springForceMagnitude = (spring.Stiffness * displacement) + (spring.Damping * relVel:Dot(dir))
				springForceMagnitude = math.clamp(springForceMagnitude, -spring.MaxForce, spring.MaxForce)
				
				local springForce = dir * springForceMagnitude
				bodyA:AddForceAtWorldPoint(springForce, anchorAWorld)
				
				if spring.BodyB and not spring.BodyB.IsStatic then
					spring.BodyB:AddForceAtWorldPoint(-springForce, targetPos)
				end
			end
		end
	end

	-- 2. Apply Inertial Damping & Boundary Soft Push
	for _, body in ipairs(self.BodyList) do
		if body.IsActive and not body.IsStatic then
			body:ApplyInertialDamping(fixedDt)
			enforceWorldBounds(body)
		end
	end

	-- 3. Integrate Rigid Bodies
	for _, body in ipairs(self.BodyList) do
		if body.IsActive then
			body:Integrate(fixedDt)
		end
	end

	-- 4. Collision Detection & Resolution (Pairwise Broadphase & Narrowphase)
	local count = #self.BodyList
	for i = 1, count - 1 do
		local bodyA = self.BodyList[i]
		for j = i + 1, count do
			local bodyB = self.BodyList[j]
			resolveCircleCollision(bodyA, bodyB)
		end
	end
end

-----------------------------------------------------------------------------
-- SPATIAL QUERIES & RAYCASTING
-----------------------------------------------------------------------------

function PhysicsWorld:CastRay(origin: Vector2, direction: Vector2, maxDistance: number, ignoreBody: any?): PhysicsTypes.RaycastHit2D?
	local dirUnit = direction.Unit
	local closestHit: any = nil
	local closestDist = maxDistance

	for _, body in ipairs(self.BodyList) do
		if body ~= ignoreBody and body.IsActive then
			-- Ray to Circle intersection test
			local center = body.Position
			local radius = body.BoundingRadius
			
			local oc = center - origin
			local proj = oc:Dot(dirUnit)
			
			if proj > 0 and proj - radius < closestDist then
				local perpSq = oc.MagnitudeSq - (proj * proj)
				if perpSq <= radius * radius then
					local th = math.sqrt(radius * radius - perpSq)
					local hitDist = proj - th
					
					if hitDist > 0 and hitDist < closestDist then
						closestDist = hitDist
						local hitPoint = origin + dirUnit * hitDist
						local hitNormal = (hitPoint - center).Unit
						
						closestHit = {
							Hit = true,
							Position = hitPoint,
							Normal = hitNormal,
							Distance = hitDist,
							Body = body,
							Part = body.BoundPart or (body.BoundModel and body.BoundModel.PrimaryPart),
						}
					end
				end
			end
		end
	end

	return closestHit
end

function PhysicsWorld:GetBodiesInRadius(center: Vector2, radius: number): { any }
	local results = {}
	local radSq = radius * radius

	for _, body in ipairs(self.BodyList) do
		if body.IsActive then
			local delta = body.Position - center
			if delta.MagnitudeSq <= (radius + body.BoundingRadius) * (radius + body.BoundingRadius) then
				table.insert(results, body)
			end
		end
	end

	return results
end

return PhysicsWorld
