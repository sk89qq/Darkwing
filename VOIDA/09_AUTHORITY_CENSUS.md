# VOIDA/09 — Authority Census

**Date:** 2026-08-26  
**Status:** IMPLEMENTED / STATIC CODE CENSUS  
**Scope:** repository-wide structural/combat/persistence/network authority tracing before gameplay changes.

## 0. Audit method and limits

The repository was inspected from the recursive `main` tree, then the authority-critical Luau modules were traced directly. The GitHub code-search endpoint returned no matches for several exact legacy terms (`partHealth`, `partMaxHealth`, `PairSocketsByProximity`, `destroyShip`), so search-index absence was **not** treated as proof of absence. Findings below come from direct file inspection and cross-module tracing.

No Roblox runtime/Studio acceptance run was available during this census. Therefore this document records **code findings**, not `VERIFIED` behavioral parity.

The existing engineering policy says code existence is not verification and that original source wins over inferred Roblox behavior. That rule remains controlling. [DOCUMENTATION_ONLY]

---

# 1. Executive result

## P0 — competing authorities found

### P0.1 Component HP authority is still duplicated

**Canonical intended authority:**
`ReplicatedStorage/Shared/Combat/ComponentAuthority.luau`

It owns `Health`, `MaxHealth`, `Destroyed`, `Critical`, parent/child state, and base color. [IMPLEMENTED]

**Conflicting legacy authority:**
`ServerScriptService/VoidHunterShipSpawner.luau`

It still declares:
- `activeShips`
- `partHealth`
- `partMaxHealth`

and `onShipDestroyed()` reads those tables and writes HP into dropped-part attributes. This is a real second HP authority, not merely a compatibility view. [ACTIVE / CONFLICTING]

The same file also contains the old `>40% HP -> clone -> random scatter -> 80% HP` salvage algorithm. This directly conflicts with the current forensic destruction path. [ACTIVE / LEGACY]

**Replacement:** migrate ShipSpawner death/drop lifecycle to `ComponentAuthority` + `StructuralAuthority` + recovered debris lifecycle, then delete its HP tables and old salvage algorithm.

---

### P0.2 `partHealth` / `partMaxHealth` compatibility views remain active in WeaponController

`ServerScriptService/VoidHunterWeaponController.luau` intentionally exposes `partHealth` and `partMaxHealth` as metatable views over `ComponentAuthority`. They no longer store independent values, so they are **COMPATIBILITY**, not a second storage authority. [COMPATIBILITY]

However the directive explicitly requires all callers to migrate and then delete these views. They currently preserve legacy API surface and hide remaining coupling. [LEGACY-PENDING]

**Replacement order:** enumerate callers -> replace reads/writes with `ComponentAuthority.Get/SetHealth/ApplyDamage/Repair` -> re-search -> delete compatibility tables.

---

### P0.3 StructuralAuthority is declared canonical, but ShipSocketGraph rebuilds topology from Roblox welds/proximity

`StructuralAuthority` is documented as the structural mutation boundary, but `BuildGraph()` constructs a **new** `ShipSocketGraph` every call.

`ShipSocketGraph.RebuildFromModel()` then:
1. scans the Model with `GetDescendants()`;
2. creates nodes from Instances;
3. resolves `WeldConstraint`s;
4. calls `PairSocketsByProximity()` to infer graph edges.

This means Roblox physical topology remains an input to the logical graph. That is the opposite of the stated architecture where the logical graph is canonical and welds are projections. [ACTIVE / CONFLICTING]

**Replacement:** persistent logical graph registry per ship. Physical weld creation/removal becomes a projection of committed graph mutations. `PairSocketsByProximity()` becomes migration/import tooling only.

---

### P0.4 Generic socket fallback can invent topology

`ShipSocketGraph.ExtractComponentSockets()` creates a generic four-way socket set whenever `Components.Connections[compTypeName]` is missing.

The repository directive explicitly says unknown component definitions must fail closed and must not invent topology. The current fallback can create connections the recovered component definition does not permit. [ACTIVE / CONFLICTING]

**Replacement:** if a component definition is absent, return no sockets and fail the operation with `[UNKNOWN]`; retain generic fallback only in an explicitly named migration/import path.

---

### P0.5 StructuralAuthority.ReplaceComponent is not atomic

Current sequence:
1. build graph;
2. locate old node;
3. `DetachComponent(oldPart)`;
4. attempt `AttachComponent(newPart)`;
5. on failure, reparent only the detached root/oldRoot and restore its CFrame.

