# VOIDA — Component Definition Validation

## SOURCE:
- `ReplicatedStorage/VoidHunterComponents.luau`
- Existing `ShipSocketGraph` / `StructuralAuthority` requirements for explicit connector topology.

## OLD:
- Connector-count divergence could only be noticed manually during graph reconstruction.
- The large authoritative component table could not be audited through a single runtime boundary.

## NEW:
- Added `Shared/Ship/ComponentDefinitionValidator.luau`.
- Validator is read-only and never mutates the authoritative catalog.
- It checks declared `InConnectCount` against `InConnectPositions`.
- It checks declared `OutConnectCount` against the available explicit output-position representation.
- Structural systems can use the validator to fail closed instead of silently inventing connectors.

## TEST:
- Uses the existing `Components.Connections` catalog directly.
- No geometry or component values are rewritten.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Treat `VoidHunterComponents.luau` as the authoritative Roblox component catalog. Use `ComponentDefinitionValidator.ValidateAll()` during development/audit passes. Do not auto-correct mismatches from the validator; compare each mismatch to raw source and update only with source evidence.
