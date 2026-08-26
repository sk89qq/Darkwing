# Void Hunters Mission Symbol Index

Purpose: stable repository-search anchor for the recovered MissionBuilder / MissionCondition / MissionAction architecture.

## Source-confirmed condition symbols

MissionConditionAtTick
MissionConditionBodyDestroyed
MissionConditionBodyInMapZone
MissionConditionNodeOnTeam
MissionConditionShipHoldsComponent
MissionConditionShipJustSpawned
MissionConditionShipOnTeam

## Source-confirmed action symbols

MissionActionAddBodyInfo
MissionActionAddNodeInfo
MissionActionAddToCustomVariable
MissionActionAwardVictory
MissionActionSetCustomVariable
MissionActionSetCustomVariableLabel
MissionActionSetTeam

## Canonical Roblox implementation

- ReplicatedStorage/Shared/Missions/MissionTypes.luau
- ReplicatedStorage/Shared/Missions/MissionConditionService.luau
- ReplicatedStorage/Shared/Missions/MissionActionService.luau
- ReplicatedStorage/Shared/Missions/MissionService.luau

## Canonical service boundaries

MissionService
- Owns mission runtime lifecycle/state transitions.
- Does not own ship/component/physics authority.

MissionConditionService
- Evaluates mission predicates only.
- Reads canonical ShipRegistry, ComponentAuthority, TeamIdentity, and mission runtime context.

MissionActionService
- Executes mission actions only.
- Mutates mission context and delegates gameplay mutations to authoritative services.

## Known original mission concepts

MissionBuilder
MissionControl
MissionEvent
MissionGenerationData
MissionState
MissionVariable
Mission

## Known game modes from source documentation

Arena / War
Assault
Double Assault
Assassination
Double Assassination
Convoy
Double Convoy
Capture and Hold
Blueprint modes
Sandbox

## Search aliases

MissionCondition
MissionAction
MissionBuilder
MissionControl
MissionState
MissionVariable
mission_conditions
mission_actions
mission state machine

## Provenance

The symbol list above is source-confirmed by the supplied Void Hunters decompiled/reference material. Exact per-mode sequencing remains a separate forensic task until the underlying MissionBuilder/MissionControl data and transition logic are fully recovered.

Do not replace these source names with ad-hoc Arena-specific equivalents.
