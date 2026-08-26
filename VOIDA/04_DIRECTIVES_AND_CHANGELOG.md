# VOIDA Directives & Changelog Logbook

## Overview
This file tracks all received directives, parameter adjustments, and version updates applied by the AI Studio Brain.

---

## 🛑 Core Engineering Directive: Problem-Solving Triage
**DO NOT SOLVE A PROBLEM TWICE.**

Before implementing any mechanic:
1. **ASK:** *"Does the original client already contain the answer?"*
   - **If YES:** Extract it directly from original reference / decompile code.
2. **THEN ASK:** *"Does Roblox already provide a mechanism capable of reproducing it?"*
   - **If YES:** Use native Roblox engine primitives and APIs.
3. **ONLY IF BOTH ANSWERS ARE NO:**
   - Design new logic.

*This directive is persisted in `AGENTS.md` and referenced on every execution turn.*

---

## Directives Registry

### [Phase 0 - Initialization]
- **Status:** Complete
- **Actions Taken:**
  - Initialized dedicated `/VOIDA` folder.
  - Formulated full DataModel structure inventory (`01_GAME_STRUCTURE_INVENTORY.md`).
  - Formulated core gameplay loop state machine (`02_BASELINE_GAMEPLAY_LOOP.md`).
  - Drafted client-server network RPC manifest (`03_NETWORK_RPC_MANIFEST.md`).

### [Phase 1 - Physics & RigidBody2D Engine]
- **Status:** Complete
- **Actions Taken:**
  - Integrated 50Hz fixed-timestep physics engine matching FunOrb / AlterOrb decompile specifications.
  - Implemented `ReplicatedStorage.Shared.Physics.PhysicsConfig` with calibrated linear damping (`0.85`), angular damping (`0.70`), brake damping, max velocity clamps, and restitution factors.
  - Implemented `ReplicatedStorage.Shared.Physics.MassPoint` with parallel-axis theorem rotational inertia calculations.
  - Implemented `ReplicatedStorage.Shared.Physics.RigidBody2D` with dynamic Center of Mass, Moment of Inertia, Vectored Thrust, and force/torque accumulation.
  - Implemented `ReplicatedStorage.Shared.Physics.PhysicsWorld` featuring circle-circle collision manifolds, momentum-conserving impulse resolution, tractor beam springs, and 2D spatial raycasting.
  - Implemented `ReplicatedStorage.Shared.Physics.Thruster` component modeling.
  - Connected `StarterPlayer.StarterPlayerScripts.VoidHunterController` directly into `RigidBody2D` with real-time mass re-distribution during assembly and build-mode detachment.

### [Phase 2 - Ship Assembly & Socket Graph]
- **Status:** Complete
- **Actions Taken:**
  - Implemented `ReplicatedStorage.Shared.ShipSocketGraph` modeling component sockets (`InConnect` female receivers, `OutConnect` male plugs, 7-stud standard grid & hexagonal transforms).
  - Built real-time socket matching, directional plug-to-socket orientation solver, and automatic `WeldConstraint` hierarchy generation.
  - Implemented BFS Root Reachability Validation (`ValidateReachability` / `SeverUnreachableComponents`).
  - Integrated `ShipSocketGraph` into `StarterPlayerScripts.VoidHunterController` for interactive drag & drop snapping and detachment.
  - Integrated BFS severance into `ServerScriptService.VoidHunterWeaponController` so weapon damage that breaks structural hull joints severs all disconnected subtrees into floating 2D debris with linear/angular momentum.
  - Linked assembly changes back to `RigidBody2D` to dynamically recompute Center of Mass and Moment of Inertia on the fly.

