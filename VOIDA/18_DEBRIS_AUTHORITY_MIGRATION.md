# VOIDA — Debris Authority Migration

## Commit
`91d886bb495c0df73923387fe8e2cd9e07582a68`

## SOURCE:
- Raw forensic reference identifies `nbb.java` as the native debris specialization.
- Raw port requirements prohibit invented component identity where the original component identity is recoverable.
- Existing Roblox `VoidHunterDebrisManager` was the designated debris/collection layer, but its component selection was random and therefore not authoritative.

## OLD:
- `SpawnDebris(position, dropChance)` randomly selected any entry from `Components.Types`.
- Debris stored `ComponentName`, which was a derived/random choice rather than the destroyed component identity.
- Collection searched for an ancestor named `Ships`.
- Animation called `task.wait()` twice in one loop iteration, coupling bobbing and rotation to different waits.
- `TweenService` and several unused imports were retained.

## NEW:
- `SpawnDebris(position, componentType, dropChance?, initialVelocity?)` requires explicit component identity.
- Component type is validated against `Components.Types`; unknown types fail closed.
- Debris stores canonical `ComponentType` and `DebrisKind` attributes.
- Collector resolution walks model ancestors until `IsShip == true` rather than requiring a literal container name.
- Inventory collection continues through `VoidHunterBuilderManager.AddComponentToInventory`.
- Animation uses one scheduler wait per frame with `os.clock()` elapsed time.
- Initial velocity can be preserved as mirrored metadata without inventing a native force value.

## TEST:
- Full UTF-8 file replacement committed and blob returned by GitHub.
- No random component selection remains in the migrated debris manager.
- Component identity is explicit and definition-validated.
- Runtime behavior remains `IMPLEMENTED`, not `VERIFIED`, until Roblox Studio tests confirm collection, visuals, cleanup, and native parity.

## STATUS:
IMPLEMENTED.

## FUTURE AGENT NOTE:
`VoidHunterDebrisManager` is a presentation/collection layer, not a component authority. The destruction caller must provide the actual canonical `ComponentType` from `ComponentAuthority` / `StructuralAuthority`. Never reintroduce random component selection. Preserve `ComponentType` as the canonical identity and use `Components.Types` only for validated configuration. Exact native debris force/lifetime/cleanup remains subject to raw `nbb` evidence and must not be guessed.
