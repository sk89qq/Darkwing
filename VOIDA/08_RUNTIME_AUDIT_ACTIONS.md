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

Status: **IMPLEMENTED — STATIC VERIFIED**.

### P0.2 — Authoritative hardpoints
- `ShipSocketGraph` consumes explicit `Components.Connections` and `MeshAttachmentPositions` hardpoint data.
- Unknown component definitions fail closed.
- Name-derived Front/Back/Hex socket-direction fallback was removed.
- Hardpoint direction is derived only from the supplied local hardpoint coordinate; zero-length hardpoints fail closed.
- Welds/proximity are not used as logical topology discovery.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

### P0.3 — Atomic structural replacement
- `StructuralAuthority.ReplaceComponent` validates the occupied parent hardpoint and replacement socket before destructive mutation.
- Replacement is committed to the same authoritative hardpoint before the old component is detached.
- Failure rolls back the touched instances and authoritative attributes.
- Logical graph mutation remains inside `StructuralAuthority`.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

### P0.4 — Native destruction/debris operator recovery
- Native `anb` accumulator transfer, `nbb.G` split-state transfer, and `ml.DA` randomized debris-launch structure are recovered and documented.
- Native launch constants `FULL_TURN_UNITS=8192`, `HALF_TURN_UNITS=4096`, `RANDOM_RANGE=200`, and `RANDOM_OFFSET=100` are mapped in `NativeDebrisPhysics`.
- Additional recovered destruction/launch scalar constants `256` and `32768` are recorded with their native operator scope.
- Exact fixed-point/unit conversion, complete call-site application of recovered scalars, debris persistence/cleanup semantics, and Roblox runtime parity remain open.

Status: **IMPLEMENTED — PARTIAL FORENSIC RECOVERY; ROBLOX RUNTIME PENDING**.

### P0.5 — Native `anb` mass/COM/inertia/update equations
- Original JAR bytecode directly verified `ge.c=4`, `tua.a=4`, `wf.e=12`, and `ou.r=8`.
- Native mass aggregation, mass-weighted COM accumulation, polygon-vertex inertia accumulation, point-force torque accumulation, and linear/angular accumulator integration are recovered and recorded in `VOIDA/27_NATIVE_ANB_EQUATIONS_RECOVERY.md`.
- Added `Shared/Physics/NativeAnbPhysics.luau` as an integer-domain equation layer; it intentionally performs no unverified native-to-Roblox unit conversion.
- Exact native-to-Roblox unit conversion and call-site mapping remain open.

Status: **IMPLEMENTED — RAW EQUATIONS RECOVERED; ROBLOX MAPPING PARTIAL**.

### P0.6 — Complete native game-variable authority
- `NativeGameplayConfig` remains the 235/235 source-resolved native vector.
- `NativeParameterResolver` remains the sole runtime source for native configuration values.
- `NativeWeaponRuntime` is wired into the live weapon controller for source-confirmed weapon timing/energy contracts.
- `PhysicsConfig` no longer contains Roblox-unit tuning/mapping; native source values are isolated from later execution adapters.

Status: **IMPLEMENTED — 235/235 STATIC AUTHORITY; SOURCE-CONFIRMED WEAPON TIMING/ENERGY WIRED; ROBLOX RUNTIME PENDING**.

### P0.7 — Native mission input authority
- Added `Shared/Missions/NativeMissionConfig.luau` as the mission/global-input adapter over `NativeParameterResolver`.
- `MissionService` exposes `GetNativeConfig` / `GetNativeConfigSnapshot` through this authority boundary.
- No per-mode sequencing is invented by this layer.

Status: **IMPLEMENTED — SOURCE-BACKED INPUT AUTHORITY; PER-MODE SEQUENCING STILL OPEN**.

### P0.8 — Native component slot ledger
- Reconciled the definitive component slot artifact into a complete **56/56 native slot ledger**.
- Every native ID `0..55` has an explicit initializer/reference classification.
- Added `VOIDA/36_NATIVE_WFB_SLOT_EXTRACTION.md` anchoring the 56-slot index space directly to the original `wlb` initializer bytecode.
- Direct, generated, and referenced-object entries remain distinguished; no generated geometry or native→Roblox identity was guessed.

Status: **IMPLEMENTED — RAW SLOT INDEXING VERIFIED; NATIVE→ROBLOX SEMANTIC RECONCILIATION PARTIAL**.

### P0.9 — Shield component authority cleanup
- `ShieldSystem` no longer reads component identity from arbitrary attributes directly.
- Shield component lookup now binds/reads through `ComponentAuthority`, whose contract requires an explicit `ComponentType` that resolves to a known `Components.Types` definition.
- No `Instance.Name` or name-pattern classification was introduced.
- Shield absorption/reboot numerical behavior remains explicitly marked inferred pending recovered native consumer tracing.

Status: **IMPLEMENTED — STATIC AUTHORITY CLEANUP; NATIVE NUMERICAL PARITY OPEN**.

## Remaining P0

1. Recover exact native-to-Roblox unit conversion and call-site mapping for `anb` physics before parity claims.
2. Recover and port exact per-mode MissionBuilder/MissionControl sequencing where raw source evidence is still incomplete.
3. Resolve native→Roblox semantic identity/geometry for component slots whose constructors/behaviors remain referenced or generated.
4. Recover exact native shield/power/repair numerical consumers and replace remaining inferred gameplay constants only when source-backed.

## Remaining P1

- Remove `_G` compatibility bridges as explicit ModuleScript wiring replaces them.
- Prefer `BallisticsEngine`/swept collision for projectile classes where source behavior supports it.
- Validate remote ownership, installation, finite numeric input, and legal state transitions.
- Audit lifecycle connection cleanup.
- Replace hot-loop `workspace:GetDescendants()` scans with indexed registries/spatial queries.
- Verify all DataStore schemas are primitive-only and versioned.
- Replace prototype tuning literals only after the corresponding native semantic mapping is source-backed.

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
