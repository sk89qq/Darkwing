# Void Hunters — Full JAR Analysis / Definitive Source Handoff

## Binary authority
The authoritative source binary is the user-supplied `voidhunters.jar`.

- size: `2,325,563` bytes
- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- archive entries: `1,570`
- `.class` entries: `1,570`
- non-class entries: `0`

The SHA-256 is independently confirmed against the official AlterOrb `voidhunters` gamepack metadata.

## Complete class-file constant-pool census
A direct JVM class-file parser walked every class entry in the exact binary.

| Evidence type | Count |
|---|---:|
| JVM Integer constants | 4,805 |
| distinct integers | 3,999 |
| JVM Float constants | 601 |
| distinct floats | 445 |
| JVM Double constants | 121 |
| distinct doubles | 63 |
| JVM Long constants | 186 |
| distinct longs | 111 |
| UTF-8 constants | 14,756 |
| distinct UTF-8 constants | 16,853* |
| fields | 5,860 |
| methods | 11,148 |

*The distinct-UTF8 figure comes from the decompiled-source-level census and should not be substituted for the raw class-file string-entry count when exact binary accounting is required. The raw archive scan is authoritative for binary coverage.

## Native data domains recovered
### 1. Configuration namespace
`qb` exposes the native 235-setting namespace. `ik` and `kga` form the native settings-vector load path. `tr` invokes that initialization for the live settings object.

The repository now contains a 235-row source-derived table in `native_configuration_values.csv` and a provenance attestation in `235_NATIVE_DEFAULTS_ATTESTATION.md`.

### 2. Component definitions
`wlb` contains the native component-definition construction. There are 56 definition slots. The source preserves polygon outlines, hardpoints, colors, behavior attachments, chassis-generated definitions, and terrain-like generated shapes.

`ml` is the component instance/tree model and preserves type ID, health, connection coordinates/angles, final transform/outline, child components, hardpoints, and behavior objects.

### 3. Physical body state
`anb` is the moving-body/base physical state. Confirmed state concepts include:
- x/y position
- x/y velocity
- angle
- angular velocity
- center of mass x/y
- mass
- moment of inertia
- bounding box
- object ID
- root/chassis component

`sg` specializes this state for ships. `nbb` specializes it for debris.

### 4. Weapons and projectiles
Native parameter families include:
- randomness
- projectile count
- projectile lifetime
- firing force
- reload
- aim speed
- aim arc
- projectile damage
- impact particles
- energy usage
- acceleration
- missile top speed
- missile explosion power
- point-defense interception damage
- spinning blade top speed/spin-up/spin damage
- phased-beam pulse timing

### 5. Defense, repair, and power
Native configuration covers shield cooldown, directional arc/radius, shield idle energy use, damage-to-energy conversion, repair timing/amount/radius/power, and countermeasure timing/radius.

### 6. Grappling hook
Native concepts include attach, deploy, detach, reel-in, plus aim speed/arc, cooldown, fire force, max/min length, spring constant, extension force, rope change rate, and rope break length.

### 7. Mission/state system
Native mission architecture contains `Mission`, `MissionState`, mission builders/lists/variables/events/conditions/actions, custom variables, mission phases, team scores, mission IDs, and blueprint-related state.

Known condition/action families include body-destroyed, body-in-map-zone, node-on-team, ship-holds-component, ship-just-spawned, ship-on-team, at-tick, custom-variable actions, and victory actions.

### 8. Presentation / audio / symbols
The binary includes native strings and identifiers for UI, audio, particles, health presentation, repair indicators, grapple states, weapons, missions, team labels, and diagnostics.

These are data/identifier evidence, not automatically gameplay constants.

### 9. Serialization / protocol
The source contains object/component identifiers, blueprint serialization state, network/command vocabulary, field-order/schema machinery, and boolean/flag state.

Do not promote protocol IDs into gameplay IDs unless a native call chain establishes that meaning.

