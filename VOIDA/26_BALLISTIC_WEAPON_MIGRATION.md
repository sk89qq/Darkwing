# VOIDA — Ballistic Weapon Migration

## Commit
`13c8a03b127f74d73bc5fbf3b2074a6e90dbc4b1`

## SOURCE:
- `src/roblox/ServerScriptService/VoidHunterWeaponController.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`
- Existing Roblox projectile visuals and component definitions.

## OLD:
- Mass-driver and plasma projectiles used independent Roblox `Touched` handlers for hit detection.
- Projectile movement was driven directly by `AssemblyLinearVelocity`, separate from the canonical ballistics state.

## NEW:
- Mass-driver and plasma now create the same Roblox visual parts but register their logical trajectory with `BallisticsEngine`.
- Ballistics engine supplies swept collision and Roblox raycast fallback.
- Shooter identity uses canonical `ShipId`; team identity comes from `TeamIdentity`.
- Ship linear velocity is inherited as the projectile's initial 2D velocity.
- Existing visuals, damage types, damage magnitudes, range, and projectile speed sources remain definition-driven.
- Missile, laser, drone, and point-defense paths remain unchanged in this scoped migration to avoid behavior changes beyond the verified ballistic path.

## TEST:
- Complete controller blob replaced atomically from the verified current source.
- Mass-driver and plasma no longer attach `Touched` callbacks to their projectile visuals.
- Visual parts are non-colliding/non-touch/query objects because the ballistics engine owns hit testing.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Mass-driver and plasma are the first production callers of `BallisticsEngine`'s Roblox-native raycast fallback. The engine callback resolves the hit model through `RobloxModel`, then existing component selection/damage authority applies. Do not restore `Touched` as a second hit authority. Remaining projectile systems should migrate one class at a time after their native behavior is compared.
