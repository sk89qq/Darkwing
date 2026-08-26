--[=[
	VoidHunterBlueprintSystem

	SUPERSEDED compatibility facade.

	Canonical blueprint persistence and construction live in
	`VoidHunterBuilderServer`. This module contains no independent datastore,
	blueprint schema, or structural mutation logic.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuilderServer = require(ServerScriptService:WaitForChild("VoidHunterBuilderServer"))

local VoidHunterBlueprintSystem = {}

function VoidHunterBlueprintSystem.GetBlueprint(player: Player)
	return BuilderServer.GetBlueprint(player)
end

function VoidHunterBlueprintSystem.SaveBlueprint(player: Player, ship: Model)
	return BuilderServer.SaveBlueprint(player, ship)
end

function VoidHunterBlueprintSystem.BuildShipFromBlueprint(blueprint: any)
	return BuilderServer.BuildShipFromBlueprint(blueprint)
end

local saveEvent = ReplicatedStorage:FindFirstChild("VoidHunterSaveBlueprint")
if not saveEvent then
	saveEvent = Instance.new("RemoteEvent")
	saveEvent.Name = "VoidHunterSaveBlueprint"
	saveEvent.Parent = ReplicatedStorage
end

local loadEvent = ReplicatedStorage:FindFirstChild("VoidHunterLoadBlueprint")
if not loadEvent then
	loadEvent = Instance.new("RemoteEvent")
	loadEvent.Name = "VoidHunterLoadBlueprint"
	loadEvent.Parent = ReplicatedStorage
end

local statusFunction = ReplicatedStorage:FindFirstChild("VoidHunterGetBlueprintStatus")
if not statusFunction then
	statusFunction = Instance.new("RemoteFunction")
	statusFunction.Name = "VoidHunterGetBlueprintStatus"
	statusFunction.Parent = ReplicatedStorage
end

(saveEvent :: RemoteEvent).OnServerEvent:Connect(function(player: Player, _slotName: string?, ship: Model?)
	if not ship or not ship:IsA("Model") or not ship.Parent then
		return
	end
	local ownerId = ship:GetAttribute("OwnerId")
	if typeof(ownerId) == "number" and ownerId ~= player.UserId then
		return
	end
	VoidHunterBlueprintSystem.SaveBlueprint(player, ship)
end)

(loadEvent :: RemoteEvent).OnServerEvent:Connect(function(player: Player, _slotName: string?)
	return VoidHunterBlueprintSystem.GetBlueprint(player)
end)

(statusFunction :: RemoteFunction).OnServerInvoke = function(player: Player, _slotName: string?)
	return VoidHunterBlueprintSystem.GetBlueprint(player)
end

return VoidHunterBlueprintSystem
