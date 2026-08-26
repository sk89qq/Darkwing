--[=[
	BlueprintSerializer
	Primitive-only ship topology serialization boundary.

	The saved representation intentionally contains no Roblox Instance/CFrame/
	Vector3/WeldConstraint values. Runtime reconstruction must flow through
	StructuralAuthority rather than bypassing the structural solver.
]=]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))

local BlueprintSerializer = {}

export type BlueprintComponent = {
	Id: string,
	ComponentType: string,
	ParentId: string?,
	ParentHardpointId: string?,
	ChildHardpointId: string?,
	Position: { x: number, y: number },
	Angle: number,
}

export type Blueprint = {
	Version: number,
	RootComponentId: string,
	Components: { BlueprintComponent },
}

local VERSION = 2

local function numberOrNil(value: any): number?
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return value
end

function BlueprintSerializer.Capture(ship: Model): Blueprint?
	if not ship or not ship:IsA("Model") or not ship.PrimaryPart then
		return nil
	end

	local rootState = ComponentAuthority.Get(ship.PrimaryPart)
	if not rootState then
		return nil
	end

	local components: { BlueprintComponent } = {}
	local rootCFrame = ship.PrimaryPart.CFrame

	for _, instance in ipairs(ship:GetDescendants()) do
		if not instance:IsA("BasePart") or instance:GetAttribute("IsDebris") then
			continue
		end

		local state = ComponentAuthority.Get(instance)
		if not state then
			continue
		end
		if not Components.Types[state.TypeName] or not Components.Connections[state.TypeName] then
			continue
		end

		local localCFrame = rootCFrame:ToObjectSpace(instance.CFrame)
		local _, yaw, _ = localCFrame:ToEulerAnglesYXZ()
		components[#components + 1] = {
			Id = state.Id,
			ComponentType = state.TypeName,
			ParentId = state.ParentId,
			ParentHardpointId = instance:GetAttribute("ParentSocketId"),
			ChildHardpointId = instance:GetAttribute("ConnectedSocketId"),
			Position = {
				x = localCFrame.Position.X,
				y = localCFrame.Position.Z,
			},
			Angle = -yaw,
		}
	end

	return {
		Version = VERSION,
		RootComponentId = rootState.Id,
		Components = components,
	}
end

function BlueprintSerializer.Encode(blueprint: Blueprint): string
	assert(blueprint.Version == VERSION, "unsupported blueprint version")
	return HttpService:JSONEncode(blueprint)
end

function BlueprintSerializer.Decode(encoded: string): Blueprint?
	if typeof(encoded) ~= "string" or encoded == "" then
		return nil
	end

	local ok, value = pcall(HttpService.JSONDecode, HttpService, encoded)
	if not ok or type(value) ~= "table" then
		return nil
	end
	if value.Version ~= VERSION or typeof(value.RootComponentId) ~= "string" or type(value.Components) ~= "table" then
		return nil
	end

	local sanitized: { BlueprintComponent } = {}
	local ids: { [string]: boolean } = {}
	for _, raw in ipairs(value.Components) do
		if type(raw) ~= "table" then
			return nil
		end
		if typeof(raw.Id) ~= "string" or raw.Id == "" or ids[raw.Id] then
			return nil
		end
		if typeof(raw.ComponentType) ~= "string" then
			return nil
		end
		if not Components.Types[raw.ComponentType] or not Components.Connections[raw.ComponentType] then
			return nil
		end
		if raw.ParentId ~= nil and typeof(raw.ParentId) ~= "string" then
			return nil
		end
		if raw.ParentHardpointId ~= nil and typeof(raw.ParentHardpointId) ~= "string" then
			return nil
		end
		if raw.ChildHardpointId ~= nil and typeof(raw.ChildHardpointId) ~= "string" then
			return nil
		end
		if type(raw.Position) ~= "table" then
			return nil
		end

		local x = numberOrNil(raw.Position.x)
		local y = numberOrNil(raw.Position.y)
		local angle = numberOrNil(raw.Angle)
		if x == nil or y == nil or angle == nil then
			return nil
		end

		ids[raw.Id] = true
		sanitized[#sanitized + 1] = {
			Id = raw.Id,
			ComponentType = raw.ComponentType,
			ParentId = raw.ParentId,
			ParentHardpointId = raw.ParentHardpointId,
			ChildHardpointId = raw.ChildHardpointId,
			Position = { x = x, y = y },
			Angle = angle,
		}
	end

	if not ids[value.RootComponentId] then
		return nil
	end

	local rootCount = 0
	for _, component in ipairs(sanitized) do
		if component.ParentId and not ids[component.ParentId] then
			return nil
		end
		if component.Id == value.RootComponentId then
			rootCount += 1
		end
	end

	if rootCount ~= 1 then
		return nil
	end

	return {
		Version = VERSION,
		RootComponentId = value.RootComponentId,
		Components = sanitized,
	}
end

function BlueprintSerializer.FindRoot(ship: Model, blueprint: Blueprint): BasePart?
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("ComponentId") == blueprint.RootComponentId then
			return instance
		end
	end
	return nil
end

return BlueprintSerializer
