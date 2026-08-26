-- vhBuilderManager.lua
-- Handles modular ship assembly and inventory management

local vhBuilderManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local SyncManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterSyncManager"))
local Components = require(game.ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterComponents"))

-- Configuration
local GRID_SIZE = 7

-- Communication
local commsFolder = ReplicatedStorage:WaitForChild("Communication")
local PlaceComponent = commsFolder:FindFirstChild("PlaceComponent") or Instance.new("RemoteEvent", commsFolder)
PlaceComponent.Name = "PlaceComponent"

-- Inventory Management
local playerInventories = {}

function vhBuilderManager.AddComponentToInventory(player, componentName)
	if not playerInventories[player.UserId] then
		playerInventories[player.UserId] = {}
	end
	
	local inv = playerInventories[player.UserId]
	inv[componentName] = (inv[componentName] or 0) + 1
	
	-- Update client UI (optional)
	print(string.format("Added %s to %s's inventory", componentName, player.Name))
end

-- Placement Logic
PlaceComponent.OnServerEvent:Connect(function(player, componentName, gridPos, rotation)
	local inv = playerInventories[player.UserId]
	if not inv or not inv[componentName] or inv[componentName] <= 0 then
		warn(player.Name .. " tried to place a component they don't have: " .. componentName)
		return
	end
	
	-- Validate placement
	local blueprint = SyncManager.GetPlayerBlueprint(player)
	if not blueprint then return end
	
	-- Check for overlap
	for _, comp in ipairs(blueprint.Components) do
		if comp.Pos == gridPos then
			warn("Placement overlap at " .. tostring(gridPos))
			return
		end
	end
	
	-- Check connectivity (must be adjacent to an existing part)
	local isAdjacent = false
	for _, comp in ipairs(blueprint.Components) do
		local dist = (comp.Pos - gridPos).Magnitude
		if dist <= GRID_SIZE + 0.1 then
			isAdjacent = true
			break
		end
	end
	
	if not isAdjacent and #blueprint.Components > 0 then
		warn("Placement not adjacent to ship structure")
		return
	end
	
	-- Deduct from inventory
	inv[componentName] = inv[componentName] - 1
	
	-- Update blueprint
	table.insert(blueprint.Components, {
		Type = componentName,
		Pos = gridPos,
		Rot = rotation
	})
	
	-- Respawn ship to reflect changes
	SyncManager.SpawnPlayerShip(player)
end)

return vhBuilderManager
