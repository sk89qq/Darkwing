# VOIDA — Native Debris Launch Mapping

## Commit history
- `2eb03c6c3b7b3c650e4dfc0072f70a4cbbf0641c` — initial native debris launch mapper.
- `608b9e362cc5daea2cbf91ed00e032401bc40fa5` — corrected the force scalar to preserve the native `n2 * debrisProperty / max(offsetLength, 1)` dependence.

## SOURCE:
Raw `voidhunters_decompiled_raw.zip`:
- `ml.java` `DA(...)` debris-launch path.
- `anb.java` four-argument body force operator.
- `ecb.java` integer vector-magnitude helper.
- `rrb.java` native angle wrapping helper.
- `hob.java` unbiased bounded random helper.
- `ge.java` (`c = 4`) and `tua.java` (`a = 4`) fixed-point shift constants.

## OLD:
- No explicit reusable Roblox representation of the native debris launch operator existed.
- Previous detach code only inherited source rigid-body point velocity.

## NEW:
- Added `Shared/Physics/NativeDebrisPhysics.luau`.
- Native angle domain is represented as 8192 turn units per revolution.
- Random angular term is exactly the recovered `-100 + random[0,199]` contribution.
- Launch scalar is represented as `LaunchScale * DebrisProperty / max(OffsetLength, 1)`.
- Logical force direction and magnitude are returned separately from Roblox assembly projection.
- No unverified Newton/stud conversion constant is introduced.

## TEST:
- Raw operator bodies were extracted locally from the intact archive.
- Helper class initializers were inspected directly.
- `ge.c` and `tua.a` were resolved to 4.
- `rrb.a(...)` and `hob.a(...)` behavior were decoded from source.
- The mapper was reviewed for the native scalar dependence after the initial normalization error was caught and corrected.
- Roblox runtime parity remains `IMPLEMENTED / PARTIAL` until Studio execution validates physical observables.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Do not bypass `NativeDebrisPhysics` with a second launch formula. Feed it the real component-relative offset and the native `n2` / debris-property equivalents recovered from the calling context. Keep logical launch computation separate from Roblox `AssemblyLinearVelocity`/impulse projection. The remaining provenance question is the exact source meaning/units of the call-site `n2` and `nbb.e(false)` values in each destruction context; do not substitute arbitrary Roblox force units until those mappings are traced.
