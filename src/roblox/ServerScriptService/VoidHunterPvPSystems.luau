-- VoidHunter PvP Systems (Server)
-- Handles: Spawn invulnerability, respawn timer, K/D/A tracking,
-- Self-destruct, Booster activation, Repair mode, Grappling hook,
-- Shield toggle cooldown, Fighter bay, Machine gun, Spinning blade,
-- Ubercannon, Torpedo, Bomblet spray, Sniper cannon, Phased energy beam,
-- Thruster trails, Projectile life/penetration, Target lock

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Components = require(ReplicatedStorage.VoidHunterComponents)
local SoundManager = require(ReplicatedStorage.VoidHunters:FindFirstChild("VoidHunterSoundManager"))
local UNIT = 7

-- ============ REMOTE EVENTS ============
local function ensureRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local PlayerActionEvent = ensureRemote("VoidHunterPlayerAction")
local KillFeedEvent = ensureRemote("VoidHunterKillFeed")
local RespawnTimerEvent = ensureRemote("VoidHunterRespawnTimer")
local InvulnEvent = ensureRemote("VoidHunterInvulnUpdate")

-- ============ STATE ============
local playerStats = {} -- [player] = {kills=0, deaths=0, assists=0}
local playerShips = {} -- [player] = ship
local shipInvuln = {} -- [ship] = endTime
local shipBoosters = {} -- [ship] = {endTime=0, cooldownEnd=0}
local shipRepairMode = {} -- [ship] = {active=false, endTime=0, cooldownEnd=0}
local shipSelfDestruct = {} -- [ship] = {active=false, endTime=0, cooldownEnd=0}
local shipGrapples = {} -- [ship] = {target=nil, rope=nil, hook=nil}
local shipShieldCooldown = {} -- [ship] = cooldownEnd
local recentDamage = {} -- [victim] = {[attacker]=time}
local fighterBays = {} -- [weapon] = {fighters={}, lastSpawnTime=0}
local thrusterTrails = {} -- [part] = emitter

-- ============ CONFIGURATION ============
local CONFIG = {
	SPAWN_INVULN_TIME = 3, -- seconds of invulnerability after spawning
	RESPAWN_TIME = 5, -- seconds before respawn
	BOOST_DURATION = 3, -- seconds of boost
	BOOST_COOLDOWN = 10, -- seconds between boosts
	BOOST_FORCE = 500, -- impulse multiplier
	REPAIR_POWER = 15, -- HP per second healed
	REPAIR_RADIUS = 30, -- studs
	REPAIR_DURATION = 5, -- seconds
	REPAIR_COOLDOWN = 15, -- seconds
	REPAIR_ENERGY_COST = 30, -- energy to activate
	SELF_DESTRUCT_TIMER = 5, -- seconds countdown
	SELF_DESTRUCT_COOLDOWN = 30, -- seconds
	SELF_DESTRUCT_RADIUS = 40, -- studs
	SELF_DESTRUCT_DAMAGE = 200, -- damage at center
	SHIELD_TOGGLE_COOLDOWN = 2, -- seconds
	SHIELD_RECHARGE_DELAY = 3, -- seconds after damage before recharge
	GRAPPLE_MAX_LENGTH = 50,
	GRAPPLE_MIN_LENGTH = 5,
	GRAPPLE_BREAK_LENGTH = 60,
	GRAPPLE_SPRING = 100,
	GRAPPLE_COOLDOWN = 2,
	GRAPPLE_ENERGY_COST = 15,
	ASSIST_TIME_WINDOW = 5, -- seconds for kill assist credit
	FIGHTER_MAX_PER_PLAYER = 6,
	FIGHTER_SPAWN_COOLDOWN = 8,
}

-- ============ HELPER FUNCTIONS ============
local function getComponentType(part)
	for typeName, def in pairs(Components.Types) do
		if def.Name == part.Name then
			return typeName
		end
	end
	return nil
end

local function getOwnerShip(part)
	local model = part:FindFirstAncestorOfClass("Model")
	return model and model:GetAttribute("IsShip") and model or nil
end

local function getShipOwner(ship)
	for player, s in pairs(playerShips) do
		if s == ship then return player end
	end
	return nil
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
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:GetAttribute("IsShip") and obj ~= ship then
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

local function isFriendly(shipA, shipB)
	if not shipA or not shipB then return false end
	local teamA = shipA:GetAttribute("Team")
	local teamB = shipB:GetAttribute("Team")
	return teamA and teamB and teamA == teamB
end

-- ============ K/D/A TRACKING ============
local function initPlayerStats(player)
	if not playerStats[player] then
		playerStats[player] = {kills = 0, deaths = 0, assists = 0}
	end
end

