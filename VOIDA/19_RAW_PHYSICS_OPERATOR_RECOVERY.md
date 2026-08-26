# VOIDA — Raw Physics Operator Recovery

## SOURCE:
Supplied `voidhunters_decompiled_raw.zip`, specifically `anb.java`, `nbb.java`, `wfb.java`, `ml.java`, `ecb.java`, `ar.java`, `rrb.java`, and `hob.java`.

## RAW-DIRECT findings

### `anb.KB(...)`
`anb.a(int n2, int n3, int n4, byte by, int n5)` performs the native force/torque accumulator update:

- `t += n5`
- `o += n2`
- local displacement is derived from body position (`d/e`) and the supplied point (`n3/n4`)
- a scaled cross-product-like term is accumulated into `p`
- overflow is clamped to integer min/max

The exact shifts/constants represented by `ge.c` and `tua.a` remain obfuscated symbols in the current decompile, so their Roblox unit conversion is still `RAW-GAP`.

### `anb.EA(...)`
`anb.b(int n2, int n3)` consumes those transient accumulators:

- `f += t / n3`
- `h += o / n3`
- then clears `t` and `o`
- if `p != 0`, converts `p` through `m` and `wf.e`, adds to angular velocity `n`, then clears `p`

This is the direct native state-transition model that the Roblox physics authority should reproduce.

### `nbb.G(...)`
The debris specialization transfers transient motion state from the parent body to the debris body:

- `debris.o = parent.o`
- `debris.p = parent.p`
- `debris.t = parent.t`
- `parent.p = 0`
- `parent.o = 0`
- `parent.t = 0`
- if the boolean argument is false, debris sets `x = true`

This establishes the **inherited accumulator state at split time**. It does **not** establish that all debris launch motion is non-random, because `ml.DA(...)` subsequently applies a separate launch term.

### `ml.DA(...)` debris-launch path
The raw call site directly constructs a debris body and computes a launch vector from geometry and a randomized angle term:

1. Construct `nbb` from the selected component payload.
2. Compute relative integer offset:
   - `n8 = nbb.d(false) - this.r`
   - `n7 = nbb.g((byte)126) - this.n`
3. Normalize/quantize the offset through `cqb.a(...)`.
4. Compute directional magnitude index:
   - `n6 = ar.a(n8, (byte)110, n7)`
   - fallback `n6 = 1` when zero.
5. Compute launch magnitude term:
   - `n5 = ecb.a(n7, (byte)-77, n8)`
   - `n4 = n2 * nbb.e(false) / n6`
6. Inherit parent linear velocity components when `anb2 != null`:
   - `nbb2.h = anb2.h`
   - `nbb2.f = anb2.f`
7. Apply the actual launch operator:
   - position/angle path includes `rrb.a(22433, -100 + (n5 + hob.a(random, 200, 118)))`
   - launch magnitude uses `n4`
   - the final call is `nbb2.a(this.n, <launch-angle>, this.r, n4, 1948934248)`.

Therefore the native path has two separable pieces:

- inherited parent kinematics;
- an additional randomized debris launch term.

The exact fixed-point-to-Roblox conversion and meanings of `cqb`, `ar.a`, `ecb.a`, `rrb.a`, `hob.a` remain subject to further deobfuscation.

### `wfb.B(...)`
Component health is assigned as:

`p = lw.a(..., u) * z`

so component health remains geometrically derived from the native polygon/area quantity and `z` scale.

## OLD:
- Roblox destruction/debris paths used guessed/random debris identity and did not preserve the native transient body accumulators.
- Detached-body projection copied the ship root assembly velocity rather than evaluating rigid-body point velocity.

## NEW:
- Raw native debris accumulator transfer is explicitly mapped.
- `RigidBody2D` remains the Roblox physics authority.
- Detached-body state preservation uses source-body point kinematics rather than an invented impulse.
- The native randomized debris-launch path is now explicitly identified from `ml.DA`, including its geometry-derived magnitude and randomized angle term.
- Exact native fixed-point scaling remains `RAW-GAP` until the remaining operator constants are recovered.

## TEST:
- Raw source was extracted from the intact 2,184,812-byte library archive and inspected locally.
- `anb.KB`, `anb.EA`, `nbb.G`, and `ml.DA` were read directly from decompiled source.
- Supporting operator implementations in `ecb`, `ar`, `rrb`, and `hob` were inspected to establish the launch-path arithmetic.
- Roblox runtime parity remains `IMPLEMENTED / PARTIAL`, not `VERIFIED`.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Native mappings are: `anb.f/h` = linear velocity components; `anb.n` = angular velocity; `anb.o/t/p` = transient force/rotation accumulators; `nbb.G` transfers those accumulators to debris and clears the source. `ml.DA` then applies an additional launch vector whose direction depends on `ecb.a`/`rrb.a` and whose angle includes `hob.a(random,200,118)`. Do not replace this with a generic explosion impulse. Recover the remaining fixed-point scale constants and exact `RigidBody2D` conversion before claiming parity. `RigidBody2D` is the sole Roblox physics model; debris helpers must remain projection/collection layers.
