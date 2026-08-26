# VOIDA RAW FORENSIC REFERENCE — FIRST PASS

## Authority

The supplied raw `voidhunters_decompiled` package is the authoritative first-pass forensic source for this port.

Library copy: `/VOIDA/voidhunters_decompiled_raw.zip`
Archive SHA-256: `2ff3fb9f02682a4bb46de13cae78b5fadf13b79862fa8692021a3dcdf2cd60d8`
Archive entries: 1581
Java/resource-text files: 1571

The raw package takes precedence over synthesized blueprints, audits, generated data tables, and previous implementation assumptions.

## Evidence classes

- `RAW-DIRECT`: directly present in supplied Java/resource text.
- `RAW-STRUCTURED`: recoverable from raw code/data despite CFR formatting.
- `RAW-GAP`: explicitly unresolved by the supplied decompilation.
- `ROBLOX-MAPPING`: implementation choice made to reproduce recovered behavior.
- `INFERRED`: not established by raw evidence.

Never promote `ROBLOX-MAPPING` or `INFERRED` to source truth without evidence.

## Key raw classes

- `ml.java` — component object; recursive subcomponents, hardpoints, health, behaviors.
- `anb.java` — physical body state and integration/collision behavior.
- `sg.java` — ship specialization.
- `nbb.java` — debris specialization.
- `wfb.java` — component definition/health derivation.
- `wlb.java` — initialization of `hab.g` component definitions; 56 slots.
- `hab.java` — component definition container.
- `lw.java` / `eo.java` — health lookup/math path.
- `summary.txt` — CFR 0.152 unresolved-method report.

## Directly confirmed from raw source

`wlb.java` initializes `hab.g = new wfb[56]`.

The following slots are directly assigned with literal polygon arrays in the static initializer:
`1, 2, 14, 15, 16, 17, 19, 20, 23, 24, 25, 26, 27, 28, 29, 42, 43, 44, 47`.

The remaining slots are generated from dependent expressions/chassis data and must not be reduced to guessed literals.

`ml.java` exposes the component fields that correspond to type ID, trigger map, connection coordinates/angles, health, final transform, final outline, recursive child components, hardpoints, and behavior objects.

`anb.java` stores position, velocity, angle, angular velocity, center of mass, mass, moment of inertia, bounding box, ID, and root component state.

`wfb.java` computes health through `lw.a(..., u) * z`.

`lw.java` uses the `eo.o[]` lookup table and branch-dependent integer scaling. A generic `sqrt(area) * z / 64` implementation is not itself raw-verified.

## Raw decompilation gaps

`summary.txt` explicitly reports CFR-structured failures including major methods in `ml`, `pe`, `uca`, `VoidHunters`, and multiple physics/mission/resource classes.

Those behaviors remain `RAW-GAP` until reconstructed from bytecode or a better decompilation. Do not invent replacements merely to make the system appear complete.

## Porting rule

1. Recover raw behavior/data first.
2. Reuse an existing Roblox implementation only when it matches the raw semantics.
3. Where no functional replacement exists, build the smallest authoritative module matching the raw data model.
4. Migrate callers before deleting a legacy implementation.
5. Preserve historical source quotations even when their names are deprecated; refactor live implementation names and explanatory documentation.
6. Record `SOURCE -> OLD -> NEW -> TEST -> STATUS` for each change.
