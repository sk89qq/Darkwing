-- vhSyncManager.lua
-- Handles player data persistence (DataStore) and multiplayer synchronization

local vhSyncManager = {}

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ShipDataStore = DataStoreService:GetDataStore("VoidHunters_ShipBlueprints_v1")

-- Dependencies with timeout handling
local BuilderServer
local Components

local function loadDependencies()
	local success, result = pcall(function()
		local builderScript = game.ServerScriptService:FindFirstChild("VoidHunterBuilderServer")
		if not builderScript then
			builderScript = game.ServerScriptService:FindFirstChild("VoidHunters")
			if builderScript then
				builderScript = builderScript:FindFirstChild("VoidHunterBuilderServer")
			end
		end
		if builderScript then
			BuilderServer = require(builderScript)
		end
		
		local vhFolder = game.ReplicatedStorage:FindFirstChild("VoidHunters")
		if vhFolder then
			Components = require(vhFolder:FindFirstChild("VoidHunterComponents"))
		end
		
		return BuilderServer ~= nil and Components ~= nil
	end)
	return success and result
end

if not loadDependencies() then
	warn("VoidHunterSyncManager: Failed to load dependencies")
end

-- Communication Setup
local commsFolder = ReplicatedStorage:WaitForChild("Communication")

local remoteEvents = {
	RequestSpawn = "RemoteEvent",
	ComponentAction = "RemoteEvent",
	UpdateShipState = "RemoteEvent"
}

for name, className in pairs(remoteEvents) do
	if not commsFolder:FindFirstChild(name) then
		local event = Instance.new(className)
		event.Name = name
		event.Parent = commsFolder
	end
end

local RequestSpawn = commsFolder.RequestSpawn
local ComponentAction = commsFolder.ComponentAction

-- Player Data Cache
local sessionData = {}

-- Persistence Logic
local function loadPlayerData(player)
	local success, data = pcall(function()
		return ShipDataStore:GetAsync(tostring(player.UserId))
	end)
	
	if success and data then
		sessionData[player.UserId] = data
	else
		-- Default starter ship blueprint if no data exists
		sessionData[player.UserId] = {
			Name = "Starter Ship",
			Components = {
				{Type = "CommandCore", Pos = Vector3.new(0, 0, 0), Rot = Vector3.new(0, 0, 0)},
				{Type = "StandardThruster", Pos = Vector3.new(0, 0, 7), Rot = Vector3.new(0, 180, 0)},
				{Type = "MassDriver", Pos = Vector3.new(0, 0, -7), Rot = Vector3.new(0, 0, 0)}
			}
		}
	end
end

local function savePlayerData(player)
	if sessionData[player.UserId] then
		pcall(function()
			ShipDataStore:SetAsync(tostring(player.UserId), sessionData[player.UserId])
		end)
	end
end

function vhSyncManager.GetPlayerBlueprint(player)
	return sessionData[player.UserId]
end

function vhSyncManager.SpawnPlayerShip(player)
	if not player or not player.Parent then
		return nil, "Invalid player"
	end
	
	local blueprint = sessionData[player.UserId]
	if not blueprint then
		return nil, "No blueprint found for player"
	end
	
	if not BuilderServer then
		return nil, "BuilderServer not loaded"
	end
	
	local success, ship = pcall(function()
		return BuilderServer.BuildShipFromBlueprint(blueprint)
	end)
	
	if not success or not ship then
		warn("Failed to build ship: " .. tostring(ship))
		return nil, "Build failed"
	end
	
	ship.Name = player.Name .. "_Ship"
		
	-- Set ownership and spawn
	local spawnPos = Vector3.new(math.random(-50, 50), 0, math.random(-50, 50))
	
	if ship.PrimaryPart then
		ship:PivotTo(CFrame.new(spawnPos))
	else
		warn("Ship has no PrimaryPart")
	end
	
	local shipsFolder = game.Workspace:FindFirstChild("Ships")
	if not shipsFolder then
		shipsFolder = Instance.new("Folder")
		shipsFolder.Name = "Ships"
		shipsFolder.Parent = game.Workspace
	end
	ship.Parent = shipsFolder
		
	-- Link player to ship
	ship:SetAttribute("OwnerId", player.UserId)
	ship:SetAttribute("IsShip", true)
	player:SetAttribute("CurrentShip", ship.Name)
	
	return ship
end

-- Multiplayer Sync Logic
RequestSpawn.OnServerEvent:Connect(function(player)
	vhSyncManager.SpawnPlayerShip(player)
end)

-- Lifecycle Hooks
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	sessionData[player.UserId] = nil
end)

return vhSyncManager
