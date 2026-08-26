# Body Recompute Authority Migration

STATUS: IMPLEMENTED

Commit: 3e3b462bbeb30b7e75476853dccf3a313a9dbe65

## CHANGE
Structural mutation now converges on `BodyRecomputeService` through `StructuralAuthority`.

The body seed is rebuilt from the live Roblox component graph after attach, detach, replacement, severance, and ship binding.

Mass precedence:
1. `ComponentDefinition.Mass`
2. `ComponentDefinition.PhysicsMass`
3. `ComponentDefinition.BodyMass`
4. explicit `ComponentMass` attribute
5. `PhysicsConfig.DEFAULT_PIECE_MASS`

`AssemblyMass` is deliberately not used as per-component logical mass because welded Roblox parts report assembly mass and would double-count the ship.

## WHY
The authoritative topology transaction requires one common post-mutation recompute boundary. The existing `BodyRecomputeService` already delegates the mathematical mass/COM/inertia calculation to `RigidBody2D`.

## RESULT
Structural callers no longer own independent mass/COM/inertia calculations.

Roblox remains the runtime environment; `RigidBody2D` and `MassPoint` provide the logical 2D representation used by the project's physics layer.

## FUTURE AGENT NOTE:
- `StructuralAuthority` is the structural mutation boundary.
- `BodyRecomputeService` is the single recomputation boundary.
- `RigidBody2D` owns mass, inverse mass, COM, inertia, inverse inertia, and bounds calculations.
- `MassPoint` uses the parallel-axis theorem for inertia contribution.
- Do not use `BasePart.AssemblyMass` as a per-component logical mass while components are welded.
- Do not create a second body-recompute implementation in weapons, debris, build, or ship-spawn code.
- Exact native debris launch remains separately tracked; this migration does not invent its unresolved term.
