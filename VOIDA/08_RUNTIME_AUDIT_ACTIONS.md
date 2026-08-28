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

## Remaining P0

1. Recover exact detach force, momentum carry-over, debris persistence, and cleanup semantics from native `anb` / `nbb` / `ml` behavior.
2. Recover exact `anb` mass/COM/inertia/update equations and native-to-Roblox unit conversion before parity claims.
3. Replace remaining shield/power/repair type-name heuristics with authoritative component definitions and recovered source behavior.
4. Port MissionCondition/MissionAction instead of expanding Arena-only orchestration.

## Remaining P1

- Remove `_G` compatibility bridges as explicit ModuleScript wiring replaces them.
- Prefer `BallisticsEngine`/swept collision for projectile classes where source behavior supports it.
- Validate remote ownership, installation, finite numeric input, and legal state transitions.
- Audit lifecycle connection cleanup.
- Replace hot-loop `workspace:GetDescendants()` scans with indexed registries/spatial queries.
- Verify all DataStore schemas are primitive-only and versioned.

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
