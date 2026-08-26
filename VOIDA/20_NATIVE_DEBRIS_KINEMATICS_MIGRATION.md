# VOIDA — Native Debris Kinematics Migration

## Commit
`ea7ee839eae5faaaee7f184ea5e61f918f72ae0d`

## SOURCE:
- Raw `nbb` debris specialization transfers the native transient body-motion state into the debris body and clears the source state.
- Raw `ml` debris creation paths carry parent body motion into newly created debris.
- Roblox `RigidBody2D` already models center of mass, linear velocity, angular velocity, and point velocity.

## OLD:
`StructuralAuthority.DetachComponent()` copied the source ship's root `AssemblyLinearVelocity` and `AssemblyAngularVelocity` to every detached part.

## NEW:
- Structural detach creates a source `RigidBody2D` from the ship's authoritative root assembly state.
- Each detached subtree is seeded from the source body's instantaneous point velocity at the detached root location using `RigidBody2D:GetWorldPointVelocity()`.
- Angular velocity is preserved from the source body.
- No arbitrary explosion/detachment impulse is introduced.
- Roblox `AssemblyLinearVelocity` / `AssemblyAngularVelocity` remain the physical projection of the recovered logical kinematics.

## TEST:
- Complete `StructuralAuthority.luau` replacement committed and read back from GitHub.
- Existing detach API preserved.
- Native-state mapping is explicit in code comments.
- Runtime parity remains `IMPLEMENTED`, not `VERIFIED`, until Studio simulation confirms observed detached-body motion.

## STATUS:
IMPLEMENTED.

## FUTURE AGENT NOTE:
`RigidBody2D` is the logical motion model. `StructuralAuthority.DetachComponent()` is the structural mutation boundary. Do not move physics authority into `VoidHunterDebrisManager`. Do not add guessed launch impulses. The remaining raw-source gap is the exact native randomized debris launch term and any source-specific scaling constants; those remain `RAW-GAP` until the relevant raw operators/constants are fully recovered.