Failure recovery does **not** reconstruct the original subtree, parent socket occupancy, graph edges, welds, or all attributes. The source directive requires validate replacement first, then commit removal only after replacement is known valid. [ACTIVE / P0]

**Replacement:** solve/validate new placement against the old hardpoint first; only then commit graph mutation; perform a single graph transaction with rollback-safe state.

---

# 2. Legacy paths

## L2.1 ShipSpawner legacy destruction path

`ServerScriptService/VoidHunterShipSpawner.luau` contains:
- independent HP dictionaries;
- Red/Blue team spawn vocabulary inconsistent with canonical Yellow/Blue;
- direct `WeldConstraint` creation for preset ship assembly;
- old clone/scatter salvage;
- direct ship destruction.

Status: **LEGACY / CONFLICTING**.

Do not delete until callers are migrated.

## L2.2 VoidHunterBlueprintSystem duplicate blueprint authority

`ServerScriptService/VoidHunterBlueprintSystem.luau` maintains a separate `playerBlueprints` DataStore and schema using `Vector3` serialization and `components/type/offset/rotation`.

`ServerScriptService/VoidHunterBuilderServer.luau` simultaneously implements V2 primitive-only blueprints in `VHBlueprints`, including migration from older `parts` and `Components` layouts.

Status: **CONFLICTING PERSISTENCE AUTHORITIES**.

Replacement: choose the V2 `BuilderServer` schema as canonical, migrate required legacy data, then remove the duplicate BlueprintSystem persistence path.

## L2.3 VoidHunterSyncManager legacy blueprint/spawn path

`VoidHunterSyncManager.luau` owns another DataStore (`VoidHunters_ShipBlueprints_v1`) with `Components = { Type, Pos, Rot }`, and `SpawnPlayerShip()` delegates into `BuilderServer.BuildShipFromBlueprint()` only after maintaining this separate session schema.

Status: **LEGACY / MIGRATION BRIDGE**.

Replacement: make one versioned blueprint service own load/save/migration and make SyncManager consume it rather than maintaining another schema.

## L2.4 VoidHunterBuilderManager legacy build authority

`VoidHunterBuilderManager.luau` validates placement by raw `Pos` adjacency and then mutates `blueprint.Components` directly before respawning the ship.

This bypasses `StructuralAuthority` and does not validate recovered hardpoints. [ACTIVE / CONFLICTING]

Replacement: route placement through `StructuralAuthority.AttachComponent()` and commit the logical graph only after socket validation.

## L2.5 Direct weld construction

`VoidHunterShipSpawner.luau` directly creates `WeldConstraint`s for preset components and for player-to-seat attachment.

`ShipSocketGraph` also constructs/resolves weld topology.

Status: **MULTIPLE PHYSICAL ASSEMBLY WRITERS**.

Player-seat welds may remain presentation/vehicle infrastructure if they are not structural component welds; component structural welds must converge on the structural projection layer.

---

# 3. Damage and hit-resolution problems

## P0.6 Actual impacted component is not guaranteed to be geometry-resolved

`VoidHunterWeaponController` accepts a `BasePart` hit and passes it directly to `ComponentAuthority.ApplyDamage()` after basic validation.

The projectile path uses Roblox `Touched` and the hit Instance itself. There is no demonstrated polygon/geometry-to-component resolution step matching the original component polygon geometry.

Status: **ACTIVE / NOT VERIFIED**.

Required path:

`projectile collision -> world hit position -> actual component geometry -> ComponentAuthority.ApplyDamage()`

Do not use random component selection or name-based substitution.

## P0.7 `Touched` projectile path uses deprecated/legacy physics style

Mass-driver projectile creation uses `BodyVelocity` and `Touched`.

The repository already contains `BallisticsEngine`, so high-speed projectile paths should be reconciled with the existing swept/raycast-capable solver where that reproduces the original behavior. [INFERRED until source comparison]

---

# 4. Private subsystem state that competes with canonical state

`VoidHunterPvPSystems.luau` maintains private dictionaries for:
- player stats;
- player -> ship;
- ship invulnerability;
- booster state;
- repair mode;
- self destruct;
- grapples;
- shield cooldown;
- recent damage;
- fighter bays;
- thruster trails.

Not all of these are inherently duplicate authorities. The P0 concern is where they duplicate canonical gameplay state.

