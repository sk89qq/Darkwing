# PORT EXECUTION QUEUE — 2026-09-02

Purpose: active forensic queue for the behavioral port to Luau + Box2D/RO2D + Roblox.

This is a port, not a literal Java translation. Native JAR evidence defines gameplay behavior; target architecture is implementation freedom.

## ORDER
1. Task 4 state/lifecycle field closure.
2. Damage selection → HP → destruction → structural mutation → debris.
3. Shared resource/power producer-consumer closure.
4. Weapon/projectile gating, spawn, lifetime, termination.
5. Component geometry/hardpoint materialization required by runtime.
6. Remaining physics-boundary producer/consumer gaps.
7. Port-readiness audit and handoff package.

## CURRENT TASK 4 FIELD PRIORITY
### ml.i
Current health/state quantity. Constructor: i = wfb.p. Native damage methods write/decrement and clamp to zero. Continue reader/writer and terminal caller closure.

### ml.p / ml.q
Both initialize to 0. Native evidence shows p/q participate in multiple state transitions and calculations. Resolve all writers/readers before assigning target semantics.

### ml.n / ml.r
High-connectivity fields used by transforms/kinematic calculations and recursive state propagation. Resolve producer/consumer chains before semantic renaming.

### ml.f
Child component array. Close creation, parent/child mutation, recursion, severance and destruction lifecycle.

### ml.d
Runtime hardpoint array created from wfb.o length. Close hardpoint construction, update, ownership and filtering.

### anb.k
Native component→body ownership/reference. Close body replacement, destruction and debris transitions.

### nbb.w/x/u/v
Debris lifecycle fields. Resolve readers/writers and cleanup/termination callers; do not guess cleanup timing.

## VERIFIED NATIVE DAMAGE SEGMENT
ml.a(int,int,pe,anb): selector/key routing, recursive child routing, direct health subtraction, zero clamp and terminal result are source-verified. Exact external selector generation, eligibility, shield ordering and destruction transaction remain active.

## PORT RULE
Only investigate native internals when they affect observable gameplay or required target inputs. Do not reconstruct generic Box2D solver behavior. Do not reopen closed Task 1–3 areas except for evidence-driven correction.

## HANDOFF TARGET
~85–90% core port-ready. Handoff when implementation can reproduce core gameplay without material gameplay-semantic guesses. Deferred UI, missions, networking architecture, rendering and engine-owned internals do not block core handoff.
