# VOIDA Runtime Audit Actions — 2026-08-26

## Completed in this audit

### Structural authority
- `ComponentAuthority` is the logical component state boundary.
- `StructuralAuthority` is the structural mutation boundary.
- Detached subtrees remain live in `Workspace.VoidHunterDebris`.
- Graph traversal uses head-index BFS rather than repeated front deletion.
- Replacement has an explicit failure/recovery path rather than silent destruction.

### Blueprint persistence
- Blueprint payload is now V2 and DataStore-safe.
- CFrame is serialized into primitive position/orientation numbers.
- Loader accepts V2 plus older `parts`/`Components` layouts.
- Builder no longer directly persists userdata/CFrame values.
- AutoBuild routes final attachment through `StructuralAuthority`.

### Provenance
- Shield prototype values are explicitly `[INFERRED]`.
- Arena MatchState is explicitly prototype/partial parity.
- ForensicDataModel is treated as mixed recovered/derived data; do not trust file-level verification labels blindly.

### Team identity
- Arena prototype uses Yellow / Blue.
- Component category colors remain separate from team identity.

## Remaining P0 implementation work

1. Migrate ALL combat HP callers off legacy `partHealth` / `partMaxHealth` maps.
2. Replace type-name heuristics with `ComponentAuthority`/component definitions.
3. Replace generic socket fallback for production component types with authoritative hardpoint definitions.
4. Recover exact original replacement semantics and implement atomic same-hardpoint replacement.
5. Recover exact original detach impulse/force and debris cleanup/persistence before adding any cleanup policy.
6. Recover exact `anb` integration/mass/COM/inertia equations before calling custom Roblox physics parity verified.
7. Recover exact shield and energy behaviour consumers.
8. Port MissionCondition/MissionAction framework rather than expanding Arena-specific logic.

## Remaining P1 code-quality work

- Remove `_G` dependencies after explicit ModuleScript wiring exists.
- Replace high-speed projectile `Touched` paths with the existing swept ballistic solver where appropriate.
- Ensure all remote handlers validate ownership, installation state, finite numeric input and legal state transitions.
- Audit connection cleanup on Ship/Player/Projectile destruction.
- Replace repeated `workspace:GetDescendants()` scans in hot loops with indexed collections/spatial queries.
- Verify all DataStore schemas are primitive-only and versioned.

## Future-agent protocol

Read this file first when continuing runtime audit. Only work on the highest unresolved item.
Do not reopen a completed item unless new source evidence contradicts it.

For each fix, record:
SOURCE → OLD → NEW → TEST → STATUS

END
