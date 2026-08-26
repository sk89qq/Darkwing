--[=[
	VoidHunter Weapon Controller (Server)
	
	Existing weapon/combat implementation retained, but component lifecycle is now
	centralized through ComponentAuthority + StructuralAuthority.

	Compatibility tables `partHealth` / `partMaxHealth` intentionally remain as
	views so existing weapon code does not need to be duplicated or rewritten;
	they no longer own state.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Components = require(ReplicatedStorage.VoidHunterComponents)
local SoundManager = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local CombatTypes = require(ReplicatedStorage.Shared.Combat.CombatTypes)
local CapacitorSystem = require(ReplicatedStorage.Shared.Combat.CapacitorSystem)
local ShieldSystem = require(ReplicatedStorage.Shared.Combat.ShieldSystem)
local BallisticsEngine = require(ReplicatedStorage.Shared.Combat.BallisticsEngine)
local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))
local UNIT = 7

-- Create RemoteEvents if they don't exist
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

-- State tracking
local weaponCooldowns = {}
local shipEnergy = {}
local shipShields = {} :: { [Model]: any }
local shipCapacitors = {} :: { [Model]: any }
local scramblerCooldowns = {}
local ballistics = BallisticsEngine.new(nil)

-- Rate limiting (max requests per second per player)
local RATE_LIMIT = 20
local playerRequestCounts = {}

-- Helper Functions
local function getComponentType(part: BasePart): string?
	local state = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
	return state and state.TypeName or nil
end

local function isHull(part)
	local name = part.Name
	return name == "Light Hull" or name == "Medium Hull" or name == "Heavy Hull"
end

local function getOwnerShip(part)
	local model = part and part:FindFirstAncestorOfClass("Model")
	return model and model:GetAttribute("IsShip") and model or nil
end

