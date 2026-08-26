# Raw JAR Census Provenance

## Exact source
`voidhunters.jar`

- bytes: `2325563`
- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- class entries: `1570`
- non-class entries: `0`

## Complete local constant-pool scan
The exact JAR was scanned locally at the JVM class-file level.

- Integer literals: `4805`
- Distinct integers: `3999`
- Float literals: `601`
- Distinct floats: `445`
- Double literals: `121`
- Distinct doubles: `63`
- Long literals: `186`
- Distinct longs: `111`
- UTF-8 constants: `94161`
- Distinct UTF-8 constants: `16853`
- Game/value-relevant strings: `1370`

A full raw numeric inventory was generated locally from the class files. The Git repository intentionally does not claim that every raw literal is semantically a gameplay value: JVM literals also encode array lengths, enum IDs, color channels, protocol fields, hash fragments, bit masks, UI constants, and implementation details.

## Git-committed semantic layers
The repository contains these authoritative derived layers:

- `native_configuration_values.csv` — 235 native configuration defaults.
- `component_56_slots.csv` — 56 component-definition initializer slots.
- `JAR_CENSUS.md` — complete archive-level counts and interpretation rules.
- `JAR_SEMANTIC_DOMAIN_MAP.md` — semantic domains and extraction guidance.
- `JAR_SEMANTIC_CLASS_INDEX.csv` — native classes grouped by gameplay domains.
- `native_class_inventory.csv` — all 1,570 class entries with raw semantic-token hits.
- `SOURCE_MANIFEST.txt` — binary identity anchor.
- `235_NATIVE_DEFAULTS_ATTESTATION.md` — provenance and reconstruction rules.

## Semantic value families already identified
### Component and geometry
- polygon outlines
- hardpoints
- connection coordinates
- connection angles
- generated chassis-dependent geometry
- terrain/generated shapes
- behavior attachments
- component colors
- symmetry/index maps

### Physical state and operators
- mass
- center of mass
- moment of inertia
- x/y position
- x/y velocity
- angle
- angular velocity
- bounding box
- collision force multipliers
- detachment/explosion force multipliers
- velocity/angular-velocity scaling factors

### Weapons and projectiles
- randomness
- projectile counts
- lifetime
- firing force
- reload
- aim speed
- aim arc
- damage
- impact particles
- energy usage
- acceleration
- missile speed/explosion power
- point-defense interception
- blade speed/spin-up/spin damage
- phased-beam pulse timing

### Defense and energy
- shield cooldown
- directional shield arc/radius
- shield idle energy usage
- damage-to-energy conversion
- repair timing/amount/radius/power
- countermeasure timing/radius

### Environment and missions
- terrain probabilities
- debris generation/voting
- world scaling
- mission timing
- Armageddon timing
- resource-node timing
- respawn/ready-room timing
- mission condition/action classes
- team state

### Presentation and assets
- color literals
- particle parameters
- sound/audio identifiers
- camera/HUD/UI strings
- diagnostic strings
- mission and component labels

### Serialization/protocol
- object IDs
- component IDs
- state field order
- packet/command identifiers
- boolean/flag masks
- blueprint persistence fields

## Important limitation
This file records the extraction state, not a claim that every one of the 5,713 raw literals has already been semantically interpreted. Interpretation requires method/class context and is being recorded as source-backed facts in the semantic tables.

## FUTURE AGENT NOTE:
When a Roblox value is needed, start with the semantic tables. Use the raw JAR census only to locate candidate literals, then trace the candidate into its native method/field. Preserve the original numeric scale and unit system. Never promote a raw literal into a gameplay constant solely because its magnitude looks plausible.

## Commit message
`Document complete raw JAR census provenance and semantic boundaries`
