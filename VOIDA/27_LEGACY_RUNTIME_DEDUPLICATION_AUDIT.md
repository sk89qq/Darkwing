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

## Archive

Historical entries are retained under `VOIDA/ARCHIVE/LEGACY_RUNTIME/VoidHunters/` so the old generation is not silently lost. Archive entries are explicitly non-runtime and carry original blob SHA/provenance where available.

## Duplicate-state findings

1. **Component identity:** old nested component table used display-name lookup in legacy combat code; current authority requires explicit `ComponentType`/shared component authority.
2. **Combat HP:** old controller maintained private `partHP`; this conflicts with canonical `ComponentAuthority` state.
3. **Weapon state:** old controller maintained private cooldown/energy tables; this conflicts with the native-parameter/resource authority direction.
4. **Socket graph:** nested file was only a re-export, so retaining it created an unnecessary second import surface.
5. **Audio:** old sound IDs/volumes are prototype choices and have not been source-verified; retaining them as runtime truth would violate the forensic completion policy.
6. **Root versus nested components:** the root-level component file is the richer connection/mesh/topology generation and is therefore the active definition surface. The nested 13-type table is now archived.

## Remaining duplicate audit targets

- Search all server/client imports for legacy `VoidHunters.*` paths and migrate any surviving callers to shared/root authority.
- Audit Arena/PvP managers for private copies of cooldown, repair, shield, capacitor, respawn, and match-state values.
- Audit `SharedSource`/`ClientSource` mirrors separately; these may be forensic source mirrors rather than runtime duplicates and must not be deleted merely because names overlap.
- Do not delete forensic registries or original-data files solely because a newer runtime projection exists; mark them superseded instead.

## Verification rule

This cleanup establishes **runtime deduplication**, not forensic parity. It does not upgrade inferred shield/audio/physics behavior to VERIFIED.