### Confirmed conflicts

- PvP component type resolution uses `definition.Name` / `part.Name` rather than the authoritative component identity path.
- Repair mode checks `part.Name == "Reactor"` rather than `ComponentDefinition -> ComponentBehaviour`.
- Booster detection similarly uses component type/name scans.
- Self-destruct writes `PendingDamage` attributes instead of directly entering the canonical damage pipeline.
- PvP records damage through `_G.VoidHunterMatchManager`, creating an implicit global service dependency.

Status: **ACTIVE / LEGACY COUPLING**.

---

# 5. Security findings

## S1 — Blueprint remote lacks complete validation

`VoidHunterBlueprintSystem` accepts `slotName` and `ship` from the client and calls `saveBlueprint()` without the ownership validation present in the newer BuilderServer.

The client can therefore submit an arbitrary server-visible Model reference to the save path if it can obtain a valid Instance reference.

Required validation:
- ship is a Model;
- `IsShip == true`;
- owner equals player;
- slot is valid/unlocked;
- component count/size limits;
- component types are known;
- transforms are finite and bounded.

## S2 — BuilderServer ownership check is incomplete for unowned ships

The check is `if ownerId and ownerId ~= player.UserId then return end`.

A ship with no `OwnerId` passes. Production authority should require an owner, not merely reject mismatches.

## S3 — Ship selection trusts arbitrary client ship name

`VoidHunterShipSpawner` accepts `shipName` and forwards it to `onShipSelected()`. The function does check against the preset table, which prevents arbitrary code execution, but it still needs state/rate/ownership/lifecycle validation and should be consolidated with the canonical ship spawn service.

## S4 — Remote/debug code executor is a security boundary

`SuperbulletServerLogger/ClientQueryRouter.luau` accepts a `code` payload and invokes a client RemoteFunction with that code. This is an explicit debug execution facility, not normal gameplay networking.

It must be disabled or isolated from production gameplay/remotes before release. [ACTIVE DEBUG TOOL]

## S5 — Match leaderboard RemoteFunction has no explicit caller validation

`VoidHunterMatchManager` returns the full leaderboard to any caller. This may be acceptable for public match UI, but it must be explicitly classified as public state rather than treated as a privileged RPC.

---

# 6. Lifecycle leaks / stale state

## LIFECYCLE-1

`ComponentAuthority` uses weak-keyed component state, which is good for garbage collection, but detached subtree cleanup only explicitly clears the root component in the WeaponController destruction path. Detached children remain in the authority table until garbage collection of their BaseParts/state references. This should be made explicit when a subtree leaves the ship graph.

## LIFECYCLE-2

`VoidHunterPvPSystems` owns multiple ship-keyed tables but does not demonstrate one centralized `ShipDestroyed` cleanup path for all dictionaries. Ship destruction can therefore leave stale state until the table key is naturally discarded.

Required: one `ShipLifecycleService` or destruction callback that clears all subsystem registrations.

## LIFECYCLE-3

`VoidHunterShipSpawner` and `VoidHunterSyncManager` can both spawn/manage ships. This creates possible duplicate active ship lifecycle state.

Required: one canonical ship registry and one spawn/despawn service.

---

# 7. Serialization problems

## SERIAL-1 — Duplicate blueprint schemas

Confirmed schemas:

1. `BuilderServer` V2: primitive position/orientation + topology IDs.
2. `VoidHunterBlueprintSystem`: `Vector3`-derived serialized components.
3. `VoidHunterSyncManager`: legacy `Components` with Vector3/Rot fields.

Only one should survive production.

## SERIAL-2 — Blueprint transform is still transform-first rather than topology-first

V2 is primitive-safe, but `BuilderServer.BuildShipFromBlueprint()` creates all parts at stored transforms and then calls `StructuralAuthority.BindShip()`.

This means stored transforms can still reconstruct physical placement before a topology solver commits the graph. The target schema should store component identity + parent identity + hardpoint identity + angle/position in canonical graph coordinates, then reconstruct Roblox CFrame through the structural solver.

## SERIAL-3 — Component IDs / Node IDs are persisted as runtime identities

V2 persists `NodeId`, `ComponentId`, `ParentNodeId`, and `ParentSocketId`. These are useful if treated as stable blueprint graph identifiers, but runtime-generated IDs must not be assumed stable across reload unless the schema explicitly defines them as persistent logical IDs.

---

# 8. Performance findings

## PERF-1

