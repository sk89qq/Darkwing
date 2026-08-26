# VOIDA — Body Recompute Boundary

## SOURCE:
- `ReplicatedStorage/Shared/Physics/RigidBody2D.luau`
- Forensic architecture directive requiring one body-recompute authority.

## OLD:
- Structural, damage, and physics callers could conceptually invoke mass/COM/inertia updates directly without a named service boundary.
- This made it harder to audit whether recalculation remained centralized.

## NEW:
- Added `Shared/Physics/BodyRecomputeService.luau` as the named Roblox-side recompute boundary.
- The service delegates all mathematics to `RigidBody2D:RecalculateMassProperties()`.
- Add/remove mass-point helpers return the resulting authoritative body properties.
- No second mass/COM/inertia formula was introduced.

## TEST:
- `RigidBody2D` remains unchanged as the mathematical implementation.
- `BodyRecomputeService.IsCanonical()` recognizes the existing body implementation.
- Roblox Studio runtime acceptance remains pending.

## STATUS:
IMPLEMENTED / PARTIAL

## FUTURE AGENT NOTE:
Use `BodyRecomputeService` as the service boundary for structural or lifecycle code that needs a recompute. Do not duplicate mass, center-of-mass, inertia, or bounds formulas in builder/damage/debris code. The actual equations remain in `RigidBody2D` until native-source parity is fully recovered.