local function getShipParts(ship)
	local parts = {}
	for _, child in ipairs(ship:GetDescendants()) do
		if child:IsA("BasePart") and not child:IsA("VehicleSeat") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function findNearestEnemy(ship, range)
	local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	local nearest, nearestDist = nil, range

	for _, obj in pairs(ShipRegistry.GetAll()) do
		if obj ~= ship then
			local objPos = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position
			local dist = (objPos - shipPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = obj
			end
		end
	end

	return nearest
end

-- Input Validation Functions
local function validatePlayer(player)
	if not player or not player.Parent then
		return false, "Invalid player"
	end
	return true
end

local function validateShip(player: Player, ship: Model): (boolean, string?)
	if not ship or not ship.Parent then
		return false, "Invalid ship"
	end
	if not ship:GetAttribute("IsShip") then
		return false, "Not a valid ship"
	end
	if not ShipRegistry.IsOwner(player, ship) then
		return false, "Ship ownership mismatch"
	end
	return true
end

local function validateWeaponPart(ship, weaponName)
	if type(weaponName) ~= "string" or weaponName == "" then
		return false, "Invalid weapon name"
	end
	local weapon = ship:FindFirstChild(weaponName, true)
	if not weapon or not weapon:IsA("BasePart") then
		return false, "Weapon not found"
	end
	local typeName = getComponentType(weapon)
	if not typeName then
		return false, "Unknown weapon type"
	end
	local def = Components.Types[typeName]
	if not def or not def.Damage then
		return false, "Not a weapon component"
	end
	return true, weapon, typeName, def
end

local function validateAimDirection(aimDir)
	if not aimDir then
		return true, nil
	end
	if typeof(aimDir) ~= "Vector3" then
		return false, "Invalid aim direction type"
	end
	if aimDir ~= aimDir or aimDir.Magnitude < 0.001 then
		return false, "Invalid aim direction"
	end
	return true, aimDir.Unit
end

local function checkRateLimit(player)
	local now = os.clock()
	local userId = player.UserId
	if not playerRequestCounts[userId] then
		playerRequestCounts[userId] = { count = 0, resetTime = now + 1 }
	end
	local data = playerRequestCounts[userId]
	if now > data.resetTime then
		data.count = 0
		data.resetTime = now + 1
	end
	data.count += 1
	return data.count <= RATE_LIMIT
end

-- Damage System.
local function applyDamage(part, damage, damageTypeOrIsPlasma, attackerShip, hitPosition)
	if not part or not part:IsA("BasePart") or typeof(damage) ~= "number" or damage <= 0 then
		return
	end

	if attackerShip then
		local attackerTeam = TeamIdentity.Get(attackerShip)
		local victimModel = part:FindFirstAncestorOfClass("Model")
		local victimTeam = victimModel and TeamIdentity.Get(victimModel)
		if attackerTeam and victimTeam and attackerTeam == victimTeam then
			return
		end
	end

	local victimShip = getOwnerShip(part)
	local damageType: CombatTypes.DamageType = "Kinetic"
	if typeof(damageTypeOrIsPlasma) == "boolean" then
		damageType = damageTypeOrIsPlasma and "Thermal" or "Kinetic"
	elseif typeof(damageTypeOrIsPlasma) == "string" then
		damageType = damageTypeOrIsPlasma :: CombatTypes.DamageType
	end

	local effectiveHullDamage = damage
	if victimShip and shipShields[victimShip] then
		local shield = shipShields[victimShip]
		effectiveHullDamage = shield:AbsorbDamage(damage, damageType)
		if shield.IsActive and effectiveHullDamage < damage then
			local shieldRing = Instance.new("Part")
			shieldRing.Name = "ShieldHitEffect"
			shieldRing.Shape = Enum.PartShape.Ball
			shieldRing.Size = Vector3.new(shield.Radius * 1.8, 1, shield.Radius * 1.8)
			shieldRing.Color = Color3.fromRGB(80, 180, 255)
			shieldRing.Material = Enum.Material.Neon
			shieldRing.Transparency = 0.6
			shieldRing.Anchored = true
			shieldRing.CanCollide = false
			local sPos = victimShip.PrimaryPart and victimShip.PrimaryPart.Position or victimShip:GetPivot().Position
			shieldRing.Position = Vector3.new(sPos.X, 3.5, sPos.Z)
			shieldRing.Parent = workspace
			Debris:AddItem(shieldRing, 0.12)
		end
	end

	if damageType == "EMP" and victimShip and shipCapacitors[victimShip] then
		shipCapacitors[victimShip]:Drain(damage * 1.5)
	end

	if (damageType == "Kinetic" or damageType == "Explosive") and victimShip and victimShip.PrimaryPart and attackerShip then
		local aPos = attackerShip.PrimaryPart and attackerShip.PrimaryPart.Position or attackerShip:GetPivot().Position
		local vPos = victimShip.PrimaryPart.Position
		local pushDir = vPos - aPos
		if pushDir.Magnitude > 0.1 then
			local impulse = pushDir.Unit * math.min(damage * 12, 400)
			victimShip.PrimaryPart.AssemblyLinearVelocity += Vector3.new(impulse.X, 0, impulse.Z) / 10
		end
	end

	if effectiveHullDamage <= 0 then
		return
	end

	local state = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
	if not state or state.MaxHealth <= 0 then
		return
	end

	-- Retain the existing prototype's thermal/hull reduction as an implementation
	-- behavior; this is not marked forensic-verified until source tracing is complete.
	if damageType == "Thermal" and isHull(part) then
		effectiveHullDamage *= 0.5
	end

	local updated, destroyed = ComponentAuthority.ApplyDamage(part, effectiveHullDamage)
	if updated and destroyed then
		destroyComponent(part)
	end
end

function destroyComponent(part)
	if not part or not part.Parent then
		return
	end

	local ship = getOwnerShip(part)
	if not ship then
		-- Projectiles/temporary combat objects are not Components and use normal
		-- transient-object cleanup instead of ship graph mutation.
		part:Destroy()
		return
	end

	local isCommandCore = part:GetAttribute("IsCore") == true or part.Name == "Command Core"

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkle_main.dds"
	emitter.Rate = 40
	emitter.Lifetime = NumberRange.new(0.1, 0.2)
	emitter.Speed = NumberRange.new(2, 6)
	emitter.Size = NumberSequence.new(0.2)
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Color = ColorSequence.new(Color3.new(1, 0.3, 0.3))
	emitter.Parent = part
	task.delay(0.05, function()
		if emitter.Parent then emitter.Enabled = false end
	end)
	Debris:AddItem(emitter, 0.5)

	ComponentAuthority.MarkDestroyed(part)

	if isCommandCore then
		-- Root/core removal is intentionally delegated to the ship-level death path.
		destroyShip(ship)
		return
	end

	-- Structural destruction is graph mutation + physical debris conversion.
	-- Do not delete the component or clone/scatter a replacement.
	StructuralAuthority.DetachComponent(ship, part, "Destroyed")
	ComponentAuthority.Clear(part)
end

function destroyShip(ship)
	if not ship or not ship.Parent then
		return
	end

	ship:SetAttribute("Destroyed", true)
	local owner
	for player, playerShip in pairs(ShipRegistry.GetAll()) do
		if playerShip == ship then
			owner = player
			break
		end
	end

	shipEnergy[ship] = nil
	shipCapacitors[ship] = nil
	shipShields[ship] = nil

	if owner then
		local character = owner.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(Vector3.new(5000, 2, 4970))
		end
		owner:SetAttribute("InShip", false)
		owner:SetAttribute("ShipType", nil)
	end

	-- Root death is a ship lifecycle event. We do not invent a clone/scatter salvage
	-- rule here; detached component behavior is handled by StructuralAuthority.
	ship:Destroy()
end

local function getMuzzlePosition(weapon, aimCFrame)
	local muzzleAttach = nil
	for _, child in ipairs(weapon:GetChildren()) do
		if child:IsA("Attachment") and child.Name == "Muzzle" then
			muzzleAttach = child
			break
		end
	end
	if muzzleAttach then
		return weapon.CFrame:PointToWorldSpace(muzzleAttach.Position)
	end
	return weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
end

local function spawnMassDriverProjectile(ship, weapon, def, aimCFrame)
	aimCFrame = aimCFrame or weapon.CFrame
	local spawnPos = getMuzzlePosition(weapon, aimCFrame)
	SoundManager.PlayWeapon("MassDriver", spawnPos)

	local projectile = Instance.new("Part")
	projectile.Name = "MD_Projectile"
	projectile.Size = Vector3.new(0.5, 0.3, 1) * (UNIT / 7)
	projectile.BrickColor = BrickColor.new(def.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartShape.Cylinder
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Position = spawnPos
	projectile.CFrame = aimCFrame
	projectile.Parent = workspace

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * def.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = projectile
	Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)

	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) then return end
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			applyDamage(hit, def.Damage, false, ship, projectile.Position)
			projectile:Destroy()
		end
	end)