local function recordDamage(victimShip, attackerShip)
	if not attackerShip or not victimShip then return end
	if not recentDamage[victimShip] then recentDamage[victimShip] = {} end
	local attackerOwner = getShipOwner(attackerShip)
	if attackerOwner then
		recentDamage[victimShip][attackerOwner] = tick()
		if _G.VoidHunterMatchManager and _G.VoidHunterMatchManager.RecordDamage then
			_G.VoidHunterMatchManager.RecordDamage(attackerOwner, 25)
		end
	end
end

local function recordKill(victimShip, killerShip)
	local victimOwner = getShipOwner(victimShip)
	local killerOwner = getShipOwner(killerShip)
	
	if victimOwner then
		initPlayerStats(victimOwner)
		playerStats[victimOwner].deaths = playerStats[victimOwner].deaths + 1
	end
	
	if killerOwner then
		initPlayerStats(killerOwner)
		playerStats[killerOwner].kills = playerStats[killerOwner].kills + 1
	end

	-- Notify Match Manager
	if _G.VoidHunterMatchManager and _G.VoidHunterMatchManager.RecordKill then
		_G.VoidHunterMatchManager.RecordKill(killerOwner, victimOwner)
	end
	
	-- Award assists
	if recentDamage[victimShip] then
		for attacker, time in pairs(recentDamage[victimShip]) do
			if tick() - time <= CONFIG.ASSIST_TIME_WINDOW and attacker ~= killerOwner then
				initPlayerStats(attacker)
				playerStats[attacker].assists = playerStats[attacker].assists + 1
			end
		end
		recentDamage[victimShip] = nil
	end
	
	-- Broadcast kill feed
	local victimName = victimOwner and victimOwner.Name or "Unknown"
	local killerName = killerOwner and killerOwner.Name or "Unknown"
	KillFeedEvent:FireAllClients(killerName, victimName)
end

-- ============ SPAWN INVULNERABILITY ============
local function applyInvulnerability(ship)
	shipInvuln[ship] = tick() + CONFIG.SPAWN_INVULN_TIME
	-- Visual indicator: make ship flash
	InvulnEvent:FireAllClients(ship, true)
	task.delay(CONFIG.SPAWN_INVULN_TIME, function()
		shipInvuln[ship] = nil
		InvulnEvent:FireAllClients(ship, false)
	end)
end

local function isInvulnerable(ship)
	local endTime = shipInvuln[ship]
	return endTime and tick() < endTime
end

-- ============ RESPAWN TIMER ============
local function handleRespawn(player)
	RespawnTimerEvent:FireClient(player, CONFIG.RESPAWN_TIME)
	task.delay(CONFIG.RESPAWN_TIME, function()
		if not player.Parent then return end
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(Vector3.new(5000, 2, 4970))
			end
		end
		player:SetAttribute("InShip", false)
		player:SetAttribute("ShipType", nil)
	end)
end

-- ============ SELF-DESTRUCT ============
local function activateSelfDestruct(player, ship)
	if not ship or not ship.Parent then return end
	
	local state = shipSelfDestruct[ship]
	if state and state.active then return end -- Already active
	if state and tick() < state.cooldownEnd then return end -- On cooldown
	
	shipSelfDestruct[ship] = {active = true, endTime = tick() + CONFIG.SELF_DESTRUCT_TIMER, cooldownEnd = tick() + CONFIG.SELF_DESTRUCT_TIMER + CONFIG.SELF_DESTRUCT_COOLDOWN}
	
	-- Visual/audio countdown
	for i = CONFIG.SELF_DESTRUCT_TIMER, 1, -1 do
		if not ship.Parent or not shipSelfDestruct[ship] or not shipSelfDestruct[ship].active then return end
		-- Flash the ship red
		for _, part in ipairs(getShipParts(ship)) do
			part.Color = Color3.new(1, 0.2, 0.2)
		end
		task.wait(0.3)
		if not ship.Parent then return end
		for _, part in ipairs(getShipParts(ship)) do
			part.Color = Color3.new(1, 1, 1)
		end
		task.wait(0.7)
	end
	
	if not ship.Parent or not shipSelfDestruct[ship] or not shipSelfDestruct[ship].active then return end
	
	-- EXPLODE
	local pos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	
	-- Damage everything in radius
	for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, CONFIG.SELF_DESTRUCT_RADIUS)) do
		local targetShip = getOwnerShip(part)
		if targetShip and targetShip ~= ship and not isInvulnerable(targetShip) then
			local dist = (part.Position - pos).Magnitude
			local falloff = 1 - (dist / CONFIG.SELF_DESTRUCT_RADIUS)
			local damage = CONFIG.SELF_DESTRUCT_DAMAGE * falloff
			-- Apply damage via weapon controller's applyDamage if available
			part:SetAttribute("PendingDamage", damage)
		end
	end
	
	-- Visual explosion
	local explosion = Instance.new("Part")
	explosion.Name = "Explosion"
	explosion.Shape = Enum.PartShape.Ball
	explosion.Size = Vector3.new(1, 1, 1)
	explosion.Color = Color3.new(1, 0.5, 0)
	explosion.Material = Enum.Material.Neon
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Position = pos
	explosion.Parent = workspace
	
	task.spawn(function()
		for i = 1, 10 do
			local scale = CONFIG.SELF_DESTRUCT_RADIUS * 2 * (i / 10)
			explosion.Size = Vector3.new(scale, scale, scale)
			explosion.Transparency = i / 10
			task.wait(0.03)
		end
		explosion:Destroy()
	end)
	
	-- Destroy own ship
	shipSelfDestruct[ship] = nil
	if ship.Parent then
		recordKill(ship, ship) -- Self-kill
		ship:Destroy()
	end
