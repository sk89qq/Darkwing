-- VoidHunter Ship Spawner (Server)
-- Handles ship selection, spawning, player welding, team spawning, and death mechanics

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Team spawn positions (Red = left, Blue = right)
local RED_SPAWN_CENTER = Vector3.new(-800, 5, 0)
local BLUE_SPAWN_CENTER = Vector3.new(800, 5, 0)

local activeShips = {} -- player -> ship mapping
local partHealth = {} -- part -> current HP (persists across drops)
local partMaxHealth = {} -- part -> max HP

-- Ship preset definitions
local SHIP_PRESETS = {
	Fighter = {
		name = "Fighter",
		color = Color3.fromRGB(200, 50, 50),
		components = {
			{type = "CommandCore", offset = Vector3.new(0, 0, 0)},
			{type = "HullSmall", offset = Vector3.new(-7, 0, 0)},
			{type = "HullSmall", offset = Vector3.new(7, 0, 0)},
			{type = "StandardThruster", offset = Vector3.new(0, 0, -7)},
			{type = "MassDriver", offset = Vector3.new(0, 0, 7)},
		}
	},
	Cruiser = {
		name = "Cruiser",
		color = Color3.fromRGB(50, 150, 200),
		components = {
			{type = "CommandCore", offset = Vector3.new(0, 0, 0)},
			{type = "HullMedium", offset = Vector3.new(-7, 0, 0)},
			{type = "HullMedium", offset = Vector3.new(7, 0, 0)},
			{type = "StandardThruster", offset = Vector3.new(-7, 0, -7)},
			{type = "StandardThruster", offset = Vector3.new(7, 0, -7)},
			{type = "MissileLauncher", offset = Vector3.new(0, 0, 7)},
			{type = "ShieldGenerator", offset = Vector3.new(0, 0, -14)},
		}
	},
	Battleship = {
		name = "Battleship",
		color = Color3.fromRGB(50, 200, 100),
		components = {
			{type = "CommandCore", offset = Vector3.new(0, 0, 0)},
			{type = "HullHeavy", offset = Vector3.new(0, 0, -14)},
			{type = "StandardThruster", offset = Vector3.new(-7, 0, -14)},
			{type = "StandardThruster", offset = Vector3.new(7, 0, -14)},
			{type = "PlasmaBall", offset = Vector3.new(-7, 0, 7)},
			{type = "PlasmaBall", offset = Vector3.new(7, 0, 7)},
			{type = "Reactor", offset = Vector3.new(0, 0, 14)},
		}
	}
}

-- Get team spawn position
local function getTeamSpawnPosition(team)
	local basePos = team == "Red" and RED_SPAWN_CENTER or BLUE_SPAWN_CENTER
	local offsetX = math.random(-50, 50)
	local offsetZ = math.random(-150, 150)
	return basePos + Vector3.new(offsetX, 0, offsetZ)
end

-- Create a ship from a preset
local function createShipFromPreset(presetName, owner)
	local preset = SHIP_PRESETS[presetName]
	if not preset then return nil end
	
	-- Get team and spawn position
	local team = owner:GetAttribute("Team") or "Red"
	local spawnPos = getTeamSpawnPosition(team)
	
	-- Create ship model
	local ship = Instance.new("Model")
	ship.Name = owner.Name .. "_" .. presetName
	ship:SetAttribute("IsShip", true)
	ship:SetAttribute("OwnerId", owner.UserId)
	ship:SetAttribute("ShipType", presetName)
	
	-- Create VehicleSeat for player to sit in
	local seat = Instance.new("VehicleSeat")
	seat.Name = "VehicleSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Position = spawnPos + Vector3.new(0, 2, 0)
	seat.Anchored = true
	seat.CanCollide = false
	seat.Material = Enum.Material.Metal
	seat.Color = preset.color
	seat.Parent = ship
	
	-- Create components
	local components = {}
	for _, compData in ipairs(preset.components) do
		local compType = compData.type
		local offset = compData.offset
		
		-- Find the component model in Workspace
		local template = workspace:FindFirstChild(compType)
		if template then
			local world = template:FindFirstChild("world")
			if world then
				local body = world:FindFirstChild("body")
				if body then
					local meshPart = body:FindFirstChild("body_geom")
					if meshPart then
						local newPart = meshPart:Clone()
						newPart.Name = compType
						newPart.Position = spawnPos + offset + Vector3.new(0, 2, 0)
						newPart.Anchored = false
						newPart.CanCollide = true
						newPart.Parent = ship
						table.insert(components, newPart)
						
						-- Weld to seat
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = seat
						weld.Part1 = newPart
						weld.Parent = newPart
					end
				end
			end
		end
	end
	
	-- Set PrimaryPart
	ship.PrimaryPart = seat
	
	ship.Parent = workspace
	
	-- Register with weapon controller
	local weaponController = script.Parent:FindFirstChild("VoidHunterWeaponController")
	if weaponController then
		-- Ship will be registered when player sits
	end
	
	return ship, seat
