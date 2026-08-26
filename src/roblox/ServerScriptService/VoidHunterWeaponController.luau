--[=[
	VoidHunter Weapon Controller (Server)

	Canonical combat orchestration:
	- ComponentAuthority owns component state and HP.
	- StructuralAuthority owns structural mutation.
	- ShipRegistry owns player <-> ship ownership.
	- TeamIdentity owns team validation.
	- Components owns component definitions and hardpoint metadata.
	- CapacitorSystem owns ship energy state.

	Roblox Instances remain the physical/presentation projection. Attributes used on
	transient projectiles and effects are local object state, not component authority.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local SoundManager = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))
local CombatTypes = require(ReplicatedStorage.Shared.Combat.CombatTypes)
local CapacitorSystem = require(ReplicatedStorage.Shared.Combat.CapacitorSystem)
local ShieldSystem = require(ReplicatedStorage.Shared.Combat.ShieldSystem)
local BallisticsEngine = require(ReplicatedStorage.Shared.Combat.BallisticsEngine)
local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))

local UNIT = Components.UNIT or 7
local HEIGHT = Components.HEIGHT or 3.5
local RATE_LIMIT = 20

local weaponCooldowns: { [BasePart]: number } = setmetatable({}, { __mode = "k" })
local scramblerCooldowns: { [BasePart]: number } = setmetatable({}, { __mode = "k" })
local playerRequestCounts: { [number]: { count: number, resetTime: number } } = {}
local shipShields: { [Model]: any } = setmetatable({}, { __mode = "k" })
local shipCapacitors: { [Model]: any } = setmetatable({}, { __mode = "k" })
local droneBayStates: { [BasePart]: { activeDrones: { BasePart } } } = setmetatable({}, { __mode = "k" })
local pointDefenceStates: { [BasePart]: { lastTargetTime: { [BasePart]: number } } } = setmetatable({}, { __mode = "k" })
local ballistics = BallisticsEngine.new(nil)

local FireWeaponEvent = ReplicatedStorage:FindFirstChild("VoidHunterFireWeapon")
if not FireWeaponEvent then
	FireWeaponEvent = Instance.new("RemoteEvent")
	FireWeaponEvent.Name = "VoidHunterFireWeapon"
	FireWeaponEvent.Parent = ReplicatedStorage
end

local FireScramblerEvent = ReplicatedStorage:FindFirstChild("VoidHunterFireScrambler")
if not FireScramblerEvent then
	FireScramblerEvent = Instance.new("RemoteEvent")
	FireScramblerEvent.Name = "VoidHunterFireScrambler"
	FireScramblerEvent.Parent = ReplicatedStorage
end

local function getComponentState(part: BasePart)
	return ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
end

local function getComponentType(part: BasePart): string?
	local state = getComponentState(part)
	return state and state.TypeName or nil
end

local function getComponentDefinition(part: BasePart): any?
	local typeName = getComponentType(part)
	return typeName and Components.Types[typeName] or nil
end

local function isHull(part: BasePart): boolean
	local definition = getComponentDefinition(part)
	return definition ~= nil and definition.IsHull == true
end

