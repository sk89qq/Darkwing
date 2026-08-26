# VOIDA — Socket Graph Authority Migration Note

## Commit
`9a4dcb030cb5cc3c625d4143e14cbf01cdcc7732`

## SOURCE:
Current `ShipSocketGraph.luau` and canonical `VoidHunterComponents` connection definitions, evaluated against the raw-first-pass authority rules.

## OLD:
- Unknown component types silently received invented generic four-way sockets.
- Graph rebuild inferred `ComponentType` from `BasePart.Name` when attributes were absent.
- Graph rebuild treated weld/proximity pairing as normal topology reconstruction.
- Snap logic could fall back to an arbitrary first InConnect even when no OutConnect existed.
- Attach did not persist explicit parent/child hardpoint relationship metadata.
- Reachability additionally verified topology through physical weld discovery.

## NEW:
- Unknown component types return no sockets and fail closed.
- Every graph node requires an explicit valid `ComponentType` present in both `Components.Types` and `Components.Connections`.
- Canonical attachments persist `NodeId`, `ParentNodeId`, `ParentSocketId`, and `ConnectedSocketId`.
- Explicit relationship metadata is applied before any legacy physical migration adapter.
- Existing weld/proximity pairing is restricted to a legacy import path and cannot invent component definitions or socket definitions.
- Snap candidates only use defined, unoccupied `InConnect` receivers and defined `OutConnect` plugs.
- Reachability traverses the authoritative graph relationships rather than rediscovering topology from arbitrary welds.
- Serialization records explicit parent relationship fields.

## TEST:
`ShipSocketGraph.luau` was replaced as a complete file and re-read from GitHub. The resulting blob SHA is `948f2e6c3c4b521f2a5301eef06ede3a3a9f433a`.

`VoidHunterComponents.luau` was inspected to confirm that connection definitions are the authoritative source of socket topology. Existing component definitions include both conventional hulls and definitions with zero `OutConnect` entries; these remain source-backed and are not silently rewritten by this migration.

## STATUS:
IMPLEMENTED. Runtime behavior remains pending Roblox Studio acceptance testing and component-definition parity review.

## FUTURE AGENT NOTE:
Treat `Components.Types` + `Components.Connections` as the only valid socket-definition authority. Do not restore name-based type inference or generic socket invention. `StructuralAuthority` must call `FindBestSnap`/`AttachComponent` using explicit component types and should migrate remaining spawn/build code away from raw WeldConstraint reconstruction. Before changing zero-OutConnect definitions, trace their original semantics from the raw decompile; do not infer a replacement connector model.
