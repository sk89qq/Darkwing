--[=[
	VoidHunter PvP Systems (Server)

	Canonical integration boundary for player actions and tactical PvP systems.
	Component identity/state is delegated to ComponentAuthority.
	Ship ownership is delegated to ShipRegistry.
	Team vocabulary is delegated to TeamIdentity.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local SoundManager = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager"))

local UNIT = Components.UNIT or 7

local function ensureRemote(name: string): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if remote then
		remote:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = name
	created.Parent = ReplicatedStorage
	return created
end

local PlayerActionEvent = ensureRemote("VoidHunterPlayerAction")
local KillFeedEvent = ensureRemote("VoidHunterKillFeed")
local RespawnTimerEvent = ensureRemote("VoidHunterRespawnTimer")
local InvulnEvent = ensureRemote("VoidHunterInvulnUpdate")

local playerStats: { [Player]: {kills: number, deaths: number, assists: number} } = setmetatable({}, { __mode = "k" })
local shipInvuln: { [Model]: number } = setmetatable({}, { __mode = "k" })
local shipBoosters: { [Model]: {endTime: number, cooldownEnd: number} } = setmetatable({}, { __mode = "k" })
local shipRepairMode: { [Model]: {active: boolean, endTime: number, cooldownEnd: number} } = setmetatable({}, { __mode = "k" })
local shipSelfDestruct: { [Model]: {active: boolean, endTime: number, cooldownEnd: number} } = setmetatable({}, { __mode = "k" })
local shipGrapples: { [Model]: {target: Model?, rope: RopeConstraint?, hook: BasePart?, cooldownEnd: number} } = setmetatable({}, { __mode = "k" })
local shipShieldCooldown: { [Model]: number } = setmetatable({}, { __mode = "k" })
local recentDamage: { [Model]: { [Player]: number } } = setmetatable({}, { __mode = "k" })
local fighterBays: { [BasePart]: {fighters: {BasePart}, lastSpawnTime: number} } = setmetatable({}, { __mode = "k" })
local thrusterTrails: { [BasePart]: ParticleEmitter } = setmetatable({}, { __mode = "k" })

local CONFIG = {
	SPAWN_INVULN_TIME = 3,
	RESPAWN_TIME = 5,
	BOOST_DURATION = 3,
	BOOST_COOLDOWN = 10,
	BOOST_FORCE = 500,
	REPAIR_POWER = 15,
	REPAIR_RADIUS = 30,
	REPAIR_DURATION = 5,
	REPAIR_COOLDOWN = 15,
	REPAIR_ENERGY_COST = 30,
	SELF_DESTRUCT_TIMER = 5,
	SELF_DESTRUCT_COOLDOWN = 30,
	SELF_DESTRUCT_RADIUS = 40,
	SELF_DESTRUCT_DAMAGE = 200,
	SHIELD_TOGGLE_COOLDOWN = 2,
	GRAPPLE_MAX_LENGTH = 50,
	GRAPPLE_MIN_LENGTH = 5,
	GRAPPLE_BREAK_LENGTH = 60,
	GRAPPLE_SPRING = 100,
	GRAPPLE_COOLDOWN = 2,
	GRAPPLE_ENERGY_COST = 15,
	ASSIST_TIME_WINDOW = 5,
	FIGHTER_MAX_PER_PLAYER = 6,
	FIGHTER_SPAWN_COOLDOWN = 8,
}

local function getComponentType(part: BasePart): string?
	local typeName = part:GetAttribute("ComponentType")
	if typeof(typeName) ~= "string" or typeName == "" then
		return nil
	end
	if type(Components.Types[typeName]) ~= "table" then
		return nil
	end
	return typeName
end

local function getOwnerShip(part: Instance): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("IsShip") == true then
		return model
	end
	return nil
end

local function getShipOwner(ship: Model?): Player?
	return ship and ShipRegistry.GetOwner(ship) or nil
end

local function getShipParts(ship: Model): {BasePart}
	local parts = {}
	for _, child in ipairs(ship:GetDescendants()) do
		if child:IsA("BasePart") and not child:IsA("VehicleSeat") and not child:GetAttribute("IsDebris") then
			parts[#parts + 1] = child
		end
	end
	return parts
end

local function findNearestEnemy(ship: Model, range: number): Model?
	local shipPosition = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	local nearest: Model? = nil
	local nearestDistance = range

	for _, candidate in pairs(ShipRegistry.GetAll()) do
		if candidate ~= ship and candidate.Parent then
			local candidateTeam = TeamIdentity.Get(candidate)
			local shipTeam = TeamIdentity.Get(ship)
			if candidateTeam and shipTeam and candidateTeam ~= shipTeam then
				local candidatePosition = candidate.PrimaryPart and candidate.PrimaryPart.Position or candidate:GetPivot().Position
				local distance = (candidatePosition - shipPosition).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = candidate
				end
			end
		end
	end
	return nearest
end

local function isFriendly(shipA: Model?, shipB: Model?): boolean
	if not shipA or not shipB then return false end
	local teamA = TeamIdentity.Get(shipA)
	local teamB = TeamIdentity.Get(shipB)
	return teamA ~= nil and teamA == teamB
end

local function initPlayerStats(player: Player)
	if not playerStats[player] then
		playerStats[player] = {kills = 0, deaths = 0, assists = 0}
	end
end

local function recordDamage(victimShip: Model, attackerShip: Model)
	if not attackerShip or not victimShip then return end
	local attackerOwner = getShipOwner(attackerShip)
	if attackerOwner then
		local damageHistory = recentDamage[victimShip]
		if not damageHistory then
			damageHistory = {}
			recentDamage[victimShip] = damageHistory
		end
		damageHistory[attackerOwner] = os.clock()
		if _G.VoidHunterMatchManager and _G.VoidHunterMatchManager.RecordDamage then
			_G.VoidHunterMatchManager.RecordDamage(attackerOwner, 25)
		end
	end
end

local function recordKill(victimShip: Model, killerShip: Model?)
	local victimOwner = getShipOwner(victimShip)
	local killerOwner = getShipOwner(killerShip)

	if victimOwner then
		initPlayerStats(victimOwner)
		playerStats[victimOwner].deaths += 1
	end
	if killerOwner then
		initPlayerStats(killerOwner)
		playerStats[killerOwner].kills += 1
	end

	if _G.VoidHunterMatchManager and _G.VoidHunterMatchManager.RecordKill then
		_G.VoidHunterMatchManager.RecordKill(killerOwner, victimOwner)
	end

	local damageHistory = recentDamage[victimShip]
	if damageHistory then
		local now = os.clock()
		for attacker, timestamp in pairs(damageHistory) do
			if now - timestamp <= CONFIG.ASSIST_TIME_WINDOW and attacker ~= killerOwner then
				initPlayerStats(attacker)
				playerStats[attacker].assists += 1
			end
		end
		recentDamage[victimShip] = nil
	end

	KillFeedEvent:FireAllClients(
		killerOwner and killerOwner.Name or "Unknown",
		victimOwner and victimOwner.Name or "Unknown"
	)
end

local function applyInvulnerability(ship: Model)
	shipInvuln[ship] = os.clock() + CONFIG.SPAWN_INVULN_TIME
	InvulnEvent:FireAllClients(ship, true)
	task.delay(CONFIG.SPAWN_INVULN_TIME, function()
		shipInvuln[ship] = nil
		if ship.Parent then
			InvulnEvent:FireAllClients(ship, false)
		end
	end)
end

local function isInvulnerable(ship: Model): boolean
	local endTime = shipInvuln[ship]
	return endTime ~= nil and os.clock() < endTime
end

local function handleRespawn(player: Player)
	RespawnTimerEvent:FireClient(player, CONFIG.RESPAWN_TIME)
	task.delay(CONFIG.RESPAWN_TIME, function()
		if not player.Parent then return end
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:IsA("BasePart") then
			rootPart.CFrame = CFrame.new(5000, 2, 4970)
		end
		player:SetAttribute("InShip", false)
		player:SetAttribute("ShipType", nil)
	end)
end

local function activateSelfDestruct(player: Player, ship: Model)
	if not ship.Parent then return end
	local state = shipSelfDestruct[ship]
	local now = os.clock()
	if state and state.active then return end
	if state and now < state.cooldownEnd then return end

	shipSelfDestruct[ship] = {
		active = true,
		endTime = now + CONFIG.SELF_DESTRUCT_TIMER,
		cooldownEnd = now + CONFIG.SELF_DESTRUCT_TIMER + CONFIG.SELF_DESTRUCT_COOLDOWN,
	}

	task.spawn(function()
		for _ = 1, CONFIG.SELF_DESTRUCT_TIMER do
			if not ship.Parent then
				return
			end
			local activeState = shipSelfDestruct[ship]
			if not activeState or not activeState.active then
				return
			end
			for _, part in ipairs(getShipParts(ship)) do
				part.Color = Color3.new(1, 0.2, 0.2)
			end
			task.wait(0.3)
			if not ship.Parent then return end
			for _, part in ipairs(getShipParts(ship)) do
				local state = ComponentAuthority.Get(part)
				part.Color = state and state.BaseColor or part.Color
			end
			task.wait(0.7)
		end

		if not ship.Parent then return end
		if not shipSelfDestruct[ship] or not shipSelfDestruct[ship].active then return end

		local position = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
		for _, part in ipairs(workspace:GetPartBoundsInRadius(position, CONFIG.SELF_DESTRUCT_RADIUS)) do
			local targetShip = getOwnerShip(part)
			if targetShip and targetShip ~= ship and not isInvulnerable(targetShip) then
				local distance = (part.Position - position).Magnitude
				local falloff = math.clamp(1 - distance / CONFIG.SELF_DESTRUCT_RADIUS, 0, 1)
				part:SetAttribute("PendingDamage", CONFIG.SELF_DESTRUCT_DAMAGE * falloff)
				recordDamage(targetShip, ship)
			end
		end

		local explosion = Instance.new("Part")
		explosion.Name = "Explosion"
		explosion.Shape = Enum.PartType.Ball
		explosion.Size = Vector3.new(1, 1, 1)
		explosion.Color = Color3.new(1, 0.5, 0)
		explosion.Material = Enum.Material.Neon
		explosion.Anchored = true
		explosion.CanCollide = false
		explosion.Position = position
		explosion.Parent = workspace
		task.spawn(function()
			for index = 1, 10 do
				local scale = CONFIG.SELF_DESTRUCT_RADIUS * 2 * (index / 10)
				explosion.Size = Vector3.new(scale, scale, scale)
				explosion.Transparency = index / 10
				task.wait(0.03)
			end
			if explosion.Parent then
				explosion:Destroy()
			end
		end)

		shipSelfDestruct[ship] = nil
		local owner = ShipRegistry.GetOwner(ship)
		if owner then
			recordKill(ship, ship)
		end
		ShipRegistry.UnregisterShip(ship)
		if ship.Parent then
			ship:Destroy()
		end
	end)
end

local function activateBooster(player: Player, ship: Model)
	if not ship.Parent then return end
	local boosterCount = 0
	for _, part in ipairs(getShipParts(ship)) do
		if getComponentType(part) == "ThrusterBooster" then
			boosterCount += 1
		end
	end
	if boosterCount == 0 then return end

	local state = shipBoosters[ship]
	local now = os.clock()
	if state and now < state.endTime then return end
	if state and now < state.cooldownEnd then return end

	local energy = ship:GetAttribute("Energy")
	if typeof(energy) == "number" and energy < 20 then return end

	shipBoosters[ship] = {
		endTime = now + CONFIG.BOOST_DURATION,
		cooldownEnd = now + CONFIG.BOOST_DURATION + CONFIG.BOOST_COOLDOWN,
	}

	task.spawn(function()
		while ship.Parent and shipBoosters[ship] and os.clock() < shipBoosters[ship].endTime do
			local primary = ship.PrimaryPart
			if primary then
				primary:ApplyImpulse(primary.CFrame.LookVector * CONFIG.BOOST_FORCE)
			end
			task.wait(0.1)
		end
	end)

	for _, part in ipairs(getShipParts(ship)) do
		if getComponentType(part) == "ThrusterBooster" then
			local light = part:FindFirstChild("BoostLight")
			if not light then
				local createdLight = Instance.new("PointLight")
				createdLight.Name = "BoostLight"
				createdLight.Color = Color3.new(1, 0.3, 0)
				createdLight.Brightness = 5
				createdLight.Range = 20
				createdLight.Parent = part
				light = createdLight
			end
			if light:IsA("PointLight") then
				light.Enabled = true
				task.delay(CONFIG.BOOST_DURATION, function()
					if light.Parent then
						light.Enabled = false
					end
				end)
			end
		end
	end
end

local function activateRepairMode(player: Player, ship: Model)
	if not ship.Parent then return end

	local hasReactor = false
	for _, part in ipairs(getShipParts(ship)) do
		if getComponentType(part) == "Reactor" then
			hasReactor = true
			break
		end
	end
	if not hasReactor then return end

	local state = shipRepairMode[ship]
	local now = os.clock()
	if state and state.active then return end
	if state and now < state.cooldownEnd then return end

	shipRepairMode[ship] = {
		active = true,
		endTime = now + CONFIG.REPAIR_DURATION,
		cooldownEnd = now + CONFIG.REPAIR_DURATION + CONFIG.REPAIR_COOLDOWN,
	}

	local aura = Instance.new("Part")
	aura.Name = "RepairAura"
	aura.Shape = Enum.PartType.Ball
	aura.Size = Vector3.new(CONFIG.REPAIR_RADIUS * 2, 6, CONFIG.REPAIR_RADIUS * 2)
	aura.Color = Color3.new(0, 1, 0.5)
	aura.Material = Enum.Material.Neon
	aura.Transparency = 0.8
	aura.Anchored = true
	aura.CanCollide = false
	aura.Parent = workspace

	task.spawn(function()
		while ship.Parent and shipRepairMode[ship] and shipRepairMode[ship].active and os.clock() < shipRepairMode[ship].endTime do
			local position = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			aura.Position = Vector3.new(position.X, 3.5, position.Z)

			for _, targetShip in pairs(ShipRegistry.GetAll()) do
				if targetShip ~= ship and isFriendly(ship, targetShip) then
					local targetPosition = targetShip.PrimaryPart and targetShip.PrimaryPart.Position or targetShip:GetPivot().Position
					if (targetPosition - position).Magnitude <= CONFIG.REPAIR_RADIUS then
						for _, part in ipairs(getShipParts(targetShip)) do
							local componentState = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
							if componentState and not componentState.Destroyed and componentState.Health < componentState.MaxHealth then
								ComponentAuthority.Repair(part, CONFIG.REPAIR_POWER * 0.1)
							end
						end
					end
				end
			end
			task.wait(0.1)
		end

		if aura.Parent then
			aura:Destroy()
		end
		if shipRepairMode[ship] then
			shipRepairMode[ship].active = false
		end
	end)
end

local function fireGrapple(player: Player, ship: Model)
	if not ship.Parent then return end

	local hookWeapon: BasePart? = nil
	for _, part in ipairs(getShipParts(ship)) do
		if getComponentType(part) == "GrapplingHook" then
			hookWeapon = part
			break
		end
	end
	if not hookWeapon then return end

	local state = shipGrapples[ship]
	if state and state.target then
		if state.rope and state.rope.Parent then state.rope:Destroy() end
		if state.hook and state.hook.Parent then state.hook:Destroy() end
		shipGrapples[ship] = nil
		return
	end

	local now = os.clock()
	if state and now < state.cooldownEnd then return end

	local target = findNearestEnemy(ship, CONFIG.GRAPPLE_MAX_LENGTH)
	if not target then return end
	local targetPosition = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position

	local hook = Instance.new("Part")
	hook.Name = "GrappleHook"
	hook.Size = Vector3.new(1, 1, 1)
	hook.Color = Color3.new(0.5, 0.5, 0.4)
	hook.Material = Enum.Material.Metal
	hook.Shape = Enum.PartType.Ball
	hook.Anchored = false
	hook.CanCollide = false
	hook.Position = hookWeapon.Position
	hook.Parent = workspace

	local direction = (targetPosition - hook.Position)
	if direction.Magnitude <= 0 then
		hook:Destroy()
		return
	end

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = direction.Unit * 200
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = hook

	shipGrapples[ship] = {
		target = target,
		hook = hook,
		rope = nil,
		cooldownEnd = now + CONFIG.GRAPPLE_COOLDOWN,
	}

	task.spawn(function()
		local startTime = os.clock()
		local attached = false
		while hook.Parent and ship.Parent and os.clock() - startTime < 2 do
			local hookPosition = hook.Position
			if not target.Parent then break end
			local targetPosition2 = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
			if (hookPosition - targetPosition2).Magnitude < 5 then
				attached = true
				break
			end
			local direction2 = targetPosition2 - hookPosition
			if direction2.Magnitude > 0 then
				velocity.Velocity = direction2.Unit * 200
			end
			task.wait(0.05)
		end

		if not attached then
			if hook.Parent then hook:Destroy() end
			shipGrapples[ship] = nil
			return
		end

		velocity:Destroy()
		hook.Anchored = true
		local pullStart = os.clock()
		while ship.Parent and target.Parent and os.clock() - pullStart < 5 do
			local primary = ship.PrimaryPart
			if not primary then break end
			local targetPosition3 = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
			local delta = targetPosition3 - primary.Position
			local distance = delta.Magnitude
			if distance < CONFIG.GRAPPLE_MIN_LENGTH or distance > CONFIG.GRAPPLE_BREAK_LENGTH then break end
			if distance > 0 then
				local force = CONFIG.GRAPPLE_SPRING * math.min(distance, 30)
				primary:ApplyImpulse(delta.Unit * force * 0.01)
			end
			hook.Position = targetPosition3
			task.wait(0.05)
		end

		if hook.Parent then hook:Destroy() end
		shipGrapples[ship] = nil
	end)
end

local function spawnFighter(ship: Model, weapon: BasePart, definition: any)
	local state = fighterBays[weapon]
	if not state then
		state = {fighters = {}, lastSpawnTime = 0}
		fighterBays[weapon] = state
	end

	local totalFighters = 0
	for _, bay in pairs(fighterBays) do
		totalFighters += #bay.fighters
	end
	if totalFighters >= CONFIG.FIGHTER_MAX_PER_PLAYER then return end
	if #state.fighters >= (definition.MaxFighters or 3) then return end

	local now = os.clock()
	if now - state.lastSpawnTime < CONFIG.FIGHTER_SPAWN_COOLDOWN then return end
	state.lastSpawnTime = now

	local fighter = Instance.new("Part")
	fighter.Name = "Fighter"
	fighter.Size = Vector3.new(0.8, 0.8, 0.8)
	fighter.Color = Color3.fromRGB(100, 200, 255)
	fighter.Material = Enum.Material.Neon
	fighter.Shape = Enum.PartType.Ball
	fighter.Anchored = false
	fighter.CanCollide = true
	fighter.Position = weapon.Position + Vector3.new(0, 2, 0)
	fighter.Parent = workspace
	fighter:SetAttribute("IsFighter", true)
	fighter:SetAttribute("FighterHP", definition.FighterHP or 60)
	fighter:SetAttribute("FighterOwnerShip", ship:GetAttribute("OwnerId") or 0)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(100, 200, 255)
	light.Brightness = 2
	light.Range = 8
	light.Parent = fighter

	state.fighters[#state.fighters + 1] = fighter

	task.spawn(function()
		local fireTimer = 0
		local orbitAngle = math.random() * math.pi * 2
		while fighter.Parent do
			if not ship.Parent then
				fighter:Destroy()
				break
			end

			local shipPosition = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			local orbitRadius = 12
			local speed = definition.FighterSpeed or 80
			orbitAngle += (speed / orbitRadius) * 0.1
			local targetPosition = shipPosition + Vector3.new(math.cos(orbitAngle) * orbitRadius, 0, math.sin(orbitAngle) * orbitRadius)
			local direction = targetPosition - fighter.Position
			fighter.AssemblyLinearVelocity = direction.Magnitude > 1 and direction.Unit * speed or Vector3.zero

			fireTimer += 0.1
			if fireTimer >= (definition.FighterFireRate or 0.3) then
				fireTimer = 0
				local enemy = findNearestEnemy(ship, definition.FighterVision or 60)
				if enemy then
					local enemyPosition = enemy.PrimaryPart and enemy.PrimaryPart.Position or enemy:GetPivot().Position
					if (enemyPosition - fighter.Position).Magnitude <= (definition.FighterRange or 40) then
						local beam = Instance.new("Part")
						beam.Name = "FighterLaser"
						beam.Size = Vector3.new(0.1, 0.1, (enemyPosition - fighter.Position).Magnitude)
						beam.Color = Color3.fromRGB(100, 200, 255)
						beam.Material = Enum.Material.Neon
						beam.Anchored = true
						beam.CanCollide = false
						beam.CFrame = CFrame.lookAt((fighter.Position + enemyPosition) / 2, enemyPosition) * CFrame.Angles(math.rad(90), 0, 0)
						beam.Parent = workspace
						Debris:AddItem(beam, 0.08)

						for _, part in ipairs(workspace:GetPartBoundsInRadius(enemyPosition, 3)) do
							local owner = getOwnerShip(part)
							if owner and owner ~= ship then
								part:SetAttribute("PendingDamage", definition.FighterDamage or 10)
								recordDamage(owner, ship)
							end
						end
					end
				end
			end
			task.wait(0.1)
		end

		for index, candidate in ipairs(state.fighters) do
			if candidate == fighter then
				table.remove(state.fighters, index)
				break
			end
		end
	end)

	fighter.Touched:Connect(function()
		if not fighter.Parent then return end
		local hp = fighter:GetAttribute("FighterHP")
		if typeof(hp) ~= "number" then hp = definition.FighterHP or 60 end
		hp -= 15
		fighter:SetAttribute("FighterHP", hp)
		if hp <= 0 then
			fighter:Destroy()
		end
	end)
end

local function spawnMachineGunProjectiles(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPosition)
	for _ = 1, 3 do
		local spread = CFrame.Angles(0, math.rad(math.random(-5, 5)), 0)
		local projectile = Instance.new("Part")
		projectile.Name = "MG_Projectile"
		projectile.Size = definition.ProjectileSize
		projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
		projectile.Material = Enum.Material.Neon
		projectile.Anchored = false
		projectile.CanCollide = true
		projectile.CFrame = aimCFrame * spread
		projectile.Position = spawnPosition
		projectile.Parent = workspace

		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = (aimCFrame * spread).LookVector * definition.ProjectileSpeed
		velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
		velocity.Parent = projectile
		Debris:AddItem(projectile, definition.Range / definition.ProjectileSpeed)

		projectile.Touched:Connect(function(hit)
			if not projectile.Parent or hit:IsDescendantOf(ship) then return end
			local owner = getOwnerShip(hit)
			if owner and owner ~= ship then
				hit:SetAttribute("PendingDamage", definition.Damage)
				recordDamage(owner, ship)
				projectile:Destroy()
			end
		end)
		task.wait(0.03)
	end
end

local function spawnSpinningBlade(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPosition)
	local blade = Instance.new("Part")
	blade.Name = "SpinningBlade"
	blade.Size = definition.ProjectileSize
	blade.BrickColor = BrickColor.new(definition.ProjectileColor)
	blade.Material = Enum.Material.Neon
	blade.Anchored = false
	blade.CanCollide = true
	blade.CFrame = aimCFrame
	blade.Position = spawnPosition
	blade.Parent = workspace
	blade:SetAttribute("IsBlade", true)

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * 60
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = blade

	task.spawn(function()
		while blade.Parent do
			blade.CFrame *= CFrame.Angles(0, math.rad(72), 0)
			task.wait(0.1)
		end
	end)

	Debris:AddItem(blade, definition.Range / 60)
	local hitParts: { [BasePart]: boolean } = {}
	blade.Touched:Connect(function(hit)
		if not blade.Parent or hit:IsDescendantOf(ship) or hitParts[hit] then return end
		hitParts[hit] = true
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			task.spawn(function()
				for _ = 1, 5 do
					if not blade.Parent or not hit.Parent then break end
					hit:SetAttribute("PendingDamage", (definition.SpinDamage or definition.Damage or 0) * 0.2)
					recordDamage(owner, ship)
					task.wait(0.2)
				end
			end)
		end
	end)
end

local function spawnUbercannon(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPosition)
	local projectile = Instance.new("Part")
	projectile.Name = "Ubercannon_Projectile"
	projectile.Size = definition.ProjectileSize
	projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartType.Ball
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.CFrame = aimCFrame
	projectile.Position = spawnPosition
	projectile.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = definition.ProjectileColor
	light.Brightness = 5
	light.Range = 20
	light.Parent = projectile

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * definition.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = projectile
	Debris:AddItem(projectile, definition.Range / definition.ProjectileSpeed)

	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) then return end
		local position = projectile.Position
		local radius = definition.ExplosionRadius or 15
		for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius)) do
			local owner = getOwnerShip(part)
			if owner and owner ~= ship then
				local falloff = math.clamp(1 - (part.Position - position).Magnitude / radius, 0, 1)
				part:SetAttribute("PendingDamage", definition.Damage * falloff)
				recordDamage(owner, ship)
			end
		end

		local explosion = Instance.new("Part")
		explosion.Shape = Enum.PartType.Ball
		explosion.Size = Vector3.new(1, 1, 1)
		explosion.Color = Color3.new(1, 0.5, 0)
		explosion.Material = Enum.Material.Neon
		explosion.Anchored = true
		explosion.CanCollide = false
		explosion.Position = position
		explosion.Parent = workspace
		task.spawn(function()
			for index = 1, 8 do
				local scale = radius * 2 * (index / 8)
				explosion.Size = Vector3.new(scale, scale, scale)
				explosion.Transparency = index / 8
				task.wait(0.03)
			end
			if explosion.Parent then explosion:Destroy() end
		end)
		projectile:Destroy()
	end)
