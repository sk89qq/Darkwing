# VOIDA — Component Authority Migration Note

## SOURCE:
`ComponentAuthority.luau` and `VoidHunterComponents.luau`.

## OLD:
`ComponentAuthority` could infer a component definition from `BasePart.Name` when `ComponentType` was absent.

## NEW:
Component binding is fail-closed. A part must carry an explicit `ComponentType` that exists in `Components.Types`. Gameplay no longer invents component identity from Roblox instance names.

## TEST:
`ComponentAuthority.Bind`, `IsComponent`, and all controller callers remain compatible with explicit component attributes created by the authoritative ship/component builders. Controller type discovery now consumes `ComponentAuthority` state.

## STATUS:
IMPLEMENTED. Runtime acceptance still required in Roblox Studio.

## FUTURE AGENT NOTE:
Do not restore name-based component inference. Unknown component identity is `RAW-GAP`/`UNKNOWN`, not a reason to fabricate topology or HP state. `ComponentAuthority` is the sole component-state owner.
