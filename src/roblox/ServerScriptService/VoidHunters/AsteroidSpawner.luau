-- AsteroidSpawner.lua
-- Manages asteroid generation, fragmentation, and collision damage

local AsteroidSpawner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterComponents"))
local WeaponController = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterWeaponController"))
local DebrisManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterDebrisManager"))

-- Configuration
local PLAY_AREA_RADIUS = 1000
local SPAWN_INTERVAL = 5
local MAX_ASTEROIDS = 20
local FRAGMENT_COUNT = 2
local SEPARATION_VELOCITY = 15

local ASTEROID_STATS = {
	Large = {Size = 25, HP = 100, Mass = 500, DamageMult = 1.5},
	Medium = {Size = 12, HP = 40, Mass = 150, DamageMult = 1.0},
	Small = {Size = 6, HP = 15, Mass = 40, DamageMult = 0.5}
}

local AsteroidsFolder = Instance.new("Folder")
AsteroidsFolder.Name = "Asteroids"
AsteroidsFolder.Parent = game.Workspace

function AsteroidSpawner.CreateAsteroid(sizeType, position, velocity)
	local stats = ASTEROID_STATS[sizeType]
	if not stats then return end

	local asteroid = Instance.new("Part")
	asteroid.Name = "Asteroid_" .. sizeType
	asteroid.Shape = Enum.PartType.Ball
	asteroid.Size = Vector3.new(stats.Size, stats.Size, stats.Size)
	asteroid.Position = position
	asteroid.Material = Enum.Material.Rock
	asteroid.Color = Color3.fromRGB(100, 100, 100)
	asteroid.Parent = AsteroidsFolder
	
	-- Physics setup
	asteroid.AssemblyLinearVelocity = velocity or Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	asteroid.AssemblyAngularVelocity = Vector3.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
	
	-- Attributes for damage system
	asteroid:SetAttribute("MaxHealth", stats.HP)
	asteroid:SetAttribute("Health", stats.HP)
	asteroid:SetAttribute("Type", "Asteroid")
	asteroid:SetAttribute("SizeType", sizeType)

	-- Collision Damage
	asteroid.Touched:Connect(function(other)
		if other:IsDescendantOf(game.Workspace:FindFirstChild("Ships")) then
			local relativeVelocity = (asteroid.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude
			local damage = relativeVelocity * (stats.Mass / 100) * stats.DamageMult
			
			-- Apply damage to ship via WeaponController
			WeaponController.ApplyDamage(other, damage)
			
			-- Asteroid also takes damage from impact
			AsteroidSpawner.TakeDamage(asteroid, damage * 0.5)
		end
	end)

	return asteroid
end

function AsteroidSpawner.TakeDamage(asteroid, amount)
	local health = asteroid:GetAttribute("Health") or 0
	health = math.max(0, health - amount)
	asteroid:SetAttribute("Health", health)
	
	if health <= 0 then
		AsteroidSpawner.DestroyAsteroid(asteroid)
	end
end

function AsteroidSpawner.DestroyAsteroid(asteroid)
	local sizeType = asteroid:GetAttribute("SizeType")
	local pos = asteroid.Position
	local vel = asteroid.AssemblyLinearVelocity
	
	asteroid:Destroy()
	
	-- Drop debris
	if sizeType == "Large" then
		DebrisManager.SpawnDebris(pos, 0.3)
	elseif sizeType == "Medium" then
		DebrisManager.SpawnDebris(pos, 0.1)
	end
	
	-- Fragmentation logic
	local nextSize = nil
	if sizeType == "Large" then nextSize = "Medium"
	elseif sizeType == "Medium" then nextSize = "Small" end
	
	if nextSize then
		for i = 1, FRAGMENT_COUNT do
			local offset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
			local sepVel = offset.Unit * SEPARATION_VELOCITY
			AsteroidSpawner.CreateAsteroid(nextSize, pos + offset, vel + sepVel)
		end
	end
end

-- Main Loop
task.spawn(function()
	while true do
		if #AsteroidsFolder:GetChildren() < MAX_ASTEROIDS then
			local angle = math.random() * math.pi * 2
			local spawnPos = Vector3.new(math.cos(angle) * PLAY_AREA_RADIUS, 0, math.sin(angle) * PLAY_AREA_RADIUS)
			local targetPos = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
			local velocity = (targetPos - spawnPos).Unit * math.random(20, 50)
			
			AsteroidSpawner.CreateAsteroid("Large", spawnPos, velocity)
		end
		task.wait(SPAWN_INTERVAL)
	end
end)

return AsteroidSpawner
