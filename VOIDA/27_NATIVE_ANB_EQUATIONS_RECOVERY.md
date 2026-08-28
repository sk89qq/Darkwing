# VOIDA — Native `anb` Physics Equation Recovery

## SOURCE
Original JAR: `VOIDA/ORIGINAL_JAR/PREPROCESSING_01_06/voidhunters-original.jar`.
Direct JVM bytecode inspection of `anb.class`, `ml.class`, `wfb.class`, `ge.class`, `tua.class`, `wf.class`, and `ou.class`.

## VERIFIED CONSTANTS
- `ge.c = 4` — native position/fixed-point shift used by `anb` force/torque accumulation.
- `tua.a = 4` — native shift used when accumulating the torque-like transient `p`.
- `wf.e = 12` — native inertia shift used when converting stored inertia `m` to the denominator used by angular integration.
- `ou.r = 8` — native polygon-coordinate shift used by `ml.a(int,int,int)` inertia accumulation.

These values are directly established by class static initializers / bytecode, not inferred from the Roblox implementation.

## BODY STATE FIELD MAPPING
`anb` extends `ara`, where `ara.d/e` are body position and `ara.f/h` are linear velocity components. `anb` adds:

- `s` = body/component aggregate mass field.
- `i`, `j` = aggregate center-of-mass coordinates.
- `m` = stored aggregate moment-of-inertia quantity.
- `n` = angular velocity.
- `o`, `t` = transient linear accumulators.
- `p` = transient angular/torque accumulator.
- `r` = native body rotation/orientation field.

The `a(tv,int)` copy path transfers `n`, `m`, `r`, `s`, `i`, and `j`, confirming these are persistent body properties/state rather than temporary Roblox projection values.

## MASS RECOVERY
`ml.e(byte)` returns the component tree mass recursively:

`mass = wfb.u + sum(child.mass)`

`wfb.u` is polygon area-derived. Its direct native computation is:

1. Accumulate signed polygon double-area from successive integer vertex pairs:
   `u += -(y_i * x_prev) + (y_prev * x_i)`.
2. Divide by `2`.
3. Clamp negative/overflow cases to the native bounds.
4. Convert through `lw.a(byte, u)` and multiply by `wfb.z` to obtain the component mass field `wfb.p`.

The exact semantics/units of `lw.a` remain a separate source-mapping question; the polygon-area arithmetic and recursive aggregation are directly recovered.

## CENTER OF MASS RECOVERY
`anb.e(byte)` requests `ml.a(byte,int[])` with an accumulator `[0,0,0]`.

For each component:

- `accumY += component.n * componentAreaMass >> 4`
- `accumMass += componentAreaMass`
- `accumX += component.r * componentAreaMass >> 4`

The body then computes:

`massDivisor = max(1, accumMass >> 4)`

`i = accumY / massDivisor`

`j = accumX / massDivisor`

Thus the COM is a mass-weighted average in the native fixed-point coordinate domain. Child `ml` trees participate through the same accumulator path.

## MOMENT OF INERTIA RECOVERY
`anb.e(byte)` then computes:

`m = ml.a(-921054591, i, j)`

The native `ml.a(int,int,int)` implementation is directly recoverable. For each polygon vertex pair:

- Vertex coordinates and the supplied COM are shifted right by `ou.r = 8`.
- `vertexCount = g.length >> 1` because `g` stores interleaved X/Y integers.
- `componentMassPerVertex = componentMass / vertexCount`.
- For each vertex, with `dx = vertexX - COM_X` and `dy = vertexY - COM_Y`:
  `inertia += componentMassPerVertex * (dx*dx + dy*dy)`.
- Child component inertia is added recursively with the same COM reference.
- Positive overflow is clamped to `2147483647`.
- The accumulator is initialized to `1`.

The native angular integration later consumes this stored quantity as:

`angularDelta = p / max(1, m >> 12)`

because `wf.e = 12` is directly verified.

## FORCE / TORQUE ACCUMULATION — `anb.a(int,int,int,byte,int)`
The direct bytecode is:

1. `t += n5`
2. `o += n2`
3. `dxRaw = n3 - d`
4. `dyRaw = n4 - e`
5. `dy = (e - n4) >> ge.c` → `ge.c = 4`
6. `dx = (n3 - d) >> ge.c` → `ge.c = 4`
7. `crossTerm = dy * n5 - n2 * dx`
8. `p += crossTerm >> tua.a` → `tua.a = 4`
9. `p` is clamped to signed 32-bit bounds on overflow.

This establishes the exact fixed-point scaling of the native point-force torque accumulator. The method also has a guarded assignment to `s` for one obfuscated control-flow case; that branch is not treated as a general physics rule.

## TRANSIENT INTEGRATION — `anb.b(int,int)`
Given the integration divisor `n3`:

`f += t / n3`

`h += o / n3`

Then `t` and `o` are cleared.

If `p != 0`:

`angularDelta = p / max(1, m >> wf.e)`

with `wf.e = 12`, then:

`n += angularDelta`

Then `p` is cleared.

This is the direct native state transition; `d(B)` is called afterward to perform the surrounding body-update bookkeeping.

## WHAT IS NOW CLOSED
- The previously reported `ge.c` and `tua.a` symbols are no longer unresolved: both are exactly `4` in the original JAR.
- `wf.e` is exactly `12`.
- `ou.r` is exactly `8`.
- The native mass aggregation, COM weighting, inertia accumulation, point-force torque accumulation, and linear/angular integration arithmetic are now directly documented from bytecode.

## WHAT REMAINS OPEN
- Exact semantic/unit conversion performed by `lw.a(...)` for polygon-derived mass.
- Exact native-to-Roblox unit mapping for position, velocity, force, and inertia.
- Exact interpretation of the integration divisor passed as `n3` at every call site.
- Exact surrounding `d(B)` body update behavior.

No arbitrary Roblox Newton/stud conversion is introduced until those call-site mappings are recovered.

## STATUS
**RAW EQUATIONS RECOVERED — ROBLOX MAPPING PARTIAL.**

## TEST
- Original JAR was freshly extracted from the uploaded project ZIP.
- `javap -p -c -s` was run directly against the original `anb.class` and supporting classes.
- Static initializers directly verified `ge.c=4`, `tua.a=4`, `wf.e=12`, and `ou.r=8`.
- Relevant `anb`, `ml`, and `wfb` bytecode was traced through field reads/writes and arithmetic.
- No Roblox-side implementation was changed from inference alone.
