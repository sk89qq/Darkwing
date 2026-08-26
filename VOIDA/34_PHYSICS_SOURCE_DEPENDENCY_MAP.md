# VOIDA — Physics Source Dependency Map

## STATUS
EXTRACTED / IMPLEMENTED / PARTIAL

## SOURCE
Authoritative raw Void Hunters package and exact JAR-derived forensic records. `anb` is the primary body implementation; `sg` and `nbb` specialize ship/debris behavior. Supporting operator classes include `ge`, `tua`, `wf`, `ecb`, `ar`, `rrb`, `hob`, `cqb`.

## VERIFIED SOURCE SURFACE
The client exposes named configuration accessors for:
- `get_velocity_sustain`
- `get_velocity_sustain_max`
- `get_angular_velocity_sustain`
- `get_angular_velocity_sustain_max`
- `get_angular_force_downshift`
- `get_torque_downshift`
- `get_moment_of_inertia_predivide_downshift`
- `get_moment_of_inertia_perpoint_calc_downshift`
- `get_physics_collision_force_multiplier`
- `get_physics_collision_grappling_hook_force_multiplier`
- `get_physics_collision_phantom_force_multiplier`
- `get_thruster_force`
- `get_thruster_small_force`
- `get_thruster_booster_force`
- `get_thruster_autobalancing`
- `get_thruster_binding_balance_threshold`
- `get_thruster_binding_move_and_turn_has_opposite_move`
- `get_thruster_particle_life`
- `get_thruster_particle_speed_downshift`

These names are source evidence that the physics/movement system is configuration-driven; the names alone do not establish numeric values or exact consumer equations.

## NATIVE BODY FLOW
`ml / component geometry`
→ `anb body state`
→ `anb.KB force/torque accumulation`
→ `anb.EA accumulator consumption`
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

## KNOWN RAW-GAPS
1. Exact fixed-point shifts represented through `ge.c` / `tua.a`.
2. Exact conversion in `anb.EA` from accumulators into linear/angular velocity.
3. Exact mass/COM/inertia equations and per-point scaling.
4. Exact collision-force consumer scaling.
5. Exact randomized debris launch conversion through `cqb`, `ar`, `ecb`, `rrb`, `hob`.
6. Exact Roblox unit mapping.

## ENGINEERING RULE
Do not promote any current Roblox damping/speed/mass/inertia constants to native truth merely because they produce plausible motion. Native configuration constants are retained separately until their consumer semantics are recovered.

## NEXT STEP
Recover the smallest exact operator bodies needed to resolve `ge.c`, `tua.a`, and the `anb` call chain. If current decompilation cannot expose them, use the original class bytecode / alternate decompiler. Do not substitute textbook physics.

## FUTURE AGENT NOTE
The named getter inventory is useful for locating configuration consumers, but it is not proof of behavior. Start from `anb` call sites and trace backwards to configuration accessors and operator helpers. Keep source values and Roblox mappings separate. Existing debris migration is intentionally based on point kinematics plus the native launch path; do not replace it with generic explosion force.
