# VOIDA — Native Thruster Binding Recovery

**Date:** 2026-08-26  
**Status:** EXTRACTED / IMPLEMENTED-PARTIAL

## SOURCE
- `voidhunters_decompiled/ml.java`, method `ml.VA()`
- `voidhunters_decompiled/aqa.java`
- `voidhunters_decompiled/fc.java`
- `voidhunters_decompiled/eu.java`
- `voidhunters_decompiled/rrb.java`
- `voidhunters_decompiled/kra.java`

## ORIGINAL BEHAVIOR

The native `ml.VA()` path evaluates thruster binding/movement state before recursively invoking child components. For a ship (`anb2 instanceof sg`), it:

1. Saves current body position fields.
2. Invokes the component transform/placement update with the component's runtime transform and native force scale.
3. Computes fixed-point movement deltas using `>> 8`.
4. Gets the current heading from `fc.a(angle)` and `eu.a(angle)`, each then shifted `>> 8`.
5. Gets a second heading at `angle - 2048` native turn units.
6. Computes two projections:

```text
n10 = n16*n13 + n14*n17
n6  = n14*n20 + n19*n13
n11 = max(n14*n14 + n13*n13, 1)
n9  = 256*n10/n11
n5  = 256*n6/n11
```

7. Sets directional flags from exact threshold tests.

### Recovered flags

| Flag | Meaning in source calculation | Condition |
|---:|---|---|
| `0x04` | negative longitudinal direction | `n15 < 0` |
| `0x08` | non-negative longitudinal direction | `n15 >= 0` |
| `0x01` | positive movement projection | `n10 > 1 && n9 > 128` |
| `0x02` | negative movement projection | `n10 < 0 && n9 < -128` |
| `0x20` | positive turn projection | `n6 > 0 && n5 > 128` |
| `0x40` | negative turn projection | `n6 < 0 && n5 < -128` |

The resulting bitfield is subsequently consumed by the thruster application path (`ml.MC()`), which decides whether the current thruster binding should receive the force update.

## ROBLOX EQUIVALENT

Added:

`src/roblox/ReplicatedStorage/Shared/Physics/ThrusterBindingSolver.luau`

The module is deliberately pure. It reproduces the fixed-point coordinate projection and flag classification but does not mutate Roblox Instances, ownership, or physics state.

The native trig dependency is `NativeTrigTable.luau`, which now exposes the exact `fc`/`eu` axis mappings from `kra.a[]`.

## MULTIPLAYER ADAPTATION

The solver itself is deterministic and side-effect free. The eventual caller belongs to the server-authoritative physics path:

`validated input → component state → binding classification → native force operator → RigidBody2D → integration → replication`

Client code must not author the consequential body state.

## DEPENDENCIES
- `NativeTrigTable.luau`
- `NativeThrusterOperator.luau`
- `RigidBody2D.luau`
- authoritative component type/transform data
- eventual recovery of the exact `ml` caller input semantics

## VERIFICATION

### Source verification
Directly inspected `ml.java` and translated the recovered arithmetic and branch conditions without replacing them with a heuristic steering model.

### Table verification
The recovered `kra.a[]` literal contains 2049 values. The construction

`round(65536 * sin(pi*i/4096))`

matches every recovered table entry.

### Runtime verification
Roblox Studio runtime acceptance remains pending. Therefore this work is **not** marked `VERIFIED`.

## REMAINING RAW-GAP

- Exact semantic origin/range of the native magnitude supplied to `aqa` by the higher-level caller.
- Full `ml.MC()` → child behavior → `aqa` activation chain in Roblox.
- Exact `anb` force operator argument semantics and unit conversion.
- Exact velocity-sustain update around the active-thruster path.

## FUTURE AGENT NOTE

The native binding logic is now source-recovered. Do not replace it with generic `AlignOrientation`, proportional steering, or “balance the nearest thrusters” logic. First trace the existing `ml.MC()` callers and the native `anb` force integration, then adapt those semantics to the existing Roblox authority model.
