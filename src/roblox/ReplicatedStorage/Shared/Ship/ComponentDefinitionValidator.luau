--[=[
	ComponentDefinitionValidator
	Read-only validation of the authoritative Void Hunters component catalog.

	This service never rewrites component definitions. It reports connector-count
	mismatches so structural code can fail closed rather than silently inventing
	topology.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))

local ComponentDefinitionValidator = {}

export type Issue = {
	ComponentType: string,
	Field: string,
	Expected: number,
	Actual: number,
	Severity: "ERROR" | "WARNING",
}

local function countList(value: any): number
	if type(value) ~= "table" then
		return 0
	end
	return #value
end

function ComponentDefinitionValidator.Validate(componentType: string): { Issue }
	local issues: { Issue } = {}
	local connection = Components.Connections[componentType]
	if type(connection) ~= "table" then
		issues[#issues + 1] = {
			ComponentType = componentType,
			Field = "Connections",
			Expected = 1,
			Actual = 0,
			Severity = "ERROR",
		}
		return issues
	end

	local expectedIn = tonumber(connection.InConnectCount) or 0
	local actualIn = countList(connection.InConnectPositions)
	if expectedIn ~= actualIn then
		issues[#issues + 1] = {
			ComponentType = componentType,
			Field = "InConnectPositions",
			Expected = expectedIn,
			Actual = actualIn,
			Severity = "ERROR",
		}
	end

	local expectedOut = tonumber(connection.OutConnectCount) or 0
	local actualOut = connection.OutConnectPosition and 1 or 0
	if expectedOut > 1 then
		actualOut = countList(connection.OutConnectPositions)
	end
	if expectedOut ~= actualOut then
		issues[#issues + 1] = {
			ComponentType = componentType,
			Field = "OutConnectPosition",
			Expected = expectedOut,
			Actual = actualOut,
			Severity = "ERROR",
		}
	end

	return issues
end

function ComponentDefinitionValidator.ValidateAll(): { Issue }
	local issues: { Issue } = {}
	for componentType in pairs(Components.Connections) do
		for _, issue in ipairs(ComponentDefinitionValidator.Validate(componentType)) do
			issues[#issues + 1] = issue
		end
	end
	return issues
end

function ComponentDefinitionValidator.IsValid(componentType: string): boolean
	return #ComponentDefinitionValidator.Validate(componentType) == 0
end

return ComponentDefinitionValidator
