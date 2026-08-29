# Grapple value integration record

Date: 2026-08-28

## Work performed

- Re-checked `GrappleSystem.luau` before making a change.
- Confirmed the existing constructor already accepts the complete recovered grapple configuration as a caller-supplied `Config`.
- Confirmed the ten native grapple parameter names are already represented in that contract.
- Added/recorded the recovered native grapple configuration through `GrappleNativeConfig.luau` rather than rewriting the existing runtime implementation.
- Preserved the established 50 native ticks/second relationship for the cooldown value.

## Decision

No modification to `GrappleSystem.luau` was necessary for the requested "only write new values" rule. The runtime contract is not itself a missing-value location; the new information belongs in the authoritative native configuration/resolver layer.

## Parameters covered

- `GRAPPLING_HOOK_AIMSPEED`
- `GRAPPLING_HOOK_AIMARC`
- `GRAPPLING_HOOK_COOLDOWN`
- `GRAPPLING_HOOK_FIRE_FORCE`
- `GRAPPLING_HOOK_SPRING_CONSTANT`
- `GRAPPLING_HOOK_MAX_EXTENSION8_FORCE`
- `GRAPPLING_HOOK_MAX_LENGTH`
- `GRAPPLING_HOOK_MIN_LENGTH`
- `GRAPPLING_HOOK_ROPE_CHANGE_RATE`
- `GRAPPLING_HOOK_ROPE_BREAK_LENGTH`
