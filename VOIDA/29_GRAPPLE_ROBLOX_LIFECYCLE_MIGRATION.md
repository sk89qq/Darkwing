# 29 — GRAPPLE ROBLOX LIFECYCLE MIGRATION

## STATUS
IMPLEMENTED / PARTIAL

## SOURCE BASIS
The forensic reference confirms the original `GrapplingHook` and `GrappleLauncherBehaviour` classes and the lifecycle:

`idle -> fired -> traveling -> attached -> reel/constraint -> detach/break/retract`

Confirmed parameter family:
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

The source documentation also establishes that grapple interaction is part of the original physical body/component architecture, not an abstract inventory action.

## ROBLOX IMPLEMENTATION
Added:
`src/roblox/ReplicatedStorage/Shared/Combat/GrappleSystem.luau`

The module provides:
- explicit grapple states
- fire/cooldown validation
- Roblox raycast target acquisition
- traveling/attachment transition
- `Attachment` + `RopeConstraint` projection
- reel-in handling
- rope break handling
- retract/return-to-idle handling
- explicit recovered configuration names

## ROBLOX-FIRST RULE
The implementation uses Roblox-native `RaycastParams`, `Attachment`, and `RopeConstraint` because Roblox is the target runtime. It does not attempt to emulate the original Java object model.

## NOT YET SOURCE-VERIFIED
- exact numeric values for every grapple configuration
- exact native target eligibility (ship vs asteroid vs debris vs all Body types)
- exact native spring-force/extension-force equations
- exact native visual rope/hook presentation

These remain source-recovery tasks, not invented runtime behavior.

## GIT-READY COMMIT MESSAGE
`feat: add Roblox-native grapple lifecycle boundary`

## FUTURE AGENT NOTE:
- Keep `GrappleSystem` under `ReplicatedStorage.Shared.Combat`.
- Preserve the recovered parameter names exactly when later values are imported.
- Do not create a second grapple authority in a weapon controller.
- `StructuralAuthority` remains authoritative for structural mutation.
- `ShipRegistry` remains authoritative for ship ownership.
- When exact source numeric force/rope equations are recovered, replace only the corresponding calculation paths; retain the Roblox constraint projection.
- If native target eligibility is recovered, change `FindTarget` filtering to match it exactly rather than broadening target classes by design.