`VoidHunterWeaponController.findNearestEnemy()` scans `workspace:GetDescendants()`.

`VoidHunterPvPSystems.findNearestEnemy()` does the same.

These are unsuitable for repeated targeting loops at scale.

Replacement: server ship registry + spatial query/index.

## PERF-2

`ComponentAuthority.BindShip()` scans every descendant of the ship.

`ShipSocketGraph.RebuildFromModel()` scans every descendant and then resolves welds.

Because `StructuralAuthority.BuildGraph()` calls `ShipSocketGraph.new(ship)` repeatedly, structural operations can repeatedly rebuild the entire logical graph.

Replacement: persistent graph index and incremental mutations.

## PERF-3

The current graph BFS uses a head index, which is correct and should be retained. Do not regress to `table.remove(queue, 1)`.

## PERF-4

Multiple subsystem loops use `GetDescendants()` repeatedly for component detection. Replace hot-path scans with component registries/tags once behavior is preserved.

---

# 9. Roblox API / translation findings

## API-1 — BodyVelocity

WeaponController creates `BodyVelocity` for projectiles. Review against `AssemblyLinearVelocity`, `LinearVelocity`, or raycast/swept projectile logic depending on required observable behavior.

This is a translation decision, not automatically a bug. Label the final choice `[INFERRED]` until compared with original projectile behavior.

## API-2 — WeldConstraint projection direction is currently violated

StructuralAuthority intends to own structural mutations, but ShipSpawner and the graph itself still manipulate WeldConstraints as authority/reconstruction mechanisms.

Final architecture must be:

`logical graph commit -> physical weld/assembly projection`

not

`physical weld -> infer logical graph`.

## API-3 — Direct CFrame writes during build

BuilderServer moves debris directly to a target CFrame before calling `AttachComponent`. This is acceptable as a temporary preview/import step only if the final solver recomputes and validates placement. It must not become an alternate placement authority.

---

# 10. Forensic provenance errors

## PROV-1 — Existing documentation overstates StructuralAuthority completion

`VOIDA/08_RUNTIME_AUDIT_ACTIONS.md` calls the structural authority path completed and says replacement has an explicit failure/recovery path. Code inspection shows replacement is not atomic and graph state is rebuilt from physical welds/proximity. Therefore the documentation is ahead of the implementation.

Status should remain **IMPLEMENTED / PARTIAL**, not VERIFIED.

## PROV-2 — Generic `UNIT = 7` is treated as settled in code

`Components.UNIT = 7`, `WeaponController.UNIT = 7`, `PvPSystems.UNIT = 7`, and component attachment offsets use a 7-stud grid. The handoff explicitly says 1 original unit = 7 studs must not be treated as forensic fact without proof.

Until source/resource conversion is documented, label the Roblox conversion `[INFERRED]` even if 7 is useful operationally.

## PROV-3 — PhysicsConfig labels Roblox-derived quantities as CODE_VERIFIED

`PhysicsConfig` labels several values `[CODE_VERIFIED]` while also expressing Roblox-world quantities such as world bounds in studs and a fixed Roblox Y elevation. Original source verification and Roblox translation should be separated into source value + translation value + rationale.

## PROV-4 — Shield and capacitor modules are correctly cautious

`ShieldSystem` and `CapacitorSystem` explicitly mark prototype values `[INFERRED]`. This is the correct provenance pattern and should be copied elsewhere.

## PROV-5 — Existing documentation says the old 40%/80% salvage path was removed, but ShipSpawner still contains it

This is a direct documentation/code contradiction. ShipSpawner must be treated as an active legacy path until callers are migrated and the code is deleted.

---

# 11. Dead / unused / compatibility paths

The following are candidates for dead/compatibility status but require caller enumeration before deletion:

- `VoidHunterWeaponController.partHealth` / `partMaxHealth` compatibility views.
- `VoidHunterBlueprintSystem` if all clients migrate to BuilderServer V2.
- `VoidHunterSyncManager` legacy `Components` schema after migration.
- `VoidHunterBuilderManager` raw blueprint placement after StructuralAuthority migration.
- `VoidHunterShipSpawner` preset assembly/death path after canonical ShipService migration.
- `ReplicatedStorage/VoidHunters/ShipSocketGraph.luau` appears to be a tiny compatibility wrapper alongside `ReplicatedStorage/Shared/ShipSocketGraph.luau`; caller inventory is required before removal.
- `_G.VoidHunterMatchManager` after explicit ModuleScript dependency injection.

