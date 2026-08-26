local PL = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lobby spawn location (off the arena)
local LOBBY_SPAWN = Vector3.new(5000, 3.5, 5000)

-- Arena spawn location
local ARENA_SPAWN = Vector3.new(0, 3.5, 0)

-- Load components for ship creation
local Components = ReplicatedStorage:FindFirstChild("VoidHunterComponents")
local ComponentsModule = Components and require(Components)

-- Reference to the CommandCore template in Workspace
local function getCommandCoreTemplate()
	return game.Workspace:FindFirstChild("CommandCore")
end

-- Function to create a fresh starter ship using the CommandCore mesh model
local function createStarterShip(position)
	local ship = Instance.new("Model")
	ship.Name = "PlayerShip_" .. math.random(1000, 9999)
	ship.Parent = workspace
	
	-- Clone the CommandCore mesh model from Workspace
	local template = getCommandCoreTemplate()
	local core = nil
	local corePart = nil
	
	if template then
		-- Clone the entire CommandCore model
		core = template:Clone()
		core.Name = "CommandCore"
		core.Parent = ship
		
		-- Get the body_geom MeshPart
		corePart = core:FindFirstChild("world", true)
		if corePart then
			corePart = corePart:FindFirstChild("body", true)
			if corePart then
				corePart = corePart:FindFirstChild("body_geom", true)
			end
		end
		
		if corePart then
			-- Position the core
			core:PivotTo(CFrame.new(position))
			corePart.Anchored = false
			
			-- Set attributes
			corePart:SetAttribute("IsCore", true)
			corePart:SetAttribute("ComponentType", "CommandCore")
			
			-- Configure physics
			corePart.CustomPhysicalProperties = PhysicalProperties.new(5, 0.3, 0.5, 1, 1)
		end
	end
	
	-- Fallback: create simple Part if template not found
	if not corePart then
		corePart = ComponentsModule.Create("CommandCore")
		corePart.Position = position
		corePart.Anchored = false
		corePart.Parent = ship
		core = corePart
		corePart:SetAttribute("IsCore", true)
	end
	
	-- Create 4 thrusters for basic movement (snapped to InConnect points)
	-- Thruster positions match the InConnect attachment positions on CommandCore
	local thrusterPositions = {
		{Vector3.new(0, 0, 4.65), "Front"},   -- InConnect_1 (front)
		{Vector3.new(0, 0, -4.65), "Back"},   -- InConnect_2 (back)
		{Vector3.new(-4.63, 0, 0), "Left"},   -- InConnect_3 (left)
		{Vector3.new(4.63, 0, 0), "Right"}    -- InConnect_4 (right)
	}
	
	for _, posData in ipairs(thrusterPositions) do
		local pos, name = posData[1], posData[2]
		local thruster = ComponentsModule.Create("StandardThruster")
		thruster.Name = "Thruster_" .. name
		thruster.Position = position + pos
		thruster.Anchored = false
		thruster.Parent = ship
		
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = corePart
		weld.Part1 = thruster
		weld.Parent = thruster
		thruster.Massless = true
	end
	
	-- Create VehicleSeat (positioned on top of CommandCore)
	local seat = Instance.new("VehicleSeat")
	seat.Name = "VehicleSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Position = position + Vector3.new(0, 3, 0)  -- On top of the core
	seat.Anchored = false
	seat.Parent = ship
	
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = corePart
	seatWeld.Part1 = seat
	seatWeld.Parent = seat
	
	-- Set ship primary part (use the actual BasePart, not the Model)
	ship.PrimaryPart = corePart
	ship:SetAttribute("IsShip", true)
	
	-- For nested models like CommandCore, ensure the core model is properly referenced
	if core and core ~= corePart then
		-- Store reference to the core model for easy access
		ship:SetAttribute("CoreModel", core.Name)
	end
	
	-- Ensure ProximityPrompt exists on core
	if not corePart:FindFirstChild("ShipPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ShipPrompt"
		prompt.ActionText = "Enter Ship"
		prompt.ObjectText = "Command Core"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 15
		prompt.RequiresLineOfSight = false
		prompt.Parent = corePart
	end
	
	return ship, seat
end

-- Function to deploy player to arena
local function deployPlayerToArena(player)
	if not player.Character then return end
	
	-- Remove existing ships
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:find("PlayerShip_") and obj:GetAttribute("Owner") == player.Name then
			obj:Destroy()
		end
	end
	
	-- Random spawn position
	local spawnOffset = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
	local spawnPos = ARENA_SPAWN + spawnOffset
	
	-- Create ship
	local ship, seat = createStarterShip(spawnPos)
	ship:SetAttribute("Owner", player.Name)
	
	-- Teleport and sit
	player.Character:SetAttribute("InLobby", false)
	player.Character:PivotTo(CFrame.new(spawnPos + Vector3.new(0, 5, 0)))
	
	task.wait(0.5)
	if player.Character and seat then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			seat:Sit(humanoid)
		end
	end
	
	print(player.Name, "deployed to arena at", spawnPos)
end

-- Spawn player in lobby
local function spawnInLobby(player)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(LOBBY_SPAWN)
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
	
	character:SetAttribute("InLobby", true)
	print(player.Name, "spawned in lobby - step on platform and hold E to deploy")
end

-- Handle ProximityPrompt for deployment
local function setupDeployPrompt()
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return end
	
	local corePlatform = lobby:FindFirstChild("CorePlatform")
	if not corePlatform then return end
	
	local prompt = corePlatform:FindFirstChild("DeployPrompt")
	if not prompt then return end
	
	prompt.Triggered:Connect(function(player)
		deployPlayerToArena(player)
	end)
end

PL.PlayerAdded:Connect(function(player)
	player:SetAttribute("InShip", false)
	player:SetAttribute("ShipType", nil)
	
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		spawnInLobby(player)
	end)
end)

-- Handle existing players
for _, player in ipairs(PL:GetPlayers()) do
	if player.Character then
		spawnInLobby(player)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		spawnInLobby(player)
	end)
end

-- Setup deployment prompt
setupDeployPrompt()
workspace.DescendantAdded:Connect(function(desc)
	if desc.Name == "DeployPrompt" then
		task.wait(0.1)
		setupDeployPrompt()
	end
end)

print("[PlayerSpawner] Players spawn in lobby at", LOBBY_SPAWN)