end

local function spawnPlasmaProjectile(ship, weapon, def, aimCFrame, muzzleOffset)
	aimCFrame = aimCFrame or weapon.CFrame
	local spawnPos = getMuzzlePosition(weapon, aimCFrame)
	if muzzleOffset then
		spawnPos = weapon.CFrame:PointToWorldSpace(muzzleOffset)
	end

	SoundManager.PlayWeapon("PlasmaBall", spawnPos)
	local projectile = Instance.new("Part")
	projectile.Name = "Plasma_Projectile"
	projectile.Size = Vector3.new(1, 1, 1) * (UNIT / 7) * 2
	projectile.BrickColor = BrickColor.new(def.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartShape.Ball
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Position = spawnPos
	projectile.CFrame = aimCFrame
	projectile.Parent = workspace
	projectile:SetAttribute("IsPlasma", true)

	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 8
	light.Color = def.ProjectileColor
	light.Parent = projectile

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * def.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = projectile

	local touchedParts = {}
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) or touchedParts[hit] then return end
		touchedParts[hit] = true
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			task.spawn(function()
				while projectile.Parent and hit.Parent do
					applyDamage(hit, def.TickDamage * 0.5, true, ship, projectile.Position)
					task.wait(0.5)
				end
			end)
		end
	end)

	Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)
	task.delay(def.Range / def.ProjectileSpeed, function()
		if projectile.Parent then
			for _, part in ipairs(workspace:GetPartBoundsInRadius(projectile.Position, 4)) do
				local owner = getOwnerShip(part)
				if owner and owner ~= ship then
					applyDamage(part, def.Damage, true, ship, projectile.Position)
				end
			end
			projectile:Destroy()
		end
	end)
