# VOIDA RAW RECONCILIATION — 2026-08-26

## Source

Authoritative source: supplied `/VOIDA/voidhunters_decompiled_raw.zip` in Library.
Manifest: `VOIDA/00_RAW_FORENSIC_REFERENCE.md`.

## Findings

### 1. Legacy ship HP authority
SOURCE: prior `VoidHunterShipSpawner`
OLD: private `partHealth` / `partMaxHealth` dictionaries and fabricated clone/scatter salvage.
NEW: `ComponentAuthority` + `StructuralAuthority` + `ShipRegistry`.
TEST: static source comparison completed; runtime acceptance still pending.
STATUS: IMPLEMENTED.

### 2. Team vocabulary
SOURCE: current port directive + recovered client target vocabulary.
OLD: Red/Blue team literals in the spawner.
NEW: `TeamIdentity.YELLOW` / `TeamIdentity.BLUE`.
TEST: spawner source re-read after migration.
STATUS: IMPLEMENTED.

### 3. Raw component definition authority
SOURCE: `wlb.java`.
OLD: synthesized static component table treated as universally source-exact.
NEW: raw `hab.g[56]` initializer is authoritative; literal polygons are direct evidence and generated/chassis-dependent definitions remain source expressions.
TEST: raw parser found direct literal slots `1,2,14,15,16,17,19,20,23,24,25,26,27,28,29,42,43,44,47`; remaining slots include generated expressions.
STATUS: EXTRACTED / PARTIAL.

### 4. Health derivation
SOURCE: `wfb.java`, `lw.java`, `eo.java`.
OLD: simplified `sqrt(area) * z / 64` treated as exact source formula.
NEW: preserve raw `wfb -> lw.a(..., u) * z` path; lookup-table/scaled integer behavior is the source reference.
TEST: raw class inspection confirmed `wfb` delegates health calculation to `lw.a` and `lw` uses `eo.o[]` branch-dependent integer scaling.
STATUS: EXTRACTED; exact Luau numeric parity remains BLOCKED on full lookup/control-flow reconstruction.

### 5. CFR gaps
SOURCE: raw `summary.txt`.
OLD: documentation sometimes treated reconstructed behavior as verified.
NEW: unresolved methods are `RAW-GAP` until bytecode or better decompilation resolves them.
TEST: summary re-read directly from supplied archive.
STATUS: IMPLEMENTED documentation rule.

### 6. Deprecated documentation
SOURCE: prior `VOIDA/05_FORENSIC_PORT_BLUEPRINT.md`.
OLD: competing synthesized blueprint with unsupported `[CODE_VERIFIED]` claims.
NEW: removed. Raw source manifest is now the authority.
TEST: repository deletion confirmed.
STATUS: SUPERSEDED.

## Still requiring actual implementation work

- migrate the remaining combat compatibility HP views to direct `ComponentAuthority` callers;
- remove generic socket fallback and require raw hardpoints;
- atomic replacement using one validated hardpoint candidate;
- exact debris detach force/momentum/persistence from raw source;
- exact `anb` integration and mass/COM/inertia behavior;
- exact shield/power/repair consumers;
- full MissionCondition/MissionAction port;
- provenance audit of every existing `ForensicDataModel` constant/data entry that predates the raw archive.

## Rule
Do not delete a legacy implementation merely because a newer abstraction exists. Delete it only after all live callers use the authoritative replacement and the raw behavior is preserved.
