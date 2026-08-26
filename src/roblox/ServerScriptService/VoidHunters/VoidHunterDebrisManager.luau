-- VoidHunterDebrisManager
-- Authoritative debris presentation/collection layer.
-- Component identity must be supplied by the canonical destruction path.
-- This module never fabricates a random component type.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Components = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterComponents"))
local BuilderManager = require(ServerScriptService.VoidHunters:WaitForChild("VoidHunterBuilderManager"))
local SoundManager = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager"))

local DEBRIS_LIFESPAN = 30
local BOB_HEIGHT = 2
local ROTATION_SPEED = math.rad(180)
local BOB_FREQUENCY = 2

local DebrisFolder = workspace:FindFirstChild("VoidHunterDebris")
if not DebrisFolder then
	DebrisFolder = Instance.new("Folder")
	DebrisFolder.Name = "VoidHunterDebris"
	DebrisFolder.Parent = workspace
end

local DebrisManager = {}

local function isValidComponentType(componentType: string): boolean
	return typeof(componentType) == "string"
		and componentType ~= ""
		and type(Components.Types[componentType]) == "table"
end

local function getShipFromCollector(instance: Instance): Model?
	local ancestor = instance:FindFirstAncestorOfClass("Model")
	while ancestor do
		if ancestor:GetAttribute("IsShip") == true then
			return ancestor
		end
		ancestor = ancestor.Parent and ancestor.Parent:FindFirstAncestorOfClass("Model") or nil
	end
	return nil
end

local function getPlayerForShip(ship: Model): Player?
	local ownerId = ship:GetAttribute("OwnerId")
	if typeof(ownerId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(ownerId)
end

function DebrisManager.SpawnDebris(
	position: Vector3,
	componentType: string,
	dropChance: number?,
	initialVelocity: Vector3?
): BasePart?
	if typeof(position) ~= "Vector3" or not position.X == position.X then
		return nil
	end

	if not isValidComponentType(componentType) then
		return nil
	end

	local chance = dropChance == nil and 1 or math.clamp(dropChance, 0, 1)
	if math.random() > chance then
		return nil
	end

	local definition = Components.Types[componentType]
	local baseColor = typeof(definition.Color) == "Color3"
		and definition.Color
		or Color3.fromRGB(255, 255, 100)

	local debris = Instance.new("Part")
	debris.Name = "Debris_" .. componentType
	debris.Size = Vector3.new(4, 4, 4)
	debris.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	debris.Anchored = true
	debris.CanCollide = false
	debris.CanTouch = true
	debris.Material = Enum.Material.Neon
	debris.Color = baseColor
	debris.Parent = DebrisFolder

	debris:SetAttribute("ComponentType", componentType)
	debris:SetAttribute("DebrisKind", "Component")
	if initialVelocity then
		debris:SetAttribute("InitialVelocityX", initialVelocity.X)
		debris:SetAttribute("InitialVelocityY", initialVelocity.Y)
		debris:SetAttribute("InitialVelocityZ", initialVelocity.Z)
	end

	local startCFrame = debris.CFrame
	local startedAt = os.clock()

	task.spawn(function()
		while debris.Parent do
			local elapsed = os.clock() - startedAt
			local bobOffset = math.sin(elapsed * BOB_FREQUENCY) * BOB_HEIGHT
			local yaw = elapsed * ROTATION_SPEED
			debris.CFrame = startCFrame
				* CFrame.new(0, bobOffset, 0)
				* CFrame.Angles(0, yaw, 0)
			task.wait()
		end
	end)

	debris.Touched:Connect(function(otherPart: BasePart)
		if not debris.Parent then
			return
		end

		local ship = getShipFromCollector(otherPart)
		if not ship then
			return
		end

		local player = getPlayerForShip(ship)
		if not player then
			return
		end

		local success, err = pcall(function()
			BuilderManager.AddComponentToInventory(player, componentType)
		end)
		if not success then
			warn(string.format("[VoidHunterDebrisManager] Inventory add failed for %s: %s", componentType, tostring(err)))
			return
		end

		SoundManager.PlayPositional("CollectDebris", debris.Position)
		debris:Destroy()
	end)

	task.delay(DEBRIS_LIFESPAN, function()
		if debris.Parent then
			debris:Destroy()
		end
	end)

	return debris
end

function DebrisManager.IsValidComponentType(componentType: string): boolean
	return isValidComponentType(componentType)
end

return DebrisManager
