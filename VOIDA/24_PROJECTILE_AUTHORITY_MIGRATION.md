# VOIDA — Projectile Authority Migration

## SOURCE:
- `ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`
- Existing Roblox physics authority: `RigidBody2D` / `PhysicsWorld`.
- Forensic directive requiring swept projectile collision and server-owned hit resolution.

## OLD:
- Projectile collision in `BallisticsEngine` tested only the projectile endpoint against body radius.
- High-speed projectiles could pass through a body between simulation steps.
- Hit impulse used an obsolete `AddImpulse` shape not guaranteed by the current rigid-body authority.

## NEW:
- Added a segment-distance sweep from previous projectile position to next position.
- First valid body intersection along the segment is selected for the step.
- Hit impulse uses the existing `RigidBody2D:ApplyImpulseAtWorldPoint()` API.
- Projectile visual projection remains Roblox-native and preserves the existing X/Z logical plane.
- Existing homing, inherited velocity, range, and lifetime behavior remains in the Roblox engine.

## TEST:
- Static API reviewed against current `RigidBody2D` implementation.
- `ApplyImpulseAtWorldPoint` exists on the authoritative physics body.
- No second physics authority was introduced.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Use `BallisticsEngine` for logical projectile state when a custom physics body is active. Keep Roblox visual objects as projection only. Do not revert to endpoint-only hit tests. Any future native trajectory recovery should replace the internal guidance/integration equations without removing the swept collision boundary.
