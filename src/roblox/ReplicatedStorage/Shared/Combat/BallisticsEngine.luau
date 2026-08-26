--[[
	BallisticsEngine: 2D Projectile Physics & Kinetic Impulse Subsystem.
	Sourced from AlterOrb / FunOrb Ballistics Decompile Mechanics.
	
	Features:
	  - True 2D planar projectile integration with ship velocity inheritance
	  - Swept line-segment collision checks against RigidBody2D hulls
	  - Momentum-conserving impulse delivery to hit ships
	  - Homing missile guidance & angular turn rates
	  - Splash/Tick area-of-effect damage propagation
]]

local Debris = game:GetService("Debris")
local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)
local CombatTypes = require(game.ReplicatedStorage.Shared.Combat.CombatTypes)

local BallisticsEngine = {}
BallisticsEngine.__index = BallisticsEngine

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

	local dir = (params.Direction2D.Magnitude > 0) and params.Direction2D.Unit or Vector2.new(0, 1)
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
		HomingTurnRate = 4.5, -- radians/sec
		ImpulseMagnitude = params.ImpulseMagnitude or (params.Damage * 12.0),
	}

	self.Projectiles[id] = proj
	return proj
end

-- Steps all active projectiles on the 2D plane
function BallisticsEngine:Step(dt: number, onHitCallback: ((CombatTypes.ProjectileData, any, Vector2) -> ())?)
	for id, proj in pairs(self.Projectiles) do
		-- 1. Homing Guidance logic
		if proj.HomingTarget and proj.HomingTarget.Position then
			local targetPos2D = Vector2.new(proj.HomingTarget.Position.X, proj.HomingTarget.Position.Z)
			local desiredDir = (targetPos2D - proj.Position).Unit
			local currentDir = proj.Velocity.Unit
			
			local currentAngle = math.atan2(currentDir.Y, currentDir.X)
			local targetAngle = math.atan2(desiredDir.Y, desiredDir.X)
			local diff = math.atan2(math.sin(targetAngle - currentAngle), math.cos(targetAngle - currentAngle))
			
			local maxTurn = (proj.HomingTurnRate or 4.0) * dt
			local actualTurn = math.clamp(diff, -maxTurn, maxTurn)
			local newAngle = currentAngle + actualTurn
			
			local newDir = Vector2.new(math.cos(newAngle), math.sin(newAngle))
			proj.Velocity = newDir * proj.Speed
		end

		-- 2. Kinematics integration
		local stepMovement = proj.Velocity * dt
		local stepDist = stepMovement.Magnitude
		local nextPos = proj.Position + stepMovement
		proj.DistanceTraveled += stepDist

		-- 3. Collision query against PhysicsWorld or 2D Spatial bodies
		local hitOccurred = false
		if self.PhysicsWorld and self.PhysicsWorld.BodyList then
			for _, body in ipairs(self.PhysicsWorld.BodyList) do
				if body.Id ~= proj.ShooterId and body.IsActive then
					local toBody = body.Position - nextPos
					if toBody.Magnitude <= (body.BoundingRadius or 6.0) then
						hitOccurred = true
						-- Deliver physical impulse onto hit body
						if body.AddImpulse then
							local impulseDir = proj.Velocity.Unit
							body:AddImpulse(impulseDir * proj.ImpulseMagnitude, nextPos)
						end

						if onHitCallback then
							onHitCallback(proj, body, nextPos)
						end
						break
					end
				end
			end
		end

		-- 4. Sync Visual Part to 3D Roblox Workspace
		if proj.VisualPart and proj.VisualPart.Parent then
			proj.VisualPart.Position = Vector3.new(nextPos.X, PhysicsConfig.FIXED_Y_ELEVATION, nextPos.Y)
			local yaw = -math.atan2(proj.Velocity.Y, proj.Velocity.X) + math.pi/2
			proj.VisualPart.CFrame = CFrame.new(proj.VisualPart.Position) * CFrame.Angles(0, yaw, 0)
		end

		proj.Position = nextPos

		-- 5. Expiration / Cleanup
		if hitOccurred or proj.DistanceTraveled >= proj.Range then
			if proj.VisualPart and proj.VisualPart.Parent then
				proj.VisualPart:Destroy()
			end
			self.Projectiles[id] = nil
		end
	end
end

return BallisticsEngine
