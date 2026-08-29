# Canonical Projectiles

## CLOSED-FOR-PORT
- Swept-hit architecture is settled at the implementation boundary.
- Projectile spawn uses the recovered weapon-component local longitudinal offset.
- Native integer angles use `angle * pi / 1024` only at the trig boundary; the native angle domain remains authoritative.

## PLASMA BALL — PORT-READY CONTRACT
- Native component slot: **44**.
- Native weapon ID: **10**.
- Launcher polygon: `(3,-3),(3,3),(-3,5),(-3,-5)`.
- Launcher local longitudinal offset: **-3**.
- Projectile count: **1**.
- Projectile damage: **50** (existing canonical/emulation weapon definition).
- Continuous intersection damage: **10 per active damage tick** (existing canonical/emulation weapon definition).
- Fire rate: **2 shots/sec** (`0.5 s` nominal shot interval in the existing weapon definition).
- Projectile range limit: **40** (existing canonical/emulation weapon definition).
- Projectile speed: **60** (existing canonical/emulation weapon definition).
- Projectile collision/visual size: **Vector3.new(1,1,1)** in the existing weapon definition.
- Projectile has **no health pool**.
- Armor intersections are non-consuming: plasma passes through armor and remains active.
- While intersecting armor/target damage volume, apply the configured continuous tick damage on each simulation tick; do not destroy on armor contact.
- A hull/stopping structural impact applies the impact damage and terminates the projectile.
- If no stopping structural impact occurs first, the projectile terminates at its range/lifetime limit.
- Do not use the generic one-hit projectile `hit => destroy` path for Plasma.

### IMPORTANT NUMERIC PROVENANCE
The `50 / 10 / 2 / 40 / 60 / Vector3.new(1,1,1)` values above are **confirmed existing project weapon-definition values**, not newly invented native-JAR constants. The supplied JAR evidence definitively establishes Plasma Ball identity, slot/weapon mapping, and native component geometry, but does not expose a separate `PLASMA_BALL_*` numeric configuration family. Keep this provenance distinction explicit rather than falsely labeling these as JAR-native constants.

## OTHER NATIVE INPUTS
Weapon-specific projectile speed, lifetime/range, damage, cooldown, energy and special behavior remain native-resolved where their dedicated configuration keys exist. Projectile-specific collision geometry remains separate from launcher geometry unless native code proves reuse.

## ANGLE ENCODING
- `1024` native angle units = `pi` radians = half turn.
- `2048` native angle units = `2pi` radians = full turn.
- Native integer angle remains authoritative; convert only at the trig boundary.

## SOURCE STATUS
- Weapon component polygons and local offsets are directly recovered from `wlb.f(byte)` / `COMPONENTS_56.csv`.
- Plasma Ball identity is directly present in the supplied JAR (`Plasma ball`, `COMPONENT_WEAPON_PLASMABALL_TEXT`, and plasma-ball resources).
- Plasma armor-clipping and persistent per-tick intersection damage are canonical gameplay requirements.
- Plasma hull/stopping-piece termination and lifetime/range termination are closed behavioral requirements.
- The remaining native-JAR gap is not the gameplay contract itself; it is whether the existing `50 / 10 / 2 / 40 / 60 / size 1` project-definition values can be proven to originate from a hidden native runtime input rather than the emulation layer.
