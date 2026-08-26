--[=[
	MissionService
	Generic runtime host for the recovered Void Hunters mission state machine.

	This service intentionally does not define a specific game mode. Mode data is
	provided as MissionDefinition and evaluated through MissionConditionService
	and MissionActionService.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MissionTypes = require(ReplicatedStorage.Shared.Missions:WaitForChild("MissionTypes"))
local MissionConditionService = require(ReplicatedStorage.Shared.Missions:WaitForChild("MissionConditionService"))
local MissionActionService = require(ReplicatedStorage.Shared.Missions:WaitForChild("MissionActionService"))

local MissionService = {}
MissionService.__index = MissionService

local function newContext(definition: MissionTypes.MissionDefinition): MissionTypes.MissionRuntimeContext
	assert(definition.States[definition.InitialState], "Mission initial state does not exist")
	return {
		Tick = 0,
		Now = os.clock(),
		Mission = definition,
		StateId = definition.InitialState,
		StateEnteredTick = 0,
		CustomVariables = {},
		BodyInfo = {},
		NodeInfo = {},
		SpawnedShips = {},
		VictoryTeam = nil,
		Data = {},
	}
end

function MissionService.new(definition: MissionTypes.MissionDefinition)
	assert(type(definition) == "table", "MissionService.new expects a mission definition")
	assert(type(definition.Id) == "string", "Mission definition requires Id")
	assert(type(definition.InitialState) == "string", "Mission definition requires InitialState")
	assert(type(definition.States) == "table", "Mission definition requires States")

	local self = setmetatable({}, MissionService)
	self.Context = newContext(definition)
	self.Running = false
	self.OnStateChanged = nil :: ((string, string) -> ())?
	self.OnVictory = nil :: ((string) -> ())?
	return self
end

function MissionService:SetStateChangedCallback(callback: ((string, string) -> ())?)
	self.OnStateChanged = callback
end

function MissionService:SetVictoryCallback(callback: ((string) -> ())?)
	self.OnVictory = callback
end

function MissionService:Start()
	self.Running = true
	self.Context.Now = os.clock()
	self.Context.StateEnteredTick = self.Context.Tick
end

function MissionService:Stop()
	self.Running = false
end

function MissionService:IsRunning(): boolean
	return self.Running
end

function MissionService:GetContext(): MissionTypes.MissionRuntimeContext
	return self.Context
end

function MissionService:RegisterSpawnedShip(ship: Model)
	if not ship or not ship:IsA("Model") then
		return
	end
	self.Context.SpawnedShips[ship] = self.Context.Tick
end

function MissionService:UnregisterShip(ship: Model)
	self.Context.SpawnedShips[ship] = nil
end

function MissionService:RecordBodyInfo(bodyId: string, info: any)
	self.Context.BodyInfo[bodyId] = info
end

function MissionService:RecordNodeInfo(nodeId: string, info: any)
	self.Context.NodeInfo[nodeId] = info
end

function MissionService:SetCustomVariable(key: string, value: any, label: string?)
	self.Context.CustomVariables[key] = {
		Value = value,
		Label = label,
	}
end

local function processTransition(self: any, transition: MissionTypes.MissionTransition): boolean
	if not MissionConditionService.EvaluateAll(self.Context, transition.Conditions) then
		return false
	end

	for _, action in ipairs(transition.Actions) do
		if not MissionActionService.Execute(self.Context, action) then
			return false
		end
	end

	local nextState = transition.NextState
	if nextState and nextState ~= self.Context.StateId then
		local previousState = self.Context.StateId
		assert(self.Context.Mission.States[nextState], "Mission transition targets an unknown state: " .. nextState)
		self.Context.StateId = nextState
		self.Context.StateEnteredTick = self.Context.Tick
		if self.OnStateChanged then
			self.OnStateChanged(previousState, nextState)
		end
	end

	if self.Context.VictoryTeam and self.OnVictory then
		self.OnVictory(self.Context.VictoryTeam)
	end

	return true
end

function MissionService:Tick(tickNumber: number?)
	if not self.Running then
		return
	end

	if tickNumber ~= nil then
		assert(type(tickNumber) == "number", "MissionService.Tick expects a numeric tick")
		self.Context.Tick = tickNumber
	else
		self.Context.Tick += 1
	end
	self.Context.Now = os.clock()

	local state = self.Context.Mission.States[self.Context.StateId]
	if not state then
		self.Running = false
		return
	end

	for _, transition in ipairs(state.Transitions) do
		if processTransition(self, transition) then
			break
		end
	end
end

return MissionService
