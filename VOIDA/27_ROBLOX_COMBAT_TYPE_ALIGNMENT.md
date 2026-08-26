# VOIDA — Roblox Combat Type Alignment

## SOURCE:
- `ReplicatedStorage/Shared/Combat/CombatTypes.luau`
- `ReplicatedStorage/Shared/Combat/CapacitorSystem.luau`
- `ReplicatedStorage/Shared/Combat/ShieldSystem.luau`
- `ReplicatedStorage/Shared/Combat/BallisticsEngine.luau`

## OLD:
`CapacitorState` declared `EffectiveRegen` and `Overcharged`, while the live Roblox capacitor authority exposes `OverchargeCapacity` instead.

## NEW:
Aligned `CombatTypes.CapacitorState` with the actual `CapacitorSystem` public state fields:
- `MaxEnergy`
- `CurrentEnergy`
- `BaseRegen`
- `OverchargeCapacity`

Projectile and shield contracts remain unchanged.

## TEST:
- Compared the type declaration directly against the current module implementation.
- No runtime behavior was changed.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED

## FUTURE AGENT NOTE:
Treat the live Roblox modules as the type-contract source for fields used by callers. Do not add convenience fields to shared types unless a corresponding authority owns them.
