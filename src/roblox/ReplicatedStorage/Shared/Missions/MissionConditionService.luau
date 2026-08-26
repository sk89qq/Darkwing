--[=[
	MissionConditionService
	Canonical evaluation of the recovered Void Hunters mission conditions.

	This service evaluates predicates only. It does not own mission state,
	ship lifecycle, component health, or team state.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))
local MissionTypes = require(ReplicatedStorage.Shared.Missions:WaitForChild("MissionTypes"))

local MissionConditionService = {}

local function asModel(value: any): Model?
	if typeof(value) == "Instance" and value:IsA("Model") then
		return value
	end
	return nil
end

local function getShipFromValue(value: any): Model?
	local model = asModel(value)
	if model and model:GetAttribute("IsShip") == true then
		return model
	end

	if typeof(value) ~= "Instance" then
		return nil
	end

	local current: Instance? = value
	while current do
		if current:IsA("Model") and current:GetAttribute("IsShip") == true then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function resolveBodyId(value: any): string?
	if type(value) == "string" then
		return value
	end
	if type(value) == "number" then
		return tostring(value)
	end
	if typeof(value) == "Instance" then
		local bodyId = value:GetAttribute("BodyId")
		if type(bodyId) == "string" then
			return bodyId
		end
		local shipId = value:GetAttribute("ShipId")
		if type(shipId) == "string" then
			return shipId
		end
	end
	return nil
end

local function resolveNode(value: any): Instance?
	if typeof(value) == "Instance" then
		return value
	end
	return nil
end

local function shipHoldsComponent(ship: Model, componentType: string): boolean
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") then
			local state = ComponentAuthority.Get(instance)
			if state and state.TypeName == componentType and not state.Destroyed then
				return true
			end
		end
	end
	return false
end

local function isConditionTrue(context: MissionTypes.MissionRuntimeContext, condition: MissionTypes.MissionCondition): boolean
	local value = condition.Value

	if condition.Type == "AtTick" then
		local targetTick = if type(value) == "number" then value else nil
		return targetTick ~= nil and context.Tick >= targetTick
	end

	if condition.Type == "BodyDestroyed" then
		local bodyId = resolveBodyId(value)
		if not bodyId then
			return false
		end
		local bodyInfo = context.BodyInfo[bodyId]
		return type(bodyInfo) == "table" and bodyInfo.Destroyed == true
	end

	if condition.Type == "BodyInMapZone" then
		if type(value) ~= "table" then
			return false
		end
		local bodyId = resolveBodyId(value.Body)
		local zone = value.Zone
		if not bodyId or type(zone) ~= "table" then
			return false
		end
		local bodyInfo = context.BodyInfo[bodyId]
		if type(bodyInfo) ~= "table" or typeof(bodyInfo.Position) ~= "Vector3" then
			return false
		end
		local center = zone.Center
		local size = zone.Size
		if typeof(center) ~= "Vector3" or typeof(size) ~= "Vector3" then
			return false
		end
		local position = bodyInfo.Position :: Vector3
		local half = size * 0.5
		return math.abs(position.X - center.X) <= half.X
			and math.abs(position.Y - center.Y) <= half.Y
			and math.abs(position.Z - center.Z) <= half.Z
	end

	if condition.Type == "NodeOnTeam" then
		if type(value) ~= "table" then
			return false
		end
		local node = resolveNode(value.Node)
		local team = value.Team
		if not node or not TeamIdentity.IsValid(team) then
			return false
		end
		return TeamIdentity.Get(node) == team
	end

	if condition.Type == "ShipHoldsComponent" then
		if type(value) ~= "table" then
			return false
		end
		local ship = getShipFromValue(value.Ship)
		if not ship or type(value.ComponentType) ~= "string" then
			return false
		end
		return shipHoldsComponent(ship, value.ComponentType)
	end

	if condition.Type == "ShipJustSpawned" then
		local ship = getShipFromValue(value)
		if not ship then
			return false
		end
		local spawnTick = context.SpawnedShips[ship]
		return type(spawnTick) == "number" and spawnTick == context.Tick
	end

	if condition.Type == "ShipOnTeam" then
		if type(value) ~= "table" then
			return false
		end
		local ship = getShipFromValue(value.Ship)
		local team = value.Team
		if not ship or not TeamIdentity.IsValid(team) then
			return false
		end
		return TeamIdentity.Get(ship) == team
	end

	return false
end

function MissionConditionService.Evaluate(context: MissionTypes.MissionRuntimeContext, condition: MissionTypes.MissionCondition): boolean
	local result = isConditionTrue(context, condition)
	if condition.Invert == true then
		return not result
	end
	return result
end

function MissionConditionService.EvaluateAll(context: MissionTypes.MissionRuntimeContext, conditions: { MissionTypes.MissionCondition }): boolean
	for _, condition in ipairs(conditions) do
		if not MissionConditionService.Evaluate(context, condition) then
			return false
		end
	end
	return true
end

return MissionConditionService
