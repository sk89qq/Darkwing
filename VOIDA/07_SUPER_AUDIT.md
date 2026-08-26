# VOIDA SUPER AUDIT — 2026-08-26

## Purpose
Deep second-pass audit of the existing Darkwing Roblox implementation against the recovered Void Hunters client blueprint. This document is an anti-rediscovery memory for future agents: read this before re-auditing the same systems.

## Executive findings

### A. AUTHORITATIVE STATE
Current direction is correct:
`ComponentAuthority` = logical component state.
`StructuralAuthority` = graph mutation boundary.
`ShipSocketGraph` = socket/geometry solver.
Roblox Instances = physical/render projection.

Future agents MUST preserve this boundary. Do not add subsystem-local authoritative HP/type/parent state.

### B. CURRENT CRITICAL RISKS
1. Blueprint persistence originally wrote live CFrame values while the loader expected a different `Components/Pos/Rot` schema. This is now being normalized to a serializable graph-compatible versioned format.
2. Structural replacement must be atomic: validate the new attachment before severing the old component where possible. Never intentionally destroy a valid attachment because a replacement cannot snap.
3. Component ID generation must use a normal runtime-safe unique identifier, not editor/debug-only identity assumptions.
4. `ShipSocketGraph` still contains a generic four-way fallback for unknown component definitions. This must be removed once every real component type used by gameplay has authoritative hardpoints/geometry.
5. Existing combat code still contains legacy subsystem-local state and heuristics. Migrate callers to `ComponentAuthority` incrementally; do not recreate a second health system.
6. Existing shield/capacitor values are prototype values unless the corresponding original consumers are directly recovered. Do not upgrade their tags to CODE_VERIFIED.
7. Current Arena match manager is a prototype only. Do not expand it into all Void Hunters modes; port MissionBuilder/MissionCondition/MissionAction semantics instead.

## ComponentAuthority audit

### Keep
- weak-key state table
- BasePart binding
- component type identity
- health/max health
- destroyed/critical presentation state
- mirrored diagnostic Attributes

### Required invariant
There is exactly one authoritative HP value for any live component.
`part:GetAttribute("ComponentHealth")` is a mirror only.
Weapon, repair, UI, shield and AI code must ask ComponentAuthority for logical health.

### Required future migration
Delete `partHealth` / `partMaxHealth` dictionaries from weapon/combat code after all callers are migrated.

### Presentation rule
15% critical threshold remains isolated as USER_OBSERVED / pending code verification. Do not relabel it as CODE_VERIFIED.

## StructuralAuthority audit

### Correct abstraction
- Attach
- Detach
- Replace
- SeverDisconnected

### Invariants
- Core/root is never detached by child-detach logic.
- Detached connected subtrees remain extant physical assemblies.
- External welds must be removed from the detached subtree.
- Source ship must retain its remaining graph.
- World cleanup must not be invented.
- Detach inherits source motion until the recovered client proves another rule.

### Required future improvement
Use the same candidate/hardpoint result for both preview and commit so AutoBuild cannot place a part into a transform that the graph rejects.

## ShipSocketGraph audit

### Existing strength
The graph already models sockets, parent/child edges, root reachability and snap candidates.

### Remaining problem
`ExtractComponentSockets()` creates generic four-way sockets when no connection definition exists.
That behavior is convenient for prototyping but violates forensic fidelity.

Future behavior:
- Unknown component type → no valid socket definition → reject build with a structured diagnostic.
- Never silently create sockets for an unknown type.

### Second problem
Existing weld reconstruction uses proximity to infer socket pairs. This is acceptable only as migration/bootstrap behavior. It must not be used as authoritative runtime topology when explicit hardpoint metadata exists.

## Blueprint audit

### Required serialized format
Use versioned primitive-only data suitable for Roblox DataStore:
- strings
- numbers
- booleans
- arrays/maps

Do NOT persist CFrame, Vector3, Color3, Instance references, userdata, or BaseParts directly.