end

-- ============ BOOSTER ACTIVATION ============
local function activateBooster(player, ship)
	if not ship or not ship.Parent then return end
	
	-- Check if ship has ThrusterBooster components
	local hasBooster = false
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and getComponentType(part) == "ThrusterBooster" then
			hasBooster = true
			break
		end
	end
	if not hasBooster then return end
	
	local state = shipBoosters[ship]
	if state and tick() < state.endTime then return end -- Already boosting
	if state and tick() < state.cooldownEnd then return end -- On cooldown
	
	-- Energy check
	local energyAttr = ship:GetAttribute("Energy")
	if energyAttr and energyAttr < 20 then return end
	
	shipBoosters[ship] = {
		endTime = tick() + CONFIG.BOOST_DURATION,
		cooldownEnd = tick() + CONFIG.BOOST_DURATION + CONFIG.BOOST_COOLDOWN
	}
	
	-- Apply boost impulse
	task.spawn(function()
		while ship.Parent and tick() < shipBoosters[ship].endTime do
			local primary = ship.PrimaryPart
			if primary then
				local dir = primary.CFrame.LookVector
				primary:ApplyImpulse(dir * CONFIG.BOOST_FORCE)
			end
			task.wait(0.1)
		end
	end)
	
	-- Visual: thruster glow
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and getComponentType(part) == "ThrusterBooster" then
			local light = part:FindFirstChild("BoostLight")
			if not light then
				light = Instance.new("PointLight")
				light.Name = "BoostLight"
				light.Color = Color3.new(1, 0.3, 0)
				light.Brightness = 5
				light.Range = 20
				light.Parent = part
			end
			light.Enabled = true
			task.delay(CONFIG.BOOST_DURATION, function()
				if light.Parent then light.Enabled = false end
			end)
		end
	end
end

-- ============ REPAIR MODE ============
local function activateRepairMode(player, ship)
	if not ship or not ship.Parent then return end
	
	-- Check if ship has Reactor components
	local hasReactor = false
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Reactor" then
			hasReactor = true
			break
		end
	end
	if not hasReactor then return end
	
	local state = shipRepairMode[ship]
	if state and state.active then return end
	if state and tick() < state.cooldownEnd then return end
	
	shipRepairMode[ship] = {
		active = true,
		endTime = tick() + CONFIG.REPAIR_DURATION,
		cooldownEnd = tick() + CONFIG.REPAIR_DURATION + CONFIG.REPAIR_COOLDOWN
	}
	
	-- Repair aura visual
	local aura = Instance.new("Part")
	aura.Name = "RepairAura"
	aura.Shape = Enum.PartShape.Ball
	aura.Size = Vector3.new(CONFIG.REPAIR_RADIUS * 2, 6, CONFIG.REPAIR_RADIUS * 2)
	aura.Color = Color3.new(0, 1, 0.5)
	aura.Material = Enum.Material.Neon
	aura.Transparency = 0.8
	aura.Anchored = true
	aura.CanCollide = false
	aura.Parent = workspace
	
	task.spawn(function()
		while ship.Parent and shipRepairMode[ship] and shipRepairMode[ship].active and tick() < shipRepairMode[ship].endTime do
			local pos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			aura.Position = Vector3.new(pos.X, 3.5, pos.Z)
			
			-- Heal nearby allied ships
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Model") and obj:GetAttribute("IsShip") and obj ~= ship then
					if isFriendly(ship, obj) then
						local objPos = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position
						if (objPos - pos).Magnitude <= CONFIG.REPAIR_RADIUS then
							for _, part in ipairs(getShipParts(obj)) do
								local currentHP = part:GetAttribute("ComponentHP") or 50
								local maxHP = part:GetAttribute("MaxHP") or 50
								if currentHP < maxHP then
									local newHP = math.min(maxHP, currentHP + CONFIG.REPAIR_POWER * 0.1)
									part:SetAttribute("ComponentHP", newHP)
								end
							end
						end
					end
				end
			end
			
			task.wait(0.1)
		end
		
		if aura.Parent then aura:Destroy() end
		if shipRepairMode[ship] then shipRepairMode[ship].active = false end
	end)
