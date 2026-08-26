# Blueprint Primitive Serialization

## Commit
`a246b76a2f794e779319ae34bb1aaba450a0ec21`

## Changed
- Added `Shared/Ship/BlueprintSerializer.luau`.
- Serialization is primitive-only: version, component IDs, component types, parent IDs/hardpoint IDs, `{x,y}` position, and numeric angle.
- Rejects unsupported versions, unknown component definitions, malformed numeric fields, and non-primitive payloads.
- Capture reads authoritative `ComponentAuthority` state and existing structural relationship attributes.
- Runtime reconstruction remains a separate operation and must use `StructuralAuthority`.

## Why
Blueprints must survive reload without embedding Roblox runtime objects or bypassing the structural graph solver.

## Resulting state
A canonical primitive blueprint representation now exists for capture/encode/decode. Full load/build sequencing remains an integration task.

## FUTURE AGENT NOTE:
- `BlueprintSerializer` owns primitive serialization only.
- `ComponentAuthority` remains component state authority.
- `StructuralAuthority` remains graph mutation authority.
- `ShipSocketGraph` remains the hardpoint solver.
- `Position` is logical 2D (`x`,`y` where `y` corresponds to world Z).
- `Angle` is the logical 2D rotation in radians used by the Roblox physics representation.