end

local function spawnMissiles(ship, weapon, def, aimCFrame)
	aimCFrame = aimCFrame or weapon.CFrame
	local spawnPos = getMuzzlePosition(weapon, aimCFrame)
	local spreadAngle = math.rad(def.SpreadAngle or 15)
	SoundManager.PlayWeapon("MissileLauncher", spawnPos)

	for i = 1, 2 do
		local offset = i == 1 and CFrame.Angles(0, spreadAngle, 0) or CFrame.Angles(0, -spreadAngle, 0)
		local projectile = Instance.new("Part")
		projectile.Name = "Missile_" .. i
		projectile.Size = Vector3.new(0.5, 0.5, 0.5)
		projectile.BrickColor = BrickColor.new(def.ProjectileColor)
		projectile.Material = Enum.Material.Neon
		projectile.Shape = Enum.PartShape.Ball
		projectile.Anchored = false
		projectile.CanCollide = true
		projectile.Position = spawnPos
		projectile.CFrame = aimCFrame * offset
		projectile.Parent = workspace
		projectile:SetAttribute("IsMissile", true)
		projectile:SetAttribute("MissileHP", def.MissileHP or 25)

		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = (aimCFrame * offset).LookVector * def.ProjectileSpeed
		velocity.MaxForce = Vector3.new(1e4, 0, 1e4)
		velocity.Parent = projectile

		local target = findNearestEnemy(ship, def.Range)
		if target then
			projectile:SetAttribute("HomingActive", true)
			task.spawn(function()
				while projectile.Parent and projectile:GetAttribute("HomingActive") do
					local targetPos = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
					if (targetPos - projectile.Position).Magnitude > 0.1 then
						velocity.Velocity = (targetPos - projectile.Position).Unit * def.ProjectileSpeed
					end
					task.wait(0.1)
				end
			end)
		end

		projectile.Touched:Connect(function(hit)
			if not projectile.Parent or hit:IsDescendantOf(ship) then return end
			if hit:GetAttribute("IsMissile") or hit:GetAttribute("IsPlasma") or hit.Name == "MD_Projectile" then
				local missileHP = projectile:GetAttribute("MissileHP") or 25
				projectile:SetAttribute("MissileHP", missileHP - 25)
				if missileHP - 25 <= 0 then projectile:Destroy() end
				return
			end
			local owner = getOwnerShip(hit)
			if owner and owner ~= ship then
				applyDamage(hit, def.Damage, false, ship, projectile.Position)
				projectile:Destroy()
			end
		end)
		Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)
	end
end

local function getDroneSpawnPosition(weapon)
	for _, child in ipairs(weapon:GetChildren()) do
		if child:IsA("Attachment") and child.Name == "DroneSpawn" then
			return weapon.CFrame:PointToWorldSpace(child.Position)
		end
	end
	return weapon.Position + Vector3.new(0, 2, 0)
end

local droneBayStates = {}

