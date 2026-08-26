# VOIDA SUPER AUDIT — 2026-08-26

## Authority
The supplied raw `voidhunters_decompiled` package is the authoritative first-pass forensic source. The repository manifest is `VOIDA/00_RAW_FORENSIC_REFERENCE.md`; the intact raw archive is `/VOIDA/voidhunters_decompiled_raw.zip` in the user Library.

No synthesized blueprint outranks the raw source. The removed `05_FORENSIC_PORT_BLUEPRINT.md` was a conflicting derived document and is not an authority.

`VOIDA/00_SOURCE_INDEX.md` is the machine-searchable navigation index for the numbered forensic corpus.

## Canonical runtime boundaries
- `ComponentAuthority` = component runtime state/HP/damage/repair/destruction.
- `StructuralAuthority` = attach/detach/replace/sever graph mutation.
- `ShipRegistry` = authoritative player <-> ship lifecycle relationship.
- `ShipSocketGraph` = hardpoint/socket topology solver.
- `RigidBody2D` / Roblox Assembly = physical projection subject to recovered source behavior.
- `TeamIdentity` = Yellow/Blue team vocabulary.
- `VoidHunterBuilderServer` = canonical blueprint persistence + blueprint construction.
- `BlueprintSerializer` / `BlueprintLoader` = primitive blueprint persistence and reconstruction boundary.
- `MissionService` = generic mission state-machine runtime.
- `MissionConditionService` = source-confirmed mission predicate evaluator.
- `MissionActionService` = source-confirmed mission action evaluator.
- `RemoteManifest` = canonical remote security/index contract.

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
- `ComponentAuthority.SetParent` now rejects self/cyclic parent relationships and keeps inverse child maps synchronized.
- `ComponentAuthority.Clear` now removes parent/inverse child linkage before deleting local state.
- `ShipSocketGraph` no longer invents generic four-way sockets for unknown component types.
- `ShipSocketGraph` requires explicit component definitions from `Components.Types` + `Components.Connections` before creating topology nodes or sockets.
- `ShipSocketGraph` records explicit `ParentNodeId`, `ParentSocketId`, and `ConnectedSocketId` metadata during canonical attachment.
- `ShipSocketGraph` uses explicit relationship metadata for runtime rebuild; legacy weld/proximity reconstruction is no longer used in `RebuildFromModel`.
- Build-time `FindBestSnap` proximity is retained as an intentional construction/editor operation and is not treated as runtime topology authority.
- `StructuralAuthority.ReplaceComponent` validates the replacement definition and preserved parent hardpoint before detaching the existing component, then attaches to that exact socket.
- `BodyRecomputeService` is the single post-mutation recompute boundary for rigid-body mass properties.
- `StructuralAuthority` rebuilds rigid-body mass points from canonical component mass precedence and recomputes body mass/COM/inertia/bounds after structural mutations.
- Blueprint persistence and construction are consolidated into `VoidHunterBuilderServer`; the old blueprint system is now a compatibility facade with no independent datastore/schema.
- `BlueprintSerializer` now uses Version 2 with explicit stable logical component IDs, separate from hardpoint/socket IDs.
- `BlueprintLoader` validates component definitions, references, root uniqueness, and dependency cycles before reconstruction and resolves parent references through blueprint IDs.
- Builder placement routes through `StructuralAuthority`; the old direct blueprint mutation/adjacency authority was removed.
- Shield identity/configuration now derives from explicit `ComponentType` + `Components.Types` definitions, with no shield-generator name scan.
- Capacitor configuration now derives from explicit component definition fields, with no Reactor/Capacitor/Battery name scan.
- PvP ship ownership now resolves through `ShipRegistry` rather than a private player->ship map.
- PvP component identity now requires explicit `ComponentType` metadata.
- PvP friendly/enemy decisions now use `TeamIdentity`.
- PvP repair now calls `ComponentAuthority.Repair`.
- PvP damage now calls `ComponentAuthority.ApplyDamage`.
- PvP non-core destruction now routes through `StructuralAuthority.DetachComponent`.
- PvP core destruction unregisters the ship from `ShipRegistry` before physical destruction.
- Spatial transient targeting remains query-based rather than workspace-descendant scanning.
- `RigidBody2D:GetWorldPointVelocity` provides rigid-body-consistent kinematic velocity at a component's local position.
- `RigidBody2D:CreateDetachedBody` seeds a newly independent body from source position, point velocity, rotation, angular velocity, restitution, and fixed-Y without inventing a detachment impulse.
- `StructuralAuthority.DetachComponent` projects the source rigid-body point velocity into the detached Roblox assembly instead of blindly copying the ship root velocity.
- `VoidHunterDebrisManager` requires explicit component identity and no longer randomly fabricates debris component types.
- Debris animation uses one scheduler wait per update and retains explicit component provenance.
- `MissionTypes` defines the source-confirmed mission condition/action/state contracts.
- `MissionConditionService` evaluates the seven source-confirmed predicates against canonical gameplay state.
- `MissionActionService` executes the seven source-confirmed actions and delegates team mutation to `TeamIdentity`.
- `MissionService` provides a generic tick-driven state transition host without inventing mode-specific timing.
- `VOIDA/MISSION_SYMBOL_INDEX.md` provides stable searchable anchors for the recovered mission symbols.
- `ReplicatedStorage/Remotes/RemoteManifest.luau` provides a canonical remote security/index contract.
- `BallisticsEngine` uses swept segment collision with nearest-hit selection rather than endpoint-only checks.
- Roblox projectile hit callbacks now act on the actual hit `BasePart` instead of selecting a random component.
- Mass-driver/plasma projectile paths are routed through `BallisticsEngine` while retaining existing Roblox visual behavior.
- Roblox API hygiene sweep found no indexed `BodyVelocity`, `wait(`, `delay(`, or `tick(` legacy usage.
- `NativeDebrisPhysics` preserves the recovered native debris-launch equation structure without inventing unresolved caller scale.
- Grapple lifecycle infrastructure exists as a Roblox-native state machine boundary; unresolved native constants/target-eligibility semantics remain isolated rather than guessed.
- `VOIDA/00_SOURCE_INDEX.md` now indexes the numbered VOIDA source/audit corpus and establishes its navigation/authority rules.

