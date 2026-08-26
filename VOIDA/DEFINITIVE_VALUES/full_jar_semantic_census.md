# Void Hunters Full-JAR Semantic Census

Source: user-supplied `voidhunters.jar`.

## Binary anchor
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- Size: 2,325,563 bytes
- Classes: 1,570
- Archive entries: 1,570 `.class` files

## Decompiled-source coverage
The supplied decompiled package contains 1,580 entries, including 1,570 Java source files plus directory metadata. Key native source classes include `qb.java`, `ik.java`, `kga.java`, `tr.java`, `jk.java`, `wlb.java`, and `wfb.java`.

## Native value census
The binary class-file scan recovered:
- 4,805 integer constant-pool entries
- 601 float entries
- 121 double entries
- 186 long entries
- 14,756 UTF-8 constants
- 5,860 fields
- 11,148 methods

These are **evidence inventories**, not automatically gameplay constants. A literal becomes authoritative gameplay data only after tracing it to a field, initializer, constructor, lookup table, or operator.

## Semantic domains identified
The decompiled source contains identifiable implementation surfaces for:
1. Configuration/settings
2. Ship/component definitions and geometry
3. Weapons and projectiles
4. Physics/body state and force calculations
5. Shields, power, damage, repair
6. Grappling/tractor behavior
7. Mission conditions/actions/events/state
8. Environment/debris/particles
9. Colors and presentation constants
10. Serialization/network/protocol identifiers
11. Blueprint/component metadata
12. UI/audio/resource identifiers

## Priority extraction order
`wlb/wfb` component and geometry data → physics operators → weapon/projectile operators → shields/power/repair/grapple → mission/state machines → presentation/assets.

## Provenance rules
- Preserve native class, method, and field names whenever they can be established.
- Preserve units/scaling separately from raw values.
- Do not infer a missing value from naming alone.
- Keep Roblox-facing representations derived from the native source rather than replacing the native source of truth.
- Do not treat arbitrary constant-pool values as tuning values without code-context verification.

## FUTURE AGENT NOTE:
The JAR hash above is the immutable source anchor. The Roblox implementation is the target environment and must not be reverted. New constants should be promoted into authoritative Roblox data only after a native source location and semantic meaning are recorded. The 235-key settings map is a separate configuration layer; do not mix it with component geometry, weapon parameters, mission state, or raw constant-pool inventories.
