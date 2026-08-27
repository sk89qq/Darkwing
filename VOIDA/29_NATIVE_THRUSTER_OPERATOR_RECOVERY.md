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

The raw archive remains the behavioral authority.

## ORIGINAL BEHAVIOR:
`aqa` is attached to the native thruster component definitions. The force operator is not a simple speed bonus or `thruster_count * force` rule.

The recovered `aqa` operator performs:

```text
forceScale = aqa.a(componentType, false)
magnitude  = (forceScale * nativeMagnitude) >> 8
forceX     = (magnitude * fc.a(angleUnits)) >> 8
forceZ     = (magnitude * eu.a(angleUnits)) >> 8
anb.a(forceX, applicationPointX, applicationPointZ, ..., forceZ)
```

Recovered component force scales:

| Native component type | Source value | Provenance |
|---:|---:|---|
| 12 | 16 | RAW-DIRECT (`clb.a`) |
| 13 | 192 | RAW-DIRECT (`pwa.b`) |
| 46 | 1024 | RAW-DIRECT (`enb.c`) |

`fc.a` and `eu.a` mask the angle with `0x1FFF`, establishing a 13-bit angular domain. `rrb.a(22433, angle)` normalizes it to `-4096 .. +4095`, giving 8192 native turn units per revolution.

The trig values are integer lookup-table results from `kra.a[]`; replacing that table with ordinary floating-point sine/cosine would be an implementation approximation, not source parity.

The `ml` caller passes the component's runtime transform angle and a separate native magnitude parameter into `aqa`. The exact semantic source of that magnitude parameter must remain traced through the caller chain; it must not be guessed from the Roblox `THRUSTER_FORCE` mapping.

## ROBLOX EQUIVALENT:
Added:
`src/roblox/ReplicatedStorage/Shared/Physics/NativeThrusterOperator.luau`

The module preserves the native fixed-point operator shape and exposes:
- native component-type force-scale lookup;
- native angle normalization;
- injectable native trig lookup functions;
- fixed-point `>> 8` force calculation;
- explicit separation between native magnitude and Roblox-unit execution values.

It is deliberately not wired into the existing `Thruster.luau` default-force path yet, because doing so without recovering the `kra.a[]` table and caller magnitude semantics would silently change functioning Roblox behavior on incomplete evidence.

## MULTIPLAYER ADAPTATION:
The operator is pure calculation. The eventual authoritative caller must remain server-owned because thrust changes consequential physical state. Client input may request thrust state, but the server must validate component ownership/state and apply the resulting force through the single `RigidBody2D`/`PhysicsWorld` authority.

## DEPENDENCIES:
- `RigidBody2D.luau` remains the sole Roblox logical physics authority.
- `PhysicsConfig.luau` retains native force constants separately from Roblox mappings.
- Component definitions must provide authoritative `ComponentType` and transform/hardpoint state.
- Native `kra.a[]` lookup table remains to be recovered for exact numeric parity.
- The `ml` caller chain must be traced to identify the exact native magnitude input.

## LOOP POSITION:
`INPUT → STATE → SIMULATION → PHYSICS → COMPONENTS`

The recovered operator belongs in the PHYSICS stage after component/command state has determined which thruster is active and before body integration/replication.

## TEST:
- Read the intact raw `aqa.java` and traced its force operator.
- Read `fc.java`, `eu.java`, and `rrb.java` to recover the 13-bit angular domain and fixed-point structure.
- Read `clb.java`, `pwa.java`, and `enb.java` to recover the three source force scales.
- Added the source-shaped Luau operator without changing the existing Roblox thrust mapping.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
**EXTRACTED / IMPLEMENTED-PARTIAL**

Resolved from `RAW-GAP`:
- native force-scale selection;
- fixed-point magnitude calculation;
- native angular normalization;
- force-vector operator structure.

Still `RAW-GAP`:
- complete `kra.a[]` trig lookup table;
- exact caller semantics/range for the native magnitude parameter;
- full autoblocking/autobalancing decision loop;
- exact velocity-sustain integration around thruster activation.

## FUTURE AGENT NOTE:
Do not replace this operator with `number_of_thrusters * RobloxForce`. Native type 12/13/46 scales are source-backed, while Roblox `THRUSTER_FORCE`, `THRUSTER_SMALL_FORCE`, and `THRUSTER_BOOSTER_FORCE` are execution mappings. Recover the remaining caller and lookup-table semantics before promoting numerical Roblox thrust parity to `VERIFIED`.
