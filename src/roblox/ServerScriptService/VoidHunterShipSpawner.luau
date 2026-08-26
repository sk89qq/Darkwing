--[=[
	VoidHunterShipSpawner (Server)

	Authoritative responsibilities:
	- ship preset selection/spawn
	- player <-> ship registration via ShipRegistry
	- team-aware spawn placement via TeamIdentity
	- ship lifecycle teardown

	Component HP/state belongs to ComponentAuthority.
	Structural graph mutation belongs to StructuralAuthority.
	No legacy partHealth/partMaxHealth maps or fabricated salvage path remain.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))
local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))

local YELLOW_SPAWN_CENTER = Vector3.new(-800, 5, 0)
local BLUE_SPAWN_CENTER = Vector3.new(800, 5, 0)
local HANGAR_POSITION = Vector3.new(5000, 2, 4970)

local SHIP_PRESETS = {
	Fighter = {
		name = "Fighter",
		color = Color3.fromRGB(200, 50, 50),
		components = {
			{ type = "CommandCore", offset = Vector3.new(0, 0, 0) },
			{ type = "HullSmall", offset = Vector3.new(-7, 0, 0) },
			{ type = "HullSmall", offset = Vector3.new(7, 0, 0) },
			{ type = "StandardThruster", offset = Vector3.new(0, 0, -7) },
			{ type = "MassDriver", offset = Vector3.new(0, 0, 7) },
		},
	},
	Cruiser = {
		name = "Cruiser",
		color = Color3.fromRGB(50, 150, 200),
		components = {
			{ type = "CommandCore", offset = Vector3.new(0, 0, 0) },
			{ type = "HullMedium", offset = Vector3.new(-7, 0, 0) },
			{ type = "HullMedium", offset = Vector3.new(7, 0, 0) },
			{ type = "StandardThruster", offset = Vector3.new(-7, 0, -7) },
			{ type = "StandardThruster", offset = Vector3.new(7, 0, -7) },
			{ type = "MissileLauncher", offset = Vector3.new(0, 0, 7) },
			{ type = "ShieldGenerator", offset = Vector3.new(0, 0, -14) },
		},
	},
	Battleship = {
		name = "Battleship",
		color = Color3.fromRGB(50, 200, 100),
		components = {
			{ type = "CommandCore", offset = Vector3.new(0, 0, 0) },
			{ type = "HullHeavy", offset = Vector3.new(0, 0, -14) },
			{ type = "StandardThruster", offset = Vector3.new(-7, 0, -14) },
			{ type = "StandardThruster", offset = Vector3.new(7, 0, -14) },
			{ type = "PlasmaBall", offset = Vector3.new(-7, 0, 7) },
			{ type = "PlasmaBall", offset = Vector3.new(7, 0, 7) },
			{ type = "Reactor", offset = Vector3.new(0, 0, 14) },
		},
	},
}

local selectShipEvent = ReplicatedStorage:FindFirstChild("VoidHunterSelectShip")
if not selectShipEvent then
	selectShipEvent = Instance.new("RemoteEvent")
	selectShipEvent.Name = "VoidHunterSelectShip"
	selectShipEvent.Parent = ReplicatedStorage
end

local function getTeamSpawnPosition(team: TeamIdentity.TeamId): Vector3
	local center = team == TeamIdentity.YELLOW and YELLOW_SPAWN_CENTER or BLUE_SPAWN_CENTER
	return center + Vector3.new(math.random(-50, 50), 0, math.random(-150, 150))
end

local function destroyShip(player: Player, ship: Model)
	if not ship or not ship.Parent then
		ShipRegistry.UnregisterPlayer(player)
		return
	end

	ship:SetAttribute("Destroyed", true)
	ShipRegistry.UnregisterShip(ship)
	player:SetAttribute("InShip", false)
	player:SetAttribute("ShipType", nil)
	ship:Destroy()
end

