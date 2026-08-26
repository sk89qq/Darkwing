--[=[
	VoidHunterBuilderManager

	Compatibility facade for inventory and placement callers.

	Blueprint persistence is owned by VoidHunterBuilderServer.
	Physical placement is owned by StructuralAuthority.
	Ship ownership is resolved through ShipRegistry.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local BuilderServer = require(ServerScriptService:WaitForChild("VoidHunterBuilderServer"))

local BuilderManager = {}
local playerInventories: { [number]: { [string]: number } } = {}

local communication = ReplicatedStorage:FindFirstChild("Communication")
if not communication then
	communication = Instance.new("Folder")
	communication.Name = "Communication"
	communication.Parent = ReplicatedStorage
end

local placeComponent = communication:FindFirstChild("PlaceComponent")
if not placeComponent then
	placeComponent = Instance.new("RemoteEvent")
	placeComponent.Name = "PlaceComponent"
	placeComponent.Parent = communication
end
placeComponent = placeComponent :: RemoteEvent

function BuilderManager.AddComponentToInventory(player: Player, componentName: string)
	if typeof(componentName) ~= "string" or not Components.Types[componentName] or not Components.Connections[componentName] then
		return false
	end

	local inventory = playerInventories[player.UserId]
	if not inventory then
		inventory = {}
		playerInventories[player.UserId] = inventory
	end

	inventory[componentName] = (inventory[componentName] or 0) + 1
	return true
end

local function placeComponentForPlayer(player: Player, componentName: string, gridPosition: Vector3, rotation: number?): (boolean, string?)
	if typeof(componentName) ~= "string" then
		return false, "Invalid component type"
	end
	if not Components.Types[componentName] or not Components.Connections[componentName] then
		return false, "Unknown component type"
	end
	if typeof(gridPosition) ~= "Vector3" then
		return false, "Invalid position"
	end

	local inventory = playerInventories[player.UserId]
	if not inventory or (inventory[componentName] or 0) <= 0 then
		return false, "Component not in inventory"
	end

	local ship = ShipRegistry.GetShip(player)
	if not ship or not ship.Parent then
		return false, "No active ship"
	end

	local created = Components.Create(componentName)
	if not created or not created.part or not created.part:IsA("BasePart") then
		return false, "Component construction failed"
	end

	local part = created.part :: BasePart
	local angle = typeof(rotation) == "number" and rotation or 0
	local worldPosition = ship:GetPivot():PointToWorldSpace(gridPosition)
	part.CFrame = CFrame.new(worldPosition) * CFrame.Angles(0, math.rad(angle), 0)

	local childNode, attachError = StructuralAuthority.AttachComponent(ship, part, componentName, 6)
	if not childNode or attachError then
		if part.Parent then
			part:Destroy()
		end
		return false, attachError or "Placement rejected"
	end

	inventory[componentName] -= 1
	BuilderServer.SaveBlueprint(player, ship)
	return true, nil
end

placeComponent.OnServerEvent:Connect(function(player: Player, componentName: string, gridPosition: Vector3, rotation: number?)
	local success, errorMessage = placeComponentForPlayer(player, componentName, gridPosition, rotation)
	if not success then
		warn(string.format("VoidHunterBuilderManager: %s placement rejected: %s", player.Name, errorMessage or "unknown error"))
	end
end)

function BuilderManager.GetInventory(player: Player): { [string]: number }
	return playerInventories[player.UserId] or {}
end

function BuilderManager.PlaceComponent(player: Player, componentName: string, gridPosition: Vector3, rotation: number?): (boolean, string?)
	return placeComponentForPlayer(player, componentName, gridPosition, rotation)
end

function BuilderManager.GetPlayerBlueprint(player: Player)
	return BuilderServer.GetBlueprint(player)
end

return BuilderManager