local function spawnDrone(ship, weapon, def)
	if not droneBayStates[weapon] then
		droneBayStates[weapon] = { activeDrones = {}, lastSpawnTime = 0 }
	end
	local state = droneBayStates[weapon]
	local maxDrones = def.MaxDrones or 3
	if #state.activeDrones >= maxDrones then return end

	local energyCost = def.EnergyPerDrone or 20
	local energyData = shipEnergy[ship]
	if not energyData or energyData.current < energyCost then return end
	energyData.current -= energyCost

	SoundManager.PlayWeapon("DroneBay", weapon.Position)
	local spawnPos = getDroneSpawnPosition(weapon)
	local drone = Instance.new("Part")
	drone.Name = "Drone_" .. tostring(ship)
	drone.Size = Vector3.new(0.5, 0.5, 0.5)
	drone.Color = Color3.fromRGB(255, 50, 50)
	drone.Material = Enum.Material.Neon
	drone.Shape = Enum.PartShape.Ball
	drone.Anchored = false
	drone.CanCollide = true
	drone.Position = spawnPos
	drone.Parent = workspace
	drone:SetAttribute("DroneHP", def.DroneHP or 50)
	drone:SetAttribute("DroneMaxHP", def.DroneHP or 50)
	drone:SetAttribute("DroneEnergy", 50)
	drone:SetAttribute("DroneOwnerShip", ship:GetAttribute("OwnerId") or 0)
	drone:SetAttribute("IsDrone", true)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 100, 100)
	light.Brightness = 2
	light.Range = 10
	light.Parent = drone
	table.insert(state.activeDrones, drone)

	task.spawn(function()
		local fireTimer = 0
		local droneEnergy = 50
		local energyRegen = def.DroneEnergyRegen or 25
		while drone.Parent do
			droneEnergy = math.min(100, droneEnergy + energyRegen * 0.1)
			drone:SetAttribute("DroneEnergy", droneEnergy)
			local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			local orbitRadius = 8
			local orbitSpeed = def.DroneSpeed or 60
			local angle = os.clock() * (orbitSpeed / orbitRadius)
			local targetPos = shipPos + Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
			local direction = targetPos - drone.Position
			if direction.Magnitude > 1 then
				drone.AssemblyLinearVelocity = direction.Unit * orbitSpeed
			else
				drone.AssemblyLinearVelocity = Vector3.zero
			end
			fireTimer += 0.1
			local fireRate = def.DroneFireRate or 0.2
			local shotEnergy = 10
			if fireTimer >= fireRate and droneEnergy >= shotEnergy then
				fireTimer = 0
				local enemy = findNearestEnemy(ship, def.DroneRange or 30)
				if enemy then
					droneEnergy -= shotEnergy
					local enemyPos = enemy.PrimaryPart and enemy.PrimaryPart.Position or enemy:GetPivot().Position
					local beam = Instance.new("Part")
					beam.Name = "DroneLaser"
					beam.Size = Vector3.new(0.15, 0.15, (enemyPos - drone.Position).Magnitude)
					beam.Color = Color3.fromRGB(255, 50, 50)
					beam.Material = Enum.Material.Neon
					beam.Anchored = true
					beam.CanCollide = false
					local mid = (drone.Position + enemyPos) / 2
					beam.CFrame = CFrame.lookAt(mid, enemyPos) * CFrame.Angles(math.rad(90), 0, 0)
					beam.Parent = workspace
					Debris:AddItem(beam, 0.1)
					for _, part in ipairs(workspace:GetPartBoundsInRadius(enemyPos, 3)) do
						local owner = getOwnerShip(part)
						if owner and owner ~= ship then applyDamage(part, def.DroneDamage or 5, false, ship, enemyPos) end
					end
				end
			end
			task.wait(0.1)
		end
	end)

	drone.Touched:Connect(function(hit)
		if hit:GetAttribute("IsPointDefence") or not drone.Parent then return end
		local hp = drone:GetAttribute("DroneHP") or 50
		drone:SetAttribute("DroneHP", hp - 10)
		if hp - 10 <= 0 then drone:Destroy() end
	end)
end

local pointDefenceStates = {}