end

local function spawnTorpedo(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MissileLauncher", spawnPosition)
	local projectile = Instance.new("Part")
	projectile.Name = "Torpedo"
	projectile.Size = definition.ProjectileSize
	projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
	projectile.Material = Enum.Material.Metal
	projectile.Shape = Enum.PartType.Block
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.CFrame = aimCFrame
	projectile.Position = spawnPosition
	projectile.Parent = workspace
	projectile:SetAttribute("IsMissile", true)
	projectile:SetAttribute("MissileHP", definition.MissileHP or 50)

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * definition.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e4, 0, 1e4)
	velocity.Parent = projectile

	local target = findNearestEnemy(ship, definition.Range)
	if target then
		projectile:SetAttribute("HomingActive", true)
		task.spawn(function()
			while projectile.Parent and projectile:GetAttribute("HomingActive") do
				if not target.Parent then break end
				local targetPosition = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
				local delta = targetPosition - projectile.Position
				if delta.Magnitude > 0 then
					velocity.Velocity = delta.Unit * definition.ProjectileSpeed
				end
				task.wait(0.1)
			end
		end)
	end

	Debris:AddItem(projectile, definition.Range / definition.ProjectileSpeed)
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) then return end
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", definition.Damage)
			recordDamage(owner, ship)
			projectile:Destroy()
		end
	end)
