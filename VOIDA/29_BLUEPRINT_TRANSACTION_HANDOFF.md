# VOIDA 29 — BLUEPRINT TRANSACTION HANDOFF

## SOURCE:
- `VOIDA/00_RAW_FORENSIC_REFERENCE.md`
- `BlueprintSerializer.luau`
- `BlueprintLoader.luau`
- `StructuralAuthority.luau`

## CURRENT STATE:
`BlueprintSerializer` uses Version 2 with explicit stable logical `BlueprintComponent.Id` values. `ParentId` references those logical IDs; hardpoint identifiers remain separate.

`BlueprintLoader` validates the complete primitive blueprint, rejects duplicate IDs, invalid component definitions, missing parents, multiple roots, self-parenting, and dependency cycles, then stages Roblox parts in parent-before-child order.

## REMAINING ISSUE:
A failure after one or more calls to `StructuralAuthority.AttachComponent` can require rollback of already-applied graph topology, not merely destruction of staged Roblox parts. The loader therefore remains `PARTIAL` until a transaction boundary exists in `StructuralAuthority` or reconstruction is changed to perform all graph commits through a rollback-capable batch operation.

## RULE:
Do not claim full transactional blueprint loading until both graph topology and created Roblox instances roll back together on failure.

## FUTURE AGENT NOTE:
Roblox remains the runtime target. Do not solve this by bypassing `StructuralAuthority` or by mutating `ShipSocketGraph` directly from the loader. Add the smallest rollback-capable batch API to `StructuralAuthority`, then make `BlueprintLoader.Load` use it. Preserve Version 2 logical IDs and keep runtime `ComponentId` values distinct from persistence IDs.

## STATUS:
PARTIAL
