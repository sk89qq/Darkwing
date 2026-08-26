# Void Hunters — Semantic Domain Map

Source: verified `voidhunters.jar` SHA-256 `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`.

## Archive-wide result
A byte-level scan of all 1,570 class files found 151 classes containing gameplay-relevant symbol families. The counts below are class-level memberships, so one class can occur in multiple domains.

| Domain | Classes |
|---|---:|
| TEAM | 38 |
| MISSION | 36 |
| BLUEPRINT | 25 |
| CHASSIS | 17 |
| REPAIR | 14 |
| ENERGY | 13 |
| MISSILE | 13 |
| RELOAD | 13 |
| SHIELD | 13 |
| THRUSTER | 12 |
| GRAPPLE | 11 |
| FIGHTER | 10 |
| WORLD | 10 |
| FORCE | 8 |
| LASER | 7 |
| MASS | 7 |
| PROJECTILE | 7 |
| DAMAGE | 6 |
| DEBRIS | 6 |
| RESOURCE | 6 |
| COLLISION | 4 |
| COUNTERMEASURE | 4 |
| INERTIA | 4 |
| SALVO | 4 |
| VELOCITY | 4 |
| AIMARC | 3 |
| AIMSPEED | 3 |
| AUTOAIM | 3 |
| DOWNSHIFT | 3 |
| PHYSICS | 3 |
| TERRAIN | 3 |
| TORPEDO | 3 |
| UPSHIFT | 3 |
| HARDPOINT | 3 |

## High-confidence authoritative domains
### Configuration
`qb` is the canonical 235-key namespace. `ik`/`kga` participate in native settings-vector initialization. Keep their numeric mapping in `native_configuration_values.csv`.

### Component definitions
`wlb` constructs the native component-definition table. `ml` is the component instance/tree representation. `wfb` contains definition state such as geometry-derived health and behavior attachments.

### Physical body state
`anb` is the physical body/moving-object class. Its documented state includes x/y, dx/dy, angle, angular velocity, center of mass, mass, moment of inertia, bounds, ID, and component root.

### Ship/debris specializations
`sg` specializes ship state. `nbb` specializes debris state. Debris is therefore a physical body lifecycle, not an immediate visual deletion.

### Weapons/projectiles
Native parameter families cover randomness, projectile count/life, firing force, reload, aim speed, aim arc, damage, impact particles, energy use, acceleration, missile top speed/explosion power, PDL interception damage, blade speed/spin-up/spin damage, and phased-beam pulse timing.

### Shields/power
Native shield parameters include toggle cooldown, directional arc, radius, idle energy use, damage-to-energy conversion, and arc-particle presentation values.

### Grapple
Native grapple state has attach/deploy/detach/reel-in concepts and parameters for aim, cooldown, fire force, length, spring constant, extension force, rope change rate, and break length.

### Missions/environment
Mission terrain probabilities, debris voting, mission time, Armageddon timing, resource capture/tick time, world scale, nebula behavior, and mission state are separate authoritative domains.

### Build/blueprint
Blueprint topology is hardpoint/connection based. Component definitions retain polygon outlines, hardpoints, child arrays, connection coordinates, connection angles, and recursive structure.

## Value classes that must remain separate
1. **Definition literals:** values embedded directly in native class construction.
2. **Derived values:** e.g. health derived from polygon area through native lookup/math operators.
3. **Configuration defaults:** native 235-key vector values.
4. **Runtime state:** mutable ship/component/mission state.
5. **Protocol/UI constants:** event IDs, schema/serialization values, labels, and display constants.

Do not merge these into one undifferentiated constants table.

## FUTURE AGENT NOTE:
- Use this map to select native classes before modifying Roblox code.
- Search `clb` for configuration getter/setter names when an unfamiliar setting appears.
- Search `anb`, `sg`, and `nbb` for body-state and lifecycle semantics.
- Search `wlb`, `wfb`, and `ml` for component/geometry/hardpoint behavior.
- Search `aqa`, `gla`, `pja`, `grb`, `fcb`, and related behavior classes for weapon/thruster/grapple semantics.
- Preserve integer downshift/upshift semantics until a consumer explicitly demonstrates a conversion.
- Roblox remains the target runtime; native values are authoritative inputs, not arbitrary tuning knobs.

## Commit message
`Document complete native JAR semantic domain map`
