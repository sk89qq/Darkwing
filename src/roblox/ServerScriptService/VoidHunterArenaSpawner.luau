-- VoidHunter Arena Spawner (Server)
-- Handles asteroid spawning, part spawning, and team management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Arena configuration
local ARENA_SIZE = 2000
local SPAWN_RADIUS = 800 -- Distance from center for spawning
local ASTEROID_COUNT = 50
local PART_SPAWN_INTERVAL = 30 -- Seconds between part spawns
local MAX_PARTS = 100

-- Team management
local teamAssignments = {} -- player -> team
local teamCounts = {Red = 0, Blue = 0}

-- Component types that can spawn
local SPAWNABLE_COMPONENTS = {
	"HullSmall", "HullMedium", "HullHeavy",
	"StandardThruster", "MassDriver", "PlasmaBall",
	"MissileLauncher", "DroneBay", "Laser",
	"ShieldGenerator", "Reactor", "ScramblerPulse"
}

-- Spawn positions for teams
local RED_SPAWN = Vector3.new(-800, 5, 0)
local BLUE_SPAWN = Vector3.new(800, 5, 0)

-- ===== TEAM MANAGEMENT =====
local function assignTeam(player)
	-- Alternate teams based on join order
	if teamCounts.Red <= teamCounts.Blue then
		teamAssignments[player] = "Red"
		teamCounts.Red = teamCounts.Red + 1
		return "Red"
	else
		teamAssignments[player] = "Blue"
		teamCounts.Blue = teamCounts.Blue + 1
		return "Blue"
	end
end

local function getTeamSpawnPosition(team)
	if team == "Red" then
		-- Random position within Red spawn zone
		local offsetX = math.random(-50, 50)
		local offsetZ = math.random(-150, 150)
		return RED_SPAWN + Vector3.new(offsetX, 0, offsetZ)
	else
		-- Random position within Blue spawn zone
		local offsetX = math.random(-50, 50)
		local offsetZ = math.random(-150, 150)
		return BLUE_SPAWN + Vector3.new(offsetX, 0, offsetZ)
	end
end

local function getPlayerTeam(player)
	return teamAssignments[player] or "Red"
end

-- ===== ASTEROID SPAWNING =====
local function createAsteroid()
	local size = math.random(5, 30)
	local asteroid = Instance.new("Part")
	asteroid.Name = "Asteroid"
	asteroid.Size = Vector3.new(size, size, size)
	asteroid.Shape = Enum.PartType.Ball
	asteroid.Material = Enum.Material.Rock
	asteroid.Color = Color3.fromRGB(80, 70, 60)
	asteroid.Anchored = true
	asteroid.CanCollide = true
	
	-- Random position in arena (avoid spawn zones)
	local x, z
	repeat
		x = math.random(-ARENA_SIZE/2 + 100, ARENA_SIZE/2 - 100)
		z = math.random(-ARENA_SIZE/2 + 100, ARENA_SIZE/2 - 100)
	until math.abs(x) > 300 -- Avoid center spawn areas
	
	asteroid.Position = Vector3.new(x, 3.5, z)
	asteroid.Parent = workspace
	
	return asteroid
end

local function spawnAsteroids()
	local asteroidsFolder = workspace:FindFirstChild("Asteroids")
	if not asteroidsFolder then
		asteroidsFolder = Instance.new("Folder")
		asteroidsFolder.Name = "Asteroids"
		asteroidsFolder.Parent = workspace
	end
	
	for i = 1, ASTEROID_COUNT do
		local asteroid = createAsteroid()
		asteroid.Parent = asteroidsFolder
	end
end

-- ===== PART SPAWNING =====
local function spawnComponent()
	local partsFolder = workspace:FindFirstChild("DroppedParts")
	if not partsFolder then
		partsFolder = Instance.new("Folder")
		partsFolder.Name = "DroppedParts"
		partsFolder.Parent = workspace
	end
	
	-- Count current parts
	local currentCount = 0
	for _ in ipairs(partsFolder:GetChildren()) do
		currentCount = currentCount + 1
	end
	
	if currentCount >= MAX_PARTS then return end
	
	-- Random component type
	local compType = SPAWNABLE_COMPONENTS[math.random(1, #SPAWNABLE_COMPONENTS)]
	
	-- Clone from template or create procedurally using Components definition
	local newPart = nil
	local template = workspace:FindFirstChild(compType)
	if template then
		local world = template:FindFirstChild("world")
		local body = world and world:FindFirstChild("body")
		local meshPart = body and body:FindFirstChild("body_geom")
		if meshPart then
			newPart = meshPart:Clone()
		end
	end

	if not newPart then
		local ComponentsModule = ReplicatedStorage:FindFirstChild("VoidHunterComponents")
		if ComponentsModule then
			local Components = require(ComponentsModule)
			if Components and Components.Create then
				newPart = Components.Create(compType)
			end
		end
	end

	if not newPart then return end

	newPart.Name = compType
	newPart.Anchored = true
	newPart.CanCollide = true
	
	-- Random position (avoid spawn zones and asteroids)
	local x, z
	repeat
		x = math.random(-ARENA_SIZE/2 + 200, ARENA_SIZE/2 - 200)
		z = math.random(-ARENA_SIZE/2 + 200, ARENA_SIZE/2 - 200)
	until math.abs(x) > 400 -- Avoid spawn zones
	
	newPart.Position = Vector3.new(x, 3.5, z)
	newPart.Parent = partsFolder
	
	-- Set HP attribute (for persistence)
	newPart:SetAttribute("PartHP", 100)
	newPart:SetAttribute("MaxHP", 100)
	newPart:SetAttribute("IsDroppedPart", true)
	
	return newPart
end

-- ===== PLAYER MANAGEMENT =====
Players.PlayerAdded:Connect(function(player)
	-- Assign team
	local team = assignTeam(player)
	player:SetAttribute("Team", team)
	
	print(player.Name, "assigned to", team, "team")
end)

Players.PlayerRemoving:Connect(function(player)
	-- Update team counts
	local team = teamAssignments[player]
	if team then
		teamCounts[team] = math.max(0, teamCounts[team] - 1)
		teamAssignments[player] = nil
	end
end)

-- ===== EXPOSE FUNCTIONS =====
_G.GetTeamSpawnPosition = getTeamSpawnPosition
_G.GetPlayerTeam = getPlayerTeam
_G.GetTeam = getPlayerTeam

-- ===== INITIALIZATION =====
task.wait(2) -- Wait for arena to load
spawnAsteroids()

-- Periodic part spawning
task.spawn(function()
	while true do
		task.wait(PART_SPAWN_INTERVAL)
		spawnComponent()
	end
end)

print("[ArenaSpawner] Loaded - Asteroids:", ASTEROID_COUNT, "Part spawn interval:", PART_SPAWN_INTERVAL)
