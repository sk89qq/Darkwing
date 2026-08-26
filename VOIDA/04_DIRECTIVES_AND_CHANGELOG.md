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
- **Required before VERIFIED:** audit every numerical constant/formula against the recovered client and distinguish original behavior from Roblox safety/performance policies.

### [Phase 2 - Ship Assembly & Socket Graph]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Recursive graph, socket matching, weld creation, reachability/severance and build-mode snapping exist. `StructuralAuthority` is now the intended mutation boundary.
- **Required before VERIFIED:** remove remaining generic socket fallbacks and prove hardpoint attach/detach/replacement against reference behavior.

### [Phase 3 - Tactical Combat, Weapons & Projectile Ballistics]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Weapon controller now uses `ComponentAuthority` as its health-state boundary and `StructuralAuthority` for component destruction. Shield/capacitor/weapon numerical parity is still not established.
- **Required before VERIFIED:** reconcile duplicated state in remaining combat/PvP systems and every damage/weapon/energy constant against the recovered client.

### [Phase 4 - HUD, Radar & Arena Match Loop]
- **Status:** IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Arena match manager and HUD exist; team vocabulary is now Yellow/Blue. This remains the Arena prototype rather than the complete Mission framework.
- **Required before VERIFIED:** port the original MissionCondition/MissionAction orchestration and verify HUD behavior against archived client evidence.

### [Phase 5 - Forensic Port Blueprint Alignment & Definitive Data Models]
- **Status:** EXTRACTED + IMPLEMENTED
- **Verification:** PARTIAL
- **Current state:** Decompiled component/body schemas, category colors, geometry data and debris configuration are present.
- **Required before VERIFIED:** audit every numeric/table entry against actual source/resource data and resolve remaining decompilation gaps.

### [Current Workstream - Foundation Structural Reconciliation]
- **Status:** ACTIVE
- **Implemented boundaries:**
  - `ComponentAuthority` = canonical component runtime state.
  - `StructuralAuthority` = canonical attach/detach/replace/sever boundary.
  - `ShipSocketGraph` = socket/hardpoint solver/index.
  - `RigidBody2D` = logical 2D body solver where native Roblox physics is not equivalent.
  - `TeamIdentity` = shared Yellow/Blue team vocabulary.
- **Next reconciliation:**
  1. migrate remaining PvP/repair code away from private component state
  2. remove generic topology fallbacks
  3. migrate all replacement/manual detach paths to `StructuralAuthority`
  4. reconcile shield/power state authority
  5. reconcile physics constants/formulas
  6. port MissionCondition/MissionAction framework

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

## 2026-08-26 — Foundation Structural Reconciliation

Implemented:
- canonical `ComponentAuthority` for component HP/state and immutable base-color presentation
- canonical `StructuralAuthority` for graph attach/detach/replacement/severance
- blueprint AutoBuild routed through the structural mutation boundary
- Yellow/Blue team identity centralized in `TeamIdentity`
- Arena `MatchState` and `VoidHunterMatchManager` corrected from Red/Blue to Yellow/Blue
- weapon damage/destruction migrated to `ComponentAuthority` compatibility views and `StructuralAuthority`
- root/ship destruction no longer fabricates random 40%-HP / 80%-HP clone salvage
- completion/status language aligned with forensic verification policy

Explicitly NOT declared verified by this change:
- exact source numerical shield/capacitor values
- exact critical-flash render threshold in original code
- complete Mission framework parity
- exact audiovisual asset parity
- exact decompiled physics formulas where CFR control flow remains unresolved

These remain `PARTIAL`, `UNKNOWN`, or `BLOCKED` until the reference evidence supports them.
