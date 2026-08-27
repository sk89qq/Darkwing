# VOIDA — Physics Source Dependency Map

## STATUS
EXTRACTED / IMPLEMENTED / PARTIAL

## SOURCE
Authoritative raw Void Hunters package and exact JAR-derived forensic records. `anb` is the primary body implementation; `sg` and `nbb` specialize ship/debris behavior. Supporting operator classes include `ge`, `tua`, `wf`, `ecb`, `ar`, `rrb`, `hob`, `cqb`.

## VERIFIED SOURCE SURFACE
The client exposes named configuration accessors for velocity sustain/max, angular sustain/max, angular/torque downshift, inertia scaling, collision multipliers, and thruster force classes. The names establish configuration-driven behavior; the JAR bytecode additionally resolves the operator constants below.

## BYTECODE-VERIFIED OPERATOR CONSTANTS
From the exact supplied `voidhunters.jar`:
- `ge.c = 4` — point-offset shift used during torque accumulation.
- `tua.a = 4` — torque accumulator downshift during force-point application.
- `wf.e = 12` — angular-velocity denominator shift during accumulator consumption.

## NATIVE FORCE/TORQUE FLOW
`anb.a(int forceX, int forceY, int pointX, int pointY, int...)`
→ accumulate linear force in `t/o`
→ compute point offset from body position
→ shift point coordinates by `ge.c`
→ integer cross-product contributes to `p`
→ cross-product contribution shifts by `tua.a`
→ signed overflow is clamped to Java int bounds.

The recovered accumulator consumer (`anb.b(int,int)`; logged internally as `anb.EA`) does:
- `f += t / divisor`
- `h += o / divisor`
- clears `t/o`
- `angularDelta = p / max(m >> wf.e, 1)`
- `n += angularDelta`
- clears `p`.

This establishes exact accumulator arithmetic but does not yet establish the caller-provided divisor or the complete body-update timestep/unit conversion.

## NATIVE BODY FLOW
`ml / component geometry`
→ `anb body state`
→ `anb` force/torque accumulation
→ accumulator consumption
→ velocity/angular state
→ ship/debris specialization (`sg` / `nbb`)

At detach:
`ml.DA`
→ `nbb`
→ inherited parent motion
→ geometry-derived launch term
→ randomized launch-angle component

## CURRENT ROBLOX BOUNDARY
`ComponentAuthority`
→ `StructuralAuthority`
→ `BodyRecomputeService`
→ `RigidBody2D`
→ visual/physical projection.

`RigidBody2D` remains the sole logical Roblox physics model. Do not introduce another solver in debris, component, or ship managers.

## REMAINING RAW-GAPS
1. Caller-provided divisor/timestep passed to native accumulator consumption.
2. Exact mass/COM/inertia equations and per-point scaling.
3. Exact collision-force consumer scaling.
4. Exact randomized debris launch conversion through `cqb`, `ar`, `ecb`, `rrb`, `hob`.
5. Exact native-to-Roblox unit mapping.

## ENGINEERING RULE
Do not promote current Roblox damping/speed/mass/inertia constants to native truth merely because they produce plausible motion. Native configuration constants and recovered operators remain separate from Roblox execution mappings until consumer semantics are complete.

## NEXT STEP
Trace callers of the recovered `anb` accumulator-consumption method to resolve its divisor/timestep, then recover mass/COM/inertia recomputation. Use the original class bytecode where decompilation is ambiguous. Do not substitute textbook physics.

## FUTURE AGENT NOTE
`ge.c`, `tua.a`, and `wf.e` are now BYTECODE-VERIFIED, not RAW-GAP. The remaining gap is how the native caller supplies the linear divisor/timestep and how body mass properties feed that path. Keep existing valid Roblox mappings intact while this is recovered.
