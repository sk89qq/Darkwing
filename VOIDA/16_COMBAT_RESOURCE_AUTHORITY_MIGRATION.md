# VOIDA — Combat / Shield / Energy / Repair Authority Migration

## Commit sequence
- Shield definition migration: `bd83903d712ad11bf5488acdb0d87a62b4532b93`
- Shield integration correction: `f0b5fb9cb9639b6249074337c272301268d2b383`
- Capacitor migration: `50522933486d3eae3d14d1a8c8d2a63cbca17a0b`
- PvP authority migration: `070a642ffc7b5f39beeac5deec922bbc32221506`
- Native resource boundary: `3d8ea75eae8035261081b805a50ece7004ff3649`
- Native shield consumer wiring: `b6eeb3c5b2a2211eef6dabf17411f6f8eb53f959`

## SOURCE:
Current Roblox combat/resource modules plus recovered native configuration and `VoidHunterComponents.Types`. Raw-source numerical parity remains subject to the raw forensic authority rules.

## OLD:
- Shield runtime searched the workspace for instances named `ShieldGenerator` / `Shield Generator`.
- Shield fallback state was coupled to legacy object names.
- Capacitor runtime searched component names such as `Reactor`, `Capacitor`, and `Battery` and fabricated subsystem values from those names.
- PvP owned a private player -> ship map.
- PvP inferred component type from `Components.Types[*].Name == part.Name`.
- PvP repair directly edited `ComponentHP` / `MaxHP` attributes.
- PvP destruction directly subtracted and wrote HP attributes, manually destroyed welds, and directly destroyed components.
- PvP nearest-enemy lookup scanned all Workspace descendants.
- PvP team comparison read raw string attributes instead of the canonical `TeamIdentity` vocabulary.
- PvP shield toggle attempted a server-side `RemoteEvent:FireServer`, which is not a valid server-to-server routing mechanism.

## NEW:
- Shield identity comes exclusively from explicit `ComponentType` metadata and `Components.Types` definitions.
- Shield configuration aggregates authoritative `ShieldOutput`, `ShieldRadius`, `DamageToEnergy`, `MinEnergyToActivate`, and optional explicit energy fields.
- Shield registration uses `ShipRegistry.GetAll()` rather than workspace-wide ship discovery.
- Shield player actions resolve the caller's ship through `ShipRegistry` and validate ownership before state mutation.
- Capacitor configuration reads explicit component definition fields (`EnergyRegen`, `MaxEnergyBoost`, `EnergyCapacity`) and never compares Instance.Name.
- PvP ship ownership is resolved exclusively through `ShipRegistry`.
- PvP component lookup requires an explicit valid `ComponentType` present in `Components.Types`.
- PvP friendly/enemy decisions use `TeamIdentity`.
- PvP repair calls `ComponentAuthority.Repair`.
- PvP damage calls `ComponentAuthority.ApplyDamage`.
- Non-core component destruction routes through `StructuralAuthority.DetachComponent`.
- Core destruction unregisters the ship before destroying the physical Model.
- Enemy search iterates the authoritative `ShipRegistry` snapshot rather than scanning every Workspace descendant.
- Server scheduling uses `task.*` and monotonic `os.clock()` timing for the migrated state paths.
- `NativeResourceProfile` groups recovered native shield, repair, and burst-energy keys without applying Roblox conversion.
- `ShieldSystem` now consumes the recovered native directional radius/arc and shield energy parameters through that boundary; its unrecovered absorption matrix and reboot constants remain explicitly inferred.

## TEST:
- Modified combat/resource files were replaced as complete UTF-8 files and re-read from GitHub.
- `ShieldSystem` imports and consumes `NativeResourceProfile` for recovered shield parameters.
- `ShipRegistry`, `ComponentAuthority`, `TeamIdentity`, and `StructuralAuthority` imports resolve through canonical paths.
- The previous PvP `playerShips` state table is removed from the live implementation.
- Name-based component matching is removed from the migrated shield/capacitor/PvP paths.
- Full Roblox Studio runtime acceptance remains required before marking numerical/behavioral parity `VERIFIED`.

## STATUS:
IMPLEMENTED. Forensic parity remains PARTIAL where source formulas or constants are not fully recovered.

## FUTURE AGENT NOTE:
`ComponentType` is the only valid runtime component identity. `Components.Types` is the configuration authority for component capabilities. Do not restore Instance.Name matching. `ShipRegistry` owns player<->ship relationships; do not create a second player ship map. `ComponentAuthority` owns component HP/state; do not write `ComponentHP`, `MaxHP`, or equivalent gameplay state directly. `StructuralAuthority` owns structural mutation; do not destroy attached components directly from combat code. `TeamIdentity` owns Yellow/Blue vocabulary. Do not replace source-resolved native values with inferred defaults. Prototype shield absorption/reboot constants remain inferred until raw source evidence upgrades them.