No file above should be deleted merely because it looks old.

---

# 12. Exact replacement / deletion order

## P0-A — Establish one ship registry/lifecycle

1. Create canonical `ShipRegistry` / `ShipLifecycleService`.
2. Register every spawned ship once.
3. Route spawn/despawn/death through it.
4. Give it a deterministic `ShipId` and required `OwnerId`.
5. Add centralized cleanup hooks for ComponentAuthority, combat state, shields, capacitors, grapples, effects and projectiles.
6. Migrate ShipSpawner and SyncManager callers.
7. Test duplicate spawn, death, player leave, and respawn.

## P0-B — Establish persistent logical graph

1. Create one graph instance per live ship.
2. Stop rebuilding graph from WeldConstraints during normal runtime.
3. Load recovered component hardpoints into the graph.
4. Make attach/detach/replace mutate the graph first.
5. Commit graph transaction.
6. Project welds/assemblies from committed graph.
7. Keep `PairSocketsByProximity()` only as import/migration tooling.

## P0-C — Remove generic socket fallback

1. Enumerate every component type used by production.
2. Verify each against recovered `Components.Connections` / hardpoint data.
3. Add explicit UNKNOWN failure for missing definitions.
4. Delete runtime generic four-way fallback.
5. Acceptance test invalid component cannot create an invented connection.

## P0-D — Make replacement atomic

1. Capture old graph edge, parent socket, child subtree, transforms and weld projection state.
2. Validate new component type and hardpoint candidate first.
3. Solve new placement without mutating committed graph.
4. Validate collisions/topology.
5. Commit graph replacement.
6. Recompute body/COM/inertia.
7. Project new physical assembly.
8. If any commit/projection step fails, restore the captured graph and projection state.
9. Only after success convert the old component to replacement debris/lifecycle.

## P0-E — Eliminate legacy HP authority

1. Inventory all reads/writes of `partHealth`, `partMaxHealth`, `PartHP`, `MaxHP`.
2. Migrate each caller to ComponentAuthority.
3. Migrate ShipSpawner death/drop behavior.
4. Delete ShipSpawner HP tables.
5. Delete WeaponController compatibility views.
6. Search again.
7. Acceptance test damage, repair, destruction, detach, reload.

## P0-F — Canonicalize blueprint persistence

1. Select BuilderServer V2 as canonical.
2. Add explicit schema version and graph-coordinate semantics.
3. Migrate `VoidHunterBlueprintSystem` data.
4. Migrate `VoidHunterSyncManager` data.
5. Stop writing legacy stores.
6. Make BuilderManager consume canonical graph APIs.
7. Delete duplicate blueprint persistence modules after migration tests.

## P0-G — Actual component hit resolution

1. Recover original polygon/hit-test semantics.
2. Build component geometry index.
3. Convert projectile world hit to the logical component.
4. Pass only resolved component identity into ComponentAuthority.
5. Replace random/name fallback.
6. Acceptance test boundary hits, overlapping geometry, detached debris, and multi-component ships.

## P1-H — Network contract consolidation

1. Build one Remote manifest from actual live remotes.
2. Record sender/receiver/payload/permission/rate limit/handler.
3. Require owned ship and installed component for combat/build actions.
4. Reject missing OwnerId instead of accepting it.
5. Validate finite numeric vectors/scalars and bounded ranges.
6. Isolate or remove Superbullet debug execution from production.
7. Migrate `_G` dependencies to explicit ModuleScript references.

## P1-I — Physics reconciliation

1. Audit every constant against actual source class/method.
2. Separate original source units from Roblox translation units.
3. Document scale conversion.
4. Verify mass/COM/inertia recomputation after every graph mutation.
5. Review `BodyVelocity` projectile paths against BallisticsEngine/native raycast alternatives.
6. Only then upgrade parity status.

## P1-J — Shield/power reconciliation

1. Recover exact shield config consumers.
2. Replace name-based Reactor/Capacitor/Battery heuristics.
3. Map `ComponentDefinition -> ComponentBehaviour/PowerBehaviour`.
4. Implement directional shield arc/radius/energy/damage conversion from source.
5. Remove inferred fallback values after migration.

## P2-K — Mission framework

1. Extract MissionCondition/MissionAction definitions.
2. Build generic MissionService.
3. Port mission modes.
4. Remove Arena-specific assumptions from the canonical gameplay path.

