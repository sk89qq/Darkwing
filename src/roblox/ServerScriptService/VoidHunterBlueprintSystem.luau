-- VoidHunter Blueprint System (Server)
-- Handles saving, loading, and managing ship blueprints

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore for persistent blueprints
local BlueprintStore = DataStoreService:GetDataStore("VoidHunterBlueprints")

-- Blueprint slots per player (1 default + 2 unlockable)
local DEFAULT_SLOTS = 1
local MAX_SLOTS = 3

-- Player blueprint data
local playerBlueprints = {} -- player -> {slot1 = {...}, slot2 = {...}, slot3 = {...}}
local playerUnlockedSlots = {} -- player -> number of unlocked slots

-- ===== BLUEPRINT DATA STRUCTURE =====
-- Blueprint = {
-- 		name = "Slot 1",
-- 		components = {
-- 			{type = "Hull1x1", offset = Vector3, rotation = number},
-- 			{type = "MassDriver", offset = Vector3, rotation = number},
-- 			...
-- 		},
-- 		complete = false, -- Whether all parts are collected
-- 		missingParts = {} -- Parts still needed
-- }

-- ===== HELPER FUNCTIONS =====
local function serializeVector3(v)
	return {X = v.X, Y = v.Y, Z = v.Z}
end

local function deserializeVector3(t)
	return Vector3.new(t.X, t.Y, t.Z)
end

local function serializeBlueprint(bp)
	local serialized = {
		name = bp.name,
		complete = bp.complete,
		components = {}
	}
	for _, comp in ipairs(bp.components) do
		table.insert(serialized.components, {
			type = comp.type,
			offset = serializeVector3(comp.offset),
			rotation = comp.rotation
		})
	end
	return serialized
end

local function deserializeBlueprint(t)
	local bp = {
		name = t.name,
		complete = t.complete,
		components = {}
	}
	for _, comp in ipairs(t.components) do
		table.insert(bp.components, {
			type = comp.type,
			offset = deserializeVector3(comp.offset),
			rotation = comp.rotation
		})
	end
	return bp
end

-- ===== PLAYER MANAGEMENT =====
local function loadPlayerBlueprints(player)
	local success, data = pcall(function()
		return BlueprintStore:GetAsync("Blueprints_" .. player.UserId)
	end)
	
	if success and data then
		playerBlueprints[player] = data.blueprints or {}
		playerUnlockedSlots[player] = data.unlockedSlots or DEFAULT_SLOTS
	else
		-- Initialize default blueprints
		playerBlueprints[player] = {}
		for i = 1, DEFAULT_SLOTS do
			playerBlueprints[player]["Slot" .. i] = {
				name = "Slot " .. i,
				components = {},
				complete = false,
				missingParts = {}
			}
		end
		playerUnlockedSlots[player] = DEFAULT_SLOTS
	end
	
	return playerBlueprints[player]
end

local function savePlayerBlueprints(player)
	local data = {
		blueprints = playerBlueprints[player],
		unlockedSlots = playerUnlockedSlots[player]
	}
	
	pcall(function()
		BlueprintStore:SetAsync("Blueprints_" .. player.UserId, data)
	end)
end

-- ===== BLUEPRINT OPERATIONS =====
local function saveBlueprint(player, slotName, ship)
	if not playerBlueprints[player] then
		loadPlayerBlueprints(player)
	end
	
	local blueprint = {
		name = slotName,
		components = {},
		complete = true
	}
	
	-- Extract components from ship
	local core = nil
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("IsCore") then
			core = part
			break
		end
	end
	
	if not core then return false, "No Command Core found" end
	
	local corePos = core.Position
	local coreCFrame = core.CFrame
	
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "VehicleSeat" then
			local compType = part:GetAttribute("ComponentType")
			if compType then
				local relativePos = coreCFrame:PointToObjectSpace(part.Position)
				local relativeRot = select(2, part.CFrame:ToOrientation())
				
				table.insert(blueprint.components, {
					type = compType,
					offset = relativePos,
					rotation = math.deg(relativeRot)
				})
			end
		end
	end
	
	playerBlueprints[player][slotName] = blueprint
	savePlayerBlueprints(player)
	
	return true, blueprint
end

local function loadBlueprint(player, slotName)
	if not playerBlueprints[player] then
		loadPlayerBlueprints(player)
	end
	
	return playerBlueprints[player][slotName]
end

local function getBlueprintStatus(player, slotName)
	local blueprint = loadBlueprint(player, slotName)
	if not blueprint then return nil end
	
	-- Check which parts are available in dropped parts
	local droppedParts = workspace:FindFirstChild("DroppedParts")
	local availableParts = {}
	local missingParts = {}
	
	if droppedParts then
		for _, comp in ipairs(blueprint.components) do
			local found = false
			for _, part in ipairs(droppedParts:GetChildren()) do
				if part:IsA("BasePart") and part:GetAttribute("ComponentType") == comp.type then
					found = true
					table.insert(availableParts, part)
					break
				end
			end
			if not found then
				table.insert(missingParts, comp.type)
			end
		end
	end
	
	blueprint.complete = #missingParts == 0
	blueprint.missingParts = missingParts
	
	return blueprint
end

-- ===== REMOTE EVENTS =====
local saveEvent = Instance.new("RemoteEvent")
saveEvent.Name = "VoidHunterSaveBlueprint"
saveEvent.Parent = ReplicatedStorage

local loadEvent = Instance.new("RemoteEvent")
loadEvent.Name = "VoidHunterLoadBlueprint"
loadEvent.Parent = ReplicatedStorage

local getStatusEvent = Instance.new("RemoteFunction")
getStatusEvent.Name = "VoidHunterGetBlueprintStatus"
getStatusEvent.Parent = ReplicatedStorage

-- Save blueprint
saveEvent.OnServerEvent:Connect(function(player, slotName, ship)
	local success, result = saveBlueprint(player, slotName, ship)
	if success then
		print("[Blueprint] Saved", slotName, "for", player.Name)
	else
		warn("[Blueprint] Failed to save:", result)
	end
end)

-- Load blueprint
loadEvent.OnServerEvent:Connect(function(player, slotName)
	local blueprint = loadBlueprint(player, slotName)
	print("[Blueprint] Loaded", slotName, "for", player.Name)
end)

-- Get blueprint status
getStatusEvent.OnServerInvoke = function(player, slotName)
	return getBlueprintStatus(player, slotName)
end

-- ===== PLAYER LIFECYCLE =====
Players.PlayerAdded:Connect(function(player)
	loadPlayerBlueprints(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerBlueprints(player)
	playerBlueprints[player] = nil
	playerUnlockedSlots[player] = nil
end)

print("[BlueprintSystem] Loaded -", DEFAULT_SLOTS, "default slots,")