local function runPointDefence(ship, weapon, def)
	if not pointDefenceStates[weapon] then pointDefenceStates[weapon] = { targets = {}, lastTargetTime = {} } end
	local state = pointDefenceStates[weapon]
	local range = def.Range or 45
	local dps = def.DamagePerSecond or 25
	local targetDelay = def.TargetingDelay or 1
	local targets = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local isTarget = false
			if obj:GetAttribute("IsDrone") then
				local ownerShip = obj:GetAttribute("DroneOwnerShip")
				isTarget = ownerShip ~= (ship:GetAttribute("OwnerId") or 0)
			end
			if obj:GetAttribute("IsMissile") then isTarget = true end
			if isTarget then
				local dist = (obj.Position - weapon.Position).Magnitude
				if dist <= range then table.insert(targets, { part = obj, distance = dist }) end
			end
		end
	end

	table.sort(targets, function(a, b) return a.distance < b.distance end)
	for _, target in ipairs(targets) do
		local targetPart = target.part
		local lastTarget = state.lastTargetTime[targetPart] or 0
		if os.clock() - lastTarget < targetDelay then continue end
		if not targetPart or not targetPart.Parent then
			state.lastTargetTime[targetPart] = nil
			continue
		end

		state.lastTargetTime[targetPart] = os.clock()
		local beam = Instance.new("Part")
		beam.Name = "PointDefenceBeam"
		beam.Size = Vector3.new(0.1, 0.1, (targetPart.Position - weapon.Position).Magnitude)
		beam.Color = Color3.fromRGB(100, 200, 255)
		beam.Material = Enum.Material.Neon
		beam.Anchored = true
		beam.CanCollide = false
		local mid = (weapon.Position + targetPart.Position) / 2
		beam.CFrame = CFrame.lookAt(mid, targetPart.Position) * CFrame.Angles(math.rad(90), 0, 0)
		beam.Parent = workspace
		Debris:AddItem(beam, 0.05)

		if targetPart:GetAttribute("IsDrone") then
			local hp = targetPart:GetAttribute("DroneHP") or 50
			targetPart:SetAttribute("DroneHP", hp - dps * 0.1)
			if hp - dps * 0.1 <= 0 then targetPart:Destroy() end
		elseif targetPart:GetAttribute("IsMissile") then
			local hp = targetPart:GetAttribute("MissileHP") or 25
			targetPart:SetAttribute("MissileHP", hp - dps * 0.1)
			if hp - dps * 0.1 <= 0 then targetPart:Destroy() end
		end
	end
end

local function spawnLaser(ship, weapon, def, aimCFrame)
	aimCFrame = aimCFrame or weapon.CFrame
	local startPos = getMuzzlePosition(weapon, aimCFrame)
	local endPos = startPos + aimCFrame.LookVector * def.Range
	SoundManager.PlayWeapon("Laser", startPos)

	local beam = Instance.new("Part")
	beam.Name = "LaserBeam"
	beam.Size = Vector3.new(0.5, 0.5, def.Range)
	beam.BrickColor = BrickColor.new(def.LaserColor)
	beam.Material = Enum.Material.Neon
	beam.Shape = Enum.PartShape.Cylinder
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.3
	local mid = (startPos + endPos) / 2
	beam.CFrame = CFrame.lookAt(mid, endPos) * CFrame.Angles(math.rad(90), 0, 0)
	beam.Position = Vector3.new(mid.X, 3.5, mid.Z)
	beam.Parent = workspace

	local hitbox = Instance.new("Part")
	hitbox.Name = "LaserHitbox"
	hitbox.Size = Vector3.new(1, 1, def.Range)
	hitbox.Transparency = 1
	hitbox.CanCollide = true
	hitbox.Anchored = true
	hitbox.CFrame = beam.CFrame
	hitbox.Position = beam.Position
	hitbox.Parent = workspace
	Debris:AddItem(hitbox, def.Duration or 0.3)
	Debris:AddItem(beam, def.Duration or 0.3)

	local hitSet = {}
	hitbox.Touched:Connect(function(hit)
		if not hitbox.Parent or hit:IsDescendantOf(ship) or hitSet[hit] then return end
		hitSet[hit] = true
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			task.spawn(function()
				while hitbox.Parent and hit.Parent do
					applyDamage(hit, def.Damage * 0.1, false, ship, hit.Position)
					task.wait(0.1)
				end
			end)
		end
	end)