local function getOwnerShip(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("IsShip") == true then
		return model
	end
	return nil
end

local function getShipPosition(ship: Model): Vector3
	return ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
end

local function findNearestEnemy(ship: Model, range: number): Model?
	local shipPosition = getShipPosition(ship)
	local nearest: Model? = nil
	local nearestDistance = range

	for _, candidate in pairs(ShipRegistry.GetAll()) do
		if candidate ~= ship and candidate.Parent then
			local distance = (getShipPosition(candidate) - shipPosition).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearest = candidate
			end
		end
	end

	return nearest
end

local function getComponentParts(ship: Model): { BasePart }
	local parts: { BasePart } = {}
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") and not instance:IsA("VehicleSeat") and ComponentAuthority.IsComponent(instance) then
			parts[#parts + 1] = instance
		end
	end
	return parts
end

local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function validatePlayer(player: Player): (boolean, string?)
	if not player.Parent then
		return false, "Invalid player"
	end
	return true, nil
end

local function validateShip(player: Player, ship: Instance): (boolean, string?)
	if not ship or not ship:IsA("Model") or not ship.Parent then
		return false, "Invalid ship"
	end
	if ship:GetAttribute("IsShip") ~= true then
		return false, "Not a valid ship"
	end
	if not ShipRegistry.IsOwner(player, ship) then
		return false, "Ship ownership mismatch"
	end
	return true, nil
end

local function validateWeaponPart(ship: Model, weaponName: any): (boolean, string?, BasePart?, string?, any?)
	if typeof(weaponName) ~= "string" or weaponName == "" then
		return false, "Invalid weapon name"
	end

	local weapon = ship:FindFirstChild(weaponName, true)
	if not weapon or not weapon:IsA("BasePart") or not weapon:IsDescendantOf(ship) then
		return false, "Weapon not found"
	end

	local typeName = getComponentType(weapon)
	local definition = typeName and Components.Types[typeName]
	if not typeName or not definition then
		return false, "Unknown component type"
	end
	if not definition.Damage then
		return false, "Not a weapon component"
	end

	return true, nil, weapon, typeName, definition
end

local function validateAimDirection(aimDirection: any): (boolean, string?, Vector3?)
	if aimDirection == nil then
		return true, nil, nil
	end
	if typeof(aimDirection) ~= "Vector3" or aimDirection.Magnitude < 0.001 then
		return false, "Invalid aim direction", nil
	end
	return true, nil, aimDirection.Unit
end

local function checkRateLimit(player: Player): boolean
	local now = os.clock()
	local state = playerRequestCounts[player.UserId]
	if not state then
		state = { count = 0, resetTime = now + 1 }
		playerRequestCounts[player.UserId] = state
	elseif now > state.resetTime then
		state.count = 0
		state.resetTime = now + 1
	end
	state.count += 1
	return state.count <= RATE_LIMIT
end

local function getMuzzlePosition(weapon: BasePart, aimCFrame: CFrame): Vector3
	local attachment = weapon:FindFirstChild("Muzzle")
	if attachment and attachment:IsA("Attachment") then
		return attachment.WorldPosition
	end
	return weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
end

local function destroyShip(ship: Model)
	if not ship.Parent then
		return
	end

	local owner = ShipRegistry.GetOwner(ship)
	ship:SetAttribute("Destroyed", true)
	ShipRegistry.UnregisterShip(ship)
	shipCapacitors[ship] = nil
	shipShields[ship] = nil

	if owner then
		owner:SetAttribute("InShip", false)
		owner:SetAttribute("ShipType", nil)
	end

	ship:Destroy()
end

local function applyDamage(part: BasePart, damage: number, damageType: CombatTypes.DamageType, attackerShip: Model?, hitPosition: Vector3?)
	if not part.Parent or not isFiniteNumber(damage) or damage <= 0 then
		return
	end

	local victimShip = getOwnerShip(part)
	if attackerShip and victimShip then
		local attackerTeam = TeamIdentity.Get(attackerShip)
		local victimTeam = TeamIdentity.Get(victimShip)
		if attackerTeam and victimTeam and attackerTeam == victimTeam then
			return
		end
	end

	local effectiveDamage = damage
	local shield = victimShip and shipShields[victimShip]
	if shield then
		effectiveDamage = shield:AbsorbDamage(effectiveDamage, damageType)
	end

	if damageType == "EMP" and victimShip then
		local capacitor = shipCapacitors[victimShip]
		if capacitor then
			capacitor:Drain(damage * 1.5)
		end
	end

	if (damageType == "Kinetic" or damageType == "Explosive") and attackerShip and victimShip and victimShip.PrimaryPart then
		local push = getShipPosition(victimShip) - getShipPosition(attackerShip)
		if push.Magnitude > 0.1 then
			victimShip.PrimaryPart:ApplyImpulse(push.Unit * math.min(damage * 12, 400) * victimShip.PrimaryPart.AssemblyMass)
		end
	end

	if effectiveDamage <= 0 then
		return
	end

	local state = getComponentState(part)
	if not state or state.MaxHealth <= 0 or state.Destroyed then
		return
	end

	if damageType == "Thermal" and isHull(part) then
		effectiveDamage *= 0.5
	end

	local updated, destroyed = ComponentAuthority.ApplyDamage(part, effectiveDamage)
	if not destroyed or not updated then
		return
	end

	local ship = getOwnerShip(part)
	if not ship then
		part:Destroy()
		return
	end

	local definition = Components.Types[updated.TypeName]
	if definition and definition.IsCore == true then
		destroyShip(ship)
	else
		StructuralAuthority.DetachComponent(ship, part, "Destroyed")
	end
end

local function spawnMassDriverProjectile(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local projectile = Instance.new("Part")
	projectile.Name = "MD_Projectile"
	projectile.Size = definition.ProjectileSize or Vector3.new(0.5, 0.3, 1)
	projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartType.Cylinder
	projectile.CFrame = aimCFrame
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Parent = Workspace
	projectile.AssemblyLinearVelocity = aimCFrame.LookVector * definition.ProjectileSpeed
	Debris:AddItem(projectile, definition.Range / math.max(definition.ProjectileSpeed, 1))
	SoundManager.PlayWeapon("MassDriver", projectile.Position)

	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) then
			return
		end
		local victimShip = getOwnerShip(hit)
		if victimShip and victimShip ~= ship then
			applyDamage(hit, definition.Damage, "Kinetic", ship, projectile.Position)
			if projectile.Parent then projectile:Destroy() end
		end
	end)
end

local function spawnPlasmaProjectile(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame, muzzleOffset: Vector3?)
	local position = muzzleOffset and weapon.CFrame:PointToWorldSpace(muzzleOffset) or getMuzzlePosition(weapon, aimCFrame)
	local projectile = Instance.new("Part")
	projectile.Name = "Plasma_Projectile"
	projectile.Size = Vector3.one * 2
	projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartType.Ball
	projectile.CFrame = CFrame.new(position)
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Parent = Workspace
	projectile:SetAttribute("IsPlasma", true)
	projectile.AssemblyLinearVelocity = aimCFrame.LookVector * definition.ProjectileSpeed

	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 8
	light.Color = definition.ProjectileColor
	light.Parent = projectile
	SoundManager.PlayWeapon("PlasmaBall", position)

	local touchedParts: { [BasePart]: boolean } = {}
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) or touchedParts[hit] then
			return
		end
		touchedParts[hit] = true
		local victimShip = getOwnerShip(hit)
		if victimShip and victimShip ~= ship then
			applyDamage(hit, (definition.TickDamage or definition.Damage) * 0.5, "Thermal", ship, projectile.Position)
		end
	end)

	local lifetime = definition.Range / math.max(definition.ProjectileSpeed, 1)
	Debris:AddItem(projectile, lifetime)
	task.delay(lifetime, function()
		if not projectile.Parent then return end
		for _, part in ipairs(Workspace:GetPartBoundsInRadius(projectile.Position, 4)) do
			local victimShip = getOwnerShip(part)
			if victimShip and victimShip ~= ship then
				applyDamage(part, definition.Damage, "Thermal", ship, projectile.Position)
			end
		end
		if projectile.Parent then projectile:Destroy() end
	end)
