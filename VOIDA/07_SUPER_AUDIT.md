# VOIDA SUPER AUDIT — 2026-08-26

## Authority
The supplied raw `voidhunters_decompiled` package is the authoritative first-pass forensic source. The repository manifest is `VOIDA/00_RAW_FORENSIC_REFERENCE.md`; the intact raw archive is `/VOIDA/voidhunters_decompiled_raw.zip` in the user Library.

No synthesized blueprint outranks the raw source. The removed `05_FORENSIC_PORT_BLUEPRINT.md` was a conflicting derived document and is not an authority.

## Canonical runtime boundaries
- `ComponentAuthority` = component runtime state/HP/damage/repair/destruction.
- `StructuralAuthority` = attach/detach/replace/sever graph mutation.
- `ShipRegistry` = authoritative player <-> ship lifecycle relationship.
- `ShipSocketGraph` = hardpoint/socket topology solver.
- `RigidBody2D` / Roblox Assembly = physical projection subject to recovered source behavior.
- `TeamIdentity` = Yellow/Blue team vocabulary.
- `VoidHunterBuilderServer` = canonical blueprint persistence + blueprint construction.

Do not add subsystem-local authoritative copies.

## Resolved migrations
- `VoidHunterShipSpawner` no longer owns `partHealth` / `partMaxHealth`.
- Ship lookup no longer uses a private spawner map; it uses `ShipRegistry`.
- Ship spawning/lifecycle now uses `TeamIdentity` and `StructuralAuthority.BindShip`.
- The fabricated 40%-HP / 80%-HP clone-salvage path was removed from the spawner because it was not supported by the raw component-debris path.
- `VoidHunterWeaponController` no longer contains `partHealth` / `partMaxHealth` compatibility tables.
- `VoidHunterWeaponController` no longer uses `activeShips`; ownership resolves through `ShipRegistry`.
- Combat component type resolution now uses `ComponentAuthority` state + `Components.Types` rather than name scanning in the controller.
- Hull classification now uses authoritative component definition `IsHull` metadata.
- Nearest-enemy ship lookup uses `ShipRegistry.GetAll()` instead of a global workspace model scan.
- Transient point-defence/scrambler scans use `Workspace:GetPartBoundsInRadius`.
- New weapon-controller scheduling uses `task.spawn`, `task.delay`, and `task.wait`.
- `ComponentAuthority` now fails closed when a component has no explicit valid `ComponentType`; it does not infer type from `BasePart.Name`.
- `ShipSocketGraph` no longer invents generic four-way sockets for unknown component types.
- `ShipSocketGraph` requires explicit component definitions from `Components.Types` + `Components.Connections` before creating topology nodes or sockets.
- `ShipSocketGraph` records explicit `ParentNodeId`, `ParentSocketId`, and `ConnectedSocketId` metadata during canonical attachment.
- `ShipSocketGraph` uses explicit relationship metadata first; legacy weld/proximity reconstruction is limited to an import adapter and cannot create unknown components or sockets.
- `StructuralAuthority.ReplaceComponent` now validates the replacement definition and preserved parent hardpoint before detaching the existing component, then attaches to that exact socket and rolls back on failure.
- Blueprint persistence and construction are consolidated into `VoidHunterBuilderServer`; the old blueprint system is now a compatibility facade with no independent datastore/schema.
- Builder placement routes through `StructuralAuthority`; the old direct blueprint mutation/adjacency authority was removed.
- Sync blueprint persistence is superseded by `VoidHunterBuilderServer`; ship lifecycle lookup routes through `ShipRegistry`.
- Spatial transient targeting remains query-based rather than workspace-descendant scanning.
- `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` is the standing implementation-style reference, subordinate to raw source semantics.

## Raw-source corrections from this pass
1. `wlb.java` directly initializes `hab.g` as 56 component-definition slots.
2. Only a subset of those slots are literal polygons in the decompiled initializer; many are generated from dependent chassis expressions. Those generated slots must not be replaced by guessed literals.
3. `wfb.java` derives health through `lw.a(..., u)`; the repository's simplified `sqrt(area) * z / 64` helper is not sufficient to call the exact transformation raw-verified.
4. `summary.txt` records CFR gaps in major methods. Those methods remain `RAW-GAP` until recovered from bytecode or a better decompilation.
5. Existing `ForensicDataModel` entries that were synthesized before the raw package was available must be treated as provisional unless they can be traced directly to raw source.

## Remaining P0
1. Recover exact source detach force, momentum carry-over, debris persistence, and cleanup behavior before adding policy.
2. Recover exact `anb` physics equations/constants from raw source/bytecode before declaring Roblox physics parity.
3. Replace remaining name/type heuristics in shield, power, repair, and combat systems with authoritative component definitions/data.
4. Port `MissionCondition` / `MissionAction` framework rather than expanding Arena-specific logic.
5. Replace any static data-table values whose provenance cannot be traced to the raw package with `RAW-GAP` / `INFERRED` status rather than leaving them marked `CODE_VERIFIED`.
6. Verify every live component definition whose `Components.Types` entry and `Components.Connections` entry diverge in connector counts before changing attachment semantics.
7. Prove all externally referenced compatibility facades have no remaining live callers, then delete `VoidHunterBlueprintSystem` and `VoidHunterSyncManager` rather than retaining unnecessary compatibility surface.

## Source-truth discipline
The raw package is evidence. The implementation must preserve uncertainty where the decompilation is uncertain.

Do not promote implementation compatibility into `VERIFIED` without acceptance testing and source evidence.

## Efficiency protocol
Before changing a mechanic:
1. Read `VOIDA/00_RAW_FORENSIC_REFERENCE.md`.
2. Read the relevant raw class/method from the supplied archive.
3. Read the relevant AGENTS directive/reference.
4. Search the repository for an existing authoritative implementation.
5. Replace deprecated callers rather than creating a parallel system.
6. Use repository-wide replacement for purely lexical deprecated symbols when the replacement is unambiguous.
7. Re-scan affected code and update status documentation.

For every resolved issue record:

```text
SOURCE:
OLD:
NEW:
TEST:
STATUS:
```

## Status vocabulary
- EXTRACTED
- IMPLEMENTED
- VERIFIED
- BLOCKED
- SUPERSEDED

END AUDIT
