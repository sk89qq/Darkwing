# VOIDA — Weapon Resource Authority Migration

## Commit
`6df25cc3b6bd51a7f30ec39fe6060445081839f5`

## SOURCE:
- `src/roblox/ServerScriptService/VoidHunterWeaponController.luau`
- `src/roblox/ReplicatedStorage/Shared/Combat/CapacitorSystem.luau`
- Existing authority directives requiring one gameplay source of truth per subsystem.

## OLD:
- `VoidHunterWeaponController` maintained a private `shipEnergy` table containing current energy, max energy, regen, and shield-active mirror state.
- Weapon, scrambler, and drone paths mutated that private mirror while `CapacitorSystem` also tracked energy.

## NEW:
- `CapacitorSystem` is now the sole ship-energy state owner in weapon orchestration.
- `shipEnergy` was removed completely from `VoidHunterWeaponController`.
- Weapon firing consumes energy through `CapacitorSystem:Consume()`.
- Scrambler firing consumes energy through `CapacitorSystem:Consume()`.
- Drone spawning consumes energy through `CapacitorSystem:Consume()`.
- Heartbeat recharge uses `CapacitorSystem:Recharge()` and publishes only the diagnostic `EnergyPercent` mirror.
- Ship destruction clears only the canonical capacitor/shield runtime objects.
- Existing Roblox projectile, drone, point-defence, and remote behavior remains intact.

## TEST:
- Complete controller blob was fetched before replacement and replaced atomically.
- All former `shipEnergy` reads/writes were removed from the replacement.
- Existing `CapacitorSystem` APIs used: `Consume`, `Recharge`, `GetEnergyPercent`.
- Full Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
`CapacitorSystem` owns ship energy. Do not recreate `current/max/regen` state in combat controllers. `EnergyPercent` on the ship is diagnostic/presentation state only. `shipCapacitors[ship]` is a runtime-object cache pointing to the canonical capacitor instance, not a competing energy state. Shield state remains separate in `shipShields[ship]` until raw shield parity is recovered.
