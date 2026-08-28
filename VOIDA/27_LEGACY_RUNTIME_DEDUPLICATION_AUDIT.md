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

`RepairSystem` delegates component health mutation to `ComponentAuthority`, so repair does not introduce a second HP authority. `NativeWeaponRuntime` bridges source-resolved reload and energy parameters through `NativeParameterResolver`, with the native 50-tick/second time conversion isolated at the consumer boundary.

## Duplicate-state findings

1. **Component identity:** old nested component table used display-name lookup in legacy combat code; current authority requires explicit `ComponentType`/shared component authority.
2. **Combat HP:** old controller maintained private `partHP`; this conflicts with canonical `ComponentAuthority` state.
3. **Weapon state:** old controller maintained private cooldown/energy tables; the native runtime now provides the source-resolved reload/energy contract for currently mapped weapons.
4. **Socket graph:** nested file was only a re-export, so retaining it created an unnecessary second import surface.
5. **Audio:** old sound IDs/volumes are prototype choices and have not been source-verified; retaining them as runtime truth would violate the forensic completion policy.
6. **Shield:** `ShieldSystem` still owns its live shield state because no separate source-verified shield authority has yet been established; its absorption/reboot constants remain explicitly `[INFERRED]`.

## Remaining reconciliation targets

- Verify actual runtime callers of `NativeWeaponRuntime` and migrate any remaining weapon consumers that still read prototype weapon timing/energy fields.
- Audit Arena/PvP managers for private copies of shield, capacitor, respawn, and match-state values.
- Recover the original shield configuration/control-flow consumers before replacing the explicitly inferred `ShieldSystem` model.
- Audit `SharedSource`/`ClientSource` mirrors separately; these may be forensic source mirrors rather than runtime duplicates and must not be deleted merely because names overlap.
- Do not delete forensic registries or original-data files solely because a newer runtime projection exists; mark them superseded instead.

## Verification rule

This cleanup establishes **runtime deduplication**, not forensic parity. It does not upgrade inferred shield/audio/physics behavior to VERIFIED.
