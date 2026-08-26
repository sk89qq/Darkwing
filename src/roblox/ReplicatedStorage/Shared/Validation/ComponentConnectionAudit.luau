--[=[
	ComponentConnectionAudit
	
	Read-only validator for the canonical VoidHunterComponents.Connections table.
	It never mutates component definitions. It reports declaration/array/count
	mismatches so raw-source review can decide whether an unusual definition is
	intentional or requires migration.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))

local ComponentConnectionAudit = {}

export type Issue = {
	ComponentType: string,
	Kind: string,
	Expected: number,
	Observed: number,
	Detail: string,
}

local function countArray(value: any): number
	if type(value) ~= "table" then
		return 0
	end
	return #value
end

local function countOut(definition: any): number
	if typeof(definition.OutConnectPosition) == "string" and definition.OutConnectPosition ~= "" then
		return 1
	end
	if type(definition.OutConnectPositions) == "table" then
		return #definition.OutConnectPositions
	end
	return 0
end

function ComponentConnectionAudit.Run(): { Issue }
	local issues: { Issue } = {}

	for componentType, definition in pairs(Components.Connections) do
		if type(definition) ~= "table" then
			issues[#issues + 1] = {
				ComponentType = componentType,
				Kind = "InvalidDefinition",
				Expected = 1,
				Observed = 0,
				Detail = "Connection definition is not a table",
			}
			continue
		end

		local declaredIn = tonumber(definition.InConnectCount) or 0
		local observedIn = countArray(definition.InConnectPositions)
		if declaredIn ~= observedIn then
			issues[#issues + 1] = {
				ComponentType = componentType,
				Kind = "InConnectCountMismatch",
				Expected = declaredIn,
				Observed = observedIn,
				Detail = "InConnectCount does not match InConnectPositions length",
			}
		end

		local declaredOut = tonumber(definition.OutConnectCount) or 0
		local observedOut = countOut(definition)
		if declaredOut ~= observedOut then
			issues[#issues + 1] = {
				ComponentType = componentType,
				Kind = "OutConnectCountMismatch",
				Expected = declaredOut,
				Observed = observedOut,
				Detail = "OutConnectCount does not match declared output connector shape",
			}
		end

		if type(definition.MeshAttachmentPositions) == "table" then
			local meshIn = 0
			for key in pairs(definition.MeshAttachmentPositions) do
				if string.match(tostring(key), "^InConnect_%d+$") then
					meshIn += 1
				end
			end
			if meshIn > 0 and meshIn ~= observedIn then
				issues[#issues + 1] = {
					ComponentType = componentType,
					Kind = "MeshInConnectCountMismatch",
					Expected = observedIn,
					Observed = meshIn,
					Detail = "MeshAttachmentPositions InConnect entries differ from declared socket array",
				}
			end
		end
	end

	table.sort(issues, function(a, b)
		if a.ComponentType == b.ComponentType then
			return a.Kind < b.Kind
		end
		return a.ComponentType < b.ComponentType
	end)

	return issues
end

return ComponentConnectionAudit