---

# 13. Acceptance tests required before VERIFIED

### Authority
- One component has exactly one canonical HP state.
- One ship has exactly one canonical graph.
- Weld changes alone cannot alter logical topology.
- Unknown component cannot invent sockets.

### Damage
- Projectile hit resolves to the correct component.
- HP reaches zero exactly once.
- Destroyed component detaches the correct subtree.
- Detached subtree retains physical state and inherited velocity according to recovered source behavior.

### Replacement
- Valid replacement preserves parent hardpoint and graph topology.
- Invalid replacement leaves the original ship unchanged.
- Replacement failure cannot orphan a subtree.

### Persistence
- Save/load produces the same logical graph.
- No runtime Instance/CFrame userdata is persisted.
- Legacy schemas migrate once into V2 and stop being written.

### Network
- Client cannot damage arbitrary Instance.
- Client cannot operate another player's ship.
- Client cannot claim an unowned ship.
- Client cannot exceed rate limits.
- Debug execution is unavailable to ordinary production clients.

### Performance
- No repeated full-workspace scan in hot targeting loops.
- No full graph rebuild on every structural operation.
- No per-frame allocation-heavy path for stable ship state.

---

# 14. Current status matrix

| Area | Status | Main blocker |
|---|---|---|
| Component HP authority | IMPLEMENTED / PARTIAL | ShipSpawner + legacy compatibility callers |
| Structural authority | IMPLEMENTED / PARTIAL | graph rebuilt from weld/proximity |
| Socket fidelity | BLOCKED / PARTIAL | generic fallback still active |
| Replacement | BLOCKED | not atomic |
| Debris lifecycle | PARTIAL | duplicate legacy drop path; exact source cleanup unresolved |
| Blueprint persistence | CONFLICTING | multiple stores/schemas |
| Hit resolution | BLOCKED | actual component geometry resolution not demonstrated |
| Shield | IMPLEMENTED / INFERRED | exact source behavior |
| Power | IMPLEMENTED / INFERRED | exact source behavior |
| Physics | IMPLEMENTED / PARTIAL | source-to-Roblox unit/formula audit |
| Network | IMPLEMENTED / UNSAFE-PARTIAL | remote contract consolidation |
| Mission framework | BLOCKED | original mission system not yet ported |
| Provenance | PARTIAL | documentation currently overstates some implementation states |

---

# 15. Source files directly traced for this census

- `AGENTS.md`
- `VOIDA/03_NETWORK_RPC_MANIFEST.md`
- `VOIDA/04_DIRECTIVES_AND_CHANGELOG.md`
- `VOIDA/08_RUNTIME_AUDIT_ACTIONS.md`
- `src/roblox/ReplicatedStorage/VoidHunterComponents.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/ComponentAuthority.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/ShieldSystem.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/CapacitorSystem.luau`
- `src/roblox/ReplicatedStorage/Shared/Physics/PhysicsConfig.luau`
- `src/roblox/ReplicatedStorage/Shared/Ship/StructuralAuthority.luau`
- `src/roblox/ReplicatedStorage/Shared/ShipSocketGraph.luau`
- `src/roblox/ServerScriptService/VoidHunterWeaponController.luau`
- `src/roblox/ServerScriptService/VoidHunterPvPSystems.luau`
- `src/roblox/ServerScriptService/VoidHunterBuilderServer.luau`
- `src/roblox/ServerScriptService/VoidHunterBlueprintSystem.luau`
- `src/roblox/ServerScriptService/VoidHunters/VoidHunterSyncManager.luau`
- `src/roblox/ServerScriptService/VoidHunters/VoidHunterBuilderManager.luau`
- `src/roblox/ServerScriptService/VoidHunters/VoidHunterDebrisManager.luau`
- `src/roblox/ServerScriptService/VoidHunterMatchManager.luau`
- `src/roblox/ServerScriptService/VoidHunterShipSpawner.luau`
- `src/roblox/ServerScriptService/SuperbulletServerLogger/ClientQueryRouter.luau`

---

# 16. Rule for the next agent

Do not add gameplay until P0-A through P0-G are resolved or explicitly blocked by missing original-source evidence.

The next agent must:

**READ → APPLY → TEST**

not:

**READ → REDISCOVER → DEBATE → REIMPLEMENT**.

Every resolved question gets recorded once with:

`SOURCE → OLD → NEW → TEST → STATUS`

**END OF CENSUS**