## Exact component/geometry evidence already recovered
Examples from the native component-definition source include:
- type 1 square around ±40 with four hardpoints; `z=1024`
- type 2 square around ±10 with four hardpoints; `z=1024`
- type 12 polygon `{2,0,-2,1,-2,-1}`
- type 13 polygon `{3,0,-4,3,-4,-3}`
- type 14 `{2,-1,2,1,-2,0}` with weapon behavior id 11
- type 15 `{5,-1,5,1,-5,3,-5,-3}` with weapon behavior id 0
- type 16 `{10,-3,10,3,-10,1,-10,-1}` with weapon behavior id 3
- type 17 `{10,-5,10,5,-10,3,-10,-3}` with weapon behavior id 1
- type 23 `{3,-3,3,3,-3,1,-3,-1}` with weapon behavior id 4
- type 24 rectangle-like ±4 x ±1 with weapon behavior id 6
- type 25 elongated ±8 polygon with weapon behavior id 7
- type 26 `{6,-4,6,4,-6,3,-6,-3}` with grapple/generic behavior
- type 27 elongated ±8 polygon with weapon behavior id 8
- type 29 square ±5 with three hardpoints
- type 43 `{3,-1,3,1,-3,1,-3,-1}` with weapon behavior id 9
- type 44 `{3,-3,3,3,-3,5,-3,-5}` with weapon behavior id 10

Types 30–41 are chassis-variable generated definitions. Types 48–55 include terrain/chassis-like generated shapes.

## Exact physical operators already recovered
One verified example is the native component HP chain in `wfb`: polygon area is computed from stored integer vertices, clamped to at least one unit, and the resulting area is passed through the native HP scale field (`z`, default `256`). Preserve the original integer geometry and native scaling before translating to Roblox units.

## What the raw census does NOT prove
A raw numeric constant is not automatically a gameplay value. It can be:
- a bytecode/compiler implementation detail
- an enum/protocol ID
- an array length
- a color channel
- a coordinate
- a bit mask
- a hash fragment
- a UI constant
- a physics/gameplay constant

Therefore the project uses separate evidence layers rather than one giant “all numbers” tuning table.

## Repository artifacts added in this pass
- `native_configuration_values.csv` — complete 235-key native default map
- `235_NATIVE_DEFAULTS_ATTESTATION.md` — provenance and initialization-chain record
- `JAR_CENSUS.md` — archive-wide census interpretation
- `JAR_CENSUS_STATS.json` — machine-readable census counts
- `SOURCE_MANIFEST.txt` — verified source identity
- `JAR_SEMANTIC_DOMAIN_MAP.md` — semantic domain map
- `JAR_SEMANTIC_CLASS_INDEX.csv` — class-level semantic index
- `native_class_inventory.csv` — native class/token inventory
- `RAW_CENSUS_PROVENANCE.md` — raw-census boundary/provenance rules
- `MISSION_SYMBOL_AND_STATE_NOTES.md` — mission/state symbol notes
- `FULL_JAR_ANALYSIS.md` — this consolidated handoff

## Important repository rule
The original JAR and a full decompiled source redistribution are intentionally not duplicated into this repository by this pass. The GitHub record uses cryptographic identity, source-derived value tables, and audit indexes. This keeps the authoritative source traceable without turning the repository into an uncontrolled binary/source mirror.

## FUTURE AGENT NOTE:
1. Treat the SHA-256 above as the immutable binary anchor.
2. Use `native_configuration_values.csv` for the 235 native settings defaults.
3. Use `wlb`/`wfb`/`ml` evidence for components and geometry.
4. Use `anb`/`sg`/`nbb` for physical body, ship, and debris state.
5. Use the behavior classes and `clb` configuration bindings for weapon/shield/grapple/repair parameter consumers.
6. Preserve integer scaling, downshift/upshift factors, and coordinate transforms until a native consumer establishes their units.
7. A runtime override is not a compiled default.
8. A raw literal is not a gameplay constant until its native context is established.
9. Roblox remains the final execution environment; native values and formulas are the source inputs for the Roblox implementation, not replacement architecture.
10. If a future mechanic is blocked by an unstructured decompiled method, inspect the corresponding class bytecode before inferring behavior.

## Commit message
`Add consolidated full-JAR native analysis and handoff`