end

-- ============ GRAPPLING HOOK ============
local function fireGrapple(player, ship)
	if not ship or not ship.Parent then return end
	
	-- Check if ship has GrapplingHook component
	local hookWeapon = nil
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and getComponentType(part) == "GrapplingHook" then
			hookWeapon = part
			break
		end
	end
	if not hookWeapon then return end
	
	local state = shipGrapples[ship]
	if state and state.target then
		-- Recall grapple
		if state.rope and state.rope.Parent then state.rope:Destroy() end
		if state.hook and state.hook.Parent then state.hook:Destroy() end
		shipGrapples[ship] = nil
		return
	end
	
	if state and tick() < state.cooldownEnd then return end
	
	-- Find nearest enemy in range
	local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	local target = findNearestEnemy(ship, CONFIG.GRAPPLE_MAX_LENGTH)
	if not target then return end
	
	local targetPos = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
	
	-- Create hook projectile
	local hook = Instance.new("Part")
	hook.Name = "GrappleHook"
	hook.Size = Vector3.new(1, 1, 1)
	hook.Color = Color3.new(0.5, 0.5, 0.4)
	hook.Material = Enum.Material.Metal
	hook.Shape = Enum.PartShape.Ball
	hook.Anchored = false
	hook.CanCollide = false
	hook.Position = hookWeapon.Position
	hook.Parent = workspace
	
	-- Fire hook toward target
	local dir = (targetPos - hook.Position).Unit
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = dir * 200
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = hook
	
	shipGrapples[ship] = {target = target, hook = hook, rope = nil, cooldownEnd = tick() + CONFIG.GRAPPLE_COOLDOWN}
	
	-- Wait for hook to reach target or timeout
	task.spawn(function()
		local startTime = tick()
		local attached = false
		
		while hook.Parent and ship.Parent and tick() - startTime < 2 do
			local hookPos = hook.Position
			local targetPos2 = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
			
			if (hookPos - targetPos2).Magnitude < 5 then
				attached = true
				break
			end
			
			-- Update velocity toward target
			local newDir = (targetPos2 - hookPos).Unit
			velocity.Velocity = newDir * 200
			task.wait(0.05)
		end
		
		if not attached then
			if hook.Parent then hook:Destroy() end
			shipGrapples[ship] = nil
			return
		end
		
		-- Hook attached - create rope constraint
		velocity:Destroy()
		hook.Anchored = true
		
		-- Pull ship toward target
		local pullStartTime = tick()
		while ship.Parent and target.Parent and tick() - pullStartTime < 5 do
			local shipPrimary = ship.PrimaryPart
			if not shipPrimary then break end
			
			local targetPos3 = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
			local shipPos2 = shipPrimary.Position
			local dist = (targetPos3 - shipPos2).Magnitude
			
			if dist < CONFIG.GRAPPLE_MIN_LENGTH then break end
			if dist > CONFIG.GRAPPLE_BREAK_LENGTH then break end
			
			-- Spring force toward target
			local dir2 = (targetPos3 - shipPos2).Unit
			local force = CONFIG.GRAPPLE_SPRING * math.min(dist, 30)
			shipPrimary:ApplyImpulse(dir2 * force * 0.01)
			
			-- Update hook position to target
			hook.Position = targetPos3
			
			task.wait(0.05)
		end
		
		-- Cleanup
		if hook.Parent then hook:Destroy() end
		shipGrapples[ship] = nil
	end)
end

