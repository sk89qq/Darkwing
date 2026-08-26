--[=[
	MissionTypes
	Canonical shared mission data types for the recovered Void Hunters mission model.

	Source-confirmed condition names:
		MissionConditionAtTick
		MissionConditionBodyDestroyed
		MissionConditionBodyInMapZone
		MissionConditionNodeOnTeam
		MissionConditionShipHoldsComponent
		MissionConditionShipJustSpawned
		MissionConditionShipOnTeam

	Source-confirmed action names:
		MissionActionAddBodyInfo
		MissionActionAddNodeInfo
		MissionActionAddToCustomVariable
		MissionActionAwardVictory
		MissionActionSetCustomVariable
		MissionActionSetCustomVariableLabel
		MissionActionSetTeam

	The exact original per-mode sequencing remains source-recovery work. This
	module defines only the stable data contract required to host it.
]=]

export type ConditionType =
	"AtTick"
	| "BodyDestroyed"
	| "BodyInMapZone"
	| "NodeOnTeam"
	| "ShipHoldsComponent"
	| "ShipJustSpawned"
	| "ShipOnTeam"

export type ActionType =
	"AddBodyInfo"
	| "AddNodeInfo"
	| "AddToCustomVariable"
	| "AwardVictory"
	| "SetCustomVariable"
	| "SetCustomVariableLabel"
	| "SetTeam"

export type MissionCondition = {
	Type: ConditionType,
	Value: any?,
	Invert: boolean?,
}

export type MissionAction = {
	Type: ActionType,
	Value: any?,
}

export type MissionTransition = {
	Conditions: { MissionCondition },
	Actions: { MissionAction },
	NextState: string?,
}

export type MissionStateDefinition = {
	Id: string,
	DurationTicks: number?,
	Transitions: { MissionTransition },
}

export type MissionDefinition = {
	Id: string,
	Name: string,
	InitialState: string,
	States: { [string]: MissionStateDefinition },
	MaxPlayers: number?,
}

export type CustomVariable = {
	Value: any,
	Label: string?,
}

export type MissionRuntimeContext = {
	Tick: number,
	Now: number,
	Mission: MissionDefinition,
	StateId: string,
	StateEnteredTick: number,
	CustomVariables: { [string]: CustomVariable },
	BodyInfo: { [string]: any },
	NodeInfo: { [string]: any },
	SpawnedShips: { [Instance]: number },
	VictoryTeam: string?,
	Data: { [string]: any },
}

return {}
