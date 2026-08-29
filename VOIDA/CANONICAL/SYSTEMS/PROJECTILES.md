# Canonical Projectiles

## CLOSED-FOR-PORT
- Swept-hit architecture is settled at the implementation boundary.
- Projectile collision implementation belongs to the replacement engine/runtime.

## CRITICAL NATIVE BEHAVIOR — PLASMA
- **Plasma ball is armor-clipping.** It is not stopped by armor geometry on the first intersection.
- Plasma damage is applied **per simulation tick while the plasma ball intersects the target**.
- Plasma continues through armor and remains active rather than being consumed by armor contact.
- **Plasma terminates on impact with a hull/stopping structural piece, or when its projectile lifetime/range limit is reached.**
- Plasma does not use projectile HP as a termination mechanic.
- The replacement runtime must not model plasma as a conventional one-hit projectile that terminates on armor contact.
- Plasma's collision/damage path must distinguish armor penetration from ordinary stopping structural impact.

### Implementation contract
For a plasma projectile, each simulation step evaluates the projectile against structural damage volumes. If the projectile intersects armor, apply the configured plasma tick damage for that tick and continue the projectile. Armor intersection does not consume the projectile. If the projectile impacts a hull/stopping structural piece, apply the impact damage and terminate the projectile. If the projectile reaches its native lifetime/range limit first, terminate it there.

## NATIVE INPUTS — DERIVED

### Projectile spawn geometry
The native weapon component definitions provide a definitive weapon-to-component mapping and a signed local spawn/attachment offset. The second constructor argument of the native `wfb` definition is the longitudinal local offset used by the component definition.

| Weapon | Native component slot | Weapon ID | Native polygon | Local longitudinal offset |
|---|---:|---:|---|---:|
| Point Defence Laser | 14 | 11 | `(2,-1),(2,1),(-2,0)` | `-2` |
| Mass Driver | 15 | 0 | `(5,-1),(5,1),(-5,3),(-5,-3)` | `-5` |
| Laser Beam | 16 | 3 | `(10,-3),(10,3),(-10,1),(-10,-1)` | `-10` |
| Machine Gun | 17 | 1 | `(10,-5),(10,5),(-10,3),(-10,-3)` | `-10` |
| Bomblet Spray | 23 | 4 | `(3,-3),(3,3),(-3,1),(-3,-1)` | `-3` |
| Torpedo | 24 | 6 | `(4,-1),(4,1),(-4,1),(-4,-1)` | `-4` |
| Sniper Cannon | 25 | 7 | `(8,-1),(8,1),(-8,2),(-8,-2)` | `-8` |
| Missile Launcher | 27 | 8 | `(8,-3),(8,3),(-8,1),(-8,-1)` | `-8` |
| Countermeasure / Scrambler | 43 | 9 | `(3,-1),(3,1),(-3,1),(-3,-1)` | `-3` |
| Plasma | 44 | 10 | `(3,-3),(3,3),(-3,5),(-3,-5)` | `-3` |

These are component-definition/spawn-geometry values, not invented projectile collision shapes. Projectile-specific collision polygons remain separate unless the native projectile class reuses the weapon definition geometry.

### Direction / angle encoding
Native angle construction uses `atan2` and normalizes by `2π`, establishing a normalized turn representation. Native angle consumers also divide integer angle values by `1024`, establishing the fixed-point relationship:

- `1024` native angle units = `π` radians = half turn.
- `2048` native angle units = `2π` radians = full turn.
- normalized turn value = `angle / (2π)`.
- conversion from native integer angle to radians: `angle * π / 1024`.

Therefore the replacement engine should retain the native integer angle domain and only convert at the math boundary when a floating-point trig operation is required.

## NATIVE INPUTS STILL RELEVANT
- Weapon-specific projectile speed, lifetime/range, damage, cooldown, energy and special behavior where not already verified.
- Projectile-specific collision geometry where it is distinct from the weapon component definition.
- Plasma numeric tick interval/damage and numeric lifetime/range remain to be traced to their native inputs.

## SOURCE STATUS
- Weapon component polygons and local offsets above are directly recovered from `wlb.f(byte)` and `COMPONENTS_56.csv`.
- Angle encoding is directly supported by native `atan2` normalization and native `/1024` angle conversion sites in the supplied JAR preprocessing.
- Plasma armor-clipping and persistent per-tick intersection damage are canonical gameplay requirements.
- Plasma hull/stopping-piece termination and lifetime/range termination are closed behavioral requirements for the replacement runtime; their numeric limits remain separate native inputs.