-- ============ FIGHTER BAY ============
local function spawnFighter(ship, weapon, def)
	if not fighterBays[weapon] then
		fighterBays[weapon] = {fighters = {}, lastSpawnTime = 0}
	end
	local state = fighterBays[weapon]
	
	-- Count total fighters for this player
	local totalFighters = 0
	for _, bay in pairs(fighterBays) do
		totalFighters = totalFighters + #bay.fighters
	end
	if totalFighters >= CONFIG.FIGHTER_MAX_PER_PLAYER then return end
	
	local maxFighters = def.MaxFighters or 3
	if #state.fighters >= maxFighters then return end
	
	if tick() - state.lastSpawnTime < CONFIG.FIGHTER_SPAWN_COOLDOWN then return end
	
	state.lastSpawnTime = tick()
	
	local spawnPos = weapon.Position + Vector3.new(0, 2, 0)
	
	-- Create fighter
	local fighter = Instance.new("Part")
	fighter.Name = "Fighter_" .. tostring(ship)
	fighter.Size = Vector3.new(0.8, 0.8, 0.8)
	fighter.Color = Color3.fromRGB(100, 200, 255)
	fighter.Material = Enum.Material.Neon
	fighter.Shape = Enum.PartShape.Ball
	fighter.Anchored = false
	fighter.CanCollide = true
	fighter.Position = spawnPos
	fighter.Parent = workspace
	fighter:SetAttribute("IsFighter", true)
	fighter:SetAttribute("FighterHP", def.FighterHP or 60)
	fighter:SetAttribute("FighterOwnerShip", ship:GetAttribute("OwnerId") or 0)
	
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(100, 200, 255)
	light.Brightness = 2
	light.Range = 8
	light.Parent = fighter
	
	table.insert(state.fighters, fighter)
	
	-- Fighter AI
	task.spawn(function()
		local fireTimer = 0
		local orbitAngle = math.random() * math.pi * 2
		
		while fighter.Parent do
			if not ship.Parent then fighter:Destroy(); break end
			
			local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			local orbitRadius = 12
			local speed = def.FighterSpeed or 80
			orbitAngle = orbitAngle + (speed / orbitRadius) * 0.1
			local targetPos = shipPos + Vector3.new(math.cos(orbitAngle) * orbitRadius, 0, math.sin(orbitAngle) * orbitRadius)
			
			local direction = (targetPos - fighter.Position)
			if direction.Magnitude > 1 then
				fighter.AssemblyLinearVelocity = direction.Unit * speed
			else
				fighter.AssemblyLinearVelocity = Vector3.zero
			end
			
			-- Fire at enemies
			fireTimer = fireTimer + 0.1
			if fireTimer >= (def.FighterFireRate or 0.3) then
				fireTimer = 0
				local enemy = findNearestEnemy(ship, def.FighterVision or 60)
				if enemy then
					local enemyPos = enemy.PrimaryPart and enemy.PrimaryPart.Position or enemy:GetPivot().Position
					if (enemyPos - fighter.Position).Magnitude <= (def.FighterRange or 40) then
						-- Blue laser beam
						local beam = Instance.new("Part")
						beam.Name = "FighterLaser"
						beam.Size = Vector3.new(0.1, 0.1, (enemyPos - fighter.Position).Magnitude)
						beam.Color = Color3.fromRGB(100, 200, 255)
						beam.Material = Enum.Material.Neon
						beam.Anchored = true
						beam.CanCollide = false
						local mid = (fighter.Position + enemyPos) / 2
						beam.CFrame = CFrame.lookAt(mid, enemyPos) * CFrame.Angles(math.rad(90), 0, 0)
						beam.Parent = workspace
						Debris:AddItem(beam, 0.08)
						
						-- Damage
						for _, part in ipairs(workspace:GetPartBoundsInRadius(enemyPos, 3)) do
							local owner = getOwnerShip(part)
							if owner and owner ~= ship then
								part:SetAttribute("PendingDamage", (def.FighterDamage or 10))
							end
						end
					end
				end
			end
			
			task.wait(0.1)
		end
		
		-- Remove from list
		for i, f in ipairs(state.fighters) do
			if f == fighter then table.remove(state.fighters, i); break end
		end
	end)
	
	-- Damage handling
	fighter.Touched:Connect(function(hit)
		if not fighter.Parent then return end
		local hp = fighter:GetAttribute("FighterHP") or 60
		hp = hp - 15
		fighter:SetAttribute("FighterHP", hp)
		if hp <= 0 then fighter:Destroy() end
	end)
end

-- ============ WEAPON IMPLEMENTATIONS ============
-- Machine Gun
local function spawnMachineGunProjectiles(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPos)
	
	for i = 1, 3 do
		local spread = CFrame.Angles(0, math.rad(math.random(-5, 5)), 0)
		local projectile = Instance.new("Part")
		projectile.Name = "MG_Projectile"
		projectile.Size = def.ProjectileSize
		projectile.BrickColor = BrickColor.new(def.ProjectileColor)
		projectile.Material = Enum.Material.Neon
		projectile.Anchored = false
		projectile.CanCollide = true
		projectile.Position = spawnPos
		projectile.CFrame = aimCFrame * spread
		projectile.Parent = workspace
		
		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = (aimCFrame * spread).LookVector * def.ProjectileSpeed
		velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
		velocity.Parent = projectile
		
		Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)
		
		projectile.Touched:Connect(function(hit)
			if not projectile.Parent then return end
			if hit:IsDescendantOf(ship) then return end
			local owner = getOwnerShip(hit)
			if owner and owner ~= ship then
				hit:SetAttribute("PendingDamage", def.Damage)
				recordDamage(owner, ship)
				projectile:Destroy()
			end
		end)
		
		task.wait(0.03)
	end
end

