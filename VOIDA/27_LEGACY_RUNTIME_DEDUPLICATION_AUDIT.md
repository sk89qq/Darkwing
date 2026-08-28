# Legacy Runtime Deduplication Audit

Date: 2026-08-28
Scope: `src/roblox/ReplicatedStorage/VoidHunters` versus current shared/root authority.

## Result

The nested `VoidHunters` directory contained an older prototype generation that duplicated concepts now owned by the current shared/root implementation.

### Removed from active runtime

| Removed path | Classification | Replacement / authority | Status |
|---|---|---|---|
| `src/roblox/ReplicatedStorage/VoidHunters/VoidHunterWeaponController.luau` | Prototype combat controller | `Shared/Combat/ComponentAuthority`, `Shared/Combat/StructuralAuthority`, native weapon runtime | SUPERSEDED |
| `src/roblox/ReplicatedStorage/VoidHunters/VoidHunterComponents.luau` | 13-type prototype component table with inferred combat tuning | `src/roblox/ReplicatedStorage/VoidHunterComponents.luau` + structural authority | SUPERSEDED |
| `src/roblox/ReplicatedStorage/VoidHunters/VoidHunterSoundManager.luau` | Prototype Roblox-library audio implementation | forensic asset/audio workstream | SUPERSEDED / UNVERIFIED |
| `src/roblox/ReplicatedStorage/VoidHunters/ShipSocketGraph.luau` | Duplicate re-export facade | `Shared/ShipSocketGraph` | SUPERSEDED |

## Reference sweep — 2026-08-28 retry

The live nested `src/roblox/ReplicatedStorage/VoidHunters` path was queried directly after the deletions and returns **404 / Not Found**, confirming that the deleted runtime directory is no longer present.

Repository code-search sweeps were run for the deleted controller path, `VoidHunterComponents`, `VoidHunterSoundManager`, the legacy archive path, the old `require(ReplicatedStorage.VoidHunters` pattern, `partHP`, `shipEnergy`, and `ComponentAuthority`. The repository search endpoint returned no indexed matches for those queries. Because GitHub's code-search index can be incomplete, that result is recorded as an audit signal rather than proof of zero textual references.

## Current authority check

`Shared/Combat` contains the intended authority/runtime set including `ComponentAuthority`, `NativeGameplayConfig`, `NativeParameterResolver`, `NativeWeaponConfig`, `NativeWeaponRuntime`, `RepairSystem`, and `ShieldSystem`. `ComponentAuthority` explicitly owns component HP/state and requires an explicit `ComponentType`; it does not infer gameplay state from Part names.

`RepairSystem` delegates component health mutation to `ComponentAuthority`, so repair does not introduce a second HP authority.

`NativeWeaponRuntime` is now the source-resolved timing/energy boundary for every weapon type for which native reload/energy keys were recovered: `MachineGun`, `MassDriver`, `Laser`, `PhasedEnergyBeam`, `BombletSpray`, `SniperCannon`, `Torpedo`, `FighterBay`, `MissileLauncher`, `PointDefence`, and `ScramblerPulse`. Native time conversion remains isolated at 50 native ticks/second. No Roblox-unit conversion for damage/force/speed was introduced.

The live `ServerScriptService/VoidHunterWeaponController.luau` was re-read after the previous change. Its fire and scrambler paths already call `NativeWeaponRuntime.GetReloadSeconds()` and `NativeWeaponRuntime.GetEnergyCost()` first, falling back to component-definition timing/energy only when no native contract exists. Therefore the consumer wiring was already present; this pass expanded the native contract coverage rather than duplicating the consumer logic.

## Duplicate-state findings

1. **Component identity:** old nested component table used display-name lookup in legacy combat code; current authority requires explicit `ComponentType`/shared component authority.
2. **Combat HP:** old controller maintained private `partHP`; this conflicts with canonical `ComponentAuthority` state.
3. **Weapon state:** the active controller keeps only per-instance last-fire timestamps; source-resolved reload/energy values now come from `NativeWeaponRuntime` for all recovered native contracts.
4. **Socket graph:** nested file was only a re-export, so retaining it created an unnecessary second import surface.
5. **Audio:** old sound IDs/volumes are prototype choices and have not been source-verified; retaining them as runtime truth would violate the forensic completion policy.
6. **Shield:** `ShieldSystem` still owns its live shield state because no separate source-verified shield authority has yet been established; its absorption/reboot constants remain explicitly `[INFERRED]`.

## Newly identified runtime defect

The active weapon controller still imports `ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterSoundManager")`, while the entire `ReplicatedStorage/VoidHunters` runtime directory was intentionally deleted. This is a stale legacy import and must be removed or migrated to a canonical audio boundary before the controller can be considered runtime-clean. Do not resurrect the archived prototype sound manager as gameplay truth.

## Remaining reconciliation targets

- Remove/migrate the stale `VoidHunterSoundManager` import and calls without restoring prototype audio IDs as authoritative data.
- Audit Arena/PvP managers for private copies of shield, capacitor, respawn, and match-state values.
- Recover the original shield configuration/control-flow consumers before replacing the explicitly inferred `ShieldSystem` model.
- Audit `SharedSource`/`ClientSource` mirrors separately; these may be forensic source mirrors rather than runtime duplicates and must not be deleted merely because names overlap.
- Do not delete forensic registries or original-data files solely because a newer runtime projection exists; mark them superseded instead.

## Verification rule

This cleanup establishes **runtime deduplication**, not forensic parity. It does not upgrade inferred shield/audio/physics behavior to VERIFIED.
