# VOIDA — Native Thruster Operator Recovery

**Date:** 2026-08-26  
**Status:** EXTRACTED / IMPLEMENTED-PARTIAL

## SOURCE:
The supplied `voidhunters_decompiled_raw.zip`, specifically:
- `aqa.java`
- `ml.java`
- `wlb.java`
- `wfb.java`
- `fc.java`
- `eu.java`
- `rrb.java`
- `clb.java`
- `pwa.java`
- `enb.java`
- `kra.java`

The raw archive remains the behavioral authority. The matching `voidhunters.jar` is also present in the Library and was used to confirm the source package is the intended Void Hunters gamepack.

## ORIGINAL BEHAVIOR:
`aqa` is attached to native thruster component definitions. The force operator is not a simple speed bonus or `thruster_count * force` rule.

The recovered `aqa` operator performs:

```text
forceScale = aqa.a(componentType, false)
magnitude  = (forceScale * nativeMagnitude) >> 8
forceX     = (magnitude * fc.a(angleUnits)) >> 8
forceZ     = (magnitude * eu.a(angleUnits)) >> 8
anb.a(forceZ, applicationPointX, applicationPointZ, ..., forceX)
```

Recovered component force scales:

| Native component type | Source value | Provenance |
|---:|---:|---|
| 12 | 16 | RAW-DIRECT (`clb.a`) |
| 13 | 192 | RAW-DIRECT (`pwa.b`) |
| 46 | 1024 | RAW-DIRECT (`enb.c`) |

`fc.a` and `eu.a` mask the angle with `0x1FFF`, establishing a 13-bit angular domain. `rrb.a(22433, angle)` normalizes it to `-4096 .. +4095`, giving 8192 native turn units per revolution.

### Exact native trig table recovered

`kra.a[]` is a **2049-entry** integer lookup table. Direct extraction shows it is exactly reproduced by:

```text
kra.a[i] = round(65536 * sin(pi * i / 4096)), i = 0..2048
```

An exhaustive comparison of the generated values against the recovered Java literal produced **zero mismatches**. Therefore the Roblox implementation now uses the exact recovered table construction rather than an approximate runtime `sin/cos` calculation.

`fc.a()` is the native sine/X sign-and-index mapping and `eu.a()` is the native cosine/Z sign-and-index mapping.

## ROBLOX EQUIVALENT:
Added:
- `src/roblox/ReplicatedStorage/Shared/Physics/NativeTrigTable.luau`
- `src/roblox/ReplicatedStorage/Shared/Physics/NativeThrusterOperator.luau`
- `src/roblox/ReplicatedStorage/Shared/Physics/ThrusterBindingSolver.luau`

`NativeThrusterOperator` now uses the recovered `kra` table by default. The optional lookup arguments remain available for deterministic tests.

`ThrusterBindingSolver` transcribes the recovered `ml.VA()` movement/binding classification. It computes the fixed-point movement delta, projects it against the current heading and the heading offset by `-2048` turn units, and reproduces the source flag thresholds:

- `4` / `8` for longitudinal direction
- `1` / `2` for forward/backward projection
- `0x20` / `0x40` for turn projection
- threshold `128`
- projection scale `256`

This is a calculation boundary only; it does not create or mutate Roblox instances.

## MULTIPLAYER ADAPTATION:
Both calculations are pure. The eventual authoritative caller remains server-owned because thrust changes consequential physical state. Client input may request thrust/binding state, but the server must validate component ownership/state and apply the resulting force through the single `RigidBody2D`/`PhysicsWorld` authority.

## DEPENDENCIES:
- `RigidBody2D.luau` remains the sole Roblox logical physics authority.
- `PhysicsConfig.luau` retains native force constants separately from Roblox mappings.
- Component definitions must provide authoritative `ComponentType` and transform/hardpoint state.
- `NativeTrigTable.luau` now supplies the recovered `kra.a[]` behavior.
- The exact caller-side source of the `aqa` native magnitude is still being traced.
- The complete higher-level thruster selection/activation loop remains to be migrated into the Roblox game loop.

## LOOP POSITION:
`INPUT → STATE → SIMULATION → PHYSICS → COMPONENTS`

The recovered operator belongs in the PHYSICS stage after component/command state has determined which thruster is active and before body integration/replication. `ml.VA()` binding classification supplies directional flags upstream of the actual thruster application path.

## TEST:
- Read the intact raw `aqa.java` and traced its force operator.
- Read `fc.java`, `eu.java`, and `rrb.java` to recover the 13-bit angular domain and fixed-point structure.
- Read `clb.java`, `pwa.java`, and `enb.java` to recover the three source force scales.
- Read `kra.java` directly and compared all 2049 recovered table entries against the mathematical construction: zero mismatches.
- Read `ml.java` `VA()` and recovered the directional projection/flag thresholds.
- Added the exact-equivalent native trig table and binding solver without replacing existing Roblox-unit thrust mappings.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
**EXTRACTED / IMPLEMENTED-PARTIAL**

Resolved from previous `RAW-GAP`:
- native force-scale selection;
- fixed-point magnitude calculation;
- native angular normalization;
- native trig lookup table;
- sine/cosine sign/index mapping;
- `ml.VA()` directional binding flag calculation.

Still `RAW-GAP`:
- exact caller semantics/range for the `aqa` native magnitude parameter;
- complete higher-level thruster activation/autobalancing loop and its caller integration;
- exact velocity-sustain integration around thruster activation;
- exact `anb` force/momentum update integration.

## FUTURE AGENT NOTE:
Do not replace this operator with `number_of_thrusters * RobloxForce`. Native type 12/13/46 scales and the `kra` lookup behavior are source-backed, while Roblox `THRUSTER_FORCE`, `THRUSTER_SMALL_FORCE`, and `THRUSTER_BOOSTER_FORCE` are execution mappings. The next investigation should trace the caller that supplies `nativeMagnitude`, then recover the complete thruster activation loop before changing existing Roblox movement behavior.
