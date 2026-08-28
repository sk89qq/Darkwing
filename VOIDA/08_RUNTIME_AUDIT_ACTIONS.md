# VOIDA Runtime Audit Actions — 2026-08-28

## Authoritative source
- Raw supplied archive: `/VOIDA/voidhunters_decompiled_raw.zip` in Library.
- Repository manifest: `VOIDA/00_RAW_FORENSIC_REFERENCE.md`.
- Raw source takes precedence over synthesized blueprints and inferred implementation values.

## Completed

### Structural authority
- `ComponentAuthority` = canonical component runtime state.
- `StructuralAuthority` = canonical structural mutation boundary.
- `ShipRegistry` = canonical player/ship lifecycle relationship.
- Detached subtrees remain live physical assemblies unless recovered source behavior says otherwise.

### Ship lifecycle
- `VoidHunterShipSpawner` no longer owns legacy `partHealth` / `partMaxHealth` maps.
- Ship lifecycle uses `ShipRegistry` and `TeamIdentity`.
- Old fabricated clone/scatter salvage logic was removed from the spawner.

### Blueprint persistence
- Blueprint V2 uses primitive-only DataStore payloads.
- AutoBuild routes attachment through `StructuralAuthority`.
- Legacy `Components` input remains a migration input only; new saves use V2.

### P0.1 — Component HP authority
- Combat/PvP/repair callers use `ComponentAuthority` rather than subsystem-local `partHealth` / `partMaxHealth` state.
- Static caller audit found no remaining live compatibility HP maps in the migrated combat path.
- Runtime Studio verification remains separate.

Status: **IMPLEMENTED — STATIC VERIFIED**.

### P0.2 — Authoritative hardpoints
- `ShipSocketGraph` consumes explicit `Components.Connections` and `MeshAttachmentPositions` hardpoint data.
- Unknown component definitions fail closed.
- Name-derived Front/Back/Hex socket-direction fallback was removed.
- Hardpoint direction is derived only from the supplied local hardpoint coordinate; zero-length hardpoints fail closed.
- Welds/proximity are not used as logical topology discovery.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

### P0.3 — Atomic structural replacement
- `StructuralAuthority.ReplaceComponent` now validates the occupied parent hardpoint and replacement socket before destructive mutation.
- Replacement is committed to the same authoritative hardpoint before the old component is detached.
- Failure rolls back the touched instances and authoritative attributes rather than reconstructing the old state from a detached debris projection.
- Logical graph mutation remains inside `StructuralAuthority`.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

### P0.4 — Native destruction/debris operator recovery
- Native `anb` accumulator transfer, `nbb.G` split-state transfer, and `ml.DA` randomized debris-launch structure are recovered and documented.
- Native launch constants `FULL_TURN_UNITS=8192`, `HALF_TURN_UNITS=4096`, `RANDOM_RANGE=200`, and `RANDOM_OFFSET=100` are mapped in `NativeDebrisPhysics`.
- Additional recovered destruction/launch scalar constants `256` and `32768` are recorded with their native operator scope.
- Detached-body point-kinematic inheritance remains implemented through `RigidBody2D`.
- Exact fixed-point/unit conversion, complete call-site application of the recovered scalars, debris persistence/cleanup semantics, and Roblox runtime parity remain open.

Status: **IMPLEMENTED — PARTIAL FORENSIC RECOVERY; ROBLOX RUNTIME PENDING**.

### P0.5 — Native `anb` mass/COM/inertia/update equations
- Original JAR bytecode directly verified `ge.c=4`, `tua.a=4`, `wf.e=12`, and `ou.r=8`.
- Native mass aggregation, mass-weighted COM accumulation, polygon-vertex inertia accumulation, point-force torque accumulation, and linear/angular accumulator integration are recovered and recorded in `VOIDA/27_NATIVE_ANB_EQUATIONS_RECOVERY.md`.
- Added `Shared/Physics/NativeAnbPhysics.luau` as an integer-domain equation layer; it intentionally performs no unverified native-to-Roblox unit conversion.
- Exact semantic/unit conversion performed by `lw.a`, integration-divisor call-site meaning, surrounding `d(B)` update behavior, and Roblox runtime parity remain open.

