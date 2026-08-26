# 30 — REPAIR AUTHORITY MIGRATION

## STATUS
IMPLEMENTED / PARTIAL

## SOURCE BASIS
The forensic reference confirms:
- `ml.a(boolean, boolean, int)` performs health addition.
- Health is capped at the component definition maximum (`wfb.p`).
- Child components may receive overflow according to the original flags.
- The source exposes repair configuration families for player, AI, fighter, cooldown, active time, radius, and power.

## ROBLOX IMPLEMENTATION
Added:
`src/roblox/ReplicatedStorage/Shared/Combat/RepairSystem.luau`

The Roblox module provides:
- explicit repair mode states: `Idle`, `Active`, `Cooldown`
- activation/cooldown timing
- radius-based target resolver contract
- repair through `ComponentAuthority.Repair()` only
- max-health clamping through the canonical component authority
- no direct health attributes as a competing state source

## REMAINING RECOVERY
- exact native target selection order
- exact overflow propagation flags
- exact numeric configuration values and power consumption equation
- exact rendering/audio feedback

These remain source-recovery items and are not substituted with invented canonical values.

## GIT-READY COMMIT MESSAGE
`feat: add Roblox-native repair authority`

## FUTURE AGENT NOTE:
- `ComponentAuthority` remains the only HP authority.
- Never write component health directly from repair UI, weapon code, AI, or animation code.
- When exact native overflow behavior is recovered, implement it through an ordered target resolver and preserve the existing `ComponentAuthority.Repair()` cap semantics.
- Numeric configuration values should be imported under the original configuration names once source consumers are recovered.
