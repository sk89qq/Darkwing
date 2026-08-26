# VOIDA — Structural Replacement Migration

## Commit
`242f6c2ce9f37fec762fcefe1ef6af4d1de14d4b`

## SOURCE:
Current `StructuralAuthority.luau`, `ShipSocketGraph.luau`, and authoritative component connection definitions in `VoidHunterComponents.luau`, evaluated against the raw-first-pass repository authority rules.

## OLD:
`ReplaceComponent()` detached the existing component before validating/establishing the replacement. If the replacement failed, recovery restored only a physical root approximately and could leave topology/state inconsistent.

## NEW:
`ReplaceComponent()` now performs a pre-mutation validation phase, captures the existing parent node/socket identity, validates the replacement component definition, preserves the exact hardpoint, detaches only after validation succeeds, rebuilds the post-detach graph, and attaches the replacement to the preserved socket rather than selecting a new socket by proximity. Failed attachment removes the partial replacement and restores the original detached assembly/root attributes.

## TEST:
Static source review completed. Verified `ReplaceComponent()` now has four phases: validate, detach, exact-socket attach, rollback. Confirmed `Components.Types[componentType]` and `Components.Connections[componentType]` are required before mutation. Roblox Studio runtime acceptance remains required for physical topology/constraint behavior.

## STATUS:
IMPLEMENTED. Runtime parity is not claimed until Roblox Studio acceptance testing.

## FUTURE AGENT NOTE:
`StructuralAuthority` is the sole structural mutation boundary. `ShipSocketGraph` provides explicit socket topology. `ComponentAuthority` owns component state/HP. Do not reintroduce detach-first replacement. Preserve `oldParentId` + `oldParentSocketId`; replacement must return to the same authoritative hardpoint. Unknown component definitions must fail closed.
