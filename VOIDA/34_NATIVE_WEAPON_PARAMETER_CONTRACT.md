# VOIDA — Native Weapon Parameter Contract

## SOURCE:
`java_full.txt` configuration-name evidence plus `VOID_HUNTERS_EXTRACTION_DIRECTIVES.md` weapon/defense directives.

## OLD:
Weapon-specific numeric/configuration values were distributed across Roblox implementation modules without a single native-key provenance surface.

## NEW:
`src/roblox/ReplicatedStorage/Shared/Combat/NativeWeaponConfig.luau` defines one canonical contract for the source-confirmed parameter families:
- Machine Gun
- Mass Driver
- Laser Beam
- Missile Launcher
- Countermeasure/Scrambler
- Grappling Hook

The contract stores native parameter keys and expected semantic units while intentionally leaving numeric payloads unresolved until their source consumers are recovered.

## TEST:
- Native keys cross-checked against `java_full.txt` and extraction directives.
- No inferred numeric value was inserted.
- Runtime Roblox weapon definitions remain unchanged.

## STATUS:
EXTRACTED / ROBLOX-MAPPING

## FUTURE AGENT NOTE:
When a numeric parameter is recovered from a native consumer, add the exact value, source class/method, unit/scale, and confidence to this contract. Do not replace native time/angle/force units with Roblox units until the transformation chain is known. The contract is subordinate to raw source evidence and does not authorize guessed values.

## Git-ready commit message:
`docs: document native weapon parameter contract`
