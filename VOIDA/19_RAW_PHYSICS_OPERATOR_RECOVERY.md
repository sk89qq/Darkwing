# VOIDA — Raw Physics Operator Recovery

## SOURCE:
Supplied `voidhunters_decompiled_raw.zip`, specifically `anb.java`, `nbb.java`, `wfb.java`, `ml.java`.

## RAW-DIRECT findings

### `anb.KB(...)`
`anb.a(int n2, int n3, int n4, byte by, int n5)` performs the native force/torque accumulator update:

- `t += n5`
- `o += n2`
- local displacement is derived from body position (`d/e`) and the supplied point (`n3/n4`)
- a scaled cross-product-like term is accumulated into `p`
- overflow is clamped to integer min/max

The exact shifts `ge.c` and `tua.a` are still obfuscated symbols in this decompile and therefore remain `RAW-GAP` for Roblox unit conversion.

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
- debris `o/t` are then zeroed by later body processing as normal

This confirms that debris does not originate from a random generic impulse; it inherits the native body's accumulated motion-state quantities at split time.

### `wfb.B(...)`
Component health is assigned as:

`p = lw.a(..., u) * z`

so component health remains geometrically derived from the native polygon/area quantity and `z` scale.

## OLD:
- Roblox destruction/debris paths used guessed/random debris identity and did not preserve the native transient body accumulators.
- A generic detached-body velocity primitive was used without an explicit native operator mapping.

## NEW:
- Raw native debris transfer is documented explicitly.
- `RigidBody2D` remains the Roblox physics authority.
- Detached-body state preservation is treated as a mapping of native body state, not as an invented force constant.
- Exact integer scaling for the native operator is not guessed while `ge.c`, `tua.a`, `wf.e`, and related obfuscated constants remain unresolved.

## TEST:
- Raw source was extracted from the intact 2,184,812-byte library archive and inspected locally.
- `anb.KB`, `anb.EA`, and `nbb.G` were read directly from the decompiled source.
- Findings were cross-checked against the declared `anb` state fields and `nbb extends anb` relationship.
- Roblox runtime parity remains `IMPLEMENTED / PARTIAL`, not `VERIFIED`.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Use this document when implementing component split/destruction motion. Native mappings are: `anb.f/h` = linear velocity components inherited from `ara`; `anb.n` = angular velocity; `anb.o/t/p` = transient force/rotation accumulators consumed by `anb.EA`; `nbb.G` transfers those transient accumulators to the debris body and clears the source. Do not invent a detach impulse until the remaining native scale constants and call context are recovered. `RigidBody2D` should expose equivalent accumulator-level operations rather than adding a second physics authority.
