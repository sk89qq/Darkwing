--[=[
	ComponentAuthority
	Canonical runtime state for Void Hunters components.

	Lua state is authoritative; Instance Attributes are diagnostic/persistence mirrors.
	Structural mutations are handled by StructuralAuthority.

	15% critical presentation threshold is user-observed and remains isolated until
	the original render/update method is recovered and code-verified.
]=]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))

local ComponentAuthority = {}
ComponentAuthority.__index = ComponentAuthority

export type ComponentState = {
	Id: string,
	TypeName: string,
	TypeId: string?,
	Health: number,
	MaxHealth: number,
	ConnectionPointX: number,
	ConnectionPointY: number,
	ConnectedAngle: number,
	CurrentConnectedAngle: number,
	FinalX: number,
	FinalY: number,
	FinalAngle: number,
	ParentId: string?,
	ParentPart: BasePart?,
	Children: { [string]: string },
	Destroyed: boolean,
	Critical: boolean,
	BoundPart: BasePart?,
	BaseColor: Color3,
}

local states: { [BasePart]: ComponentState } = setmetatable({}, { __mode = "k" })

local function newId(): string
	return "component_" .. HttpService:GenerateGUID(false)
end

local function findDefinition(part: BasePart): (string?, any?)
	local attrType = part:GetAttribute("ComponentType")
	if typeof(attrType) == "string" and Components.Types[attrType] then
		return attrType, Components.Types[attrType]
	end

	for typeName, definition in pairs(Components.Types) do
		if definition.Name == part.Name then
			return typeName, definition
		end
	end
	return nil, nil
end

local function readHealth(definition: any): number
	if type(definition) ~= "table" then return 0 end
	local hp = definition.HP
	if typeof(hp) == "number" and hp >= 0 then return hp end
	local maxHp = definition.MaxHP
	if typeof(maxHp) == "number" and maxHp >= 0 then return maxHp end
	return 0
end

function ComponentAuthority.Get(part: BasePart): ComponentState?
	return states[part]
end

function ComponentAuthority.IsComponent(part: Instance): boolean
	return part:IsA("BasePart") and select(1, findDefinition(part)) ~= nil
end

function ComponentAuthority.Bind(part: BasePart, explicitTypeName: string?): ComponentState?
	if not part or not part:IsA("BasePart") then return nil end

	local typeName, definition = explicitTypeName, nil
	if typeName then
		definition = Components.Types[typeName]
	else
		typeName, definition = findDefinition(part)
	end
	if not typeName or type(definition) ~= "table" then return nil end

	local existing = states[part]
	if existing then return existing end

	local maxHealth = readHealth(definition)
	local existingBaseColor = part:GetAttribute("BaseColor")
	local baseColor = typeof(existingBaseColor) == "Color3" and existingBaseColor or part.Color
	local state: ComponentState = {
		Id = part:GetAttribute("ComponentId") or newId(),
		TypeName = typeName,
		TypeId = tostring(definition.TypeId or definition.Id or typeName),
		Health = maxHealth,
		MaxHealth = maxHealth,
		ConnectionPointX = 0,
		ConnectionPointY = 0,
		ConnectedAngle = 0,
		CurrentConnectedAngle = 0,
		FinalX = 0,
		FinalY = 0,
		FinalAngle = 0,
		ParentId = nil,
		ParentPart = nil,
		Children = {},
		Destroyed = false,
		Critical = false,
		BoundPart = part,
		BaseColor = baseColor,
	}

	part:SetAttribute("ComponentId", state.Id)
	part:SetAttribute("ComponentType", state.TypeName)
	part:SetAttribute("ComponentHealth", state.Health)
	part:SetAttribute("ComponentMaxHealth", state.MaxHealth)
	part:SetAttribute("ComponentState", "Healthy")
	part:SetAttribute("BaseColor", state.BaseColor)
	states[part] = state
	return state
end

function ComponentAuthority.BindShip(ship: Model): { [BasePart]: ComponentState }
	local bound: { [BasePart]: ComponentState } = {}
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") then
			local state = ComponentAuthority.Bind(instance)
			if state then bound[instance] = state end
		end
	end
	return bound
end

local function updateVisual(state: ComponentState)
	local part = state.BoundPart
	if not part or not part.Parent then return end

	local maxHealth = math.max(state.MaxHealth, 1)
	local fraction = math.clamp(state.Health / maxHealth, 0, 1)
	state.Critical = fraction > 0 and fraction <= 0.15

	if state.Destroyed then
		part:SetAttribute("ComponentState", "Destroyed")
		part:SetAttribute("ComponentHealth", 0)
		part:SetAttribute("ComponentMaxHealth", state.MaxHealth)
		return
	end

	part:SetAttribute("ComponentState", state.Critical and "Critical" or (fraction < 1 and "Damaged" or "Healthy"))
	part:SetAttribute("ComponentHealth", state.Health)
	part:SetAttribute("ComponentMaxHealth", state.MaxHealth)

	local damage = 1 - fraction
	part.Color = state.BaseColor:Lerp(Color3.fromRGB(255, 30, 30), damage)
end

function ComponentAuthority.SetHealth(part: BasePart, health: number): ComponentState?
	local state = states[part] or ComponentAuthority.Bind(part)
	if not state then return nil end
	state.Health = math.clamp(health, 0, state.MaxHealth)
	state.Destroyed = state.Health <= 0
	updateVisual(state)
	return state
end

function ComponentAuthority.ApplyDamage(part: BasePart, damage: number): (ComponentState?, boolean)
	local state = states[part] or ComponentAuthority.Bind(part)
	if not state or state.Destroyed then return state, false end
	if typeof(damage) ~= "number" or damage <= 0 or damage ~= damage or damage == math.huge or damage == -math.huge then
		return state, false
	end

	state.Health = math.max(0, state.Health - damage)
	local destroyed = state.Health <= 0
	state.Destroyed = destroyed
	updateVisual(state)
	return state, destroyed
end

function ComponentAuthority.Repair(part: BasePart, amount: number): (ComponentState?, number)
	local state = states[part] or ComponentAuthority.Bind(part)
	if not state or typeof(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge or state.Destroyed then
		return state, 0
	end

	local before = state.Health
	state.Health = math.min(state.MaxHealth, state.Health + amount)
	updateVisual(state)
	return state, state.Health - before
end

function ComponentAuthority.MarkDestroyed(part: BasePart): ComponentState?
	local state = states[part] or ComponentAuthority.Bind(part)
	if not state then return nil end
	state.Health = 0
	state.Destroyed = true
	updateVisual(state)
	return state
end

function ComponentAuthority.SetParent(part: BasePart, parentPart: BasePart?): ComponentState?
	local state = states[part] or ComponentAuthority.Bind(part)
	if not state then return nil end

	if state.ParentPart and state.ParentPart ~= parentPart then
		local oldParent = states[state.ParentPart]
		if oldParent then
			oldParent.Children[state.Id] = nil
		end
	end

	if parentPart then
		local parentState = states[parentPart] or ComponentAuthority.Bind(parentPart)
		if not parentState then return nil end
		state.ParentId = parentState.Id
		state.ParentPart = parentPart
		parentState.Children[state.Id] = state.Id
	else
		state.ParentId = nil
		state.ParentPart = nil
	end

	part:SetAttribute("ParentComponentId", state.ParentId)
	return state
end

function ComponentAuthority.Clear(part: BasePart)
	local state = states[part]
	if not state then return end

	if state.ParentPart then
		local parentState = states[state.ParentPart]
		if parentState then
			parentState.Children[state.Id] = nil
		end
	end
	states[part] = nil
end

return ComponentAuthority
