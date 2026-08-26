# VOIDA — Ballistics Hit-Resolution Migration

## Commit
`ab6d4f6757e3db23bd3cf7541390602171e469ed`

## SOURCE:
- `src/roblox/ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`
- Existing Roblox-first architecture: logical 2D projectile state with Roblox physical/presentation projection.
- `CombatTypes.ProjectileData` defines shooter identity, trajectory, damage, and visual state.

## OLD:
- Swept segment helper could return the first qualifying body rather than the nearest hit along the segment.
- The engine only attempted collision when a `PhysicsWorld` was supplied.
- `VoidHunterWeaponController` constructs the engine with `nil`, so that path had no working engine-level collision query.
- The controller's separate `Touched` projectile paths remained the active hit implementation for several weapons.

## NEW:
- Segment collision evaluates all logical bodies and selects the nearest qualifying hit.
- A Roblox-native `Workspace:Raycast()` fallback now runs whenever `PhysicsWorld` is absent.
- The fallback excludes the shooter's ship by `ShipId`, accepts only models explicitly marked `IsShip`, and returns the hit model through the existing callback contract.
- Existing `PhysicsWorld` support remains intact; no second logical body registry was created.
- Roblox remains the runtime authority for the physical projection.

## TEST:
- Complete source blob replaced atomically.
- Static review confirms nearest-hit tracking uses segment parameter/travel distance rather than iteration order.
- Static review confirms `RaycastParams` uses `Exclude` and `IgnoreWater` and resolves ship models through explicit `IsShip` metadata.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
`BallisticsEngine` may operate with a logical `PhysicsWorld` or directly against Roblox. Prefer the Roblox fallback when the production controller has no shared `PhysicsWorld`; do not create duplicate ship bodies merely to satisfy the projectile API. Keep shooter identity based on canonical `ShipId`/`ShipRegistry`, not weapon names. The remaining work is migrating individual projectile constructors so they consistently use `BallisticsEngine` instead of parallel `Touched` implementations where behavioral parity permits.
