# VOIDA — Native Component Provenance Anchors

## SOURCE:
- `VOID_HUNTERS_EXTRACTION_DIRECTIVES.md`
- raw/qualitative `wlb.java` component-definition evidence
- `java_full.txt` configuration/name strings
- `src/roblox/ReplicatedStorage/VoidHunterComponents.luau`

## Directly source-supported facts
- Native component definition table: `hab.g[56]`.
- Component object carries type ID, health, connection point X/Y, connected angle, current connected angle, final transform, final outline, subcomponents, hardpoints, weapon/thruster/grapple/generic behavior.
- Native configuration includes component/weapon identifiers for Machine Gun, Mass Driver, Plasma Ball, Ubercannon, Fighter Bay, Spinning Blade, Bomblet Spray, Laser Beam, Sniper Cannon, Grappling Hook, Missile Launcher, Torpedo, Phased Energy Beam, Point Defence Laser, and Countermeasure/Scrambler.
- Native configuration includes exact parameter-name families for those behaviors, but the currently exposed qualitative corpus does not provide every numeric consumer value.
- The raw source explicitly requires numeric component IDs to be mapped to human-readable names through registration/label tables rather than declaration order or wiki ordering.

## Roblox policy
- Keep `Components.Types` as the runtime implementation authority.
- Do not attach fabricated `NativeTypeId` values merely from Roblox names.
- Where a native ID/name mapping is not source-proven, leave the mapping unresolved.
- Preserve the existing Roblox geometry/visual implementation; source reconciliation should modify it only when native evidence is definitive.

## Current resolved mapping class
The following Roblox names are source-vocabulary matches, but are **not** declared native-ID verified merely from their names:
`MachineGun`, `MassDriver`, `PlasmaBall`, `Ubercannon`, `FighterBay`, `SpinningBlade`, `BombletSpray`, `Laser`, `SniperCannon`, `GrapplingHook`, `MissileLauncher`, `Torpedo`, `PhasedEnergyBeam`.

`PointDefenceLaser` and `Countermeasure`/scrambler remain source-vocabulary matches where the live Roblox table exposes those identities.

## TEST:
- Source vocabulary cross-checked against `java_full.txt` and extraction directives.
- No native IDs were guessed or inserted into Roblox definitions.

## STATUS:
EXTRACTED / ROBLOX-MAPPING

## FUTURE AGENT NOTE:
Use this file to distinguish name-level source evidence from native numeric-ID proof. The next authoritative step is direct registration/label-table recovery, then slot-by-slot component mapping. Numeric weapon constants must be recovered from actual configuration consumers; do not derive them from current Roblox values.

## Git-ready commit message
`docs: record native component provenance anchors`
