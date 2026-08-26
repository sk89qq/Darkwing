# VOIDA — Blueprint / Build Authority Migration

## Commit scope
Consolidates blueprint persistence, construction, placement, and multiplayer lifecycle around the canonical runtime boundaries.

## SOURCE:
- `VoidHunterBlueprintSystem.luau`
- `VoidHunterBuilderServer.luau`
- `VoidHunterBuilderManager.luau`
- `VoidHunterSyncManager.luau`
- `StructuralAuthority.luau`
- `ShipRegistry.luau`

## OLD:
- `VoidHunterBlueprintSystem` owned a second DataStore (`VoidHunterBlueprints`) and a flat slot/components schema.
- `VoidHunterBuilderServer` owned the newer versioned schema but still contained compatibility type-name inference.
- `VoidHunterBuilderManager` directly mutated `blueprint.Components` and used its own adjacency/overlap rules.
- `VoidHunterSyncManager` owned a second DataStore (`VoidHunters_ShipBlueprints_v1`) and a separate starter blueprint/session schema.
- Sync lifecycle cached its own player-to-ship map instead of using `ShipRegistry`.
- Builder `weld` actions could imply direct physical topology mutation.

## NEW:
- `VoidHunterBuilderServer` is the single canonical blueprint persistence/construction service.
- `VoidHunterBuilderManager` keeps only inventory/placement compatibility and routes physical placement through `StructuralAuthority`.
- `VoidHunterBlueprintSystem` is a superseded facade; it owns no datastore/schema/structural mutation logic.
- `VoidHunterSyncManager` is a superseded multiplayer facade; it owns no blueprint datastore and resolves current ships through `ShipRegistry`.
- Component type resolution in the builder is explicit and requires both `Components.Types` and `Components.Connections`.
- Placement consumes inventory only after successful `StructuralAuthority.AttachComponent` validation.
- Save operations use `BuilderServer.SaveBlueprint` and therefore the canonical V2 primitive-only schema.
- Legacy network action names remain only as compatibility endpoints; they do not create parallel structural authorities.

## TEST:
- All four affected modules were fully replaced and reread after commit.
- GitHub code search for `VoidHunterSyncManager` and `VoidHunterBlueprintSystem` returned no indexed caller matches (`incomplete_results=true`), so those searches are evidence-limited rather than exhaustive.
- The new build manager contains no direct blueprint mutation and no private ship map.
- `StructuralAuthority` remains the only public attach/detach/replace/sever mutation boundary.

## STATUS:
IMPLEMENTED. Full runtime acceptance remains pending Roblox Studio integration testing.

## FUTURE AGENT NOTE:
`VoidHunterBuilderServer` is the canonical persistence/construction owner. Do not add another DataStore or blueprint schema. `BuilderManager` may own inventory UX state but must route physical placement through `StructuralAuthority` and ownership through `ShipRegistry`. `VoidHunterBlueprintSystem` and `VoidHunterSyncManager` are compatibility facades only and should be deleted once all external callers are proven migrated. Preserve `normalizeBlueprint` only until stored legacy data has been migrated or explicitly deprecated; never reinterpret unknown component types by Part name.
