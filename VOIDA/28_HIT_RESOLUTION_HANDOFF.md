# VOIDA — Hit Resolution Authority Handoff

## SOURCE:
- `ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`
- `ServerScriptService/VoidHunterWeaponController.luau`
- Existing forensic architecture requiring centralized server-owned damage and structural state.

## OLD:
- Projectile collision could resolve only against the next endpoint instead of the swept segment.
- A confirmed logical hit could subsequently choose a random component on the victim ship.
- The Roblox controller used separate projectile implementations for some weapons.

## NEW:
- `BallisticsEngine` performs swept 2D segment collision against the logical physics world.
- When no logical `PhysicsWorld` is attached, it falls back to a Roblox `Workspace:Raycast` along the same segment.
- The nearest logical body along the segment is selected.
- Roblox fallback preserves `RaycastResult.Instance` as `RobloxPart` on the hit body.
- `VoidHunterWeaponController` routes mass-driver and plasma projectile trajectory/hit handling through `BallisticsEngine` while retaining Roblox visual/presentation behavior.
- Energy state remains owned by `CapacitorSystem`; shield state remains owned by `ShieldSystem`.

## TEST:
- Static source inspection confirms the random component selection path is absent from the indexed controller.
- `BallisticsEngine` callback receives the actual hit body and hit position.
- Full Roblox Studio acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Do not reintroduce random component selection after a projectile collision. For Roblox fallback hits, use `hitBody.RobloxPart` as the authoritative component candidate and pass it through `ComponentAuthority` validation. Keep the Roblox environment as the execution target; the native 2D physics model is behavioral/source guidance, not a reason to recreate Java architecture.
