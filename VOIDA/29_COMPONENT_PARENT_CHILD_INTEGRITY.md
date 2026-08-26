# Component Parent/Child Integrity Migration

## Commit
`49d2989e50a9ece571096b7a9498a2bcbbc90b58`

## Changed
- Hardened `ComponentAuthority.SetParent()` against self-parenting and ancestry cycles.
- Reparenting now removes the child from the old parent's `Children` map before adding it to the new parent.
- Repeated assignment to the same parent repairs the inverse `Children` entry instead of duplicating semantics.
- `Clear()` removes the component from its parent's inverse map, clears child references, clears `ParentComponentId`, and drops the runtime state record.
- Invalid parent instances fail closed.

## Why
The authoritative structural model requires parent and child state to remain mutually consistent. Stale inverse references can corrupt graph traversal, detach selection, persistence, and later recomputation.

## Resulting state
`ComponentAuthority` now enforces the basic bidirectional parent/child invariant at its runtime boundary.

## FUTURE AGENT NOTE:
- `ComponentAuthority` remains the runtime component-state authority.
- `StructuralAuthority` remains the only structural mutation boundary.
- `ParentPart`/`ParentId` are authoritative runtime links; `ParentComponentId` is an Instance mirror.
- `Children` is keyed by child component ID.
- Cycle rejection is local to `SetParent`; graph-level socket legality remains `ShipSocketGraph`/`StructuralAuthority` responsibility.