end

local function spawnBombletSpray(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPosition)
	for _ = 1, (definition.Projectiles or 8) do
		local spread = CFrame.Angles(0, math.rad(math.random(-30, 30)), math.rad(math.random(-30, 30)))
		local bomblet = Instance.new("Part")
		bomblet.Name = "Bomblet"
		bomblet.Size = definition.ProjectileSize
		bomblet.BrickColor = BrickColor.new(definition.ProjectileColor)
		bomblet.Material = Enum.Material.Neon
		bomblet.Shape = Enum.PartType.Ball
		bomblet.Anchored = false
		bomblet.CanCollide = true
		bomblet.CFrame = aimCFrame * spread
		bomblet.Position = spawnPosition
		bomblet.Parent = workspace

		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = (aimCFrame * spread).LookVector * definition.ProjectileSpeed
		velocity.MaxForce = Vector3.new(1e4, 0, 1e4)
		velocity.Parent = bomblet
		Debris:AddItem(bomblet, definition.ProjectileLife or 1.5)

		bomblet.Touched:Connect(function(hit)
			if not bomblet.Parent or hit:IsDescendantOf(ship) then return end
			local owner = getOwnerShip(hit)
			if owner and owner ~= ship then
				hit:SetAttribute("PendingDamage", definition.Damage)
				recordDamage(owner, ship)
				bomblet:Destroy()
			end
		end)
		task.wait(0.02)
	end
