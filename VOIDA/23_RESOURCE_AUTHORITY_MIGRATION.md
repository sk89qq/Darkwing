# VOIDA — Resource Authority Migration

## SOURCE:
- `ReplicatedStorage/Shared/Combat/ShieldSystem.luau`
- `ReplicatedStorage/Shared/Combat/CapacitorSystem.luau`
- `ReplicatedStorage/Shared/VoidHunterComponents.luau`
- `ServerScriptService/VoidHunterWeaponController.luau`
- Existing forensic directives requiring component-definition-driven identity and no string-based gameplay identity.

## OLD:
- `ShieldSystem:CalculateFromShip()` used `BasePart.Name` substring checks (`Shield`, `Deflector`) as a compatibility fallback.
- Weapon orchestration kept a separate `shipEnergy` mirror alongside `CapacitorSystem` state.

## NEW:
- Shield discovery/configuration is exclusively driven by explicit `ComponentType` + `Components.Types` metadata.
- No shield identity is inferred from instance names.
- Existing prototype/inferred shield numerical behavior is retained unchanged and explicitly remains non-canonical.
- Resource consolidation target remains `CapacitorSystem` as the sole energy state owner; weapon-side mirror removal is the next sub-step.

## TEST:
- Top-level `ReplicatedStorage`/`Components` dependencies are explicit.
- No dynamic `require()` remains in the shield calculation path.
- Existing public `ShieldSystem` API is preserved.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
`ShieldSystem` now treats `ComponentType` as the only gameplay identity source. `Components.Types[typeName]` supplies shield fields. Do not reintroduce name matching. Keep inferred numerical shield values marked inferred until raw shield consumers are recovered. `CapacitorSystem` should become the sole authoritative energy state; do not add another ship-level `current/max/regen` table.
