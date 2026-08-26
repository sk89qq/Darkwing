--[=[
	VoidHunter Shield System

	Canonical shield runtime boundary.
	- Component identity comes from explicit ComponentType metadata.
	- Component configuration comes from VoidHunterComponents.Types.
	- No gameplay state is inferred from Instance.Name.
	- Shield runtime state is local to each registered shield assembly.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ShipRegistry = require(ReplicatedStorage.Shared.Ship:WaitForChild("ShipRegistry"))

local SHIELD_COMPONENT_TYPES: { [string]: boolean } = {
	ShieldGenerator = true,
	ShieldDish = true,
}

local DEFAULT_MAX_ENERGY = 100
local DEFAULT_RECHARGE_DELAY = 2
local DEFAULT_GLOW_BRIGHTNESS = 0.9
local DEFAULT_GLOW_RANGE = 80

export type ShieldState = {
	bubble: BasePart,
	ship: Model,
	energy: number,
	maxEnergy: number,
	active: boolean,
	wasActive: boolean,
	lastHitTime: number,
	rechargeRate: number,
	damageToEnergy: number,
	minEnergyToActivate: number,
	radius: number,
}

local activeShields: { [BasePart]: ShieldState } = setmetatable({}, { __mode = "k" })

local function isShieldDefinition(typeName: string?): boolean
	return typeof(typeName) == "string" and SHIELD_COMPONENT_TYPES[typeName] == true
end

local function getComponentDefinition(part: Instance): (string?, any?)
	if not part:IsA("BasePart") then
		return nil, nil
	end
	local typeName = part:GetAttribute("ComponentType")
	if not isShieldDefinition(typeName) then
		return nil, nil
	end
	local definition = Components.Types[typeName]
	if type(definition) ~= "table" then
		return nil, nil
	end
	return typeName, definition
end

local function getShieldComponents(ship: Model): { [BasePart]: any }
	local result: { [BasePart]: any } = {}
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") then
			local _, definition = getComponentDefinition(instance)
			if definition then
				result[instance] = definition
			end
		end
	end
	return result
end

local function calculateShieldConfiguration(ship: Model): (number, number, number, number)
	local totalOutput = 0
	local totalRegen = 0
	local totalRadius = 0
	local shieldCount = 0
	local minActivation = 0
	local totalEnergy = 0

	for _, definition in pairs(getShieldComponents(ship)) do
		shieldCount += 1
		totalOutput += typeof(definition.ShieldOutput) == "number" and definition.ShieldOutput or 0
		totalRegen += typeof(definition.ShieldRegen) == "number" and definition.ShieldRegen or 0
		local radius = typeof(definition.ShieldRadius) == "number" and definition.ShieldRadius or 0
		totalRadius = math.max(totalRadius, radius)
		minActivation = math.max(minActivation, typeof(definition.MinEnergyToActivate) == "number" and definition.MinEnergyToActivate or 0)
		totalEnergy += typeof(definition.MaxShieldEnergy) == "number" and definition.MaxShieldEnergy or 0
	end

	if shieldCount == 0 then
		return 0, 0, DEFAULT_RECHARGE_DELAY, 0
	end

	local maxEnergy = totalEnergy > 0 and totalEnergy or DEFAULT_MAX_ENERGY * shieldCount
	local rechargeRate = totalRegen > 0 and totalRegen or math.max(1, totalOutput * 0.1)
	local radius = totalRadius > 0 and totalRadius or 0
	return maxEnergy, rechargeRate, math.max(minActivation, maxEnergy * 0.5), radius
end

local function findBubble(shieldPart: BasePart): BasePart?
	local direct = shieldPart:FindFirstChild("ShieldBubble")
	if direct and direct:IsA("BasePart") then
		return direct
	end
	return nil
end

local function findShieldPart(ship: Model): BasePart?
	for part, _ in pairs(getShieldComponents(ship)) do
		return part
	end
	return nil
end

local function getBubbleForShip(ship: Model): BasePart?
	local shieldPart = findShieldPart(ship)
	if not shieldPart then
		return nil
	end
	return findBubble(shieldPart)
end

local function updateShieldVisual(state: ShieldState)
	local bubble = state.bubble
	if not bubble.Parent then
		return
	end

	local percent = state.maxEnergy > 0 and math.clamp(state.energy / state.maxEnergy, 0, 1) or 0
	local opaqueModule = bubble.Parent:FindFirstChild("GeneratorModule_Opaque")
	local light = bubble:FindFirstChild("BubbleGlow")

	if state.active then
		bubble.Transparency = 0.85 - percent * 0.1
		bubble.Color = Color3.fromRGB(
			math.floor(100 + (1 - percent) * 50),
			math.floor(180 + percent * 40),
			math.floor(220 + percent * 35)
		)
		if light and light:IsA("PointLight") then
			light.Brightness = DEFAULT_GLOW_BRIGHTNESS + percent * 0.5
			light.Range = DEFAULT_GLOW_RANGE + percent * 15
		end
		if opaqueModule and opaqueModule:IsA("BasePart") then
			opaqueModule.Color = Color3.fromRGB(
				math.floor(70 + percent * 30),
				math.floor(160 + percent * 40),
				math.floor(180 + percent * 40)
			)
			opaqueModule.Reflectance = 0.2 + percent * 0.15
		end
	else
		bubble.Transparency = 0.92
		bubble.Color = Color3.fromRGB(100, 200, 255)
		if light and light:IsA("PointLight") then
			light.Brightness = DEFAULT_GLOW_BRIGHTNESS * 0.3 * percent
			light.Range = DEFAULT_GLOW_RANGE * 0.5
		end
		if opaqueModule and opaqueModule:IsA("BasePart") then
			opaqueModule.Color = Color3.fromRGB(70, 160, 160)
			opaqueModule.Reflectance = 0.2
		end
	end

	bubble:SetAttribute("ShieldActive", state.active)
	bubble:SetAttribute("ShieldEnergy", state.energy)
	bubble:SetAttribute("MaxEnergy", state.maxEnergy)
	bubble:SetAttribute("ShieldRadius", state.radius)
end

local function activateShield(bubble: BasePart): boolean
	local state = activeShields[bubble]
	if not state or state.energy < state.minEnergyToActivate then
		return false
	end
	state.active = true
	state.wasActive = false
	updateShieldVisual(state)
	return true
end

local function deactivateShield(bubble: BasePart): boolean
	local state = activeShields[bubble]
	if not state then
		return false
	end
	state.active = false
	state.wasActive = true
	state.lastHitTime = os.clock()
	updateShieldVisual(state)
	return true
end

local function damageShield(bubble: BasePart, amount: number): boolean
	local state = activeShields[bubble]
	if not state or not state.active or typeof(amount) ~= "number" or amount <= 0 then
		return false
	end

	local effectiveCost = amount * state.damageToEnergy
	state.energy = math.max(0, state.energy - effectiveCost)
	state.lastHitTime = os.clock()

	if state.energy <= 0 then
		deactivateShield(bubble)
		return false
	end

	updateShieldVisual(state)
	return true
end

local function initializeShipShield(ship: Model)
	if not ship:IsA("Model") or not ship:GetAttribute("IsShip") then
		return
	end

	local shieldPart = findShieldPart(ship)
	local bubble = shieldPart and findBubble(shieldPart)
	if not shieldPart or not bubble then
		return
	end

	local maxEnergy, rechargeRate, minActivation, radius = calculateShieldConfiguration(ship)
	if maxEnergy <= 0 then
		return
	end

	local existing = activeShields[bubble]
	if existing and existing.ship == ship then
		return
	end

	local primaryDefinition = getComponentDefinition(shieldPart)
	local damageToEnergy = 0.5
	if primaryDefinition and typeof(primaryDefinition.DamageToEnergy) == "number" then
		damageToEnergy = primaryDefinition.DamageToEnergy
	end

	local state: ShieldState = {
		bubble = bubble,
		ship = ship,
		energy = maxEnergy,
		maxEnergy = maxEnergy,
		active = false,
		wasActive = false,
		lastHitTime = os.clock(),
		rechargeRate = rechargeRate,
		damageToEnergy = damageToEnergy,
		minEnergyToActivate = minActivation,
		radius = radius,
	}
	activeShields[bubble] = state
	updateShieldVisual(state)
end

local function cleanupDestroyedShields()
	for bubble, state in pairs(activeShields) do
		if not bubble.Parent or not state.ship.Parent then
			activeShields[bubble] = nil
		end
	end
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	cleanupDestroyedShields()
	local now = os.clock()
	for bubble, state in pairs(activeShields) do
		if state.active then
			updateShieldVisual(state)
		elseif now - state.lastHitTime >= DEFAULT_RECHARGE_DELAY then
			state.energy = math.min(state.maxEnergy, state.energy + state.rechargeRate * deltaTime)
			if state.wasActive and state.energy >= state.minEnergyToActivate then
				activateShield(bubble)
			else
				updateShieldVisual(state)
			end
		end
	end
end)

local function scanRegisteredShips()
	for _, ship in pairs(ShipRegistry.GetAll()) do
		initializeShipShield(ship)
	end
end

scanRegisteredShips()

RunService.Heartbeat:Connect(function()
	scanRegisteredShips()
end)

local comms = ReplicatedStorage:FindFirstChild("Communication")
if not comms then
	comms = Instance.new("Folder")
	comms.Name = "Communication"
	comms.Parent = ReplicatedStorage
end

local shieldAction = comms:FindFirstChild("ShieldAction")
if not shieldAction then
	shieldAction = Instance.new("RemoteEvent")
	shieldAction.Name = "ShieldAction"
	shieldAction.Parent = comms
end

(shieldAction :: RemoteEvent).OnServerEvent:Connect(function(player: Player, action: string, shieldModel: Model)
	if typeof(action) ~= "string" or not shieldModel or not shieldModel:IsA("Model") then
		return
	end
	local ship = ShipRegistry.GetShip(player)
	if ship ~= shieldModel then
		return
	end

	initializeShipShield(ship)
	local bubble = getBubbleForShip(ship)
	if not bubble then
		return
	end

	if action == "activate" then
		activateShield(bubble)
	elseif action == "deactivate" then
		deactivateShield(bubble)
	end
end)

local ShieldSystem = {}
ShieldSystem.damageShield = damageShield
ShieldSystem.activateShield = activateShield
ShieldSystem.deactivateShield = deactivateShield
ShieldSystem.isShieldActive = function(bubble: BasePart): boolean
	local state = activeShields[bubble]
	return state ~= nil and state.active
end

return ShieldSystem
