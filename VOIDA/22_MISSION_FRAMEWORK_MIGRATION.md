# VOIDA — Mission Framework Migration

## Commit sequence
- `3b6ff204ff966b169cc4f57d4cb90ccfdce60a5a` — add canonical mission type contracts.
- `fbe5e996062a756fbfaabc58695848b758a320a4` — add searchable mission symbol index.
- `ef32740a0286697b09f07616c71b61d0265bde5c` — add canonical mission action service.
- `01e58de92fea1ed258187978f205a5768bc0bbe9` / `68a40a78b6be544b494fa4f4357f536704f603dc` — add and correct canonical mission condition service.
- `b8134487a41158f67cfd3132548c3cee1058eb0e` — add canonical mission runtime service.

## SOURCE:
- Supplied Void Hunters reference identifies MissionBuilder, MissionControl, MissionState, MissionVariable, MissionEvent, and MissionGenerationData concepts.
- Source-confirmed condition names: AtTick, BodyDestroyed, BodyInMapZone, NodeOnTeam, ShipHoldsComponent, ShipJustSpawned, ShipOnTeam.
- Source-confirmed action names: AddBodyInfo, AddNodeInfo, AddToCustomVariable, AwardVictory, SetCustomVariable, SetCustomVariableLabel, SetTeam.
- Existing Arena `VoidHunterMatchManager` is explicitly documented as a prototype rather than the complete mission framework.

## OLD:
- Match behavior lived in a single Arena-specific state machine.
- Mission condition/action concepts were documented but had no reusable Roblox runtime boundary.
- GitHub code search could not reliably surface the mission symbols.

## NEW:
- `MissionTypes` defines the source-confirmed condition/action/state contracts.
- `MissionConditionService` evaluates the seven confirmed predicates without owning gameplay state.
- `MissionActionService` executes the seven confirmed action types while delegating team vocabulary to `TeamIdentity`.
- `MissionService` hosts generic tick-driven state transitions from a supplied mission definition.
- `VOIDA/MISSION_SYMBOL_INDEX.md` is a stable search anchor containing all recovered mission symbol names and canonical paths.
- No Arena timing/mode behavior is promoted into canonical mission data by this change.

## TEST:
- Static API alignment checked against existing `ComponentAuthority` and `TeamIdentity` exports.
- Mission condition implementation uses `ComponentAuthority.Get` rather than an invented accessor.
- Mission action implementation uses the existing team vocabulary.
- Full Roblox Studio runtime acceptance has not been performed.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Use `MissionService` as the generic runtime host only after recovering a concrete `MissionDefinition`. Do not hard-code Arena timings or fabricate mode transitions in the service itself. Use `MissionConditionService` for predicate evaluation and `MissionActionService` for actions. `ShipRegistry`, `ComponentAuthority`, `StructuralAuthority`, `TeamIdentity`, and physics services remain external authorities. The source-confirmed symbol index is `VOIDA/MISSION_SYMBOL_INDEX.md`. Exact mode sequencing remains a forensic data-recovery task.
