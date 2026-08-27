# VOIDA/12 — Native Semantic Extraction Status

**Date:** 2026-08-27
**Source authority:** original `voidhunters.jar` supplied to the ChatGPT Project
**Implementation target:** Roblox/Luau Darkwing

## Source anchor

The supplied original binary remains immutable forensic authority. Previously recorded SHA-256:

`4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`

The Project also contains the corresponding decompiled source archive and `java_full.txt`.

## Verified native domains currently recovered

### Component graph and geometry

`wlb` initializes 56 component-definition slots. Component definitions contain explicit polygon outlines, hardpoints, behavior identifiers, colors, and chassis-dependent geometry. The source records concrete polygon coordinates for multiple component types; these must remain polygonal in the Roblox representation rather than being reduced to generic Blocks/Triangles.

`ml` contains explicit connection-point coordinates/angles and child arrays. Structural removal repairs parent child/hardpoint references.

### Health and destruction

`ml.a(int damage, int targetType, pe, anb)` recursively traverses component children and decrements component health. Health clamps at zero. Component construction initializes health from `wfb.p`.

`wfb.p` is geometry-derived through `lw.a(area) * z`; the source references a square-root lookup table (`eo.o[]`) scaled by 4096. The exact transform must be retained from native code rather than replaced by an approximate formula.

Structural destruction can create `new nbb(component, false)`, add the resulting debris body to world state, remove the component from the parent graph, and recalculate the parent body.

### Physics state

`anb` explicitly carries position, velocity, angle, angular velocity, center of mass, mass, moment of inertia, bounding-box state, and root state. Native configuration names include velocity/angular-velocity sustain and limits, angular-force/torque scaling, inertia calculation downshifts, collision force multipliers, grappling-hook collision force, phantom collision force, and ship-to-ship ram damage.

The Roblox `RigidBody2D`/`PhysicsWorld` layer remains the logical implementation authority, but exact native `anb` equations are still a RAW-GAP until the CFR gaps are resolved against bytecode or another decompiler.

### Thrusters

Native component definitions distinguish Small Thruster, Standard Thruster, and Booster Rocket. Configuration includes separate force values, autoblocking/autobalancing controls, binding balance threshold, opposite-movement behavior, and particle parameters. `aqa` is the identified `ThrusterBehaviour` class.

Do not replace this with a simple thruster-count-times-force model.

### Weapons/projectiles

The source identifies Machine Gun, Mass Driver, Plasma Ball, Ubercannon, Fighter Bay, Spinning Blade, Bomblet Spray, Laser Beam, Sniper Cannon, Grappling Hook, Missile Launcher, Torpedo, Phased Energy Beam, Point Defence Laser, and Countermeasure/Scrambler. Native configuration families include projectile count/lifetime/force, reload, aim speed/arc, projectile damage, energy usage, acceleration, missile speed/lifetime/explosion power, PDL interception damage, blade speed/spin-up/spin damage, and phased-beam pulse timing.

Actual behavior classes and parameter consumers must be traced before final Luau weapon constants are promoted to VERIFIED.

### Shields/power

Native keys include shield toggle cooldown, directional shield idle energy usage, radius, arc, damage-to-energy conversion, and directional-arc particle parameters. Power Plant behavior is definition/behavior driven and must not be inferred from the UI.

### Grappling

Native keys include aim arc/speed, cooldown, fire force, max/min length, spring constant, max-extension force, rope change rate, rope break length, and grapple-debris behavior. The source identifies `GrapplingHook` and `GrappleLauncherBehaviour`.

### Missions

The native data model includes `Mission`, `MissionState`, `MissionCondition`, `MissionAction`, `MissionEvent`, `MissionVariable`, `MissionGenerationData`, `MissionControl`, map zones, clearance areas, and terrain/debris probabilities. The implementation must model these as state-machine data rather than extending Arena-only logic.

### Environment/debris

Native configuration includes terrain probabilities, debris probabilities, mission time limit, world-width scaling, nebula visibility/fade controls, debris pairing/max limits, and multiple debris collision/persistence/throwing modes.

## Current extraction boundary

The archive-wide binary census is complete, but raw literal presence does not establish semantic meaning. Values are promoted to the authoritative chart only when tied to a concrete field initializer, accessor, constructor, or operator with sufficient provenance.

The following remain explicitly non-verified until source tracing is complete:

- exact native rigid-body integration equations;
- exact detach/separation impulse and angular transfer;
- exact debris lifetime/cleanup rules;
- exact component-to-polygon collision selection;
- exact weapon behavior constants where the consumer method remains unstructured;
- exact mission condition/action transition semantics where CFR gaps remain.

## Roblox preservation rules

- Roblox is the final execution environment; existing Roblox implementation is not to be undone.
- Native component topology remains authoritative logically; Roblox Instances are projections.
- Preserve explicit `ComponentType`; never infer identity from `Instance.Name`.
- Preserve actual polygon geometry and hardpoints.
- Preserve detached components as physical debris where native behavior requires it.
- Keep component health in `ComponentAuthority`.
- Keep topology mutations in `StructuralAuthority`.
- Keep ship lifecycle in `ShipRegistry`.
- Keep logical physics in `RigidBody2D`/`PhysicsWorld` until native equations are fully recovered.
- Use idiomatic Luau scheduler APIs (`task.wait`, `task.delay`, `task.spawn`) in implementation code.

## FUTURE AGENT NOTE:

Start with `VOIDA/09_AUTHORITY_CENSUS.md`, then use the Project's original `voidhunters.jar` and decompiled archive for source recovery. Do not treat the existing forensic blueprint as permission to invent values. The highest-value next extraction is `aqa`/thruster behavior and `anb`/`nbb` physical integration, followed by weapon behavior classes and component polygon hit resolution. Any unresolved native operator should be marked `RAW-GAP`, not silently replaced by a guessed formula.
