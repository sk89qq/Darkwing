# VOIDA Foundation Audit

## Scope
This audit covers the existing Darkwing/VOIDA architecture after the forensic review and the first structural reconciliation pass.

## Canonical boundaries

```text
ComponentAuthority
    owns Component runtime state
        ↓
StructuralAuthority
    owns graph mutation
        ↓
ShipSocketGraph
    solves hardpoint/socket topology
        ↓
RigidBody2D / Roblox Assembly
    owns physical projection
```

Combat/match/UI systems consume these boundaries; they must not create parallel authoritative copies.

## Completed structural corrections

### 1. Completion-state honesty
`VOIDA/04_DIRECTIVES_AND_CHANGELOG.md` no longer treats code existence as forensic completion. `VERIFIED` now requires a scoped acceptance test plus source evidence.

### 2. Component authority
`ReplicatedStorage.Shared.Combat.ComponentAuthority` now owns per-component HP/state and exposes compatibility-safe bind, damage, repair, and destruction operations.

Instance Attributes are mirrors for diagnostics/persistence, not authoritative gameplay state.

### 3. Structural mutation boundary
`ReplicatedStorage.Shared.Ship.StructuralAuthority` now provides the intended attach/detach/replace/sever boundary. Detached subtrees remain physical Models under `Workspace.VoidHunterDebris` instead of being immediately deleted.

### 4. Builder convergence
`VoidHunterBuilderServer` now uses `StructuralAuthority.AttachComponent` for AutoBuild instead of nearest-neighbor welding. Manual detach also routes through the same structural boundary.

### 5. Team identity
`TeamIdentity` and `MatchState` now use historical Yellow/Blue team identifiers. Component category red/blue/etc. remains independent from ownership.

### 6. Damage-controller convergence
`VoidHunterWeaponController` now uses compatibility views over `ComponentAuthority` rather than owning an independent component-health dictionary. Structural destruction routes through `StructuralAuthority`.

## Explicitly not declared forensic-verified

- exact original critical-flash render threshold
- exact shield/capacitor formulas and values
- exact original physics numerical constants where control flow/resource data remains unresolved
- complete MissionCondition/MissionAction mode parity
- original audiovisual assets
- exact debris cleanup/persistence policy
- complete PvP/repair subsystem migration away from legacy state

## Acceptance gates for the next phase

### Component gate
Two or more component types can be bound, damaged, repaired, and queried without a subsystem-local HP dictionary.

### Structural gate
Removing a non-root component produces one connected detached physical assembly containing the surviving descendant components, preserving internal welds and inherited motion.

### Replacement gate
Replacement is detach + attach. The old component remains physically extant; replacement never mutates old HP into a repaired state.

### Build gate
Manual build and AutoBuild produce the same socket/graph topology for the same target configuration.

### Authority gate
Client requests cannot directly mutate HP or structural topology. Server modules own those mutations.

### Team gate
Yellow/Blue is the only team vocabulary in new systems. Component display colors remain category colors.

## Known legacy surfaces to migrate next

- `VoidHunterPvPSystems` private repair/ship state
- legacy `_G.VoidHunterMatchManager` compatibility bridge
- remaining ad-hoc `WeldConstraint` creation
- generic socket fallback in `ShipSocketGraph`
- string/name-based shield/capacitor classification
- Arena-only match manager versus the original Mission framework

## Design principle
Do not replace working subsystems merely to make them look cleaner. Introduce one authoritative boundary, migrate callers, then delete the obsolete parallel authority. This preserves functional behavior while eliminating state divergence.
