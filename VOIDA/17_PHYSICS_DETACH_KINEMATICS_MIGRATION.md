# VOIDA — Physics Detach Kinematics Migration

## Commit
`3d0e2c7c0d3f0052d6ba5f9382bf269f974393de`

## SOURCE:
Current `RigidBody2D` / `MassPoint` implementation, grounded in the project's raw-source requirement that detach momentum and physics remain source-traceable. The existing engine already contains world-point impulse, center-of-mass, angular velocity, mass-point, and inertia primitives.

## OLD:
The structural/destruction path had no reusable rigid-body primitive for seeding a detached component from the parent body's instantaneous kinematics. Any future detachment logic would otherwise be forced to invent an arbitrary Roblox impulse or duplicate physics calculations in gameplay code.

## NEW:
`RigidBody2D:GetWorldPointVelocity(localPoint)` returns the instantaneous translational velocity of a point on the rigid body, including angular contribution about the current world COM.

`RigidBody2D:CreateDetachedBody(localOrigin, newId)` creates a new `RigidBody2D` at the corresponding world position and carries across:
- world point velocity
- parent rotation
- parent angular velocity
- restitution
- fixed-Y configuration

The detached body intentionally receives no guessed explosion force. Its mass points must be populated by the structural layer before physics-world registration.

## TEST:
- Complete `RigidBody2D.luau` replacement was written as a whole UTF-8 source file.
- New APIs use explicit Luau types and existing physics primitives.
- No numeric detachment impulse constant was invented.
- Roblox Studio runtime acceptance remains required.
- Exact raw detach force, debris lifetime, and cleanup behavior remain unresolved until the corresponding raw method/bytecode is recovered.

## STATUS:
IMPLEMENTED; exact raw detach behavior remains PARTIAL / RAW-GAP.

## FUTURE AGENT NOTE:
Do not add ad-hoc `BasePart:ApplyImpulse()` values to destruction code. Use `RigidBody2D:CreateDetachedBody()` for the kinematic seed when a component becomes independent. Populate detached mass points from authoritative component definitions before registering the body with `PhysicsWorld`. Keep exact source-derived detach-force policy separate from this kinematic primitive until raw `wfb`/`anb`/related bytecode is recovered. Never promote inferred constants to `VERIFIED` without source evidence and Roblox Studio acceptance.