### [Phase 3 - Tactical Combat, Weapons & Projectile Ballistics]
- **Status:** Complete
- **Actions Taken:**
  - Implemented `ReplicatedStorage.Shared.Combat.CombatTypes` specifying 5 damage typologies (`Kinetic`, `Thermal`, `Energy`, `Explosive`, `EMP`).
  - Implemented `ReplicatedStorage.Shared.Combat.CapacitorSystem` modeling energy generation, reactor scaling, brownouts, and weapon/thruster power drain.
  - Implemented `ReplicatedStorage.Shared.Combat.ShieldSystem` featuring dynamic damage type absorption multipliers (e.g. EMP 2.50x shield drain, Kinetic 0.70x mitigation), broken shield reboot delay, and visual hit ripples.
  - Implemented `ReplicatedStorage.Shared.Combat.BallisticsEngine` with velocity inheritance ($v_{\text{proj}} = v_{\text{ship}} + v_{\text{muzzle}} \cdot \text{dir}$), swept 2D collision integration, homing guidance, and physical impulse transfer ($J = m \cdot \Delta v$).
  - Integrated combat subsystems into `ServerScriptService.VoidHunterWeaponController` for full server-authoritative damage resolution and kinetic ship knockback.
  - Enhanced `StarterPlayerScripts.VoidHunterController` with split weapon firing controls (LMB primary kinetic/beam, RMB secondary heavy ordnance/plasma/missiles, F scrambler pulse, T shield toggle).

### [Phase 4 - HUD, Radar & Arena Match Loop]
- **Status:** Complete
- **Actions Taken:**
  - Implemented `ReplicatedStorage.Shared.Combat.MatchState` specifying pacing durations (Lobby 15s, Ingress 4s, Active 180s, Settlement 10s), score thresholds, and player stat schemas.
  - Implemented `ServerScriptService.VoidHunterMatchManager` managing the complete match state machine, team scoring (Red vs Blue), kill/damage tracking, win conditions, and remote synchronization.
  - Integrated match manager callbacks into `ServerScriptService.VoidHunterPvPSystems` to credit kills, deaths, damage, and assists in real time.
  - Implemented high-resolution tactical client HUD in `StarterPlayerScripts.VoidHunterHUD`:
    - **360° Rotating Radar**: 250m tactical display with range rings (33%, 66%, 95%), heading rotation, and color-coded entity blips (Red for enemies, Blue for allies, Gold for salvage, Grey for asteroids).
    - **Ship Vitality Gauges**: Command Core HP bar with exact numerical readouts, Deflector Shield capacity bar, and Capacitor Power gauge with Brownout warnings.
    - **Arena Match Header**: Dynamic countdown timer, round number, phase label, and real-time team score ticker.
    - **Match Notifications**: High-visibility banner popups for sector ingress, round engagement, and victory celebrations.
    - **Interactive Scoreboard**: Tab-toggled overlay listing player rankings, team affiliation, K/D/A, damage dealt, and match points.
    - **Killfeed Ticker**: Real-time multi-line combat event feed.

### [Phase 5 - Forensic Port Blueprint Alignment & Definitive Data Models]
- **Status:** Complete
- **Actions Taken:**
  - Integrated all 21 Forensic Port Directives from the Void Hunters client decompile into `AGENTS.md` and system prompts.
  - Sourced and established the **Source-Truth Verification Rule** with tags (`[CODE_VERIFIED]`, `[ASSET_VERIFIED]`, `[ORIGINAL_DATA_VERIFIED]`, `[ALTERORB_BEHAVIOR_VERIFIED]`, `[DOCUMENTATION_ONLY]`, `[INFERRED]`, `[UNKNOWN]`).
  - Created `ReplicatedStorage.Shared.Combat.ForensicDataModel` containing:
    - `ml.java` Component structure (`j`, `e`, `o`, `m`, `q`, `p`, `i`, `r`, `n`, `b`, `g[]`, `f[]`, `d[]`, `c`, `a`, `k`, `h`).
    - `anb.java` Body structure (`d`, `e`, `f`, `h`, `r`, `n`, `i`, `j`, `s`, `m`, `q[]`, `l`, `k`).
    - Exact `wfb.a()` Category Color palette (`-1` Red `#D72828`, `-2` Blue `#2849D7`, `-3` Orange `#D77628`, `3` Grey `#DCDCDC`, `4` Pink `#D728AC`, `5` Green `#49D728`, `6` Purple `#8F28D7`).
    - Exact 56 Component Geometry Definitions from `wlb.java` / `hab.g[56]`.
    - Debris configuration (`DEBRIS_CARRY_OVER`, `DEBRIS_COLLISION_DAMAGE`, `DEBRIS_DETACHMENT_FORCE_MULTIPLIER`, `DEBRIS_FOUND_IN_PAIRS`, `DEBRIS_GRABBING_RANGE`, `DEBRIS_MAX`, etc.).
  - Preserved Debris creation behavior (`new nbb(ml, false)`) upon structural joint severance.


