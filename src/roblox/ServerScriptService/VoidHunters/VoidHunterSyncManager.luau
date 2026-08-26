--[=[
	VoidHunterSyncManager

	SUPERSEDED compatibility facade for multiplayer lifecycle callers.

	Canonical blueprint persistence and construction live in
	`VoidHunterBuilderServer`. This module owns only player/session lifecycle,
	spawn placement, and the legacy RemoteEvent bridge.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local BuilderServer = require(ServerScriptService:WaitForChild("VoidHunterBuilderServer"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))

local VoidHunterSyncManager = {}
local activeShips: { [Player]: Model } = {}

local commsFolder = ReplicatedStorage:FindFirstChild("Communication")
if not commsFolder then
	commsFolder = Instance.new("Folder")
	commsFolder.Name = "Communication"
	commsFolder.Parent = ReplicatedStorage
end

local RequestSpawn = commsFolder:FindFirstChild("RequestSpawn")
if not RequestSpawn then
	RequestSpawn = Instance.new("RemoteEvent")
	RequestSpawn.Name = "RequestSpawn"
	RequestSpawn.Parent = commsFolder
end
RequestSpawn = RequestSpawn :: RemoteEvent

for _, name in ipairs({ "ComponentAction", "UpdateShipState" }) do
	if not commsFolder:FindFirstChild(name) then
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = commsFolder
	end
end

local shipsFolder = Workspace:FindFirstChild("Ships")
if not shipsFolder then
	shipsFolder = Instance.new("Folder")
	shipsFolder.Name = "Ships"
	shipsFolder.Parent = Workspace
end
shipsFolder = shipsFolder :: Folder

local function spawnPosition(player: Player): Vector3
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position + Vector3.new(0, 0, -40)
	end
	return Vector3.new(0, 0, 0)
end

function VoidHunterSyncManager.GetPlayerBlueprint(player: Player)
	return BuilderServer.GetBlueprint(player)
end

function VoidHunterSyncManager.SavePlayerBlueprint(player: Player, ship: Model)
	return BuilderServer.SaveBlueprint(player, ship)
end

function VoidHunterSyncManager.SpawnPlayerShip(player: Player): (Model?, string?)
	if not player or not player.Parent then
		return nil, "Invalid player"
	end

	local blueprint = BuilderServer.GetBlueprint(player)
	if not blueprint then
		return nil, "No blueprint found for player"
	end

	local success, ship = pcall(function()
		return BuilderServer.BuildShipFromBlueprint(blueprint)
	end)
	if not success or not ship then
		warn("VoidHunterSyncManager: ship construction failed: " .. tostring(ship))
		return nil, "Build failed"
	end

	local previousShip = activeShips[player]
	if previousShip and previousShip.Parent then
		ShipRegistry.Unregister(previousShip)
		previousShip:Destroy()
	end

	ship.Name = player.Name .. "_Ship"
	ship:SetAttribute("OwnerId", player.UserId)
	ship:SetAttribute("IsShip", true)
	ship.Parent = shipsFolder
	ship:PivotTo(CFrame.new(spawnPosition(player)))

	ShipRegistry.Register(player, ship)
	activeShips[player] = ship
	player:SetAttribute("CurrentShip", ship.Name)

	return ship, nil
end

RequestSpawn.OnServerEvent:Connect(function(player: Player)
	VoidHunterSyncManager.SpawnPlayerShip(player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local ship = activeShips[player]
	if ship and ship.Parent then
		ShipRegistry.Unregister(ship)
		ship:Destroy()
	end
	activeShips[player] = nil
end)

return VoidHunterSyncManager