end

local function scramblerPulse(ship, weapon, def)
	local pos = weapon.Position
	SoundManager.PlayWeapon("ScramblerPulse", pos)
	local ring = Instance.new("Part")
	ring.Name = "ScramblerRing"
	ring.Size = Vector3.new(0.5, 3.5, 0.5)
	ring.Shape = Enum.PartShape.Cylinder
	ring.Transparency = 0.5
	ring.BrickColor = BrickColor.new(def.PulseColor)
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.Position = Vector3.new(pos.X, 3.5, pos.Z)
	ring.Parent = workspace

	task.spawn(function()
		for i = 1, 10 do
			local scale = def.Radius * 2 * (i / 10) / 7
			ring.Size = Vector3.new(scale, 3.5, scale)
			ring.Transparency = 0.5 + 0.4 * (i / 10)
			task.wait(0.03)
		end
		if ring.Parent then ring:Destroy() end
	end)

	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("IsMissile") and part:GetAttribute("HomingActive") then
			if (part.Position - pos).Magnitude <= def.Radius then
				part:SetAttribute("HomingActive", false)
				local velocity = part:FindFirstChildWhichIsA("BodyVelocity")
				if velocity then
					local randomDir = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
					if randomDir.Magnitude > 0 then velocity.Velocity = randomDir.Unit * 80 end
				end
			end
		end
	end
end

function RegisterShip(ship)
	if not ship:GetAttribute("IsShip") then ship:SetAttribute("IsShip", true) end
	ComponentAuthority.BindShip(ship)
	StructuralAuthority.BindShip(ship)

	local cap = CapacitorSystem.new()
	cap:CalculateFromShip(ship)
	shipCapacitors[ship] = cap

	local shield = ShieldSystem.new()
	shield:CalculateFromShip(ship)
	shipShields[ship] = shield

	shipEnergy[ship] = {
		current = cap.CurrentEnergy,
		max = cap.MaxEnergy,
		regen = cap.BaseRegen,
		shieldActive = shield.IsActive,
		rechargeTimer = 0,
	}
end

