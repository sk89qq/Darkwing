# VOIDA — JAR Bytecode Physics Verification

**Date:** 2026-08-26  
**Status:** EXTRACTED / CODE-VERIFIED / IMPLEMENTATION-PENDING

## SOURCE
Exact uploaded `voidhunters.jar`, inspected with JVM `javap -c -p` against the original obfuscated classes.

Primary classes/methods:
- `anb.e(byte)` — body mass / COM / inertia recomputation
- `anb.a(int,int,int,byte,int)` — force/torque accumulator
- `anb.b(int,int)` — accumulator consumption
- `ml.e(byte)` — component-tree mass
- `ml.a(byte,int[])` — mass-weighted position accumulation
- `ml.a(int,int,int)` — polygon/component inertia accumulation
- `wfb.<init>(int[],int,int)` — component definition initialization
- `wfb.a(boolean)` — native component mass derivation from polygon geometry
- `ge.<clinit>`, `tua.<clinit>`, `ou.<clinit>`, `wf.<clinit>` — fixed-point constants

## VERIFIED NATIVE CONSTANTS
- `ge.c = 4`
- `tua.a = 4`
- `ou.r = 8`
- `wf.e = 12`

These are CODE-VERIFIED.

## VERIFIED COMPONENT MASS DERIVATION
Correction to the previous wording: `wfb.u` is **not an arbitrary pre-existing definition mass** in the constructor path inspected here.

`wfb.a(boolean)` initializes `u = 0`, then walks the polygon coordinate array `v` in `(x,y)` pairs. For each vertex it accumulates:

`u += x_i * (y_prev - y_next)`

then performs:

`u /= 2`

and clamps the result to a minimum of `1` and a maximum of `Integer.MAX_VALUE`.

Thus the native component base mass `wfb.u` is derived from the signed polygon area (shoelace-style vertex accumulation), subject to the native integer/clamp behavior. The constructor then uses that derived `u` in the component's subsequent state initialization.

This is a direct bytecode finding from `wfb.a(boolean)` and is more authoritative than the earlier decompiler-level description.

## VERIFIED COMPONENT-TREE MASS
`ml.e(-86)` starts from the component's `wfb.u` and recursively adds child component masses. Therefore body mass ultimately derives from the component polygon geometry and child hierarchy, not from a generic Roblox default mass.

## VERIFIED COM
`ml.a(byte,int[])` accumulates final component positions weighted by native component mass:
- X contribution: `finalX * mass >> 4`
- Y contribution: `finalY * mass >> 4`
- total mass: `mass`
then recursively processes descendants.

`anb.e(byte)` uses the resulting accumulator to establish body COM and rebases body state around the new geometry center.

## VERIFIED COMPONENT INERTIA
`ml.a(int,int,int)` computes polygon inertia from `finaloutline` vertices.

Verified:
- `pointMass = componentMass / max(vertexCount, 1)`
- vertex coordinates use `ou.r = 8` (`>> 8`)
- relative coordinates are measured against supplied COM
- each vertex contributes proportional to `pointMass * (dx² + dy²)`
- child components recurse
- integer overflow is clamped

Do not replace this native polygon-point procedure with a generic textbook inertia approximation and call it native parity.

## VERIFIED FORCE/TORQUE
`anb.a(...)`:
- accumulates linear force
- computes force-point offset from body position
- applies `ge.c = 4`
- accumulates integer cross-product torque
- applies `tua.a = 4`
- clamps signed integer overflow

## VERIFIED ACCUMULATOR CONSUMPTION
`anb.b(int,int)`:
- `f += t / divisor`
- `h += o / divisor`
- clears linear accumulators
- angular delta = `p / max(m >> wf.e, 1)`
- `n += angularDelta`
- clears torque accumulator

`wf.e = 12` is CODE-VERIFIED.

## ROBLOX EQUIVALENT
`RigidBody2D` remains the sole Roblox physics authority. Existing Roblox mappings remain valid unless evidence shows they are wrong, obsolete, duplicated, or otherwise harmful to faithful behavior.

Native values/operators should be represented separately and translated at the Roblox consumer boundary. Do not blindly substitute native fixed-point units for Roblox execution units.

## MULTIPLAYER
Consequential body state remains server-authoritative: mass, COM, inertia, force/torque accumulators, structural mutations, and consequential physics.

## TEST
Direct `javap -c -p` inspection of the exact JAR verified the `wfb.u` polygon-area construction and the previously recovered physics operators/constants.

Roblox Studio runtime parity remains unverified.

## NEXT STEP
Trace the `wfb` coordinate-array producer and `finaloutline` construction so the native polygon geometry can be mapped into the existing Roblox component representation. Then trace the native `anb` update caller/divisor.

## FUTURE AGENT NOTE
IMPORTANT: `wfb.u` is geometry-derived. Do not model it as a free-standing component mass unless another native call explicitly overwrites it. The exact observed construction is the shoelace-style signed polygon sum divided by 2, with integer min/max clamping. Preserve existing Roblox mass mappings while building a native-informed geometry path; do not rip out working Roblox values merely to imitate the Java field layout.
