# VOIDA — Native Variable Mapping Status

## SOURCE
Original supplied JAR / decompiled package, with repository forensic records used as the evidence ledger.

## CLOSED VARIABLE FAMILIES

### `anb` body state
- `d/e`: body position coordinates.
- `f/h`: linear velocity coordinates.
- `r`: body rotation/orientation.
- `n`: angular velocity.
- `s`: aggregate mass.
- `i/j`: aggregate center of mass.
- `m`: stored moment of inertia.
- `o/t`: transient linear accumulators.
- `p`: transient torque accumulator.

### `anb` fixed-point shifts
- `ge.c = 4` — force/position normalization.
- `tua.a = 4` — torque accumulation shift.
- `wf.e = 12` — inertia integration shift.
- `ou.r = 8` — polygon-coordinate shift.

### Thruster operator
- Native component types `12`, `13`, `46` map to recovered force scales `16`, `192`, `1024` respectively.
- Native turn domain is `8192` units per full turn; half turn is `4096`.
- Thruster force projection uses the recovered trig table and `>> 8` scaling.
- `ml.VA()` directional flags and threshold `128` are implemented in `ThrusterBindingSolver`.

### Component runtime authority
- Component identity is explicit `ComponentType` and resolved through `ComponentAuthority`.
- Component HP is owned by `ComponentAuthority`.
- Shield component lookup now uses that authority boundary.

## IMPORTANT REMAINING MAPPING GAPS

1. Exact `lw.a(...)` health/mass lookup semantics and its `eo.o[]` scaling are still raw-source work, not a Roblox tuning problem.
2. Exact `anb.b(...)` integration-divisor call-site meaning remains unresolved. Do not invent a `dt` conversion.
3. Exact native `d(B)` surrounding body-update semantics remain unresolved.
4. Higher-level `ml.MC()` caller semantics supplying thruster magnitude remain unresolved.
5. Shield/power/repair numerical consumers remain partially inferred.
6. Referenced/generated component constructors still require semantic identity reconciliation.

## RULE
Do not label the above open items as “unmapped because complex.” They are narrow evidence gaps. Everything else listed in this document is mapped or authority-wired and should not be re-investigated without contradictory source evidence.

## TEST
Static cross-check against `VOIDA/00_RAW_FORENSIC_REFERENCE.md`, `VOIDA/27_NATIVE_ANB_EQUATIONS_RECOVERY.md`, `VOIDA/30_NATIVE_THRUSTER_BINDING_RECOVERY.md`, `NativeAnbPhysics.luau`, `NativeThrusterOperator.luau`, `ThrusterBindingSolver.luau`, and `ComponentAuthority.luau`.

## STATUS
**MAPPED — REMAINING GAPS NARROWED TO SOURCE-CALLSITE/UNIT SEMANTICS.**
