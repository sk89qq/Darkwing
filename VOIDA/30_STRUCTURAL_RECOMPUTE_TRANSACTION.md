# Structural Recompute Transaction

STATUS: IMPLEMENTED

Commit: 3e3b462bbeb30b7e75476853dccf3a313a9dbe65

## RESULT
StructuralAuthority now converges attach, detach, replacement, severance, and ship binding on a common body-recompute boundary.

The logical body is rebuilt from current Roblox component instances using canonical component mass definitions, then recomputed through `BodyRecomputeService` / `RigidBody2D`.

Recorded projection values:
- `BodyMass`
- `BodyCenterOfMassX`
- `BodyCenterOfMassZ`
- `BodyMomentOfInertia`
- `BodyBoundingRadius`

## ROBLOX IMPLEMENTATION RULE
Roblox remains the runtime environment. The native source informs observable equations/state, while Roblox `Model`, `BasePart`, welds, assemblies, and constraints remain the final implementation/projection layer.

## FUTURE AGENT NOTE:
- Do not create another body recompute service.
- Do not use welded `AssemblyMass` as per-component mass.
- `BodyRecomputeService` delegates to `RigidBody2D`.
- `MassPoint` performs per-piece inertia plus parallel-axis contribution.
- Structural graph state remains authoritative; Roblox welds/assemblies are projection.
- Exact native debris launch remains separately tracked and must not be replaced by arbitrary constants.