-- Spinning Blade
local function spawnSpinningBlade(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPos)
	
	local blade = Instance.new("Part")
	blade.Name = "SpinningBlade"
	blade.Size = def.ProjectileSize
	blade.BrickColor = BrickColor.new(def.ProjectileColor)
	blade.Material = Enum.Material.Neon
	blade.Anchored = false
	blade.CanCollide = true
	blade.Position = spawnPos
	blade.CFrame = aimCFrame
	blade.Parent = workspace
	blade:SetAttribute("IsBlade", true)
	
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * 60
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = blade
	
	-- Spin the blade
	task.spawn(function()
		while blade.Parent do
			blade.CFrame = blade.CFrame * CFrame.Angles(0, math.rad(720 * 0.1), 0)
			task.wait(0.1)
		end
	end)
	
	Debris:AddItem(blade, def.Range / 60)
	
	local hitParts = {}
	blade.Touched:Connect(function(hit)
		if not blade.Parent then return end
		if hit:IsDescendantOf(ship) then return end
		if hitParts[hit] then return end
		hitParts[hit] = true
		
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			task.spawn(function()
				for i = 1, 5 do
					if not blade.Parent or not hit.Parent then break end
					hit:SetAttribute("PendingDamage", def.SpinDamage * 0.2)
					recordDamage(owner, ship)
					task.wait(0.2)
				end
			end)
		end
	end)
end

-- Ubercannon
local function spawnUbercannon(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPos)
	
	local projectile = Instance.new("Part")
	projectile.Name = "Ubercannon_Projectile"
	projectile.Size = def.ProjectileSize
	projectile.BrickColor = BrickColor.new(def.ProjectileColor)
	projectile.Material = Enum.Material.Neon
	projectile.Shape = Enum.PartShape.Ball
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Position = spawnPos
	projectile.CFrame = aimCFrame
	projectile.Parent = workspace
	
	local light = Instance.new("PointLight")
	light.Color = def.ProjectileColor
	light.Brightness = 5
	light.Range = 20
	light.Parent = projectile
	
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * def.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	velocity.Parent = projectile
	
	Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)
	
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent then return end
		if hit:IsDescendantOf(ship) then return end
		
		-- AOE explosion on impact
		local pos = projectile.Position
		for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, def.ExplosionRadius or 15)) do
			local owner = getOwnerShip(part)
			if owner and owner ~= ship then
				local dist = (part.Position - pos).Magnitude
				local falloff = 1 - (dist / (def.ExplosionRadius or 15))
				part:SetAttribute("PendingDamage", def.Damage * falloff)
				recordDamage(owner, ship)
			end
		end
		
		-- Explosion visual
		local explosion = Instance.new("Part")
		explosion.Shape = Enum.PartShape.Ball
		explosion.Size = Vector3.new(1, 1, 1)
		explosion.Color = Color3.new(1, 0.5, 0)
		explosion.Material = Enum.Material.Neon
		explosion.Anchored = true
		explosion.CanCollide = false
		explosion.Position = pos
		explosion.Parent = workspace
		task.spawn(function()
			for i = 1, 8 do
				local s = (def.ExplosionRadius or 15) * 2 * (i / 8)
				explosion.Size = Vector3.new(s, s, s)
				explosion.Transparency = i / 8
				task.wait(0.03)
			end
			explosion:Destroy()
		end)
		
		projectile:Destroy()
	end)
end

-- Torpedo
local function spawnTorpedo(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MissileLauncher", spawnPos)
	
	local projectile = Instance.new("Part")
	projectile.Name = "Torpedo"
	projectile.Size = def.ProjectileSize
	projectile.BrickColor = BrickColor.new(def.ProjectileColor)
	projectile.Material = Enum.Material.Metal
	projectile.Shape = Enum.PartShape.Block
	projectile.Anchored = false
	projectile.CanCollide = true
	projectile.Position = spawnPos
	projectile.CFrame = aimCFrame
	projectile.Parent = workspace
	projectile:SetAttribute("IsMissile", true)
	projectile:SetAttribute("MissileHP", def.MissileHP or 50)
	
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = aimCFrame.LookVector * def.ProjectileSpeed
	velocity.MaxForce = Vector3.new(1e4, 0, 1e4)
	velocity.Parent = projectile
	
	-- Homing
	local target = findNearestEnemy(ship, def.Range)
	if target then
		projectile:SetAttribute("HomingActive", true)
		task.spawn(function()
			while projectile.Parent and projectile:GetAttribute("HomingActive") do
				if not target.Parent then break end
				local targetPos = target.PrimaryPart and target.PrimaryPart.Position or target:GetPivot().Position
				local direction = (targetPos - projectile.Position).Unit * def.ProjectileSpeed
				velocity.Velocity = direction
				velocity.MaxForce = Vector3.new(1e5, 0, 1e5)
				task.wait(0.1)
			end
		end)
	end
	
	Debris:AddItem(projectile, def.Range / def.ProjectileSpeed)
	
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent then return end
		if hit:IsDescendantOf(ship) then return end
		
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", def.Damage)
			recordDamage(owner, ship)
			projectile:Destroy()
		end
	end)
