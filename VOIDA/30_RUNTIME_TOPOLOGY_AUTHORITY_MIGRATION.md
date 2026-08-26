# Runtime Topology Authority Migration

## Commit
`2c52096ecc669f7eda9ce0d55b025fa77888eb5d`

## Changed
- Removed legacy WeldConstraint/proximity reconstruction from `ShipSocketGraph:RebuildFromModel()`.
- Runtime graph rebuild now consumes explicit `ParentNodeId`, `ParentSocketId`, and `ConnectedSocketId` metadata only.
- Unknown/missing structural relationships no longer get synthesized from physical weld proximity.
- `FindBestSnap()` remains because it is an intentional build/editor placement operation, not runtime reconstruction of existing topology.

## Why
The structural graph is authoritative. Physical welds are a projection and cannot be allowed to silently invent gameplay topology after load or mutation.

## Resulting state
Runtime ship topology is now metadata-driven and fail-closed. Existing legacy weld evidence can no longer alter authoritative graph state during normal rebuild.

## FUTURE AGENT NOTE:
- `StructuralAuthority` is still the only runtime structural mutation boundary.
- `ShipSocketGraph.FindBestSnap()` is editor/build snapping only.
- `ShipSocketGraph.RebuildFromModel()` requires explicit relationship metadata for non-root nodes.
- `WeldConstraint` should be treated as Roblox physical projection, never topology source.
- Legacy migration/import tooling may be created separately if old saves need conversion.