Status: **IMPLEMENTED — RAW EQUATIONS RECOVERED; ROBLOX MAPPING PARTIAL**.

### P0.6 — Complete native game-variable authority
- Added `Shared/Combat/NativeGameplayConfig.luau` as the runtime projection of the complete **235/235** source-resolved native configuration vector.
- Restored the 18 keys that were absent from the intermediate 217-key runtime table: `USE_TRAILS`, `FIGHTER_VISION`, `TEAM_SELECTION_SPEEDUP`, `FULL_MISSION_SET`, `WAIT_FOR_PLAYERS`, `KEEP_TEAM_COLOURS`, `FOG_OF_WAR_ON`, `USE_MODELS`, `BOTS`, `AUTOAIM`, `SALVOAIM`, `FIXEDAIM`, `ANGLESET`, `PEDROS_REPAIR_MODE`, `SHIP_PERSISTENCE`, `CLIENT_SIDE_DRAGGING`, `MISSION_VOTES`, and `MUTATOR_VOTES`.
- `NativeParameterResolver` now loads the native table at module initialization, preserves source provenance, hard-fails missing lookups, exposes `Get`, `Has`, `GetAll`, and validates the expected 235-entry coverage.
- `NativeWeaponConfig` now resolves contract status against the authoritative native resolver instead of reporting all parameters as pending.
- Added `Shared/Combat/NativeWeaponRuntime.luau` as the explicit weapon consumer boundary. Native time values use the source-confirmed `oq.l = 50` conversion; unresolved damage/force/speed conversion remains intentionally isolated.
- No native value is silently replaced with a prototype/Roblox value by these modules.

Status: **IMPLEMENTED — 235/235 STATIC AUTHORITY; CONSUMER MIGRATION IN PROGRESS**.

## Remaining P0

1. Wire `NativeWeaponRuntime` into the live weapon controller for all source-confirmed weapon timing/energy consumers, replacing prototype `FireRate`/`Cooldown`/`PowerPerShot` fallbacks.
2. Replace remaining shield/power/repair type-name heuristics with authoritative component definitions and recovered source behavior.
3. Recover exact native-to-Roblox unit conversion and call-site mapping for `anb` physics before parity claims.
4. Port MissionCondition/MissionAction and the recovered per-mode MissionBuilder/MissionControl sequencing instead of expanding Arena-only orchestration.
5. Complete native 56-slot component reconciliation, retaining `RAW-GAP`/`INFERRED` status for generated slots without direct source evidence.

## Remaining P1

- Remove `_G` compatibility bridges as explicit ModuleScript wiring replaces them.
- Prefer `BallisticsEngine`/swept collision for projectile classes where source behavior supports it.
- Validate remote ownership, installation, finite numeric input, and legal state transitions.
- Audit lifecycle connection cleanup.
- Replace hot-loop `workspace:GetDescendants()` scans with indexed registries/spatial queries.
- Verify all DataStore schemas are primitive-only and versioned.
- Replace any prototype tuning literals only after the corresponding native semantic mapping is source-backed.

## Source-truth rule

Native source remains authoritative. `VERIFIED` requires an explicit acceptance test and source citation. `ROBLOX-MAPPING` and `INFERRED` values must not be promoted to source truth merely because they are compatible with the reference.

## Future-agent protocol

Read `VOIDA/00_RAW_FORENSIC_REFERENCE.md` first. Then inspect the smallest relevant raw class/method needed to close the delta. Work only on the highest unresolved item. Do not reopen a completed item unless new source evidence contradicts it.

For each fix:

```text
SOURCE:
OLD:
NEW:
TEST:
STATUS:
```

END
