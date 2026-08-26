--[[
	BallisticsEngine: 2D Projectile Physics & Kinetic Impulse Subsystem.
	Roblox-first runtime implementation using the project's canonical 2D
	physics representation and Roblox visual projection.

	Behavioral goals:
	  - True 2D planar projectile integration with ship velocity inheritance
	  - Swept segment collision checks to prevent tunneling
	  - Nearest-hit selection along the projectile segment
	  - Roblox Workspace raycast fallback when no logical PhysicsWorld is attached
	  - Preserve the actual collision part for authoritative component damage
	  - Momentum-style impulse delivery to hit logical bodies when supported
	  - Homing missile guidance with bounded angular turn rate
	  - Deterministic projectile lifetime/range cleanup
]]

local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)
local CombatTypes = require(game.ReplicatedStorage.Shared.Combat.CombatTypes)
local Workspace = game:GetService("Workspace")

local BallisticsEngine = {}
BallisticsEngine.__index = BallisticsEngine

local function distancePointToSegment(point: Vector2, startPoint: Vector2, endPoint: Vector2): (number, number)
	local segment = endPoint - startPoint
	local lengthSq = segment.MagnitudeSq
	if lengthSq <= 0.000001 then
		return (point - startPoint).Magnitude, 0
	end

	local t = math.clamp((point - startPoint):Dot(segment) / lengthSq, 0, 1)
	local closest = startPoint + segment * t
	return (point - closest).Magnitude, t
end

local function findSegmentBodyHit(startPoint: Vector2, endPoint: Vector2, bodies: { any }, shooterId: string): (any?, Vector2?)
	local bestBody: any = nil
	local bestHit: Vector2? = nil
	local bestTravel = math.huge
	local segmentLength = (endPoint - startPoint).Magnitude

	for _, body in ipairs(bodies) do
		if body.Id ~= shooterId and body.IsActive then
			local radius = body.BoundingRadius or 6.0
			local distanceToSegment, segmentT = distancePointToSegment(body.Position, startPoint, endPoint)
			if distanceToSegment <= radius then
				local candidateTravel = segmentLength * segmentT
				if candidateTravel < bestTravel then
					local direction = endPoint - startPoint
					local hitOffset = math.sqrt(math.max(radius * radius - distanceToSegment * distanceToSegment, 0))
					local hitT = math.clamp(segmentT - hitOffset / math.max(segmentLength, 0.000001), 0, 1)
					bestTravel = candidateTravel
					bestBody = body
					bestHit = startPoint + direction * hitT
				end
			end
		end
	end

	return bestBody, bestHit
end