local function createShipFromPreset(presetName: string, owner: Player): (Model?, VehicleSeat?)
	local preset = SHIP_PRESETS[presetName]
	if not preset then
		return nil, nil
	end

	local team = TeamIdentity.Get(owner)
	if not team then
		team = TeamIdentity.AssignDeterministic(owner.UserId)
		TeamIdentity.Set(owner, team)
	end

	local spawnPos = getTeamSpawnPosition(team)
	local ship = Instance.new("Model")
	ship.Name = owner.Name .. "_" .. presetName
	ship:SetAttribute("IsShip", true)
	ship:SetAttribute("OwnerId", owner.UserId)
	ship:SetAttribute("ShipType", presetName)
	TeamIdentity.Set(ship, team)

	local seat = Instance.new("VehicleSeat")
	seat.Name = "VehicleSeat"
	seat.Size = Vector3.new(2, 1, 2)
	seat.Position = spawnPos + Vector3.new(0, 2, 0)
	seat.Anchored = true
	seat.CanCollide = false
	seat.Material = Enum.Material.Metal
	seat.Color = preset.color
	seat.Parent = ship

	for _, compData in ipairs(preset.components) do
		local template = Workspace:FindFirstChild(compData.type)
		local world = template and template:FindFirstChild("world")
		local body = world and world:FindFirstChild("body")
		local meshPart = body and body:FindFirstChild("body_geom")
		if meshPart and meshPart:IsA("BasePart") then
			local newPart = meshPart:Clone()
			newPart.Name = compData.type
			newPart.CFrame = CFrame.new(spawnPos + compData.offset + Vector3.new(0, 2, 0))
			newPart.Anchored = false
			newPart.CanCollide = true
			newPart:SetAttribute("ComponentType", compData.type)
			newPart.Parent = ship

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = seat
			weld.Part1 = newPart
			weld.Parent = newPart
		end
	end

	ship.PrimaryPart = seat
	ship.Parent = Workspace
	StructuralAuthority.BindShip(ship)
	ShipRegistry.Register(owner, ship)

	return ship, seat
end

local function onShipSelected(player: Player, shipName: string)
	if typeof(shipName) ~= "string" then
		return
	end

	local previousShip = ShipRegistry.GetShip(player)
	if previousShip then
		destroyShip(player, previousShip)
	end

	local ship, seat = createShipFromPreset(shipName, player)
	if not ship or not seat then
		warn("Failed to create ship: " .. shipName)
		return
	end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if hrp and humanoid then
		hrp.CFrame = CFrame.new(seat.Position + Vector3.new(0, 3, 0))
		humanoid.Sit = true

		local weld = Instance.new("WeldConstraint")
		weld.Name = "PlayerShipWeld"
		weld.Part0 = seat
		weld.Part1 = hrp
		weld.Parent = seat
	end

	player:SetAttribute("InShip", true)
	player:SetAttribute("ShipType", shipName)
end

selectShipEvent.OnServerEvent:Connect(onShipSelected)

Players.PlayerAdded:Connect(function(player)
	if not TeamIdentity.Get(player) then
		TeamIdentity.Set(player, TeamIdentity.AssignDeterministic(player.UserId))
	end

	player:SetAttribute("InShip", false)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local ship = ShipRegistry.GetShip(player)
			if ship then
				destroyShip(player, ship)
			end
			player:SetAttribute("InShip", false)
			player:SetAttribute("ShipType", nil)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local ship = ShipRegistry.GetShip(player)
	if ship then
		destroyShip(player, ship)
	else
		ShipRegistry.UnregisterPlayer(player)
	end
end)

local function setupHangarPrompts()
	local hangar = Workspace:FindFirstChild("Hangar")
	local shipSelections = hangar and hangar:FindFirstChild("ShipSelections")
	if not shipSelections then
		return
	end

	for _, item in ipairs(shipSelections:GetChildren()) do
		if item:IsA("BasePart") then
			local prompt = item:FindFirstChild("SelectPrompt")
			local shipName = item:GetAttribute("ShipName")
			if prompt and prompt:IsA("ProximityPrompt") and typeof(shipName) == "string" then
				prompt.Triggered:Connect(function(player)
					onShipSelected(player, shipName)
				end)
			end
		end
	end
end

setupHangarPrompts()
print("[ShipSpawner] Authoritative ship lifecycle loaded")