end

local function spawnSniperCannon(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local spawnPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("Laser", spawnPosition)
	local projectile = Instance.new("Part")
	projectile.Name = "SniperRound"
	projectile.Size = definition.ProjectileSize
	projectile.BrickColor = BrickColor.new(definition.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.CFrame = aimCFrame
	projectile.Position = spawnPosition
	projectile.Parent = workspace

	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * definition.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = projectile
	Debris:AddItem(projectile, definition.Range / definition.ProjectileSpeed)

	local hitSet: { [BasePart]: boolean } = {}
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent or hit:IsDescendantOf(ship) or hitSet[hit] then return end
		hitSet[hit] = true
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", definition.Damage)
			recordDamage(owner, ship)
		end
	end)
end

local function spawnPhasedEnergyBeam(ship: Model, weapon: BasePart, definition: any, aimCFrame: CFrame)
	local startPosition = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("Laser", startPosition)
	local duration = definition.PulseTime or 0.2
	local beam = Instance.new("Part")
	beam.Name = "PhasedBeam"
	beam.Size = Vector3.new(0.8, 0.8, definition.Range)
	beam.BrickColor = BrickColor.new(definition.ProjectileColor)
	beam.Material = Enum.Material.Neon
	beam.Shape = Enum.PartType.Cylinder
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.2
	local midpoint = startPosition + aimCFrame.LookVector * (definition.Range / 2)
	beam.CFrame = CFrame.lookAt(midpoint, midpoint + aimCFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0)
	beam.Position = Vector3.new(midpoint.X, 3.5, midpoint.Z)
	beam.Parent = workspace

	local hitbox = Instance.new("Part")
	hitbox.Name = "PhasedHitbox"
	hitbox.Size = Vector3.new(1.5, 1.5, definition.Range)
	hitbox.Transparency = 1
	hitbox.CanCollide = true
	hitbox.Anchored = true
	hitbox.CFrame = beam.CFrame
	hitbox.Position = beam.Position
	hitbox.Parent = workspace
	Debris:AddItem(hitbox, duration)
	Debris:AddItem(beam, duration)

	local hitSet: { [BasePart]: boolean } = {}
	hitbox.Touched:Connect(function(hit)
		if not hitbox.Parent or hit:IsDescendantOf(ship) or hitSet[hit] then return end
		hitSet[hit] = true
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", definition.Damage)
			recordDamage(owner, ship)
		end
	end)
end

local function updateThrusterTrails()
	for _, ship in pairs(ShipRegistry.GetAll()) do
		if ship.Parent then
			for _, part in ipairs(getShipParts(ship)) do
				local typeName = getComponentType(part)
				if typeName == "StandardThruster" or typeName == "SmallThruster" or typeName == "ThrusterBooster" then
					if not thrusterTrails[part] then
						local emitter = Instance.new("ParticleEmitter")
						emitter.Name = "ThrusterTrail"
						emitter.Texture = "rbxasset://textures/particles/sparkle_main.dds"
						emitter.Rate = 30
						emitter.Lifetime = NumberRange.new(0.2, 0.5)
						emitter.Speed = NumberRange.new(3, 8)
						emitter.Size = NumberSequence.new(0.5, 0)
						emitter.Transparency = NumberSequence.new(0, 1)
						emitter.Color = ColorSequence.new(Color3.new(1, 0.5, 0), Color3.new(1, 0.2, 0))
						emitter.SpreadAngle = Vector2.new(20, 20)
						emitter.EmissionDirection = Enum.NormalId.Back
						emitter.Parent = part
						thrusterTrails[part] = emitter
					end
				end
			end
		end
	end
end

local function handleShieldToggle(ship: Model, action: string)
	local now = os.clock()
	if now < (shipShieldCooldown[ship] or 0) then return end
	shipShieldCooldown[ship] = now + CONFIG.SHIELD_TOGGLE_COOLDOWN

	local comms = ReplicatedStorage:FindFirstChild("Communication")
	local event = comms and comms:FindFirstChild("ShieldAction")
	if event and event:IsA("RemoteEvent") then
		-- Client -> server RemoteEvent cannot be invoked from server. The shield
		-- authority also listens to VoidHunterPlayerAction and resolves ownership.
		return
	end
end

PlayerActionEvent.OnServerEvent:Connect(function(player: Player, action: string, ...: any)
	if not player.Parent then return end
	local ship = ShipRegistry.GetShip(player)
	if not ship or not ship.Parent then return end

	if action == "SelfDestruct" then
		activateSelfDestruct(player, ship)
	elseif action == "Booster" then
		activateBooster(player, ship)
	elseif action == "RepairMode" then
		activateRepairMode(player, ship)
	elseif action == "GrappleFire" then
		fireGrapple(player, ship)
	elseif action == "ShieldToggle" then
		handleShieldToggle(ship, ...)
	elseif action == "LaunchFighters" then
		for _, part in ipairs(getShipParts(ship)) do
			if getComponentType(part) == "FighterBay" then
				local definition = Components.Types.FighterBay
				if definition then
					spawnFighter(ship, part, definition)
				end
			end
		end
	end
end)

local function registerShip(ship: Model, player: Player)
	ShipRegistry.Register(player, ship)
	StructuralAuthority.BindShip(ship)
	initPlayerStats(player)
	applyInvulnerability(ship)
end

RunService.Heartbeat:Connect(function()
	for _, instance in ipairs(workspace:GetDescendants()) do
		if not instance:IsA("BasePart") then
			continue
		end

		local pendingDamage = instance:GetAttribute("PendingDamage")
		if typeof(pendingDamage) ~= "number" or pendingDamage <= 0 then
			continue
		end
		instance:SetAttribute("PendingDamage", nil)

		local ship = getOwnerShip(instance)
		if ship and isInvulnerable(ship) then
			continue
		end

		local componentState = ComponentAuthority.Get(instance) or ComponentAuthority.Bind(instance)
		if not componentState then
			continue
		end

		local _, destroyed = ComponentAuthority.ApplyDamage(instance, pendingDamage)
		if not destroyed then
			continue
		end

		if ship then
			local definition = Components.Types[componentState.TypeName]
			local isCore = definition and definition.IsCore == true
			if isCore then
				local killerShip: Model? = nil
				local damageHistory = recentDamage[ship]
				if damageHistory then
					local latestTimestamp = 0
					local killerPlayer: Player? = nil
					for attackerPlayer, timestamp in pairs(damageHistory) do
						if timestamp > latestTimestamp then
							latestTimestamp = timestamp
							killerPlayer = attackerPlayer
						end
					end
					if killerPlayer then
						killerShip = ShipRegistry.GetShip(killerPlayer)
					end
				end

				local owner = ShipRegistry.GetOwner(ship)
				recordKill(ship, killerShip)
				if owner then
					handleRespawn(owner)
				end
				ShipRegistry.UnregisterShip(ship)
				if ship.Parent then
					ship:Destroy()
				end
			else
				StructuralAuthority.DetachComponent(ship, instance, "ComponentDestroyed")
			end
		else
			instance:Destroy()
		end
	end

	updateThrusterTrails()
end)

Players.PlayerAdded:Connect(function(player: Player)
	initPlayerStats(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerStats[player] = nil
	ShipRegistry.UnregisterPlayer(player)
end)

for _, instance in ipairs(workspace:GetDescendants()) do
	if instance:IsA("Model") and instance:GetAttribute("IsShip") == true then
		local ownerId = instance:GetAttribute("OwnerId")
		if typeof(ownerId) == "number" then
			local player = Players:GetPlayerByUserId(ownerId)
			if player then
				registerShip(instance, player)
			end
		end
	end
end

print("[PvPSystems] Loaded with ComponentAuthority, StructuralAuthority, ShipRegistry, TeamIdentity integration")