end

-- Handle ship selection from hangar
local function onShipSelected(player, shipName)
	-- Check if player already has a ship
	if activeShips[player] then
		activeShips[player]:Destroy()
		activeShips[player] = nil
	end
	
	-- Create new ship
	local ship, seat = createShipFromPreset(shipName, player)
	if not ship then
		warn("Failed to create ship: " .. shipName)
		return
	end
	
	activeShips[player] = ship
	
	-- Teleport player to arena
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Teleport near the ship
			hrp.CFrame = CFrame.new(seat.Position + Vector3.new(0, 3, 0))
			
			-- Force player to sit in the seat
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Sit = true
				task.wait(0.1)
				
				-- Weld player to seat
				local weld = Instance.new("WeldConstraint")
				weld.Name = "PlayerShipWeld"
				weld.Part0 = seat
				weld.Part1 = hrp
				weld.Parent = seat
				
				-- Set camera mode attribute
				player:SetAttribute("InShip", true)
				player:SetAttribute("ShipType", shipName)
			end
		end
	end
	
	print(player.Name .. " spawned in " .. shipName)
end

-- Create RemoteEvent for ship selection
local selectShipEvent = ReplicatedStorage:FindFirstChild("VoidHunterSelectShip")
if not selectShipEvent then
	selectShipEvent = Instance.new("RemoteEvent")
	selectShipEvent.Name = "VoidHunterSelectShip"
	selectShipEvent.Parent = ReplicatedStorage
end

selectShipEvent.OnServerEvent:Connect(function(player, shipName)
	onShipSelected(player, shipName)
end)

-- Handle ship death - break apart and drop parts
local function onShipDestroyed(ship, owner)
	if not ship then return end
	
	-- Create dropped parts folder if needed
	local droppedPartsFolder = workspace:FindFirstChild("DroppedParts")
	if not droppedPartsFolder then
		droppedPartsFolder = Instance.new("Folder")
		droppedPartsFolder.Name = "DroppedParts"
		droppedPartsFolder.Parent = workspace
	end
	
	-- Break ship apart
	local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "VehicleSeat" then
			-- Get part HP
			local currentHP = partHealth[part] or 100
			local maxHP = partMaxHealth[part] or 100
			local hpPercent = currentHP / maxHP
			
			-- Parts with >40% HP drop with 80% HP
			if hpPercent > 0.4 then
				local droppedPart = part:Clone()
				droppedPart.Name = part.Name
				droppedPart.Anchored = true
				droppedPart.CanCollide = true
				droppedPart.Material = Enum.Material.Metal
				droppedPart.Color = part.Color -- Reset color (remove damage tint)
				
				-- Random scatter position
				local scatterX = math.random(-20, 20)
				local scatterZ = math.random(-20, 20)
				droppedPart.Position = Vector3.new(shipPos.X + scatterX, 3.5, shipPos.Z + scatterZ)
				droppedPart.Parent = droppedPartsFolder
				
				-- Set HP to 80% of max (persists)
				local newHP = math.floor(maxHP * 0.8)
				partHealth[droppedPart] = newHP
				partMaxHealth[droppedPart] = maxHP
				droppedPart:SetAttribute("PartHP", newHP)
				droppedPart:SetAttribute("MaxHP", maxHP)
				droppedPart:SetAttribute("IsDroppedPart", true)
			end
		end
	end
	
	-- Destroy ship
	ship:Destroy()
	activeShips[owner] = nil
end

-- Handle player death - respawn at hangar
local function onPlayerDied(player)
	-- Break ship apart
	if activeShips[player] then
		onShipDestroyed(activeShips[player], player)
	end
	
	-- Reset attributes
	player:SetAttribute("InShip", false)
	player:SetAttribute("ShipType", nil)
	
	-- Teleport to hangar
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(Vector3.new(5000, 2, 4970))
		end
	end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("InShip", false)
	
	-- Track character death
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			onPlayerDied(player)
		end)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	if activeShips[player] then
		activeShips[player]:Destroy()
		activeShips[player] = nil
	end
end)

-- Handle proximity prompts in hangar
local function setupHangarPrompts()
	local hangar = workspace:FindFirstChild("Hangar")
	if not hangar then return end
	
	local shipSelections = hangar:FindFirstChild("ShipSelections")
	if not shipSelections then return end
	
	for _, item in ipairs(shipSelections:GetChildren()) do
		if item:IsA("Part") and item:FindFirstChild("SelectPrompt") then
			local prompt = item.SelectPrompt
			local shipName = item:GetAttribute("ShipName")
			
			if shipName then
				prompt.Triggered:Connect(function(player)
					onShipSelected(player, shipName)
				end)
			end
		end
	end
end

setupHangarPrompts()

print("[ShipSpawner] Loaded")
