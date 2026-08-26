# VOIDA — Weapon Authority Migration Note

## Commit
`e00546dfcfb6a7d43ef35b72af755f0b1e1c8290`

## SOURCE:
Current Roblox weapon controller plus canonical runtime services, evaluated against the raw-first-pass authority rules.

## OLD:
`partHealth`, `partMaxHealth`, `activeShips`, controller-local component-name lookup, hull-name heuristics, workspace-wide enemy ship scan, legacy duplicate lifecycle registration.

## NEW:
`ComponentAuthority`, `ShipRegistry`, `StructuralAuthority`, `Components.Types[*].IsHull`, registry-based ship targeting, spatial queries for transient targets, `task.*` scheduling, and standard `Workspace` service naming.

## TEST:
Controller was replaced as a complete file and re-read from GitHub. The replacement preserves the existing weapon families present in the controller: MassDriver, PlasmaBall, PlasmaTurret, MissileLauncher, DroneBay, Laser, PointDefence, and ScramblerPulse. New blob SHA: `58bf876ddbd3058f3173547e0e0a5592a7b2bfb1`.

## STATUS:
IMPLEMENTED. Runtime parity is not claimed until Roblox Studio acceptance testing.

## FUTURE AGENT NOTE:
Do not reintroduce compatibility HP dictionaries or a local player-to-ship map. `VoidHunterShipSpawner` already owns ship creation and registration through `ShipRegistry`. Combat consumes `ShipRegistry`, `ComponentAuthority`, and `StructuralAuthority`. Raw-source uncertainty remains `RAW-GAP` rather than being guessed.
