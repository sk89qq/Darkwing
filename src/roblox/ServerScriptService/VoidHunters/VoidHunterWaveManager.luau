-- vhWaveManager.lua
-- Wave system: auto-starts on first player join, scales max waves = playerCount * 5
-- Resets and restarts automatically each full run.

local vhWaveManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponController = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterWeaponController"))
local DebrisManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterDebrisManager"))

local SPAWN_RADIUS = 800
local GROUP_SIZE       = 5   -- enemies spawned per group
local GROUP_DELAY      = 30  -- seconds between each group spawn within a wave
local BETWEEN_WAVE_BASE= 15  -- seconds rest after wave 1
local BETWEEN_WAVE_STEP= 3   -- extra seconds added per completed wave
local BETWEEN_WAVE_MAX = 45  -- cap so late-game doesn't stall forever
local AI_UPDATE_RATE   = 1.0
local WAVES_PER_PLAYER = 5

local ENEMY_PROFILES = {
	Grunt   = { Speed = 50,  HP = 50,  Weapon = "MassDriver",    Color = Color3.fromRGB(255,100,100), Size = 1.0 },
	Fighter = { Speed = 35,  HP = 150, Weapon = "PlasmaBall",    Color = Color3.fromRGB(200,50,50),  Size = 1.5 },
	Bomber  = { Speed = 20,  HP = 400, Weapon = "MissileLauncher",Color = Color3.fromRGB(150,0,0),   Size = 2.5 },
}

-- Base wave templates (scale enemy counts by playerCount)
local WAVE_TEMPLATES = {
	[1] = {Grunt = 3},
	[2] = {Grunt = 5, Fighter = 1},
	[3] = {Grunt = 4, Fighter = 3},
	[4] = {Fighter = 5, Bomber = 1},
	[5] = {Fighter = 4, Bomber = 2},
	-- Beyond 5: generated dynamically
}

local EnemiesFolder = game.Workspace:FindFirstChild("Enemies") or (function()
	local f = Instance.new("Folder"); f.Name = "Enemies"; f.Parent = game.Workspace; return f
end)()

local currentWave = 0
local maxWaves = 0
local activeEnemies = {}
local sessionActive = false  -- prevents double-running

-- Between-wave rest grows with difficulty: later waves earned longer breathers
local function calcPause(waveNum)
	return math.min(BETWEEN_WAVE_BASE + (waveNum - 1) * BETWEEN_WAVE_STEP, BETWEEN_WAVE_MAX)
end

-- Compute enemy config for a given wave number, scaled to playerCount
local function buildWaveConfig(waveNum, playerCount)
	local base = WAVE_TEMPLATES[waveNum]
	if not base then
		-- Deep waves: ramp fighters + bombers
		local bombCount = math.min(math.floor((waveNum - 5) / 2) + 2, 6)
		base = {Fighter = 3, Bomber = bombCount}
	end
	local scaled = {}
	for enemyType, count in pairs(base) do
		scaled[enemyType] = math.ceil(count * math.max(1, playerCount * 0.75))
	end
	return scaled
end

function vhWaveManager.GetNearestPlayer(position)
	local nearest, minDist = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char.PrimaryPart then
			local dist = (char.PrimaryPart.Position - position).Magnitude
			if dist < minDist then minDist = dist; nearest = char.PrimaryPart end
		end
	end
	return nearest
end

function vhWaveManager.SpawnEnemy(enemyType, position)
	local profile = ENEMY_PROFILES[enemyType]
	if not profile then return end

	local enemyShip = Instance.new("Model")
	enemyShip.Name = "Enemy_" .. enemyType

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(7, 7, 7) * profile.Size
	core.Color = profile.Color
	core.Material = Enum.Material.Neon
	core.Position = position
	core.Parent = enemyShip
	enemyShip.PrimaryPart = core

	local att = Instance.new("Attachment", core)
	local ap = Instance.new("AlignPosition", core)
	ap.Attachment0 = att; ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.MaxForce = 100000; ap.Responsiveness = 10
	local ao = Instance.new("AlignOrientation", core)
	ao.Attachment0 = att; ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.MaxTorque = 100000; ao.Responsiveness = 15

	enemyShip:SetAttribute("MaxHealth", profile.HP)
	enemyShip:SetAttribute("Health", profile.HP)
	enemyShip:SetAttribute("Speed", profile.Speed)
	enemyShip:SetAttribute("Type", "Enemy")
	enemyShip.Parent = EnemiesFolder
	table.insert(activeEnemies, enemyShip)

	task.spawn(function()
		enemyShip.AncestryChanged:Connect(function(_, parent)
			if not parent then DebrisManager.SpawnDebris(core.Position, 0.5) end
		end)
		while enemyShip.Parent do
			local target = vhWaveManager.GetNearestPlayer(core.Position)
			if target then
				ap.Position = target.Position
				ao.CFrame = CFrame.lookAt(core.Position, target.Position)
				if (target.Position - core.Position).Magnitude < 300 then
					WeaponController.FireWeapon(enemyShip, profile.Weapon, target.Position)
				end
			end
			task.wait(AI_UPDATE_RATE)
		end
	end)

	return enemyShip
