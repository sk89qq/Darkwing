-- vhDebrisManager.lua
-- Handles spawning and collection of component debris

local vhDebrisManager = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterComponents"))
local BuilderManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterBuilderManager"))
local SoundManager = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager"))

-- Configuration
local DEBRIS_LIFESPAN = 30
local BOB_HEIGHT = 2
local ROTATION_SPEED = 180 -- Degrees per second

local DebrisFolder = Instance.new("Folder")
DebrisFolder.Name = "Debris"
DebrisFolder.Parent = game.Workspace

function vhDebrisManager.SpawnDebris(position, dropChance)
	if math.random() > (dropChance or 1) then return end
	
	-- Select random component
	local componentNames = {}
	for name, _ in pairs(Components.Types) do
		table.insert(componentNames, name)
	end
	local selectedComponent = componentNames[math.random(#componentNames)]
	
	-- Create Debris Part
	local debris = Instance.new("Part")
	debris.Name = "Debris_" .. selectedComponent
	debris.Size = Vector3.new(4, 4, 4)
	debris.Position = position + Vector3.new(0, 2, 0)
	debris.Anchored = true
	debris.CanCollide = false
	debris.Material = Enum.Material.Neon
	debris.Color = Color3.fromRGB(255, 255, 100)
	debris.Parent = DebrisFolder
	
	debris:SetAttribute("ComponentName", selectedComponent)
	debris:SetAttribute("Type", "Debris")
	
	-- Visual Effects (Bobbing and Rotating)
	local startPos = debris.Position
	task.spawn(function()
		local t = 0
		while debris.Parent do
			t = t + task.wait()
			debris.Position = startPos + Vector3.new(0, math.sin(t * 2) * BOB_HEIGHT, 0)
			debris.CFrame = debris.CFrame * CFrame.Angles(0, math.rad(ROTATION_SPEED * task.wait()), 0)
		end
	end)
	
	-- Collection Logic
	debris.Touched:Connect(function(other)
		local ship = other:FindFirstAncestor("Ships")
		if ship then
			local ownerId = ship:GetAttribute("OwnerId")
			local player = ownerId and Players:GetPlayerByUserId(ownerId)
			
			if player then
				print("Collected Debris: " .. selectedComponent)
				-- Play collection sound
				SoundManager.PlayPositional("CollectDebris", debris.Position)
				BuilderManager.AddComponentToInventory(player, selectedComponent)
				debris:Destroy()
			end
		end
	end)
	
	-- Auto-cleanup
	task.delay(DEBRIS_LIFESPAN, function()
		if debris.Parent then debris:Destroy() end
	end)
	
	return debris
end

return vhDebrisManager