end

-- Bomblet Spray
local function spawnBombletSpray(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("MassDriver", spawnPos)
	
	local count = def.Projectiles or 8
	for i = 1, count do
		local spreadX = math.rad(math.random(-30, 30))
		local spreadZ = math.rad(math.random(-30, 30))
		local spread = CFrame.Angles(0, spreadX, spreadZ)
		
		local bomblet = Instance.new("Part")
		bomblet.Name = "Bomblet"
		bomblet.Size = def.ProjectileSize
		bomblet.BrickColor = BrickColor.new(def.ProjectileColor)
		bomblet.Material = Enum.Material.Neon
		bomblet.Shape = Enum.PartShape.Ball
		bomblet.Anchored = false
		bomblet.CanCollide = true
		bomblet.Position = spawnPos
		bomblet.CFrame = aimCFrame * spread
		bomblet.Parent = workspace
		
		local velocity = Instance.new("BodyVelocity")
		velocity.Velocity = (aimCFrame * spread).LookVector * def.ProjectileSpeed
		velocity.MaxForce = Vector3.new(1e4, 0, 1e4)
		velocity.Parent = bomblet
		
		Debris:AddItem(bomblet, def.ProjectileLife or 1.5)
		
		bomblet.Touched:Connect(function(hit)
			if not bomblet.Parent then return end
			if hit:IsDescendantOf(ship) then return end
			local owner = getOwnerShip(hit)
			if owner and owner ~= ship then
				hit:SetAttribute("PendingDamage", def.Damage)
				recordDamage(owner, ship)
				bomblet:Destroy()
			end
		end)
		
		task.wait(0.02)
	end
end

-- Sniper Cannon
local function spawnSniperCannon(ship, weapon, def, aimCFrame)
	local spawnPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("Laser", spawnPos)
	
	local projectile = Instance.new("Part")
	projectile.Name = "SniperRound"
	projectile.Size = def.ProjectileSize
	projectile.BrickColor = BrickColor.new(def.ProjectileColor)
	projectile.Material = Enum.Material.Neon
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
	
	-- Penetrating - doesn't destroy on first hit
	local hitSet = {}
	projectile.Touched:Connect(function(hit)
		if not projectile.Parent then return end
		if hit:IsDescendantOf(ship) then return end
		if hitSet[hit] then return end
		hitSet[hit] = true
		
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", def.Damage)
			recordDamage(owner, ship)
			-- Don't destroy - penetrates!
		end
	end)
end

-- Phased Energy Beam
local function spawnPhasedEnergyBeam(ship, weapon, def, aimCFrame)
	local startPos = weapon.Position + aimCFrame.LookVector * (UNIT / 2 + 1)
	SoundManager.PlayWeapon("Laser", startPos)
	
	-- Pulse beam
	local beam = Instance.new("Part")
	beam.Name = "PhasedBeam"
	beam.Size = Vector3.new(0.8, 0.8, def.Range)
	beam.BrickColor = BrickColor.new(def.ProjectileColor)
	beam.Material = Enum.Material.Neon
	beam.Shape = Enum.PartShape.Cylinder
	beam.Anchored = true
	beam.CanCollide = false
	beam.Transparency = 0.2
	local mid = startPos + aimCFrame.LookVector * (def.Range / 2)
	beam.CFrame = CFrame.lookAt(mid, mid + aimCFrame.LookVector) * CFrame.Angles(math.rad(90), 0, 0)
	beam.Position = Vector3.new(mid.X, 3.5, mid.Z)
	beam.Parent = workspace
	
	local hitbox = Instance.new("Part")
	hitbox.Name = "PhasedHitbox"
	hitbox.Size = Vector3.new(1.5, 1.5, def.Range)
	hitbox.Transparency = 1
	hitbox.CanCollide = true
	hitbox.Anchored = true
	hitbox.CFrame = beam.CFrame
	hitbox.Position = beam.Position
	hitbox.Parent = workspace
	
	Debris:AddItem(hitbox, def.PulseTime or 0.2)
	Debris:AddItem(beam, def.PulseTime or 0.2)
	
	local hitSet = {}
	hitbox.Touched:Connect(function(hit)
		if not hitbox.Parent then return end
		if hit:IsDescendantOf(ship) then return end
		if hitSet[hit] then return end
		hitSet[hit] = true
		
		local owner = getOwnerShip(hit)
		if owner and owner ~= ship then
			hit:SetAttribute("PendingDamage", def.Damage)
			recordDamage(owner, ship)
		end
	end)
end

-- ============ THRUSTER TRAILS ============
local function updateThrusterTrails()
	for ship, _ in pairs(playerShips) do
		if not ship.Parent then
			thrusterTrails = {}
			continue
		end
		
		for _, part in ipairs(ship:GetDescendants()) do
			if part:IsA("BasePart") then
				local typeName = getComponentType(part)
				if typeName and (typeName == "StandardThruster" or typeName == "SmallThruster" or typeName == "ThrusterBooster") then
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

-- ============ SHIELD TOGGLE COOLDOWN ============
local function handleShieldToggle(player, ship, action)
	if not ship or not ship.Parent then return end
	
	local now = tick()
	local cooldownEnd = shipShieldCooldown[ship] or 0
	if now < cooldownEnd then return end -- On cooldown
	
	shipShieldCooldown[ship] = now + CONFIG.SHIELD_TOGGLE_COOLDOWN
	
	-- Forward to shield system
	local comms = ReplicatedStorage:FindFirstChild("Communication")
	if comms then
		local shieldAction = comms:FindFirstChild("ShieldAction")
		if shieldAction then
			-- Find shield generator on ship
			for _, part in ipairs(ship:GetDescendants()) do
				if part:IsA("BasePart") and (part.Name == "ShieldGenerator" or part.Name == "Shield Generator") then
					shieldAction:FireServer(action, part)
				end
			end
		end
	end
end

-- ============ PLAYER ACTION HANDLER ============
PlayerActionEvent.OnServerEvent:Connect(function(player, action, ...)
	if not player or not player.Parent then return end
	
	local ship = playerShips[player]
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
		handleShieldToggle(player, ship, ...)
	elseif action == "LaunchFighters" then
		for _, part in ipairs(ship:GetDescendants()) do
			if part:IsA("BasePart") and getComponentType(part) == "FighterBay" then
				local def = Components.Types.FighterBay
				if def then spawnFighter(ship, part, def) end
			end
		end
	end
end)

-- ============ SHIP REGISTRATION ============
function RegisterShip(ship, player)
	if player then
		playerShips[player] = ship
		initPlayerStats(player)
	end
	
	-- Apply spawn invulnerability
	applyInvulnerability(ship)
end

-- ============ HEARTBEAT: Process pending damage, trails, invuln ============
RunService.Heartbeat:Connect(function(dt)
	-- Process pending damage from all sources
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			local pendingDmg = part:GetAttribute("PendingDamage")
			if pendingDmg and pendingDmg > 0 then
				part:SetAttribute("PendingDamage", nil)
				local ship = getOwnerShip(part)
				if ship and isInvulnerable(ship) then
					continue -- Skip damage for invulnerable ships
				end
				local currentHP = part:GetAttribute("ComponentHP") or 50
				local newHP = currentHP - pendingDmg
				part:SetAttribute("ComponentHP", newHP)
				
				-- Visual damage
				local maxHP = part:GetAttribute("MaxHP") or 50
				local ratio = newHP / maxHP
				if ratio <= 0.5 and ratio > 0 then
					part.Color = Color3.new(1, 0.3 * (ratio / 0.5), 0.3 * (ratio / 0.5))
				end
				
				if newHP <= 0 then
					-- Part destroyed
					local destroyedShip = getOwnerShip(part)
					local isCommandCore = part.Name == "Command Core" or part:GetAttribute("IsCore")
					
					if isCommandCore and destroyedShip then
						-- Ship destroyed - find killer
						local killerShip = nil
						if recentDamage[destroyedShip] then
							local latestTime = 0
							for attacker, time in pairs(recentDamage[destroyedShip]) do
								if time > latestTime then
									latestTime = time
									killerShip = attacker
								end
							end
						end
						recordKill(destroyedShip, killerShip)
						
						-- Handle respawn
						local owner = getShipOwner(destroyedShip)
						if owner then
							handleRespawn(owner)
						end
					end
					
					-- Remove welds and destroy
					for _, weld in ipairs(part:GetDescendants()) do
						if weld:IsA("WeldConstraint") then weld:Destroy() end
					end
					part:Destroy()
				end
			end
		end
	end
	
	-- Update thruster trails
	updateThrusterTrails()
end)

-- ============ PLAYER MANAGEMENT ============
Players.PlayerAdded:Connect(function(player)
	initPlayerStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerStats[player] = nil
	if playerShips[player] then
		playerShips[player] = nil
	end
end)

-- Register existing ships
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("Model") and obj:GetAttribute("IsShip") then
		local ownerId = obj:GetAttribute("OwnerId")
		if ownerId then
			local player = Players:GetPlayerByUserId(ownerId)
			if player then
				RegisterShip(obj, player)
			end
		end
	end
end

print("[PvPSystems] Loaded: Invulnerability, Respawn, K/D/A, Self-Destruct, Booster, Repair, Grapple, Shield Cooldown, Fighter Bay, Machine Gun, Spinning Blade, Ubercannon, Torpedo, Bomblet Spray, Sniper Cannon, Phased Energy Beam, Thruster Trails")
