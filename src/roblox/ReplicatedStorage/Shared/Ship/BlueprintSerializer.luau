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

local VERSION = 1

local function numberOrNil(value: any): number?
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return nil
	end
	return value
end

local function findComponentById(ship: Model, componentId: string): BasePart?
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("ComponentId") == componentId then
			return instance
		end
	end
	return nil
end

function BlueprintSerializer.Capture(ship: Model): Blueprint?
	if not ship or not ship:IsA("Model") or not ship.PrimaryPart then
		return nil
	end

	local rootId = ship.PrimaryPart:GetAttribute("ComponentId")
	if typeof(rootId) ~= "string" or rootId == "" then
		return nil
	end

	local rootCFrame = ship.PrimaryPart.CFrame
	local components: { BlueprintComponent } = {}

	for _, instance in ipairs(ship:GetDescendants()) do
		if not instance:IsA("BasePart") or instance:GetAttribute("IsDebris") then
			continue
		end

		local state = ComponentAuthority.Get(instance)
		if not state then
			continue
		end

		if not Components.Types[state.TypeName] then
			continue
		end

		local localCFrame = rootCFrame:ToObjectSpace(instance.CFrame)
		local _, yaw, _ = localCFrame:ToEulerAnglesYXZ()
		components[#components + 1] = {
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
		RootComponentId = rootId,
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
	for _, raw in ipairs(value.Components) do
		if type(raw) ~= "table" or typeof(raw.ComponentType) ~= "string" then
			return nil
		end
		if not Components.Types[raw.ComponentType] or not Components.Connections[raw.ComponentType] then
			return nil
		end
		if type(raw.Position) ~= "table" then
			return nil
		end
		local x = numberOrNil(raw.Position.x)
		local y = numberOrNil(raw.Position.y)
		local angle = numberOrNil(raw.Angle)
		if not x or not y or angle == nil then
			return nil
		end

		sanitized[#sanitized + 1] = {
			ComponentType = raw.ComponentType,
			ParentId = typeof(raw.ParentId) == "string" and raw.ParentId or nil,
			ParentHardpointId = typeof(raw.ParentHardpointId) == "string" and raw.ParentHardpointId or nil,
			ChildHardpointId = typeof(raw.ChildHardpointId) == "string" and raw.ChildHardpointId or nil,
			Position = { x = x, y = y },
			Angle = angle,
		}
	end

	return {
		Version = VERSION,
		RootComponentId = value.RootComponentId,
		Components = sanitized,
	}
end

function BlueprintSerializer.FindRoot(ship: Model, blueprint: Blueprint): BasePart?
	return findComponentById(ship, blueprint.RootComponentId)
end

return BlueprintSerializer
