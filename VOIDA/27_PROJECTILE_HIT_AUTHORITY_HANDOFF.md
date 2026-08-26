# VOIDA — Projectile Hit Authority Handoff

## SOURCE:
- `src/roblox/ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`
- `src/roblox/ServerScriptService/VoidHunterWeaponController.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/ComponentAuthority.luau`
- `src/roblox/ReplicatedStorage/Shared/Ship/ShipRegistry.luau`

## CURRENT STATE:
- Ballistics uses swept segment collision for logical `PhysicsWorld` bodies.
- When no logical physics world is attached, Ballistics uses a Roblox `Workspace:Raycast()` fallback.
- The fallback returns the actual `BasePart` hit as `RobloxPart` on the hit body adapter.
- Weapon orchestration applies damage to that actual component when `ComponentAuthority.IsComponent()` accepts it.
- Random selection of a victim component after a ballistic hit has been removed.
- Mass-driver and plasma visuals are retained as Roblox objects; logical trajectory/hit authority is centralized in `BallisticsEngine`.

## REMAINING:
- Projectile raycast filtering should be reconciled against the canonical ship registry so non-ship workspace geometry does not become an accidental terminal hit.
- Missile and laser paths still use their existing Roblox `Touched` implementations and should be migrated only after their native/source behavior is compared.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Do not restore random component selection after a confirmed collision. `BallisticsEngine` should return the exact Roblox hit part whenever the Roblox fallback is active. `VoidHunterWeaponController` owns damage application; `ComponentAuthority` owns health/destruction state. `ShipRegistry` is the canonical source for ship ownership and should also become the source for projectile raycast filtering rather than introducing a second ship list.