end

-- Build a flat ordered queue from a config table, shuffled for variety
local function buildQueue(config)
	local queue = {}
	for enemyType, count in pairs(config) do
		for _ = 1, count do queue[#queue+1] = enemyType end
	end
	-- Fisher-Yates shuffle
	for i = #queue, 2, -1 do
		local j = math.random(1, i)
		queue[i], queue[j] = queue[j], queue[i]
	end
	return queue
end

-- Spawn a single enemy at a random arc position
local function spawnOne(enemyType)
	local angle = math.random() * math.pi * 2
	vhWaveManager.SpawnEnemy(enemyType,
		Vector3.new(math.cos(angle)*SPAWN_RADIUS, 0, math.sin(angle)*SPAWN_RADIUS))
end

-- Spawn wave in groups of GROUP_SIZE with GROUP_DELAY seconds between groups.
-- Runs in background (task.spawn) so the wave monitor loop can keep tracking kills.
function vhWaveManager.SpawnWave(waveNum, playerCount, sessionActive_ref, GameManager)
	currentWave = waveNum
	local config = buildWaveConfig(waveNum, playerCount)
	local queue  = buildQueue(config)
	local total  = #queue

	print(string.format("[WaveManager] Wave %d/%d | %d enemies in groups of %d",
		waveNum, maxWaves, total, GROUP_SIZE))

	task.spawn(function()
		local spawned = 0
		while spawned < total do
			if not sessionActive_ref() or GameManager.GetState() ~= "Active" then break end
			-- Spawn next group
			local groupEnd = math.min(spawned + GROUP_SIZE, total)
			for i = spawned + 1, groupEnd do
				spawnOne(queue[i])
			end
			spawned = groupEnd
			-- If more groups remain, wait GROUP_DELAY before the next batch
			if spawned < total then
				task.wait(GROUP_DELAY)
			end
		end
	end)
end

function vhWaveManager.Reset()
	-- Destroy all active enemies
	for _, e in ipairs(activeEnemies) do
		if e.Parent then e:Destroy() end
	end
	activeEnemies = {}
	currentWave = 0
	maxWaves = 0
	sessionActive = false
end

function vhWaveManager.GetCurrentWave() return currentWave end
function vhWaveManager.GetMaxWaves() return maxWaves end

-- Main run loop: called once per arena session
function vhWaveManager.RunSession(GameManager, HUDController)
	if sessionActive then return end
	sessionActive = true

	-- Snapshot player count at session start; recount each wave
	maxWaves = #Players:GetPlayers() * WAVES_PER_PLAYER
	maxWaves = math.max(maxWaves, WAVES_PER_PLAYER) -- minimum 5 even if count drops
	print("[WaveManager] Session started. Max waves: " .. maxWaves)

	task.spawn(function()
		for waveNum = 1, maxWaves do
			if not sessionActive or GameManager.GetState() ~= "Active" then break end

			-- Recount live players each wave for scaling
			local playerCount = math.max(#Players:GetPlayers(), 1)
			maxWaves = playerCount * WAVES_PER_PLAYER -- recalc if players joined/left

			-- HUD broadcast
			if HUDController then
				HUDController.BroadcastStatus("⚠ WAVE " .. waveNum .. " / " .. maxWaves, 3)
				task.wait(0.5)
				-- enemy count will be known after spawn; send 0 first, update after
				HUDController.BroadcastWaveInfo(waveNum, maxWaves, 0)
			end

			vhWaveManager.SpawnWave(waveNum, playerCount)

			-- Broadcast actual enemy count now
			if HUDController then
				HUDController.BroadcastWaveInfo(waveNum, maxWaves, #activeEnemies)
			end

			-- Wait for all enemies to die (or game to end)
			while sessionActive and GameManager.GetState() == "Active" do
				-- Clean dead entries
				for i = #activeEnemies, 1, -1 do
					if not activeEnemies[i].Parent then table.remove(activeEnemies, i) end
				end
				-- Update enemy count on HUD
				if HUDController then
					HUDController.BroadcastWaveInfo(waveNum, maxWaves, #activeEnemies)
				end
				if #activeEnemies == 0 then break end
				task.wait(1)
			end

			if not sessionActive or GameManager.GetState() ~= "Active" then break end

			-- Between-wave countdown pause (skip after last wave)
			if waveNum < maxWaves then
				local pause = calcPause(waveNum, maxWaves)
				for t = pause, 1, -1 do
					if not sessionActive or GameManager.GetState() ~= "Active" then break end
					if HUDController then
						HUDController.BroadcastStatus(
							"✓ Wave " .. waveNum .. " cleared!  Next wave in " .. t .. "s", 1.1)
					end
					task.wait(1)
				end
			end
		end

		-- All waves completed — victory!
		if sessionActive and GameManager.GetState() == "Active" then
			if HUDController then
				HUDController.BroadcastStatus("★ ALL WAVES CLEARED! VICTORY! ★", 6)
			end
			print("[WaveManager] All " .. maxWaves .. " waves completed. Triggering restart.")
			task.wait(6)
			GameManager.SetState("GameOver")
		end

		sessionActive = false
	end)
end

return vhWaveManager
