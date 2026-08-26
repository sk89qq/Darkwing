--[=[
	BlueprintLoader
	Transactional Roblox-side reconstruction for BlueprintSerializer.

	Rules:
	- Validate the complete primitive blueprint before mutating the target ship.
	- Blueprint IDs are logical persistence identifiers only.
	- ParentId references blueprint component Id values.
	- ParentHardpointId and ChildHardpointId are socket identifiers, not component IDs.
	- Newly created Roblox parts receive runtime ComponentId values through
	  ComponentAuthority.
	- Every topology mutation flows through StructuralAuthority.
	- A failed load removes only staged new parts and leaves pre-existing ship
	  components untouched.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local BlueprintSerializer = require(script.Parent:WaitForChild("BlueprintSerializer"))
local StructuralAuthority = require(script.Parent:WaitForChild("StructuralAuthority"))

local BlueprintLoader = {}

export type ComponentFactory = (componentType: string, logicalId: string) -> BasePart?

type BlueprintComponent = BlueprintSerializer.BlueprintComponent

type PartMap = { [string]: BasePart }

local function validFiniteNumber(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function validateBlueprint(blueprint: BlueprintSerializer.Blueprint): (boolean, string?)
	if type(blueprint) ~= "table" then
		return false, "invalid blueprint"
	end
	if blueprint.Version ~= 2 then
		return false, "unsupported blueprint version"
	end
	if typeof(blueprint.RootComponentId) ~= "string" or blueprint.RootComponentId == "" then
		return false, "missing root component id"
	end
	if type(blueprint.Components) ~= "table" or #blueprint.Components == 0 then
		return false, "blueprint contains no components"
	end

	local ids: { [string]: boolean } = {}
	local rootCount = 0

	for _, component in ipairs(blueprint.Components) do
		if type(component) ~= "table" then
			return false, "invalid component record"
		end
		if typeof(component.Id) ~= "string" or component.Id == "" or ids[component.Id] then
			return false, "invalid or duplicate component id"
		end
		if typeof(component.ComponentType) ~= "string" or component.ComponentType == "" then
			return false, "invalid component type"
		end
		if not Components.Types[component.ComponentType] or not Components.Connections[component.ComponentType] then
			return false, "unknown component definition: " .. component.ComponentType
		end
		if component.ParentId ~= nil and (typeof(component.ParentId) ~= "string" or component.ParentId == "") then
			return false, "invalid parent id"
		end
		if component.ParentHardpointId ~= nil and (typeof(component.ParentHardpointId) ~= "string" or component.ParentHardpointId == "") then
			return false, "invalid parent hardpoint id"
		end
		if component.ChildHardpointId ~= nil and (typeof(component.ChildHardpointId) ~= "string" or component.ChildHardpointId == "") then
			return false, "invalid child hardpoint id"
		end
		if type(component.Position) ~= "table" or not validFiniteNumber(component.Position.x) or not validFiniteNumber(component.Position.y) then
			return false, "invalid component position"
		end
		if not validFiniteNumber(component.Angle) then
			return false, "invalid component angle"
		end

		ids[component.Id] = true
		if component.Id == blueprint.RootComponentId then
			rootCount += 1
		end
	end

	if rootCount ~= 1 then
		return false, "blueprint root id does not resolve exactly once"
	end

	for _, component in ipairs(blueprint.Components) do
		if component.ParentId == nil then
			if component.Id ~= blueprint.RootComponentId then
				return false, "multiple root components"
			end
		else
			if component.ParentId == component.Id or not ids[component.ParentId] then
				return false, "invalid parent reference"
			end
			if not component.ParentHardpointId or not component.ChildHardpointId then
				return false, "attached component missing hardpoint references"
			end
		end
	end

	return true, nil
end

local function indexById(blueprint: BlueprintSerializer.Blueprint): { [string]: BlueprintComponent }
	local result: { [string]: BlueprintComponent } = {}
	for _, component in ipairs(blueprint.Components) do
		result[component.Id] = component
	end
	return result
end

local function orderComponents(blueprint: BlueprintSerializer.Blueprint): { BlueprintComponent }?
	local byId = indexById(blueprint)
	local visiting: { [string]: boolean } = {}
	local visited: { [string]: boolean } = {}
	local ordered: { BlueprintComponent } = {}

	local function visit(component: BlueprintComponent): boolean
		if visited[component.Id] then
			return true
		end
		if visiting[component.Id] then
			return false
		end
		visiting[component.Id] = true

		if component.ParentId then
			local parent = byId[component.ParentId]
			if not parent or not visit(parent) then
				visiting[component.Id] = nil
				return false
			end
		end

		visiting[component.Id] = nil
		visited[component.Id] = true
		ordered[#ordered + 1] = component
		return true
	end

	for _, component in ipairs(blueprint.Components) do
		if not visit(component) then
			return nil
		end
	end

	return ordered
end

local function destroyStaged(created: { BasePart })
	for _, part in ipairs(created) do
		if part.Parent then
			part:Destroy()
		end
	end
end

local function setBlueprintTransform(ship: Model, part: BasePart, component: BlueprintComponent)
	local shipPivot = ship:GetPivot()
	local localCFrame = CFrame.new(component.Position.x, 0, component.Position.y)
		* CFrame.Angles(0, -component.Angle, 0)
	part.CFrame = shipPivot * localCFrame
end

function BlueprintLoader.Validate(blueprint: BlueprintSerializer.Blueprint): (boolean, string?)
	local valid, validationError = validateBlueprint(blueprint)
	if not valid then
		return false, validationError
	end
	if not orderComponents(blueprint) then
		return false, "blueprint contains a parent dependency cycle"
	end
	return true, nil
end

function BlueprintLoader.Load(
	ship: Model,
	blueprint: BlueprintSerializer.Blueprint,
	factory: ComponentFactory
): (boolean, string?)
	if not ship or not ship:IsA("Model") or not ship.Parent then
		return false, "invalid ship"
	end
	if type(factory) ~= "function" then
		return false, "missing component factory"
	end

	local valid, validationError = BlueprintLoader.Validate(blueprint)
	if not valid then
		return false, validationError
	end

	local ordered = orderComponents(blueprint)
	if not ordered then
		return false, "dependency ordering failed"
	end

	local staged: PartMap = {}
	local created: { BasePart } = {}

	for _, component in ipairs(ordered) do
		local part = factory(component.ComponentType, component.Id)
		if not part or not part:IsA("BasePart") then
			destroyStaged(created)
			return false, "component factory failed for " .. component.Id
		end

		part:SetAttribute("ComponentType", component.ComponentType)
		part:SetAttribute("BlueprintId", component.Id)
		part.Parent = ship
		setBlueprintTransform(ship, part, component)
		staged[component.Id] = part
		created[#created + 1] = part
	end

	local rootPart = staged[blueprint.RootComponentId]
	if not rootPart then
		destroyStaged(created)
		return false, "root component was not staged"
	end
	ship.PrimaryPart = rootPart

	for _, component in ipairs(ordered) do
		if component.ParentId then
			local part = staged[component.Id]
			local parentPart = staged[component.ParentId]
			if not part or not parentPart then
				destroyStaged(created)
				return false, "staged parent/child mapping failed"
			end

			local childNode = StructuralAuthority.AttachComponent(
				ship,
				part,
				component.ComponentType,
				math.huge
			)
			if not childNode then
				destroyStaged(created)
				return false, "structural attach failed for " .. component.Id
			end

			part:SetAttribute("ParentNodeId", component.ParentId)
			part:SetAttribute("ParentSocketId", component.ParentHardpointId)
			part:SetAttribute("ConnectedSocketId", component.ChildHardpointId)
			ComponentAuthority.SetParent(part, parentPart)
		else
			ComponentAuthority.Bind(rootPart, component.ComponentType)
		end
	end

	ComponentAuthority.BindShip(ship)
	return true, nil
end

return BlueprintLoader
