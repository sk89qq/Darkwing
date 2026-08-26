# VOIDA Runtime Audit Actions — 2026-08-26

## Authority order
1. `VOIDA/00_FORENSIC_ENGINEER_BLUEPRINT.md` — authoritative first-pass forensic contract.
2. `AGENTS.md` — implementation and authority rules.
3. `VOIDA/09_AUTHORITY_CENSUS.md` — repository authority findings/deltas.
4. `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` — Roblox/Luau implementation reference.

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

### Provenance
- Inferred shield/capacitor values remain explicitly `[INFERRED]`.
- Arena remains prototype/partial parity.
- The authoritative first-pass blueprint forbids guessing unrecovered data.

## Remaining P0

1. Remove remaining `partHealth` / `partMaxHealth` compatibility access from combat after callers are migrated to `ComponentAuthority` directly.
2. Replace generic socket fallback with authoritative hardpoints; unknown definitions fail closed.
3. Make replacement atomic at the hardpoint/graph level.
4. Recover exact detach force, momentum carry-over, debris persistence, and cleanup semantics before inventing policy.
5. Recover exact `anb` mass/COM/inertia/update equations before parity claims.
6. Replace remaining shield/power/repair type-name heuristics with authoritative component definitions and recovered source behavior.
7. Port MissionCondition/MissionAction instead of expanding Arena-only orchestration.

## Remaining P1

- Remove `_G` compatibility bridges as explicit ModuleScript wiring replaces them.
- Prefer `BallisticsEngine`/swept collision for projectile classes where source behavior supports it.
- Validate remote ownership, installation, finite numeric input, and legal state transitions.
- Audit lifecycle connection cleanup.
- Replace hot-loop `workspace:GetDescendants()` scans with indexed registries/spatial queries.
- Verify all DataStore schemas are primitive-only and versioned.

## Future-agent protocol

Read `VOIDA/00_FORENSIC_ENGINEER_BLUEPRINT.md` first. Work only on the highest unresolved item. Do not reopen a completed item unless new source evidence contradicts it.

For each fix:

```text
SOURCE:
OLD:
NEW:
TEST:
STATUS:
```

END
