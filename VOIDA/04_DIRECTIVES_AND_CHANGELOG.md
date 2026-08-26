# VOIDA Directives & Changelog Logbook

## Overview
This file tracks received directives, implementation changes, and verification status for the Void Hunters forensic port.

---

## 🛑 Core Engineering Directive: Problem-Solving Triage
**DO NOT SOLVE A PROBLEM TWICE.**

Before implementing any mechanic:
1. **ASK:** "Does the original client already contain the answer?"
   - If YES: extract it from the original reference/decompile code and record the source location.
2. **THEN ASK:** "Does Roblox already provide a mechanism capable of reproducing it?"
   - If YES: use the native Roblox primitive/API where it preserves the required observable behavior.
3. **ONLY IF BOTH ANSWERS ARE NO:**
   - Design custom logic and label it `[INFERRED]` until validated.

This rule is persisted in `AGENTS.md` and applies to every engineering turn.

---

## 🔬 Completion / Verification Policy
The previous log used `Complete` for phases whose implementations had not been fully audited against the recovered client. That status is retired.

A phase may use these states only:

- **EXTRACTED** — reference behavior/data recovered; implementation not yet reconciled.
- **IMPLEMENTED** — Roblox implementation exists; full forensic parity is not yet demonstrated.
- **VERIFIED** — implementation has been compared against recovered client behavior for the scoped acceptance tests.
- **BLOCKED** — required source/resource evidence or runtime verification is missing.
- **SUPERSEDED** — previous implementation replaced by a later authoritative implementation.

`VERIFIED` requires an explicit acceptance test and source citation. Presence of code, a populated module, or a passing basic smoke test is not sufficient.

Every claim/value must retain its source-truth tag:
`[CODE_VERIFIED]`, `[ASSET_VERIFIED]`, `[ORIGINAL_DATA_VERIFIED]`, `[ALTERORB_BEHAVIOR_VERIFIED]`, `[DOCUMENTATION_ONLY]`, `[INFERRED]`, `[UNKNOWN]`.

Do not mark inferred Roblox choices as `[CODE_VERIFIED]` merely because they are compatible with the reference.

---

## Current Phase Registry

### [Phase 0 - Initialization]
- **Status:** IMPLEMENTED
- **Scope:** VOIDA documentation, source-truth rules, baseline project inventory, and development scaffolding.

### [Phase 1 - Physics & RigidBody2D Engine]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** A 50 Hz custom 2D rigid-body layer exists with mass points, COM, inertia, force/torque, impulses, damping, and Roblox transform synchronization.
- **Required before VERIFIED:** audit every numerical constant/formula against the recovered client and distinguish original behavior from Roblox safety/performance policies such as clamps, fixed elevation, and fallback inertia/mass values.

### [Phase 2 - Ship Assembly & Socket Graph]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Recursive graph, socket matching, weld creation, reachability/severance and build-mode snapping exist.
- **Required before VERIFIED:** replace/retire generic socket fallbacks where the recovered component-specific hardpoint definitions are authoritative; prove manual attach, detach, severance, and graph-to-physics synchronization against reference behavior.

### [Phase 3 - Tactical Combat, Weapons & Projectile Ballistics]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Weapon controller, damage routing, shields, capacitor, ballistics and multiple weapon behaviors exist.
- **Required before VERIFIED:** reconcile duplicated state and every damage/weapon/energy constant against the recovered client. Remove placeholder/type-name heuristics where authoritative component behavior exists.

### [Phase 4 - HUD, Radar & Arena Match Loop]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Arena match manager, HUD, radar, scoreboard and notifications exist.
- **Required before VERIFIED:** distinguish reproduction of the original Arena loop from modern additions, correct team identity to the historical Yellow/Blue model where applicable, and verify HUD behavior against archived client evidence.

### [Phase 5 - Forensic Port Blueprint Alignment & Definitive Data Models]
- **Status:** EXTRACTED + IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Decompiled component/body schemas, category colors, component geometry table and debris parameter registry are present.
- **Required before VERIFIED:** audit every numeric/table entry against the actual source/resource data and remove unsupported claims from the `[CODE_VERIFIED]` bucket.

### [Current Workstream - Forensic Reconciliation]
- **Status:** ACTIVE
- **Priority order:**
  1. Authoritative Component state
  2. Component graph/hardpoints
  3. Health/damage state
  4. Zero-HP destruction and detached-body lifecycle
  5. Debris persistence/cleanup
  6. Physics recomputation after topology changes
  7. Replacement and AutoBuild through the same graph mutation path
  8. Shield/power state authority
  9. Yellow/Blue team identity
  10. Mission/game-mode parity

---

## Engineering Rule For Completion Claims
A directive is **not complete because code exists**.

For each directive the engineer must record:

```text
SOURCE:
original class/method/data or archival reference

CURRENT IMPLEMENTATION:
file/module/function

BEHAVIORAL DELTA:
none / known difference / unknown

ACCEPTANCE TEST:
what must be observed to call the directive VERIFIED

STATUS:
EXTRACTED | IMPLEMENTED | VERIFIED | BLOCKED | SUPERSEDED
```

This preserves the existing Roblox/Luau architecture while preventing the documentation layer from claiming forensic parity before it has been demonstrated.

---

## 2026-08-26 Correction
The earlier phase log classified several systems as `Complete`. That was premature. This correction changes those labels to `IMPLEMENTED` with `PARTIAL` verification and establishes `VERIFIED` as the only status meaning demonstrated behavioral parity for the scoped feature.