RunService.Heartbeat:Connect(function(dt)
	ballistics:Step(dt, function(proj, targetBody, hitPos)
		if targetBody and targetBody.RobloxModel then
			local victimShip = targetBody.RobloxModel
			local shipParts = getShipParts(victimShip)
			if #shipParts > 0 then
				local hitPart = shipParts[math.random(1, #shipParts)]
				applyDamage(hitPart, proj.BaseDamage, proj.DamageType, nil, Vector3.new(hitPos.X, 3.5, hitPos.Y))
			end
		end
	end)

	for ship, data in pairs(shipEnergy) do
		if not ship.Parent then
			shipEnergy[ship] = nil
			shipCapacitors[ship] = nil
			shipShields[ship] = nil
			continue
		end

		local cap = shipCapacitors[ship]
		if cap then
			cap:Recharge(dt)
			data.current = cap.CurrentEnergy
			data.max = cap.MaxEnergy
			ship:SetAttribute("EnergyPercent", cap:GetEnergyPercent())
		else
			data.current = math.min(data.max, data.current + data.regen * dt)
			ship:SetAttribute("EnergyPercent", data.max > 0 and (data.current / data.max) or 1.0)
		end

		local shield = shipShields[ship]
		if shield then
			shield:Step(dt)
			data.shieldActive = shield.IsActive
			ship:SetAttribute("ShieldHP", shield.CurrentHP)
		end

		for _, part in ipairs(ship:GetDescendants()) do
			if part:IsA("BasePart") then
				local typeName = getComponentType(part)
				if typeName then
					local def = Components.Types[typeName]
					if def then
						if typeName == "DroneBay" then
							spawnDrone(ship, part, def)
						elseif typeName == "PointDefence" then
							runPointDefence(ship, part, def)
						end
					end
				end
			end
		end
	end
end)

FireWeaponEvent.OnServerEvent:Connect(function(player, ship, weaponName, aimDirection)
	if not checkRateLimit(player) then return end
	local valid, err = validatePlayer(player)
	if not valid then warn("[WeaponController] " .. err); return end
	valid, err = validateShip(player, ship)
	if not valid then warn("[WeaponController] " .. err); return end

	local weapon, typeName, def
	valid, err, weapon, typeName, def = validateWeaponPart(ship, weaponName)
	if not valid then warn("[WeaponController] " .. err); return end

	local aimDir
	valid, err, aimDir = validateAimDirection(aimDirection)
	if not valid then warn("[WeaponController] " .. err); return end

	local now = os.clock()
	local lastFire = weaponCooldowns[weapon] or 0
	local cooldown = def.FireRate or def.Cooldown or 0.5
	if now < lastFire + cooldown then return end

	local energyData = shipEnergy[ship]
	local powerCost = def.PowerPerShot or 0
	if energyData and powerCost > 0 and energyData.current < powerCost then return end
	if energyData then energyData.current -= powerCost end
	weaponCooldowns[weapon] = now

	local aimCFrame = aimDir and CFrame.lookAt(weapon.Position, weapon.Position + aimDir) or weapon.CFrame
	if typeName == "MassDriver" then
		spawnMassDriverProjectile(ship, weapon, def, aimCFrame)
	elseif typeName == "PlasmaBall" then
		spawnPlasmaProjectile(ship, weapon, def, aimCFrame)
	elseif typeName == "PlasmaTurret" then
		local muzzle1 = weapon:FindFirstChild("Muzzle")
		local muzzle2 = weapon:FindFirstChild("Muzzle2")
		spawnPlasmaProjectile(ship, weapon, def, aimCFrame, muzzle1 and muzzle1.Position or Vector3.new(0, 0, 4))
		if muzzle2 then
			task.wait(0.1)
			spawnPlasmaProjectile(ship, weapon, def, aimCFrame, muzzle2.Position)
		end
	elseif typeName == "MissileLauncher" then
		spawnMissiles(ship, weapon, def, aimCFrame)
	elseif typeName == "DroneBay" then
		spawnDrone(ship, weapon, def)
	elseif typeName == "Laser" then
		spawnLaser(ship, weapon, def, aimCFrame)
	elseif typeName == "PointDefence" then
		runPointDefence(ship, weapon, def)
	end
end)

FireScramblerEvent.OnServerEvent:Connect(function(player, ship, scramblerName)
	if not checkRateLimit(player) then return end
	local valid, err = validatePlayer(player)
	if not valid then warn("[WeaponController] " .. err); return end
	valid, err = validateShip(player, ship)
	if not valid then warn("[WeaponController] " .. err); return end
	if type(scramblerName) ~= "string" or scramblerName == "" then
		warn("[WeaponController] Invalid scrambler name"); return
	end

	local scrambler = ship:FindFirstChild(scramblerName, true)
	if not scrambler or not scrambler:IsA("BasePart") then
		warn("[WeaponController] Scrambler not found"); return
	end

	local typeName = getComponentType(scrambler)
	if typeName ~= "ScramblerPulse" then
		warn("[WeaponController] Not a scrambler component"); return
	end

	local def = Components.Types[typeName]
	local now = os.clock()
	local lastFire = scramblerCooldowns[scrambler] or 0
	if now < lastFire + def.Cooldown then return end

	local energyData = shipEnergy[ship]
	local powerCost = def.PowerCost or 0
	if energyData and powerCost > 0 and energyData.current < powerCost then return end
	if energyData then energyData.current -= powerCost end
	scramblerCooldowns[scrambler] = now
	scramblerPulse(ship, scrambler, def)
end)

print("[WeaponController] Loaded with centralized component authority")
