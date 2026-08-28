# VOIDA/09 — Authority Census

**Date:** 2026-08-28  
**Status:** IMPLEMENTED / STATIC CODE CENSUS  
**Scope:** repository-wide structural/combat/persistence/network authority tracing before gameplay changes.

## 0. Audit method and limits

The repository and the supplied project bundle were inspected from the authority-critical Luau modules and the preserved original-JAR bytecode dumps. GitHub code-search can report incomplete results, so search-index absence is never treated as proof of absence.

No Roblox Studio runtime/acceptance run is currently available. This document therefore records **code findings and migration state**, not final behavioral verification.

The raw `voidhunters` package remains the first-pass forensic authority. `ROBLOX-MAPPING` and `INFERRED` values must not be promoted to `VERIFIED` without source/runtime evidence.

---

# 1. Canonical runtime authorities

- `ComponentAuthority` = component runtime state, health, damage, repair, destruction markers.
- `StructuralAuthority` = attach/detach/replace/sever graph mutation.
- `ShipRegistry` = player <-> ship lifecycle relationship.
- `ShipSocketGraph` = explicit component/socket topology.
- `RigidBody2D` / `PhysicsWorld` = logical 2D physical state and integration.
- `TeamIdentity` = Yellow/Blue team vocabulary.
- `VoidHunterBuilderServer` = canonical blueprint persistence/construction.
- `VoidHunterDebrisManager` = designated debris presentation/collection layer; must consume destroyed-component identity rather than inventing random components.

Do not introduce subsystem-local authoritative copies of these domains.

---

# 2. Resolved migrations

- Ship spawner HP dictionaries were removed from the migrated live path; component health is owned by `ComponentAuthority`.
- Ship ownership lookup uses `ShipRegistry`.
- Ship spawning/lifecycle uses `TeamIdentity` and `StructuralAuthority`.
- Old fabricated 40%-HP / 80%-HP clone-scatter salvage was removed from the migrated spawner path.
- `VoidHunterWeaponController` no longer owns `partHealth` / `partMaxHealth` or `activeShips`.
- Combat component identity uses explicit `ComponentType` + `Components.Types`.
- Hull classification uses `IsHull` definition metadata.
- Enemy lookup uses `ShipRegistry.GetAll()` in migrated paths.
- `ComponentAuthority` fails closed when `ComponentType` is absent/invalid.
- `ShipSocketGraph` no longer invents generic socket positions or name-based socket normals.
- `ShipSocketGraph` requires authoritative component definitions and explicit graph relationships.
- `StructuralAuthority.ReplaceComponent` validates before destructive mutation and installs the replacement on the same authoritative hardpoint before detaching the old subtree; failure rolls back touched state.
- Blueprint construction/persistence is consolidated around `VoidHunterBuilderServer`.
- Shield identity/configuration is definition-driven.
- Capacitor configuration is definition-driven.
- PvP ownership/team/component identity is canonical.
- PvP repair/damage routes through canonical authorities.
- `RigidBody2D` contains COM/inertia/force/torque/impulse integration and detached-body kinematics helpers.
- `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` is the standing implementation-style reference, subordinate to raw source semantics.

---

# 3. Remaining P0 / source-recovery work

## P0.1 Component HP authority

The former compatibility HP maps have been removed from the migrated combat path. `ComponentAuthority` is the sole runtime component-health authority.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

## P0.2 Authoritative hardpoints

The socket solver now consumes explicit connection definitions and mesh attachment coordinates. Name-derived direction fallback was removed; unknown definitions and zero-length hardpoints fail closed.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

## P0.3 Atomic structural replacement

Replacement now validates the occupied parent hardpoint and replacement socket before destructive mutation, commits the replacement edge first, then detaches the old subtree. Touched instance state is snapshotted for rollback.

Status: **IMPLEMENTED — STATIC VERIFIED; ROBLOX RUNTIME PENDING**.

## P0.4 Exact native destruction operator

