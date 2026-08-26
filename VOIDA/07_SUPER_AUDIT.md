# VOIDA SUPER AUDIT — 2026-08-26

## Authority
The authoritative first-pass forensic contract is `VOIDA/00_FORENSIC_ENGINEER_BLUEPRINT.md` and its supplied source artifact. Do not use a duplicate blueprint as a competing source.

## Canonical runtime boundaries
- `ComponentAuthority` = component runtime state/HP/damage/repair/destruction.
- `StructuralAuthority` = attach/detach/replace/sever graph mutation.
- `ShipRegistry` = authoritative player <-> ship lifecycle relationship.
- `ShipSocketGraph` = authoritative hardpoint/socket topology solver.
- `RigidBody2D` / Roblox Assembly = physical projection subject to recovered source behavior.
- `TeamIdentity` = Yellow/Blue team vocabulary.

Do not add subsystem-local authoritative copies.

## Resolved migrations
- `VoidHunterShipSpawner` no longer owns `partHealth` / `partMaxHealth`.
- Ship lookup no longer uses a private spawner map; it uses `ShipRegistry`.
- Ship spawning/lifecycle now uses `TeamIdentity` and `StructuralAuthority.BindShip`.
- The old fabricated 40%-HP / 80%-HP clone-salvage path was removed from the spawner.
- A Roblox/Luau implementation reference exists at `VOIDA/10_ROBLOX_LUAU_REFERENCE.md`.

## Remaining P0
1. Remove the remaining `partHealth` / `partMaxHealth` compatibility surface from `VoidHunterWeaponController` after all callers are confirmed to use `ComponentAuthority` directly.
2. Remove generic four-way socket fallback from `ShipSocketGraph`; unknown component definitions must fail closed.
3. Make structural replacement atomic: validate candidate hardpoint/connection before mutating the existing structure.
4. Stop treating weld/proximity reconstruction as authoritative topology when explicit hardpoint metadata exists.
5. Consolidate blueprint persistence/build systems onto one authoritative implementation without inventing behavior.
6. Recover exact source detach force, momentum carry-over, debris persistence, and cleanup behavior before adding policy.
7. Recover exact `anb` physics equations/constants from source/bytecode before declaring Roblox physics parity.
8. Replace remaining name/type heuristics in shield, power, repair, and combat systems with authoritative component definitions/data.
9. Port `MissionCondition` / `MissionAction` framework rather than expanding Arena-specific logic.

## Source-truth discipline
The first-pass blueprint explicitly forbids guessing missing data. Existing implementation values tagged `[INFERRED]` must remain inferred until recovered evidence supports them.

Do not promote implementation compatibility into `VERIFIED` without acceptance testing and source evidence.

## Efficiency protocol
Before changing a mechanic:
1. Read `VOIDA/00_FORENSIC_ENGINEER_BLUEPRINT.md`.
2. Read the relevant AGENTS directive/reference.
3. Search the repository for existing authoritative implementation.
4. Replace deprecated callers rather than creating a parallel system.
5. Use repository-wide replacement for purely lexical deprecated symbols when the replacement is unambiguous.
6. Re-scan affected code and update status documentation.

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
