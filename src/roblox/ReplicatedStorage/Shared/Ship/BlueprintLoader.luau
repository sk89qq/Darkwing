--[=[
	BlueprintLoader
	Transactional Roblox-side reconstruction for BlueprintSerializer.

	Rules:
	- Validate the complete primitive blueprint before mutating the target ship.
	- Blueprint IDs are logical persistence identifiers only.
	- ParentId references blueprint component Id values.
	- ParentHardpointId and ChildHardpointId are socket identifiers.
	- Newly created Roblox parts receive runtime ComponentId values through
	  ComponentAuthority.
	- Every topology mutation flows through StructuralAuthority.
	- Staging occurs outside the target ship until schema/topology validation passes.
	- The structural commit runs inside StructuralAuthority.RunTransaction().
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local BlueprintSerializer = require(script.Parent:WaitForChild("BlueprintSerializer"))
local StructuralAuthority = require(script.Parent:WaitForChild("StructuralAuthority"))
local ShipSocketGraph = require(ReplicatedStorage.Shared:WaitForChild("ShipSocketGraph"))

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

local function destroyCreated(created: { BasePart })
	for _, part in ipairs(created) do
		if part.Parent then
			part:Destroy()
		end
	end
end

local function stageTransform(ship: Model, part: BasePart, component: BlueprintComponent)
	local shipPivot = ship:GetPivot()
	part.CFrame = shipPivot
		* CFrame.new(component.Position.x, 0, component.Position.y)
		* CFrame.Angles(0, -component.Angle, 0)
end

local function validateStagedTopology(
	staged: PartMap,
	blueprint: BlueprintSerializer.Blueprint,
	ordered: { BlueprintComponent }
): (boolean, string?)
	local stageModel = Instance.new("Model")
	stageModel.Name = "BlueprintValidationStage"

	local root = staged[blueprint.RootComponentId]
	if not root then
		stageModel:Destroy()
		return false, "staged root missing"
	end

	for _, component in ipairs(ordered) do
		local part = staged[component.Id]
		if not part then
			stageModel:Destroy()
			return false, "staged component missing"
		end
		part.Parent = stageModel
	end

	stageModel.PrimaryPart = root
	local graph = ShipSocketGraph.new(stageModel)
	if not graph.RootNodeId then
		stageModel:Destroy()
		return false, "staged root does not define a valid component"
	end

	local byId = indexById(blueprint)
	local occupied: { [string]: boolean } = {}

	for _, component in ipairs(ordered) do
		if component.ParentId then
			local parent = byId[component.ParentId]
			local parentPart = parent and staged[parent.Id]
			if not parentPart then
				stageModel:Destroy()
				return false, "missing staged parent"
			end

			local parentNode = graph.Nodes[parentPart:GetAttribute("NodeId")]
			if not parentNode then
				stageModel:Destroy()
				return false, "staged parent graph node missing"
			end

			local parentSocket = parentNode.Sockets[component.ParentHardpointId]
			if not parentSocket or parentSocket.Type ~= "InConnect" then
				stageModel:Destroy()
				return false, "invalid parent hardpoint: " .. tostring(component.ParentHardpointId)
			end

			local childPart = staged[component.Id]
			local childNode = childPart and graph.Nodes[childPart:GetAttribute("NodeId")]
			if not childNode then
				stageModel:Destroy()
				return false, "staged child graph node missing"
			end

			local childSocket = childNode.Sockets[component.ChildHardpointId]
			if not childSocket or childSocket.Type ~= "OutConnect" then
				stageModel:Destroy()
				return false, "invalid child hardpoint: " .. tostring(component.ChildHardpointId)
			end

			local occupancyKey = component.ParentId .. ":" .. component.ParentHardpointId
			if occupied[occupancyKey] then
				stageModel:Destroy()
				return false, "duplicate parent hardpoint assignment"
			end
			occupied[occupancyKey] = true
		end
	end

	stageModel:Destroy()
	return true, nil
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
			destroyCreated(created)
			return false, "component factory failed for " .. component.Id
		end

		part:SetAttribute("ComponentType", component.ComponentType)
		part:SetAttribute("BlueprintId", component.Id)
		part:SetAttribute("NodeId", "blueprint_node_" .. component.Id)
		part.Parent = nil
		stageTransform(ship, part, component)
		staged[component.Id] = part
		created[#created + 1] = part
	end

	local topologyValid, topologyError = validateStagedTopology(staged, blueprint, ordered)
	if not topologyValid then
		destroyCreated(created)
		return false, topologyError
	end

	for _, part in pairs(staged) do
		part.Parent = nil
	end

	local rootPart = staged[blueprint.RootComponentId]
	if not rootPart then
		destroyCreated(created)
		return false, "root component was not staged"
	end

	local committed, commitResult = StructuralAuthority.RunTransaction(ship, function(): (boolean, any?)
		for _, component in ipairs(ordered) do
			local part = staged[component.Id]
			if not part then
				return false, "missing staged component during commit"
			end
			part.Parent = ship
		end

		ship.PrimaryPart = rootPart

		for _, component in ipairs(ordered) do
			local part = staged[component.Id]
			if component.ParentId then
				local childNode, attachError = StructuralAuthority.AttachComponent(
					ship,
					part,
					component.ComponentType,
					math.huge
				)
				if not childNode then
					return false, attachError or ("structural attach failed for " .. component.Id)
				end

				part:SetAttribute("ParentNodeId", component.ParentId)
				part:SetAttribute("ParentSocketId", component.ParentHardpointId)
				part:SetAttribute("ConnectedSocketId", component.ChildHardpointId)

				local parentPart = staged[component.ParentId]
				if not parentPart or not ComponentAuthority.SetParent(part, parentPart) then
					return false, "parent state commit failed for " .. component.Id
				end
			else
				if not ComponentAuthority.Bind(part, component.ComponentType) then
					return false, "root component binding failed"
				end
			end
		end

		ComponentAuthority.BindShip(ship)
		return true, nil
	end)

	if not committed then
		destroyCreated(created)
		return false, commitResult
	end

	return true, nil
end

return BlueprintLoader