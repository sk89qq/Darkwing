# VOIDA Directives & Changelog Logbook

## Overview
This file tracks received directives, implementation changes, and verification status for the Void Hunters forensic port.

---

## Core Engineering Directive: Problem-Solving Triage
**DO NOT SOLVE A PROBLEM TWICE.**

Before implementing any mechanic:
1. ASK whether the original client already contains the answer; if yes, extract and cite it.
2. ASK whether Roblox already provides an equivalent primitive; if yes, use it when behavior is preserved.
3. ONLY if both are unavailable, design custom logic and label it `[INFERRED]` until validated.

---

## Completion / Verification Policy
Allowed states: EXTRACTED, IMPLEMENTED, VERIFIED, BLOCKED, SUPERSEDED.

`VERIFIED` requires an explicit acceptance test and source citation. Code presence or a smoke test is insufficient.

Source-truth tags remain mandatory: `[CODE_VERIFIED]`, `[ASSET_VERIFIED]`, `[ORIGINAL_DATA_VERIFIED]`, `[ALTERORB_BEHAVIOR_VERIFIED]`, `[DOCUMENTATION_ONLY]`, `[INFERRED]`, `[UNKNOWN]`.

---

## Current Phase Registry

### Phase 0 - Initialization
- Status: IMPLEMENTED

### Phase 1 - Physics & RigidBody2D Engine
- Status: IMPLEMENTED / PARTIAL
- 50 Hz custom 2D rigid-body layer exists; formula-by-formula forensic verification remains open.

### Phase 2 - Ship Assembly & Socket Graph
- Status: IMPLEMENTED / PARTIAL
- `StructuralAuthority` is the mutation boundary; remaining generic fallbacks require reconciliation.

### Phase 3 - Tactical Combat, Weapons & Projectile Ballistics
- Status: IMPLEMENTED / PARTIAL
- `ComponentAuthority` and native configuration are authoritative directions; inferred shield/resource behavior remains open.

### Phase 4 - HUD, Radar & Arena Match Loop
- Status: IMPLEMENTED / PARTIAL
- Arena remains a prototype shell until original Mission sequencing is fully ported.

### Phase 5 - Forensic Port Blueprint Alignment & Definitive Data Models
- Status: EXTRACTED + IMPLEMENTED / PARTIAL

### Current Workstream - Foundation Structural Reconciliation
- Status: ACTIVE
- Canonical boundaries: `ComponentAuthority`, `StructuralAuthority`, `Shared/ShipSocketGraph`, `RigidBody2D`, `TeamIdentity`, `NativeParameterResolver`.

---

## 2026-08-28 — Legacy Runtime Deduplication

Implemented:
- archived the nested `src/roblox/ReplicatedStorage/VoidHunters/VoidHunterWeaponController.luau` prototype;
- archived the nested 13-type `VoidHunterComponents.luau` prototype;
- archived the nested prototype `VoidHunterSoundManager.luau` because its asset IDs/volumes are not forensic-authoritative;
- archived the nested `ShipSocketGraph.luau` re-export because the shared graph is authoritative;
- removed those four legacy entries from the active nested runtime surface;
- preserved provenance and historical notes under `VOIDA/ARCHIVE/LEGACY_RUNTIME/VoidHunters/`;
- recorded the root-level `VoidHunterComponents.luau` as the active richer connection/mesh definition surface;
- added `VOIDA/27_LEGACY_RUNTIME_DEDUPLICATION_AUDIT.md` documenting duplicate-state findings and remaining audit targets.

Behavioral policy:
- This cleanup is a **runtime deduplication** change, not a forensic parity claim.
- Inferred shield/audio/physics behavior remains unverified.
- Forensic source mirrors and definitive-data files are preserved even when superseded by runtime projections.

Next reconciliation:
1. audit remaining imports for deleted nested paths;
2. remove private PvP/resource state where a canonical authority exists;
3. wire native weapon/resource consumers;
4. reconcile shield state and native shield controls;
5. reconcile physics conversion boundaries;
6. complete Mission variable/action/condition sequencing.

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

Explicitly NOT declared verified:
- exact source numerical shield/capacitor values
- exact critical-flash render threshold
- complete Mission framework parity
- exact audiovisual asset parity
- exact decompiled physics formulas where CFR control flow remains unresolved
