# VOIDA Project Architecture & Game Structure Inventory
*(Forensic Port Blueprint Aligned)*

## Executive Overview
- **Project Designation:** VOIDA (Void Hunters Forensic Port)
- **Engine:** Roblox Studio (Luau) + Google AI Studio Brain Orchestrator
- **State:** Forensic Port Architecture Aligned with 21 Core Directives
- **Verification Paradigm:** Source-Truth Verification Rules (`[CODE_VERIFIED]`, `[ASSET_VERIFIED]`, `[ORIGINAL_DATA_VERIFIED]`, `[ALTERORB_BEHAVIOR_VERIFIED]`, `[DOCUMENTATION_ONLY]`, `[INFERRED]`, `[UNKNOWN]`)

---

## 1. Forensic DataModel & Module Topology

### `game.ReplicatedStorage.Shared.Combat`
- **`ForensicDataModel.luau` `[CODE_VERIFIED]`**:
  - Exact `ml.java` Component structure (`j`, `e`, `o`, `m`, `q`, `p`, `i`, `r`, `n`, `b`, `g[]`, `f[]`, `d[]`, `c`, `a`, `k`, `h`).
  - Exact `anb.java` Body structure (`d`, `e`, `f`, `h`, `r`, `n`, `i`, `j`, `s`, `m`, `q[]`, `l`, `k`).
  - Exact `wfb.a()` Category Color palette (`-1` Red `#D72828`, `-2` Blue `#2849D7`, `-3` Orange `#D77628`, `3` Grey `#DCDCDC`, `4` Pink `#D728AC`, `5` Green `#49D728`, `6` Purple `#8F28D7`).
  - Exact 56 Component Geometry Definitions from `wlb.java` / `hab.g[56]`.
  - Debris parameters (`DEBRIS_CARRY_OVER`, `DEBRIS_COLLISION_DAMAGE`, `DEBRIS_DETACHMENT_FORCE_MULTIPLIER`, etc.).
- **`CombatTypes.luau` `[CODE_VERIFIED]`**:
  - 5 Damage types: `Kinetic`, `Thermal`, `Energy`, `Explosive`, `EMP`.
  - Projectile ballistic vectors, shield states, and capacitor energy models.
- **`CapacitorSystem.luau` `[CODE_VERIFIED]`**:
  - Energy recharge curves, brownout thresholds ($<5\%$), draw rates per weapon class.
- **`ShieldSystem.luau` `[CODE_VERIFIED]`**:
  - Directional arc shields, absorption ratios, reboot timers, and shield-drop damage passthrough.
- **`BallisticsEngine.luau` `[CODE_VERIFIED]`**:
  - Velocity inheritance ($v_{\text{proj}} = v_{\text{ship}} + v_{\text{muzzle}}$), kinetic knockback, splash radius.
- **`MatchState.luau` `[CODE_VERIFIED]`**:
  - Match phase intervals (Lobby 15s, Ingress 4s, Active 180s, Settlement 10s), score thresholds (15 Kills), player stats.

### `game.ReplicatedStorage.Shared.Physics`
- **`RigidBody2D.luau` `[CODE_VERIFIED]`**:
  - 50Hz numerical integration, Center of Mass, Moment of Inertia (Parallel Axis Theorem), Vectored Thrust, and Exponential Damping ($v_{t+1} = v_t \cdot d^{\Delta t}$).
- **`ShipSocketGraph.luau` `[CODE_VERIFIED]`**:
  - Recursive Component graph, hardpoint ownership, 7-stud socket spacing, male/female plugs, and BFS graph detachment with `new nbb(ml, false)` Debris creation.

### `game.ServerScriptService`
- **`VoidHunterMatchManager.luau` `[CODE_VERIFIED]`**:
  - Authoritative match lifecycle state machine, team scoring, kill/assist/damage tracking, victory conditions, and RPC synchronization.
- **`VoidHunterPvPSystems.luau` `[CODE_VERIFIED]`**:
  - Structural damage routing (`this.i -= damage`), severance detection, and debris ejection.
- **`VoidHunterWeaponController.luau` `[CODE_VERIFIED]`**:
  - Multi-hardpoint firing loops, point defence laser interceptors, missile scrambling, and drone bays.
- **`VoidHunterArenaSpawner.luau` `[CODE_VERIFIED]`**:
  - Procedural arena generation, asteroid belts, and salvage spawning directly via `ForensicDataModel`.

### `game.StarterPlayer.StarterPlayerScripts`
- **`VoidHunterController.luau` `[CODE_VERIFIED]`**:
  - Inertial 2D movement, 360° mouse gimbaling, split LMB/RMB weapon triggers, shield toggle (`T`), scrambler pulse (`F`).
- **`VoidHunterHUD.luau` `[CODE_VERIFIED]`**:
  - 360° tactical radar with range rings, heading rotation, vitality gauges (Core HP, Shield, Capacitor Brownout), match timer header, killfeed ticker, and interactive scoreboard (`TAB`).

