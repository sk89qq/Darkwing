# VOIDA — Blueprint Transaction Migration

## SOURCE:
- `VOIDA/15_BLUEPRINT_BUILD_AUTHORITY_MIGRATION.md`
- `src/roblox/ReplicatedStorage/Shared/Ship/BlueprintSerializer.luau`
- `src/roblox/ReplicatedStorage/Shared/Ship/BlueprintLoader.luau`
- `src/roblox/ReplicatedStorage/Shared/Ship/StructuralAuthority.luau`

## OLD:
- Blueprint loading staged components and then attached them directly to the live ship.
- A later structural attach failure could destroy staged parts without guaranteeing restoration of the ship's pre-load topology.
- Blueprint component IDs and hardpoint IDs had previously been conflated in an earlier draft and were corrected in Version 2.

## NEW:
- `BlueprintSerializer` Version 2 persists an explicit stable `BlueprintComponent.Id`.
- `ParentId` references component IDs only.
- `ParentHardpointId` / `ChildHardpointId` remain socket identifiers.
- `BlueprintLoader` validates schema, component definitions, root uniqueness, parent references, cycles, and staged hardpoint assignments before the target ship is mutated.
- `StructuralAuthority.RunTransaction()` snapshots structural Roblox state and restores it if the operation fails or throws.
- `BlueprintLoader.Load()` performs its live structural commit inside `RunTransaction()`.
- Newly created Roblox runtime `ComponentId` values remain separate from persisted blueprint IDs.

## TEST:
- Source-level contract review completed against current `StructuralAuthority`, `BlueprintSerializer`, and `BlueprintLoader` APIs.
- Loader uses no deprecated scheduler APIs.
- Loader contains no Part-name type inference.
- Remaining runtime acceptance requires Roblox Studio execution because this environment cannot run the Roblox engine.

## STATUS:
IMPLEMENTED / PARTIAL — transactional structural rollback boundary is implemented at source level; runtime Studio acceptance remains pending.

## FUTURE AGENT NOTE:
Treat `BlueprintSerializer` V2 as the persistence schema. Never reuse `ComponentId`, `NodeId`, or hardpoint IDs as substitutes for `BlueprintComponent.Id`. All live graph mutation must remain inside `StructuralAuthority`. `RunTransaction()` restores topology-relevant part membership/attributes/physics state, but it is not a universal undo mechanism for external side effects outside the structural boundary.

## Git-ready commit message:
`feat: make blueprint load commit transactional`