## Raw-source corrections from this pass
1. `wlb.java` directly initializes `hab.g` as 56 component-definition slots.
2. Only a subset of those slots are literal polygons in the decompiled initializer; many are generated from dependent chassis expressions. Those generated slots must not be replaced by guessed literals.
3. `wfb.java` derives health through `lw.a(..., u)`; the repository's simplified `sqrt(area) * z / 64` helper is not sufficient to call the exact transformation raw-verified.
4. `summary.txt` records CFR gaps in major methods. Those methods remain `RAW-GAP` until recovered from bytecode or a better decompilation.
5. Existing `ForensicDataModel` entries that were synthesized before the raw package was available must be treated as provisional unless they can be traced directly to raw source.
6. Raw `nbb` debris transfer behavior has now been directly recovered: the debris specialization receives native transient motion quantities from its source body and clears those source accumulators. The Roblox port mirrors the recovered inherited kinematic state through `RigidBody2D`.
7. The raw `ml.DA` debris path also applies a separate launch term after state inheritance. Its geometric/random structure is recovered; caller-specific scale remains isolated until the source context is fully mapped.
8. `nbb.e(false)` resolves to inherited `anb.s`, the native body-mass field.
9. Blueprint component identity is now explicitly persisted as `BlueprintComponent.Id`; hardpoint IDs remain separate fields and are never used as component identity.

## Remaining P0
1. **BLOCKED:** recover the exact source caller mapping for the `ml.DA` launch scalar `n2` in every destruction context. Do not map it to damage/HP/mass/force by inference.
2. Recover exact remaining `anb` physics equations/constants that are still not structurally available from the supplied decompilation before declaring full Roblox physics parity.
3. Complete raw per-mode `MissionBuilder` / `MissionControl` sequencing from recovered source data before replacing the Arena prototype as the runtime mode authority.
4. Replace any static data-table values whose provenance cannot be traced to the raw package with `RAW-GAP` / `INFERRED` status rather than leaving them marked `CODE_VERIFIED`.
5. Verify every live component definition whose `Components.Types` entry and `Components.Connections` entry diverge in connector counts before changing attachment semantics.
6. Prove all externally referenced compatibility facades have no remaining live callers, then delete `VoidHunterBlueprintSystem` and `VoidHunterSyncManager` rather than retaining unnecessary compatibility surface.
7. **PARTIAL:** `BlueprintLoader` validates and stages a complete dependency-ordered blueprint but still needs an atomic `StructuralAuthority` transaction/rollback primitive before it can truthfully claim full topology rollback on mid-commit failure.
8. **PARTIAL:** grapple constants and exact target-eligibility behavior are known by parameter name/state strings but not fully backed by recovered method bodies in the currently indexed raw corpus.

## Mission/network lookahead status
- Mission framework infrastructure: `IMPLEMENTED / PARTIAL`.
- Mission symbol indexing: `IMPLEMENTED`.
- Remote security manifest: `IMPLEMENTED / PARTIAL`.
- Exact original game-mode state machines: `RAW-GAP / PARTIAL`.
- Full remote penetration/Studio runtime acceptance: `NOT VERIFIED`.

## Source-truth discipline
The raw package is evidence. The implementation must preserve uncertainty where the decompilation is uncertain.

Do not promote implementation compatibility into `VERIFIED` without acceptance testing and source evidence.

## Efficiency protocol
When a path is blocked by incomplete source/tooling:
1. Record the exact blocker and evidence.
2. Mark the narrow question `BLOCKED`.
3. Do not invent a replacement value.
4. Continue to the next independent goal.
5. Return to the blocked item only when new evidence makes it tractable.

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