Blueprint V2 should preserve:
- component type
- component ID if available
- NodeId
- ParentNodeId
- relative position
- relative Euler rotation
- future hardpoint/connection identifiers

The loader must accept V2 `parts` and optionally legacy `Components` input while migrating all newly saved data to V2.

## Physics audit

### Preserve
`RigidBody2D`, mass points, COM, inertia, force/torque concepts.

### Do not silently call these original constants
unless directly sourced:
- Roblox velocity clamps
- fixed Y plane
- fallback chassis mass
- fallback inertia
- collision restitution
- maximum world radius
- Roblox safety limits

Tag these as ROBLOX_IMPLEMENTATION / INFERRED, not CODE_VERIFIED.

### Future efficient extraction
When an original `anb` method is needed:
1. Locate method signature.
2. Search all callers.
3. Identify every field it mutates.
4. Identify every configuration key it reads.
5. Map exact equation/state transition.
6. Only then modify Roblox physics.
Do not repeatedly inspect unrelated classes.

## Combat audit

### Current problem
WeaponController still contains multiple prototype paths and legacy state:
- local HP tables
- type-name detection
- arbitrary shield/energy behavior
- direct velocity mutation
- broad `Touched` collision handlers
- random ship-part hit selection in the ballistics callback

### Future rule
No weapon gets marked VERIFIED while hit-location selection, damage routing, armor interaction, projectile timing and energy cost remain inferred.

### Critical technical concern
`Touched` + arbitrary part selection can diverge sharply from deterministic swept projectile collision. Prefer the existing BallisticsEngine for projectile classes where the reference supports physical projectiles.

## Match audit

Current Arena loop is implementation scaffolding, not full Void Hunters mission parity.
Keep it isolated. Do not entangle MissionBuilder with Arena-specific score logic.

Team identity is Yellow / Blue for the project target. Component category colors remain independent.

## Roblox runtime / security audit

All RemoteEvent handlers must validate:
- player is connected
- ship belongs to player / authorized controller
- ship is a live ship
- requested component is actually part of that ship
- requested weapon is actually installed and operational
- state transition is legal
- numeric inputs are finite and bounded

Never trust client-supplied Instance references, weapon names, damage numbers, CFrames, or target models without server-side reconstruction/validation.

## Lifecycle / leak audit
Future agents must check:
- Heartbeat connections disconnected on destroyed ships
- player tables cleared on PlayerRemoving
- projectile callbacks cannot retain destroyed projectiles indefinitely
- drone/fighter state arrays remove dead objects
- debounce/cooldown maps are cleaned when component instances are destroyed
- temporary visual Instances use Debris only for genuinely transient VFX, never core gameplay objects

## Efficiency protocol for future agents

Before reading source:
1. Read this file.
2. Read `VOIDA/05_FORENSIC_PORT_BLUEPRINT.md`.
3. Read the relevant AGENTS directive.
4. Identify whether the question is already resolved.
5. Only inspect the smallest source slice needed to close the delta.

For every resolved issue, append:
- SOURCE
- OLD BEHAVIOR
- NEW BEHAVIOR
- TEST
- STATUS

Do not reopen an issue marked VERIFIED unless new source evidence contradicts it.

## Status vocabulary
- EXTRACTED = reference recovered
- IMPLEMENTED = Roblox code exists
- VERIFIED = behavior tested against reference
- BLOCKED = missing evidence/runtime capability
- SUPERSEDED = replaced by newer authoritative path

## Current priority queue
P0: authoritative component state migration
P0: structural graph/hardpoint fidelity
P0: blueprint V2 serialization/load consistency
P1: debris lifecycle + momentum + no invented cleanup
P1: physics formula/constant provenance
P1: deterministic projectile hit routing
P1: remove type-name heuristics in combat/power systems
P2: repair exact source behavior
P2: shields exact source behavior
P2: construction/AutoBuild exact hardpoint semantics
P2: Mission condition/action port
P3: assets/UI/audio extraction

END AUDIT