end

local function spawnMissiles(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = getMuzzlePosition(weapon, aimCFrame)
	SoundManager.PlayWeapon("MissileLauncher", spawnPosition)
	local spread = math.rad(definition.SpreadAngle or 15)

	for index = 1, 2 do
		local offset = index == 1 and CFrame.Angles(0, spread, 0) or CFrame.Angles(0, -spread, 0)
		local missileCFrame = aimCFrame * offset
		local missile = Instance.new("Part")
		missile.Name = "Missile_" .. index
		missile.Size = Vector3.new(0.5, 0.5, 0.5)
		missile.BrickColor = BrickColor.new(definition.ProjectileColor)
		missile.Material = Enum.Material.Neon
		missile.Shape = Enum.PartType.Ball
		missile.CFrame = CFrame.new(spawnPosition)
		missile.Anchored = false
		missile.CanCollide = true
		missile.Parent = Workspace
		missile:SetAttribute("IsMissile", true)
		missile:SetAttribute("MissileHP", definition.MissileHP or 25)
		missile.AssemblyLinearVelocity = missileCFrame.LookVector * definition.ProjectileSpeed

		local target = findNearestEnemy(ship, definition.Range)
		if target then
			missile:SetAttribute("HomingActive", true)
			task.spawn(function()
				while missile.Parent and missile:GetAttribute("HomingActive") and target.Parent do
					local direction = getShipPosition(target) - missile.Position
					if direction.Magnitude > 0.1 then
						missile.AssemblyLinearVelocity = direction.Unit * definition.ProjectileSpeed
					end
					task.wait(0.1)
				end
			end)
		end

		missile.Touched:Connect(function(hit)
			if not missile.Parent or hit:IsDescendantOf(ship) then return end
			if hit:GetAttribute("IsMissile") or hit:GetAttribute("IsPlasma") or hit.Name == "MD_Projectile" then
				local hp = missile:GetAttribute("MissileHP") or 25
				hp -= 25
				missile:SetAttribute("MissileHP", hp)
				if hp <= 0 then missile:Destroy() end
				return
			end
			local victimShip = getOwnerShip(hit)
			if victimShip and victimShip ~= ship then
				applyDamage(hit, definition.Damage, "Kinetic", ship, missile.Position)
				if missile.Parent then missile:Destroy() end
			end
		end)

		Debris:AddItem(missile, definition.Range / math.max(definition.ProjectileSpeed, 1))
	end
end

local function getDroneSpawnPosition(weapon: BasePart): Vector3
	local attachment = weapon:FindFirstChild("DroneSpawn")
	if attachment and attachment:IsA("Attachment") then return attachment.WorldPosition end
	return weapon.Position + Vector3.new(0, 2, 0)
end

local function spawnDrone(ship: Model, weapon: BasePart, definition: any)
	local state = droneBayStates[weapon]
	if not state then
		state = { activeDrones = {} }
		droneBayStates[weapon] = state
	end

	for index = #state.activeDrones, 1, -1 do
		if not state.activeDrones[index].Parent then table.remove(state.activeDrones, index) end
	end
	if #state.activeDrones >= (definition.MaxDrones or 3) then return end

	local capacitor = shipCapacitors[ship]
	local cost = definition.EnergyPerDrone or 20
	if not capacitor or not capacitor:Consume(cost) then return end

	local drone = Instance.new("Part")
	drone.Name = "Drone"
	drone.Size = Vector3.new(0.5, 0.5, 0.5)
	drone.Color = Color3.fromRGB(255, 50, 50)
	drone.Material = Enum.Material.Neon
	drone.Shape = Enum.PartType.Ball
	drone.Position = getDroneSpawnPosition(weapon)
	drone.Anchored = false
	drone.CanCollide = true
	drone.Parent = Workspace
	drone:SetAttribute("IsDrone", true)
	drone:SetAttribute("DroneHP", definition.DroneHP or 50)
	drone:SetAttribute("DroneMaxHP", definition.DroneHP or 50)
	drone:SetAttribute("DroneOwnerShip", ship:GetAttribute("OwnerId") or 0)
	state.activeDrones[#state.activeDrones + 1] = drone

	task.spawn(function()
		local fireTimer = 0
		local droneEnergy = 50
		while drone.Parent and ship.Parent do
			droneEnergy = math.min(100, droneEnergy + (definition.DroneEnergyRegen or 25) * 0.1)
			drone:SetAttribute("DroneEnergy", droneEnergy)

			local orbitRadius = 8
			local orbitSpeed = definition.DroneSpeed or 60
			local angle = os.clock() * (orbitSpeed / orbitRadius)
			local orbitTarget = getShipPosition(ship) + Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
			local direction = orbitTarget - drone.Position
			if direction.Magnitude > 1 then drone.AssemblyLinearVelocity = direction.Unit * orbitSpeed end

			fireTimer += 0.1
			if fireTimer >= (definition.DroneFireRate or 0.2) and droneEnergy >= 10 then
				fireTimer = 0
				local enemy = findNearestEnemy(ship, definition.DroneRange or 30)
				if enemy then
					droneEnergy -= 10
					local targetPosition = getShipPosition(enemy)
					local beam = Instance.new("Part")
					beam.Name = "DroneLaser"
					beam.Size = Vector3.new(0.15, 0.15, (targetPosition - drone.Position).Magnitude)
					beam.Color = Color3.fromRGB(255, 50, 50)
					beam.Material = Enum.Material.Neon
					beam.Anchored = true
					beam.CanCollide = false
					beam.CFrame = CFrame.lookAt((drone.Position + targetPosition) / 2, targetPosition) * CFrame.Angles(math.rad(90), 0, 0)
					beam.Parent = Workspace
					Debris:AddItem(beam, 0.1)
					for _, part in ipairs(Workspace:GetPartBoundsInRadius(targetPosition, 3)) do
						local victimShip = getOwnerShip(part)
						if victimShip and victimShip ~= ship then
							applyDamage(part, definition.DroneDamage or 5, "Kinetic", ship, targetPosition)
						end
					end
				end
			end
			task.wait(0.1)
		end
	end)

	drone.Touched:Connect(function(hit)
		if not drone.Parent or hit:GetAttribute("IsPointDefence") then return end
		local hp = (drone:GetAttribute("DroneHP") or 50) - 10
		drone:SetAttribute("DroneHP", hp)
		if hp <= 0 and drone.Parent then drone:Destroy() end
	end)
end

local function runPointDefence(ship: Model, weapon: BasePart, definition: any)
	local state = pointDefenceStates[weapon]
	if not state then
		state = { lastTargetTime = {} }
		pointDefenceStates[weapon] = state
	end

	local range = definition.Range or 45
	local dps = definition.DamagePerSecond or 25
	local targetDelay = definition.TargetingDelay or 1
	local candidates = Workspace:GetPartBoundsInRadius(weapon.Position, range)
	local targets = table.create(#candidates)

	for _, target in ipairs(candidates) do
		local ownerId = target:GetAttribute("DroneOwnerShip")
		local isEnemyDrone = target:GetAttribute("IsDrone") == true and ownerId ~= (ship:GetAttribute("OwnerId") or 0)
		if isEnemyDrone or target:GetAttribute("IsMissile") == true then
			targets[#targets + 1] = { part = target, distance = (target.Position - weapon.Position).Magnitude }
		end
	end

	table.sort(targets, function(a, b) return a.distance < b.distance end)
	for _, entry in ipairs(targets) do
		local target = entry.part
		local last = state.lastTargetTime[target] or 0
		if os.clock() - last < targetDelay then continue end
		if not target.Parent then
			state.lastTargetTime[target] = nil
			continue
		end
		state.lastTargetTime[target] = os.clock()

		local beam = Instance.new("Part")
		beam.Name = "PointDefenceBeam"
		beam.Size = Vector3.new(0.1, 0.1, entry.distance)
		beam.Color = Color3.fromRGB(100, 200, 255)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		beam.CFrame = CFrame.lookAt((weapon.Position + target.Position) / 2, target.Position) * CFrame.Angles(math.rad(90), 0, 0)
		beam.Parent = Workspace
		Debris:AddItem(beam, 0.05)

		if target:GetAttribute("IsDrone") then
			local hp = (target:GetAttribute("DroneHP") or 50) - dps * 0.1
			target:SetAttribute("DroneHP", hp)
			if hp <= 0 then target:Destroy() end
		elseif target:GetAttribute("IsMissile") then
			local hp = (target:GetAttribute("MissileHP") or 25) - dps * 0.1
			target:SetAttribute("MissileHP", hp)
			if hp <= 0 then target:Destroy() end
		end
	end
end

local function spawnLaser(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local startPosition = getMuzzlePosition(weapon, aimCFrame)
	local endPosition = startPosition + aimCFrame.LookVector * definition.Range
	SoundManager.PlayWeapon("Laser", startPosition)

	local beam = Instance.new("Part")
	beam.Name = "LaserBeam"
	beam.Size = Vector3.new(0.5, 0.5, definition.Range)
	beam.BrickColor = BrickColor.new(definition.LaserColor)
	beam.Material = Enum.Material.Neon
	beam.Shape = Enum.PartType.Cylinder
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.3
	beam.CFrame = CFrame.lookAt((startPosition + endPosition) / 2, endPosition) * CFrame.Angles(math.rad(90), 0, 0)
	beam.Parent = Workspace

	local hitbox = Instance.new("Part")
	hitbox.Name = "LaserHitbox"
	hitbox.Size = Vector3.new(1, 1, definition.Range)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = true
	hitbox.CFrame = beam.CFrame
	hitbox.Parent = Workspace

	local duration = definition.Duration or 0.3
	Debris:AddItem(beam, duration)
	Debris:AddItem(hitbox, duration)

	hitbox.Touched:Connect(function(hit)
		if not hitbox.Parent or hit:IsDescendantOf(ship) then return end
		local victimShip = getOwnerShip(hit)
		if victimShip and victimShip ~= ship then
			applyDamage(hit, definition.Damage * 0.1, "Energy", ship, hit.Position)
		end
	end)
end

local function scramblerPulse(ship: Model, weapon: BasePart, definition: any)
	local position = weapon.Position
	SoundManager.PlayWeapon("ScramblerPulse", position)

	local ring = Instance.new("Part")
	ring.Name = "ScramblerRing"
	ring.Size = Vector3.new(0.5, HEIGHT, 0.5)
	ring.Shape = Enum.PartType.Cylinder
	ring.Transparency = 0.5
	ring.BrickColor = BrickColor.new(definition.PulseColor)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.Position = Vector3.new(position.X, HEIGHT, position.Z)
	ring.Parent = Workspace

	task.spawn(function()
		for index = 1, 10 do
			local scale = definition.Radius * 2 * (index / 10) / UNIT
			ring.Size = Vector3.new(scale, HEIGHT, scale)
			ring.Transparency = 0.5 + 0.4 * (index / 10)
			task.wait(0.03)
		end
		if ring.Parent then ring:Destroy() end
	end)

	for _, target in ipairs(Workspace:GetPartBoundsInRadius(position, definition.Radius)) do
		if target:GetAttribute("IsMissile") and target:GetAttribute("HomingActive") then
			target:SetAttribute("HomingActive", false)
			local direction = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
			if direction.Magnitude > 0 then target.AssemblyLinearVelocity = direction.Unit * 80 end
		end
	end
end

local function ensureShipState(ship: Model)
	if shipCapacitors[ship] and shipShields[ship] then return end

	if not shipCapacitors[ship] then
		local capacitor = CapacitorSystem.new()
		capacitor:CalculateFromShip(ship)
		shipCapacitors[ship] = capacitor
	end

	if not shipShields[ship] then
		local shield = ShieldSystem.new()
		shield:CalculateFromShip(ship)
		shipShields[ship] = shield
	end
end

local function updateShipState(ship: Model, dt: number)
	ensureShipState(ship)
	local capacitor = shipCapacitors[ship]
	local shield = shipShields[ship]
	if not capacitor then return end

	capacitor:Recharge(dt)
	ship:SetAttribute("EnergyPercent", capacitor:GetEnergyPercent())
	if shield then
		shield:Step(dt)
		ship:SetAttribute("ShieldHP", shield.CurrentHP)
	end
end

RunService.Heartbeat:Connect(function(dt)
	ballistics:Step(dt, function(projectile, targetBody, hitPosition)
		local victimShip = targetBody and targetBody.RobloxModel
		if not victimShip then return end
		local parts = getComponentParts(victimShip)
		if #parts == 0 then return end
		local hitPart = parts[math.random(1, #parts)]
		applyDamage(hitPart, projectile.BaseDamage, projectile.DamageType, nil, hitPosition)
	end)

	for _, ship in pairs(ShipRegistry.GetAll()) do
		if not ship.Parent then continue end
		updateShipState(ship, dt)
		for _, part in ipairs(getComponentParts(ship)) do
			local typeName = getComponentType(part)
			local definition = typeName and Components.Types[typeName]
			if typeName == "DroneBay" and definition then
				spawnDrone(ship, part, definition)
			elseif typeName == "PointDefence" and definition then
				runPointDefence(ship, part, definition)
			end
		end
	end
end)

FireWeaponEvent.OnServerEvent:Connect(function(player: Player, ship: any, weaponName: any, aimDirection: any)
	if not checkRateLimit(player) then return end
	local valid, err = validatePlayer(player)
	if not valid then warn("[WeaponController] " .. err); return end
	valid, err = validateShip(player, ship)
	if not valid then warn("[WeaponController] " .. err); return end

	local weapon: BasePart?
	local typeName: string?
	local definition: any
	valid, err, weapon, typeName, definition = validateWeaponPart(ship, weaponName)
	if not valid or not weapon or not typeName or not definition then
		warn("[WeaponController] " .. (err or "Invalid weapon")); return
	end

	local aimValid, aimErr, aimDir = validateAimDirection(aimDirection)
	if not aimValid then warn("[WeaponController] " .. (aimErr or "Invalid aim direction")); return end

	local now = os.clock()
	local cooldown = definition.FireRate or definition.Cooldown or 0.5
	if now < (weaponCooldowns[weapon] or 0) + cooldown then return end

	ensureShipState(ship)
	local capacitor = shipCapacitors[ship]
	local powerCost = definition.PowerPerShot or 0
	if powerCost > 0 and (not capacitor or not capacitor:Consume(powerCost)) then return end
	weaponCooldowns[weapon] = now

	local aimCFrame = aimDir and CFrame.lookAt(weapon.Position, weapon.Position + aimDir) or weapon.CFrame
	if typeName == "MassDriver" then
		spawnMassDriverProjectile(ship, weapon, definition, aimCFrame)
	elseif typeName == "PlasmaBall" then
		spawnPlasmaProjectile(ship, weapon, definition, aimCFrame)
	elseif typeName == "PlasmaTurret" then
		local muzzle1 = weapon:FindFirstChild("Muzzle")
		local muzzle2 = weapon:FindFirstChild("Muzzle2")
		spawnPlasmaProjectile(ship, weapon, definition, aimCFrame, muzzle1 and muzzle1:IsA("Attachment") and muzzle1.Position or Vector3.new(0, 0, 4))
		if muzzle2 and muzzle2:IsA("Attachment") then
			task.delay(0.1, function()
				if weapon.Parent then spawnPlasmaProjectile(ship, weapon, definition, aimCFrame, muzzle2.Position) end
			end)
		end
	elseif typeName == "MissileLauncher" then
		spawnMissiles(ship, weapon, definition, aimCFrame)
	elseif typeName == "DroneBay" then
		spawnDrone(ship, weapon, definition)
	elseif typeName == "Laser" then
		spawnLaser(ship, weapon, definition, aimCFrame)
	elseif typeName == "PointDefence" then
		runPointDefence(ship, weapon, definition)
	end
end)

FireScramblerEvent.OnServerEvent:Connect(function(player: Player, ship: any, scramblerName: any)
	if not checkRateLimit(player) then return end
	local valid, err = validatePlayer(player)
	if not valid then warn("[WeaponController] " .. err); return end
	valid, err = validateShip(player, ship)
	if not valid then warn("[WeaponController] " .. err); return end
	if typeof(scramblerName) ~= "string" or scramblerName == "" then
		warn("[WeaponController] Invalid scrambler name"); return
	end

	local scrambler = ship:FindFirstChild(scramblerName, true)
	if not scrambler or not scrambler:IsA("BasePart") or not scrambler:IsDescendantOf(ship) then
		warn("[WeaponController] Scrambler not found"); return
	end

	local typeName = getComponentType(scrambler)
	if typeName ~= "ScramblerPulse" then
		warn("[WeaponController] Not a scrambler component"); return
	end
	local definition = Components.Types[typeName]
	if not definition then return end

	local now = os.clock()
	local cooldown = definition.Cooldown or 0
	if now < (scramblerCooldowns[scrambler] or 0) + cooldown then return end

	ensureShipState(ship)
	local capacitor = shipCapacitors[ship]
	local powerCost = definition.PowerCost or 0
	if powerCost > 0 and (not capacitor or not capacitor:Consume(powerCost)) then return end

	scramblerCooldowns[scrambler] = now
	scramblerPulse(ship, scrambler, definition)
end)

print("[WeaponController] Canonical authority controller loaded")