The raw reference identifies `anb.java` as the native physical body source and `nbb.java` as debris specialization. Targeted `javap` recovery now establishes exact `ge.c = 4` and `tua.a = 4` shifts used by `anb.KB`, while `wf.e = 12` is already preserved in the canonical physics inputs. Remaining fixed-point conversion and full destruction/launch semantics are still source-recovery work.

Status: **RAW-GAP / PARTIALLY RECOVERED**.

## P0.5 Exact physics constants/equations

Native operator inputs and several fixed-point shifts are now preserved in `PhysicsConfig`, but the complete `anb` integration/unit-conversion chain is not yet proven equivalent to the Roblox solver.

Status: **RAW-GAP / ROBLOX-MAPPING**.

## P0.6 Debris manager replacement

The current debris path still requires complete source-backed destroyed-component identity, native launch/persistence semantics, and canonical collection behavior.

Status: **ACTIVE / LEGACY**.

## P0.7 Component-to-geometry hit resolution

Projectile collision must resolve the actual impacted component from geometry before damage is applied. This remains unverified against the native polygon model.

Status: **ACTIVE / NOT VERIFIED**.

## P0.8 Mission framework

Port `MissionCondition` / `MissionAction` semantics rather than expanding Arena-specific logic.

Status: **ACTIVE**.

## P0.9 Provenance cleanup

Any static table or conversion value lacking raw traceability must be marked `RAW-GAP` or `INFERRED` rather than `CODE_VERIFIED`.

Status: **ACTIVE**.

## P0.10 Compatibility facades

`VoidHunterBlueprintSystem` and `VoidHunterSyncManager` remain superseded compatibility layers pending complete caller enumeration and safe deletion.

Status: **SUPERSEDED / PENDING DELETION**.

---

# 4. Important source facts

The raw reference confirms:

- `wlb.java` initializes `hab.g` with 56 component-definition slots.
- `wfb.java` computes geometry-derived health through `lw.a(..., u) * z`.
- `anb.java` stores physical body state including position, velocity, angle, angular velocity, center of mass, mass, moment of inertia, and root state.
- `nbb.java` specializes debris behavior.
- `summary.txt` reports CFR gaps in several major methods.
- Targeted bytecode confirms `ge.c = 4` and `tua.a = 4`.

Do not replace the native operator set with inferred Roblox approximations when the raw behavior is recoverable.

---

# 5. Roblox translation rules

- Use `game:GetService("ServiceName")` consistently.
- Prefer `task.wait`, `task.delay`, and `task.spawn` over legacy scheduler APIs.
- Use `os.clock()` for monotonic duration measurement.
- Do not use `BodyVelocity` merely because it is convenient; prefer the canonical physics layer or modern assembly APIs when they reproduce the required behavior.
- Keep logical topology authoritative; Roblox welds/assemblies are projections, not graph discovery inputs.
- Keep Instance Attributes as mirrors/diagnostics when canonical state exists in Lua authority modules.
- Preserve explicit `ComponentType`; never infer gameplay identity from `Instance.Name`.

---

# 6. Status vocabulary

- `EXTRACTED`
- `IMPLEMENTED`
- `VERIFIED`
- `BLOCKED`
- `SUPERSEDED`
- `RAW-GAP`
- `ROBLOX-MAPPING`
- `INFERRED`

---

## FUTURE AGENT NOTE:

The raw archive is the highest-priority evidence source. Read `VOIDA/00_RAW_FORENSIC_REFERENCE.md` before changing physics. `ComponentAuthority` owns component health/state, `StructuralAuthority` owns topology mutations, `ShipRegistry` owns ship lifecycle, and `RigidBody2D`/`PhysicsWorld` own logical physical state. Never restore private HP maps, player->ship maps, name-based component identity, random debris generation, or weld-driven logical topology. For source gaps, recover the native operator from bytecode/better decompilation rather than guessing constants.

END AUDIT
