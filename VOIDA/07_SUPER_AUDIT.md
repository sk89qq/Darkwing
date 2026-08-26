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

Do not add subsystem-local authoritative copies.

## Resolved migrations
- `VoidHunterShipSpawner` no longer owns `partHealth` / `partMaxHealth`.
- Ship lookup no longer uses a private spawner map; it uses `ShipRegistry`.
- Ship spawning/lifecycle now uses `TeamIdentity` and `StructuralAuthority.BindShip`.
- The fabricated 40%-HP / 80%-HP clone-salvage path was removed from the spawner because it was not supported by the raw component-debris path.
- `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` is the standing implementation-style reference, subordinate to raw source semantics.

## Raw-source corrections from this pass
1. `wlb.java` directly initializes `hab.g` as 56 component-definition slots.
2. Only a subset of those slots are literal polygons in the decompiled initializer; many are generated from dependent chassis expressions. Those generated slots must not be replaced by guessed literals.
3. `wfb.java` derives health through `lw.a(..., u) * z`; the repository's simplified `sqrt(area) * z / 64` helper is not sufficient to call the exact transformation raw-verified.
4. `summary.txt` records CFR gaps in major methods. Those methods remain `RAW-GAP` until recovered from bytecode or a better decompilation.
5. Existing `ForensicDataModel` entries that were synthesized before the raw package was available must be treated as provisional unless they can be traced directly to raw source.

## Remaining P0
1. Remove the remaining `partHealth` / `partMaxHealth` compatibility surface from `VoidHunterWeaponController` after all callers are confirmed to use `ComponentAuthority` directly.
2. Remove generic four-way socket fallback from `ShipSocketGraph`; unknown component definitions must fail closed.
3. Make structural replacement atomic: validate candidate hardpoint/connection before mutating the existing structure.
4. Stop treating weld/proximity reconstruction as authoritative topology when explicit hardpoint metadata exists.
5. Consolidate blueprint persistence/build systems onto one authoritative implementation without inventing behavior.
6. Recover exact source detach force, momentum carry-over, debris persistence, and cleanup behavior before adding policy.
7. Recover exact `anb` physics equations/constants from raw source/bytecode before declaring Roblox physics parity.
8. Replace remaining name/type heuristics in shield, power, repair, and combat systems with authoritative component definitions/data.
9. Port `MissionCondition` / `MissionAction` framework rather than expanding Arena-specific logic.
10. Replace any static data-table values whose provenance cannot be traced to the raw package with `RAW-GAP` / `INFERRED` status rather than leaving them marked `CODE_VERIFIED`.

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
