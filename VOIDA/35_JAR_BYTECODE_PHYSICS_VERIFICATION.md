# VOIDA — JAR Bytecode Physics Verification

**Date:** 2026-08-26
**Status:** EXTRACTED / CODE-VERIFIED / IMPLEMENTATION-PENDING

## SOURCE
Exact uploaded `/mnt/data/voidhunters.jar` (3,939,214 bytes; 1,570 entries), inspected with JVM `javap -c -p` against the original obfuscated classes.

Primary classes/methods:
- `anb.e(byte)` — body mass / COM / inertia recomputation
- `anb.a(int,int,int,byte,int)` — force/torque accumulator (`KB`)
- `anb.b(int,int)` — accumulator consumption (`EA`)
- `ml.e(byte)` — component-tree mass
- `ml.a(byte,int[])` — component-tree mass-weighted position accumulation
- `ml.a(int,int,int)` — polygon/component inertia accumulation
- `ge.<clinit>` — fixed-point shift constant
- `tua.<clinit>` — accumulator shift constant
- `ou.<clinit>` — geometry coordinate shift constant
- `wf.<clinit>` — angular conversion shift constant

## VERIFIED NATIVE CONSTANTS
Direct class initializers establish:

- `ge.c = 4`
- `tua.a = 4`
- `ou.r = 8`
- `wf.e = 12`

These are now **CODE-VERIFIED**, not inferred.

## VERIFIED BODY RECOMPUTATION
`anb.e(byte)` performs the following native sequence:

1. Preserve prior body reference position values.
2. Recalculate component geometry/state.
3. Read total component mass from `ml.e(-86)` into body field `s`.
4. Accumulate mass-weighted component positions into a 3-element integer accumulator through `ml.a(114, int[])`.
5. Divide the position accumulators by `max(totalMass, accumulator[2] >> 4)` and assign:
   - body `i` = center-of-mass X
   - body `j` = center-of-mass Y
6. Rebase body position by the newly computed geometry center.
7. Recalculate component transforms.

`ml.e(-86)` starts from the component definition mass `wfb.u` and recursively adds every child component mass.

`ml.a(byte,int[])` adds:
- X contribution: `finalX * mass >> 4`
- Y contribution: `finalY * mass >> 4`
- total mass: `mass`
then recursively processes descendants.

Therefore the native COM operation is a fixed-point weighted centroid, with a verified right shift of **4** on coordinate*mass contributions.

## VERIFIED COMPONENT INERTIA OPERATOR
`ml.a(int,int,int)` computes a component's polygon inertia contribution from its `finaloutline` vertices.

Verified structure:
- `pointMass = definitionMass / max(vertexCount, 1)`
- vertex coordinates are shifted right by `ou.r = 8`
- relative coordinates are measured from the supplied COM arguments
- contribution accumulates `pointMass * (dx^2 + dy^2)`
- child components recurse and their contributions are added
- overflow is clamped to `Integer.MAX_VALUE`

This establishes the native inertia operator's actual fixed-point coordinate treatment. The Roblox implementation must not substitute a generic textbook inertia formula for this native polygon-point procedure.

## VERIFIED FORCE/ACCUMULATOR OPERATOR
`anb.a(int n2, int n3, int n4, byte by, int n5)` performs:

- `t += n5`
- `o += n2`
- `dx = n3 - body.d`
- `dy = n4 - body.e`
- `dyScaled = (-dy) >> ge.c`
- `dxScaled = dx >> ge.c`
- torque accumulator increment:
  `p += ((dyScaled * n5) - (n2 * dxScaled)) >> tua.a`
- `p` clamps to signed 32-bit range
- the supplied force point is forwarded into `cqb.a(...)`

With bytecode initializers recovered, both `ge.c` and `tua.a` are **4**. The earlier RAW-GAP classification for those constants is closed.

## VERIFIED ACCUMULATOR CONSUMPTION
`anb.b(int n2, int n3)` consumes the transient accumulators as:

- `f += t / n3`
- `h += o / n3`
- clear `t` and `o`
- if `p != 0`:
  - angular delta = `p / max(m >> wf.e, 1)`
  - `n += angular delta`
  - clear `p`

`wf.e = 12` is directly verified.

## ROBLOX EQUIVALENT
The existing `RigidBody2D` remains the single Roblox physics authority. This finding does **not** justify replacing its current Roblox execution values wholesale.

Required next implementation boundary:
- add native fixed-point helper/operator representation where needed;
- preserve native mass/COM/inertia state separately from Roblox mapped values;
- feed recovered operators from authoritative component geometry;
- do not introduce arbitrary Newton/stud conversion.

## MULTIPLAYER ADAPTATION
All consequential body-state updates remain server-authoritative. Clients receive replicated physical state/projection; they do not own mass, COM, inertia, force accumulators, or structural mutations.

## TEST
Executed against the exact uploaded JAR using `javap -c -p`. Static assertions confirmed the four initializer values and the relevant bytecode shift sites.

Roblox Studio runtime parity is **not verified**.

## NEXT STEP
Trace the remaining `anb` body update caller/timestep path and `wfb.u` mass derivation, then patch `BodyRecomputeService`/`RigidBody2D` only at the demonstrated consumer boundaries.

## FUTURE AGENT NOTE
`ge.c=4`, `tua.a=4`, `ou.r=8`, and `wf.e=12` are now direct JAR bytecode facts. Do not revert them to inferred/unknown status. Native COM uses mass-weighted coordinates with a `>>4` contribution shift; native polygon inertia uses vertex coordinates `>>8`. Preserve the distinction between these native fixed-point operators and Roblox runtime units.