local function findRobloxRaycastHit(startPoint: Vector2, endPoint: Vector2, shooterId: string): (any?, Vector2?)
	local origin = Vector3.new(startPoint.X, PhysicsConfig.FIXED_Y_ELEVATION, startPoint.Y)
	local destination = Vector3.new(endPoint.X, PhysicsConfig.FIXED_Y_ELEVATION, endPoint.Y)
	local direction = destination - origin
	if direction.Magnitude <= 0.000001 then
		return nil, nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local ignore: { Instance } = {}
	for _, instance in ipairs(Workspace:GetChildren()) do
		if instance:IsA("Model") and instance:GetAttribute("ShipId") == shooterId then
			ignore[#ignore + 1] = instance
		end
	end
	params.FilterDescendantsInstances = ignore

	local result = Workspace:Raycast(origin, direction, params)
	if not result then
		return nil, nil
	end

	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
	if not hitModel or hitModel:GetAttribute("IsShip") ~= true then
		return nil, nil
	end

	local body = {
		Id = hitModel:GetAttribute("ShipId") or hitModel.Name,
		IsActive = true,
		BoundingRadius = 0,
		Position = Vector2.new(hitModel:GetPivot().Position.X, hitModel:GetPivot().Position.Z),
		RobloxModel = hitModel,
		RobloxPart = result.Instance,
	}
	return body, Vector2.new(result.Position.X, result.Position.Z)
end

function BallisticsEngine.new(physicsWorld: any?)
	local self = setmetatable({}, BallisticsEngine)
	self.PhysicsWorld = physicsWorld
	self.Projectiles = {} :: { [string]: CombatTypes.ProjectileData }
	self.NextId = 1
	return self
end

function BallisticsEngine:SpawnProjectile(params: {
	Type: string,
	DamageType: CombatTypes.DamageType,
	Damage: number,
	TickDamage: number?,
	SplashRadius: number?,
	Speed: number,
	Range: number,
	Origin2D: Vector2,
	Direction2D: Vector2,
	InheritedVelocity: Vector2?,
	ShooterId: string,
	ShooterTeam: string?,
	Color: Color3?,
	Size: Vector3?,
	VisualModel: BasePart?,
	HomingTarget: any?,
	ImpulseMagnitude: number?,
}): CombatTypes.ProjectileData
	local id = "proj_" .. tostring(self.NextId)
	self.NextId += 1

	local dir = (params.Direction2D.Magnitude > 0) and params.Direction2D.Unit or Vector2.yAxis
	local inherited = params.InheritedVelocity or Vector2.zero
	local muzzleVel = dir * params.Speed
	local finalVel = inherited + muzzleVel

	local proj: CombatTypes.ProjectileData = {
		Id = id,
		Type = params.Type,
		DamageType = params.DamageType,
		BaseDamage = params.Damage,
		TickDamage = params.TickDamage,
		SplashRadius = params.SplashRadius,
		Speed = params.Speed,
		Range = params.Range,
		Position = params.Origin2D,
		Velocity = finalVel,
		Origin = params.Origin2D,
		DistanceTraveled = 0.0,
		ShooterId = params.ShooterId,
		ShooterTeam = params.ShooterTeam,
		Color = params.Color or Color3.new(1, 1, 0),
		Size = params.Size or Vector3.new(0.5, 0.3, 1.2),
		Lifetime = (params.Speed > 0) and (params.Range / params.Speed) or 2.0,
		VisualPart = params.VisualModel,
		HomingTarget = params.HomingTarget,
		HomingTurnRate = 4.5,
		ImpulseMagnitude = params.ImpulseMagnitude or (params.Damage * 12.0),
	}

	self.Projectiles[id] = proj
	return proj
end

function BallisticsEngine:Step(dt: number, onHitCallback: ((CombatTypes.ProjectileData, any, Vector2) -> ())?)
	if typeof(dt) ~= "number" or dt <= 0 or dt ~= dt or dt == math.huge then
		return
	end

	for id, proj in pairs(self.Projectiles) do
		if not self.Projectiles[id] then
			continue
		end

		if proj.HomingTarget and proj.HomingTarget.Position then
			local targetPosition = proj.HomingTarget.Position
			local offset = Vector2.new(targetPosition.X, targetPosition.Z) - proj.Position
			if offset.Magnitude > 0.001 and proj.Velocity.Magnitude > 0.001 then
				local desiredDir = offset.Unit
				local currentDir = proj.Velocity.Unit
				local currentAngle = math.atan2(currentDir.Y, currentDir.X)
				local targetAngle = math.atan2(desiredDir.Y, desiredDir.X)
				local diff = math.atan2(math.sin(targetAngle - currentAngle), math.cos(targetAngle - currentAngle))
				local maxTurn = (proj.HomingTurnRate or 4.0) * dt
				local actualTurn = math.clamp(diff, -maxTurn, maxTurn)
				local newAngle = currentAngle + actualTurn
				proj.Velocity = Vector2.new(math.cos(newAngle), math.sin(newAngle)) * proj.Speed
			end
		end

		local startPos = proj.Position
		local stepMovement = proj.Velocity * dt
		local nextPos = startPos + stepMovement
		local stepDist = stepMovement.Magnitude
		proj.DistanceTraveled += stepDist

		local hitBody: any = nil
		local hitPosition = nextPos
		if self.PhysicsWorld and self.PhysicsWorld.BodyList then
			hitBody, hitPosition = findSegmentBodyHit(startPos, nextPos, self.PhysicsWorld.BodyList, proj.ShooterId)
		else
			hitBody, hitPosition = findRobloxRaycastHit(startPos, nextPos, proj.ShooterId)
		end

		local hitOccurred = hitBody ~= nil and hitPosition ~= nil
		if hitOccurred then
			if hitBody.ApplyImpulseAtWorldPoint then
				hitBody:ApplyImpulseAtWorldPoint(proj.Velocity.Unit * proj.ImpulseMagnitude, hitPosition)
			end
			if onHitCallback then
				onHitCallback(proj, hitBody, hitPosition :: Vector2)
			end
		end

		proj.Position = hitOccurred and hitPosition or nextPos

		if proj.VisualPart and proj.VisualPart.Parent then
			proj.VisualPart.Position = Vector3.new(proj.Position.X, PhysicsConfig.FIXED_Y_ELEVATION, proj.Position.Y)
			if proj.Velocity.Magnitude > 0.001 then
				local yaw = -math.atan2(proj.Velocity.Y, proj.Velocity.X) + math.pi / 2
				proj.VisualPart.CFrame = CFrame.new(proj.VisualPart.Position) * CFrame.Angles(0, yaw, 0)
			end
		end

		if hitOccurred or proj.DistanceTraveled >= proj.Range or proj.Lifetime <= 0 then
			if proj.VisualPart and proj.VisualPart.Parent then
				proj.VisualPart:Destroy()
			end
			self.Projectiles[id] = nil
		else
			proj.Lifetime = math.max(0, proj.Lifetime - dt)
		end
	end
end

return BallisticsEngine
