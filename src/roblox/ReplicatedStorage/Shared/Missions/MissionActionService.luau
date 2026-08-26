--[=[
	MissionActionService
	Canonical execution boundary for the recovered Void Hunters mission actions.

	This service owns only mission-context mutation. Gameplay authority remains
	in the existing services and is injected through the mission context rather
	than duplicated here.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamIdentity = require(ReplicatedStorage.Shared.Combat:WaitForChild("TeamIdentity"))
local MissionTypes = require(ReplicatedStorage.Shared.Missions:WaitForChild("MissionTypes"))

local MissionActionService = {}

local function setCustomVariable(context: MissionTypes.MissionRuntimeContext, key: string, value: any)
	context.CustomVariables[key] = {
		Value = value,
		Label = context.CustomVariables[key] and context.CustomVariables[key].Label or nil,
	}
end

function MissionActionService.Execute(context: MissionTypes.MissionRuntimeContext, action: MissionTypes.MissionAction): boolean
	if not context or not action or not action.Type then
		return false
	end

	local value = action.Value

	if action.Type == "AddBodyInfo" then
		if type(value) ~= "table" or value.Id == nil then
			return false
		end
		context.BodyInfo[tostring(value.Id)] = value.Data or value
		return true
	end

	if action.Type == "AddNodeInfo" then
		if type(value) ~= "table" or value.Id == nil then
			return false
		end
		context.NodeInfo[tostring(value.Id)] = value.Data or value
		return true
	end

	if action.Type == "AddToCustomVariable" then
		if type(value) ~= "table" or type(value.Key) ~= "string" or type(value.Amount) ~= "number" then
			return false
		end
		local existing = context.CustomVariables[value.Key]
		local current = existing and existing.Value or 0
		if type(current) ~= "number" then
			return false
		end
		setCustomVariable(context, value.Key, current + value.Amount)
		return true
	end

	if action.Type == "AwardVictory" then
		if type(value) ~= "string" or not TeamIdentity.IsValid(value) then
			return false
		end
		context.VictoryTeam = value
		return true
	end

	if action.Type == "SetCustomVariable" then
		if type(value) ~= "table" or type(value.Key) ~= "string" then
			return false
		end
		setCustomVariable(context, value.Key, value.Value)
		return true
	end

	if action.Type == "SetCustomVariableLabel" then
		if type(value) ~= "table" or type(value.Key) ~= "string" or type(value.Label) ~= "string" then
			return false
		end
		local existing = context.CustomVariables[value.Key]
		if existing then
			existing.Label = value.Label
		else
			context.CustomVariables[value.Key] = {
				Value = nil,
				Label = value.Label,
			}
		end
		return true
	end

	if action.Type == "SetTeam" then
		if type(value) ~= "table" or typeof(value.Node) ~= "Instance" or not value.Node:IsA("Model") then
			return false
		end
		if not TeamIdentity.IsValid(value.Team) then
			return false
		end
		TeamIdentity.Set(value.Node, value.Team)
		return true
	end

	return false
end

return MissionActionService
