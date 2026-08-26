# VOIDA — Shield Forensics Boundary

## SOURCE:
- `VOID_HUNTERS_FORENSIC_ENGINEER_BLUEPRINT.md`
- `java_full.txt`
- Existing `ReplicatedStorage/Shared/Combat/ShieldSystem.luau`

## RECOVERED:
The original client exposes these shield configuration keys:
- `SHIELDS_TOGGLE_COOLDOWN`
- `SHIELDS_DIRECTIONAL_IDLE_ENERGY_USAGE`
- `SHIELDS_DIRECTIONAL_RADIUS`
- `SHIELDS_DIRECTIONAL_ARC`
- `SHIELDS_DAMAGE_ENERGY_CONVERSION`

The original client also has dedicated directional shield arc particle configuration.

## BLOCKED:
The currently indexed raw source does not expose enough verified consumer context to map the five configuration values into exact runtime equations and units without inference.

## CURRENT ROBLOX STATE:
- `ShieldSystem` remains the Roblox runtime authority.
- Name-based shield discovery has been removed.
- Existing prototype/inferred numerical behavior remains unchanged and explicitly marked inferred.
- No Roblox implementation is reverted because native Roblox execution is the project target.

## FUTURE AGENT NOTE:
When the shield consumer method or resource table is recovered, replace only the inferred numerical/control-flow sections and retain the existing `ShieldSystem` API. Do not recreate Java classes. Use the recovered values to drive idiomatic Roblox state/visual projection.

## STATUS:
BLOCKED
