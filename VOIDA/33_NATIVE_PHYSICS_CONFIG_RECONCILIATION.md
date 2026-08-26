# VOIDA — Native Physics Configuration Reconciliation

## SOURCE
Exact user-supplied `voidhunters.jar`, represented by:
- `VOIDA/DEFINITIVE_VALUES/native_configuration_values.csv`
- `VOIDA/DEFINITIVE_VALUES/FULL_JAR_ANALYSIS.md`
- native physical-body class `anb`

Relevant native configuration rows:
- `THRUSTER_FORCE = 192`
- `THRUSTER_BOOSTER_FORCE = 1024`
- `THRUSTER_SMALL_FORCE = 16`
- `VELOCITY_SUSTAIN = 508`
- `VELOCITY_SUSTAIN_MAX = 512`
- `ANGULAR_VELOCITY_SUSTAIN = 234`
- `ANGULAR_FORCE_DOWNSHIFT = 4`
- `ANGULAR_VELOCITY_SUSTAIN_MAX = 256`
- `TORQUE_DOWNSHIFT = 4`
- `MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 12`
- `MOMENT_OF_INERTIA_PERPOINT_CALC_DOWNSHIFT = 8`
- `PHYSICS_COLLISION_FORCE_MULTIPLIER = 4096`
- `PHYSICS_COLLISION_GRAPPLING_HOOK_FORCE_MULTIPLIER = 4096`
- `PHYSICS_COLLISION_PHANTOM_FORCE_MULTIPLIER = 2048`
- `DEBRIS_DETACHMENT_FORCE_MULTIPLIER = 256`
- `COMPONENT_BREAKING_EXPLOSION_FORCE_MULTIPLIER = 32768`

## ORIGINAL BEHAVIOR
The native body uses explicit physics configuration values and stores position, velocity, angle, angular velocity, center of mass, mass, moment of inertia, and bounds. The exact `anb` update/operator semantics are still source-recovery work; the numeric settings must therefore be preserved in native units without pretending they are Roblox stud/second values.

## DARKWING EQUIVALENT
`Shared/Physics/PhysicsConfig.luau` now exposes `NATIVE_*` constants containing the exact recovered native defaults. Existing Roblox execution values remain in separate fields and are explicitly classified as `ROBLOX-MAPPING` rather than `CODE_VERIFIED`.

## MULTIPLAYER ADAPTATION
None in this change. The constants are shared physics inputs; server-authoritative physics remains the intended runtime boundary.

## DEPENDENCIES
- `RigidBody2D`
- `BodyRecomputeService`
- `StructuralAuthority`
- native `anb` source recovery

## GAME-LOOP POSITION
`SIMULATION → PHYSICS → COMPONENTS → COMBAT → ...`

## VERIFICATION
- Native values cross-checked against the committed 235-row native configuration table.
- `PhysicsConfig.luau` updated successfully in GitHub commit `c826ed0b83c659f24fad288c65645fe9c1d9de1a`.
- Roblox Studio runtime verification is still unavailable.
- Exact native-to-Roblox unit conversion remains `RAW-GAP`.

## OPEN QUESTIONS
1. Recover the exact `anb` update equations and field/operator mapping.
2. Establish whether the fixed-point physics values use division/downshift rules at each consumer.
3. Recover exact native max-speed/bounds behavior from `anb`/ship callers before replacing Roblox mapping values.
4. Trace force/torque application from `aqa` and `anb` call sites.

## NEXT STEP
Recover the native `anb` operator/update call chain from bytecode or a better decompilation. Do not replace the remaining Roblox mapping values with raw constants until their consumer semantics establish the conversion.

## FUTURE AGENT NOTE
The native values above are authoritative source data, but their units are not interchangeable with Roblox units. Do not delete the `NATIVE_*` layer or collapse it into the execution mapping. When `anb` bytecode is recovered, update the mapping at the consumer boundary and record the exact source method/operator. Never promote the current `RigidBody2D` damping, speed, mass, inertia, or world-scale values to native-verified status without that evidence.

## STATUS
`EXTRACTED / IMPLEMENTED / PARTIAL`

## Git-ready commit message
`physics: reconcile native configuration constants`
