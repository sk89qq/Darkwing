# VOIDA/09 — Authority Census

**Date:** 2026-08-26  
**Status:** IMPLEMENTED / STATIC CODE CENSUS  
**Scope:** repository-wide structural/combat/persistence/network authority tracing before gameplay changes.

## 0. Audit method and limits

The repository was inspected from the recursive `main` tree and the authority-critical Luau modules were traced directly. GitHub code-search can report incomplete results, so search-index absence is never treated as proof of absence.

No Roblox Studio runtime/acceptance run is currently available. This document therefore records **code findings and migration state**, not final behavioral verification.

The raw `voidhunters_decompiled` package remains the first-pass forensic authority. `ROBLOX-MAPPING` and `INFERRED` values must not be promoted to `VERIFIED` without source/runtime evidence.

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
- `ShipSocketGraph` no longer invents generic fallback sockets.
- `ShipSocketGraph` requires authoritative component definitions and explicit graph relationships.
- `StructuralAuthority.ReplaceComponent` validates before detach and restores the previous state on failed replacement.
- Blueprint construction/persistence is consolidated around `VoidHunterBuilderServer`.
- Shield identity/configuration is definition-driven.
- Capacitor configuration is definition-driven.
- PvP ownership/team/component identity is canonical.
- PvP repair/damage routes through canonical authorities.
- `RigidBody2D` contains COM/inertia/force/torque/impulse integration and detached-body kinematics helpers.
- `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` is the standing implementation-style reference, subordinate to raw source semantics.

---

# 3. Remaining P0 / source-recovery work

## P0.1 Exact native destruction operator

The raw reference identifies `anb.java` as the native physical body source and `nbb.java` as debris specialization. The supplied decompile still has CFR gaps in major physics methods.

Required before claiming source parity:
- recover exact detach/separation force;
- recover momentum/angular-velocity transfer semantics;
- recover debris lifetime/persistence/cleanup;
- recover exact collision/body removal sequence;
- compare multiple decompiler outputs or inspect bytecode where CFR remains unstructured.

Status: **RAW-GAP**.

## P0.2 Exact physics constants/equations

`RigidBody2D` is the canonical Roblox logical solver, but its constants remain a mixture of recovered values and Roblox mappings. Exact native `anb` equations/constants must be source-traced before final parity is claimed.

Status: **RAW-GAP / ROBLOX-MAPPING**.

## P0.3 Debris manager replacement

The current `VoidHunterDebrisManager` still contains legacy behavior that randomly chooses a component type and writes `ComponentName`. That is not compatible with forensic destruction semantics, where debris should correspond to the component actually detached/destroyed.

Required replacement:
- accept explicit destroyed component identity/state from `StructuralAuthority`/`ComponentAuthority`;
- preserve source-backed component type/metadata;
- use `task.*` timing correctly;
- route collection through canonical inventory/persistence;
- do not fabricate random component types.

Status: **ACTIVE / LEGACY**.

## P0.4 Component-to-geometry hit resolution

Projectile collision must resolve the actual impacted component from geometry before damage is applied. The existing Roblox collision surface is not yet proven equivalent to the native polygon model.

Required path:
`collision -> world hit -> component geometry -> ComponentAuthority.ApplyDamage()`.

Status: **ACTIVE / NOT VERIFIED**.

## P0.5 Mission framework

Port `MissionCondition` / `MissionAction` semantics rather than expanding Arena-specific logic.

Status: **ACTIVE**.

## P0.6 Provenance cleanup

Any static table or conversion value lacking raw traceability must be marked `RAW-GAP` or `INFERRED` rather than `CODE_VERIFIED`.

Status: **ACTIVE**.

## P0.7 Compatibility facades

`VoidHunterBlueprintSystem` and `VoidHunterSyncManager` are treated as superseded compatibility layers. Delete them only after complete caller enumeration proves there are no live production callers.

Status: **SUPERSEDED / PENDING DELETION**.

---

# 4. Important source facts

The raw reference confirms:

- `wlb.java` initializes `hab.g` with 56 component-definition slots.
- `wfb.java` computes geometry-derived health through `lw.a(..., u) * z`.
- `anb.java` stores physical body state including position, velocity, angle, angular velocity, center of mass, mass, moment of inertia, and root state.
- `nbb.java` specializes debris behavior.
- `summary.txt` reports CFR gaps in several major methods.

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
