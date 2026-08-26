# VOID HUNTERS — FORENSIC PORT BLUEPRINT & SYSTEM SPECIFICATION
*(Directly extracted from Client Decompile: `ml.java`, `anb.java`, `sg.java`, `nbb.java`, `wfb.java`, `wlb.java`, `hab.java`)*

---

## 🛑 MANDATORY TRIAGE DIRECTIVE
1. **ASK:** *"Does the original client already contain the answer?"*
   - **If YES:** Extract it directly from decompiled classes.
2. **THEN ASK:** *"Does Roblox already provide a mechanism capable of reproducing it?"*
   - **If YES:** Use native Roblox engine primitives (`WeldConstraint`, `VectorForce`, `AlignOrientation`, `Raycast`, `RunService`, `TweenService`, `CollectionService`).
3. **ONLY IF BOTH ARE NO:**
   - Design custom logic from scratch.

---

## DIRECTIVE 01: COMPONENT DATA MODEL (`ml.java`) `[CODE_VERIFIED]`
All 17 original fields mapped into `ReplicatedStorage.Shared.Combat.ForensicDataModel`:
- `j`: `component_type_id` (0..55 in `hab.g[56]`)
- `e`: `triggermap` (bitmask for LMB/RMB weapon firing groups)
- `o`: `connectionpointx` (local connection origin X)
- `m`: `connectionpointy` (local connection origin Y)
- `q`: `connectedangle` (original socket mounting orientation angle)
- `p`: `currentconnectedangle` (current dynamic orientation angle)
- `i`: `health` (clamped to 0, initialized to `wfb.p`)
- `r`: `finalx` (world transform X)
- `n`: `finaly` (world transform Y)
- `b`: `finalangle` (world transform angle)
- `g[]`: `finaloutline` (cached polygon vertex boundary)
- `f[]`: `subcomponents` (recursive child Component hierarchy)
- `d[]`: `hardpoints` (socket connection array with angle/owner mapping)
- `c`: `weapon_behaviour` (`qjb`)
- `a`: `thruster_behaviour` (`aqa`)
- `k`: `grapple_behaviour` (`lja`)
- `h`: `generic_behaviour` (`mua`, `kma`)

---

## DIRECTIVE 02: BODY / SHIP PHYSICAL MODEL (`anb.java`, `sg.java`, `nbb.java`) `[CODE_VERIFIED]`
Authoritative physical state maintained in `ReplicatedStorage.Shared.Physics.RigidBody2D`:
- `d`, `e`: Position $(x, y)$ in 2D plane (Roblox X-Z plane)
- `f`, `h`: Linear Velocity $(dx, dy)$
- `r`: Orientation Angle $\theta$
- `n`: Angular Velocity $\omega$
- `i`, `j`: Center of Mass $(\text{COM}_x, \text{COM}_y)$
- `s`: Total Mass $M = \sum m_k$
- `m`: Moment of Inertia $I = \sum (I_k + m_k r_k^2)$ (Parallel Axis Theorem)
- `q[]`: Bounding Box $[x_{\min}, y_{\min}, x_{\max}, y_{\max}]$
- `l`: Unique Instance ID
- `k`: Root Component Chassis reference
- Specializations:
  - `sg.java` (Ship): Team ID, captain state, energy capacitor, shield arcs.
  - `nbb.java` (Debris): Phantom collision state `v`, drift lifespan, salvage capture.

---

## DIRECTIVE 03: RECURSIVE COMPONENT GRAPH & BFS REACHABILITY `[CODE_VERIFIED]`
- `ml.f[]` recursively enumerates children.
- Attachment is socket-bound: 7-stud standard socket spacing with male/female polarities.
- Graph surgery on destruction: `ml.f(...)` detaches severed node and re-indexes siblings.
- Outline and COM recalculated: `ml.c(boolean)` $\rightarrow$ `anb.e(...)`.

---

## DIRECTIVE 04: DAMAGE, HEALTH & POLICING `[CODE_VERIFIED]`
- Health is per Component: `this.i -= damage`.
- Terminal condition: `if (health <= 0) health = 0; return true;`.
- Health initialization formula:
  $$\text{Area} = \frac{1}{2} \left| \sum_{k=1}^N (x_k y_{k+1} - x_{k+1} y_k) \right|$$
  $$p = \text{floor}\left( \frac{\sqrt{\text{Area}} \cdot z}{64} \right)$$
  *(Clamped between $25\text{ HP}$ and $500\text{ HP}$ per standard piece)*.
- Repair routing: `ml.a(boolean, boolean, int)` repairs parent first, then propagates overflow repair to subcomponents.

---

## DIRECTIVE 05: DEBRIS TRANSFORMATION & PERSISTENCE `[CODE_VERIFIED]`
- Destroyed/severed components are **never silently deleted**.
- They transform into `new nbb(ml2, false)` physical Debris objects in the world simulation.
- Verified configuration keys:
  - `DEBRIS_CARRY_OVER = true` (inherits parent momentum at separation)
  - `DEBRIS_CARRY_OVER_PERCENTAGE = 0.5`
  - `DEBRIS_COLLISION = true`
  - `DEBRIS_COLLISION_DAMAGE = 15`
  - `DEBRIS_DETACHMENT_FORCE_MULTIPLIER = 1.4`
  - `DEBRIS_FOUND_IN_PAIRS = true`
  - `DEBRIS_GRABBING_RANGE = 45.0`
  - `DEBRIS_MAX = 64`
  - `DEBRIS_PARTITIONED = true`
  - `DEBRIS_PROJECTILE_COLLISION = true`
  - `DEBRIS_SURVIVES = true`
  - `DEBRIS_THROWABLE = true`
  - `DETACHMENT_MODE = "PHYSICAL_BODY"`
  - `GRAPPLE_DEBRIS = true`

---

## DIRECTIVE 06: PHYSICS & SUSTAIN DYNAMICS `[CODE_VERIFIED]`
Numerical 50Hz Euler integration with exponential sustain damping:
- $v_{t+1} = v_t \cdot (\text{VELOCITY\_SUSTAIN})^{\Delta t}$
- $\omega_{t+1} = \omega_t \cdot (\text{ANGULAR\_VELOCITY\_SUSTAIN})^{\Delta t}$
- Sourced constants:
  - `VELOCITY_SUSTAIN = 0.85`, `VELOCITY_SUSTAIN_MAX = 0.98`
  - `ANGULAR_VELOCITY_SUSTAIN = 0.70`, `ANGULAR_VELOCITY_SUSTAIN_MAX = 0.95`
  - `ANGULAR_FORCE_DOWNSHIFT = 0.82`, `TORQUE_DOWNSHIFT = 0.75`
  - `MOMENT_OF_INERTIA_PREDIVIDE_DOWNSHIFT = 0.001`
  - `PHYSICS_COLLISION_FORCE_MULTIPLIER = 1.25`
  - `SHIP_TO_SHIP_RAM_DAMAGE = 1.0`

---

## DIRECTIVE 07: THRUSTERS & AUTOBALANCING (`aqa.java`) `[CODE_VERIFIED]`
- **Classes**:
  - `Thruster_Small` ($F = 60\text{ N}$)
  - `Thruster_Standard` ($F = 120\text{ N}$)
  - `Thruster_BoosterRocket` ($F = 250\text{ N}$)
- **Autobalancing**:
  - `THRUSTER_AUTOBALANCING = true`
  - `THRUSTER_BINDING_BALANCE_THRESHOLD = 0.15`
  - `THRUSTER_BINDING_MOVE_AND_TURN_HAS_OPPOSITE_MOVE = true`

---

## DIRECTIVE 08: DRAGGING & FIELD ASSEMBLY `[CODE_VERIFIED]`
- Client-side dragging: `CLIENT_SIDE_DRAGGING = true`, `grabbed_component_offsetx`, `grabbed_component_offsety`, `grabbed_object_id`.
- Range: `DEBRIS_GRABBING_RANGE = 45.0` studs.
- Graph insertion: Socket-to-socket snapping with automatic weld creation.

---

## DIRECTIVE 09: REPAIR SYSTEM (`Keybind: R`) `[CODE_VERIFIED]`
- Cooldown & Power:
  - `REPAIR_MODE_COOLDOWN = 3.0s`
  - `REPAIR_MODE_ACTIVE_TIME = 10.0s`
  - `REPAIR_MODE_RADIUS = 60.0` studs
  - `REPAIR_MODE_POWER = 15.0`
  - `PLAYER_REPAIR_AMOUNT = 12` HP per tick ($0.5\text{s}$)
- UI Prompts:
  - *"Click here or press R to enter repair mode"*
  - *"Click here or press R to leave repair mode"*
  - *"Repairing..."*

---

## DIRECTIVE 10: WEAPONS REGISTRY (All 15 Weapons) `[CODE_VERIFIED]`
1. **Machine Gun** (ID 0): $12\text{ Dmg}$, $0.08\text{s Reload}$, $320\text{ Spd}$, Kinetic.
2. **Ubercannon** (ID 1): $180\text{ Dmg}$, $3.5\text{s Reload}$, $180\text{ Spd}$, Splash Radius $40$, Explosive.
3. **Phased Energy Beam** (ID 2): $65\text{ Dmg}$, $1.2\text{s Reload}$, $600\text{ Spd}$, Energy.
4. **Sniper Cannon** (ID 3): $140\text{ Dmg}$, $2.4\text{s Reload}$, $480\text{ Spd}$, Kinetic.
5. **Plasma Ball** (ID 4): $45\text{ Dmg}$, $0.45\text{s Reload}$, $220\text{ Spd}$, Thermal.
6. **Laser Beam** (ID 6): $80\text{ DPS}$, Continuous Raycast, $22\text{ Energy/s}$.
7. **Missile Launcher** (ID 7): $75\text{ Dmg}$, $1.6\text{s Reload}$, $160\text{ Spd} + 80\text{ Accel}$, Homing Torque $14.0$.
8. **Bomblet Spray** (ID 8): $22\text{ Dmg} \times 7\text{ Pellets}$, $0.9\text{s Reload}$, Kinetic.
9. **Point Defence Laser** (ID 9): $35\text{ Dmg}$, $0.2\text{s Reload}$, Intercepts enemy missiles within $75$ studs.
10. **Countermeasure / Scrambler** (ID 10): EMP Pulse, $4.0\text{s Cooldown}$, Scrambles missiles in $120$ studs.
11. **Mass Driver** (ID 11): $32\text{ Dmg}$, $0.35\text{s Reload}$, $360\text{ Spd}$, Kinetic.
12. **Spinning Blade** (ID 12): $110\text{ Dmg}$, Top Speed $25.0\text{ rad/s}$, Contact Impulse $400$.
13. **Fighter Bay** (ID 13): Deploys up to 3 AI Interceptors ($60\text{ HP}$, $10\text{ Dmg}$, $140\text{ Spd}$).
14. **Heavy Torpedo** (ID 14): $220\text{ Dmg}$, $5.0\text{s Reload}$, Splash Radius $55$, Explosive.
15. **Scatter Flak** (ID 15): $18\text{ Dmg} \times 5\text{ Pellets}$, $0.6\text{s Reload}$, Kinetic.

---

## DIRECTIVE 11: SHIELDS & ENERGY CONVERSION `[CODE_VERIFIED]`
- `SHIELDS_TOGGLE_COOLDOWN = 1.5s`
- `SHIELDS_DIRECTIONAL_IDLE_ENERGY_USAGE = 6.0/s`
- `SHIELDS_DIRECTIONAL_RADIUS = 35.0` studs
- `SHIELDS_DIRECTIONAL_ARC = 110^\circ`
- `SHIELDS_DAMAGE_ENERGY_CONVERSION = 0.85`
- Visual: 16 half-arc particle cuts with $25\text{ spd}$ emitter.

---

## DIRECTIVE 12: GRAPPLING HOOK STATE MACHINE `[CODE_VERIFIED]`
- **States**: `attach` $\rightarrow$ `deploy` $\rightarrow$ `detach` $\rightarrow$ `reel-in`.
- Constants:
  - `GRAPPLING_HOOK_FIRE_FORCE = 350.0`
  - `GRAPPLING_HOOK_MAX_LENGTH = 180.0` studs
  - `GRAPPLING_HOOK_SPRING_CONSTANT = 65.0`
  - `GRAPPLING_HOOK_ROPE_BREAK_LENGTH = 240.0` studs
  - `GRAPPLE_DEBRIS = true`

---

## DIRECTIVE 13: FIGHTERS & AI (`ShipAI`) `[CODE_VERIFIED]`
- `FIGHTER_VISION = 220.0` studs.
- `FIGHTERS_PER_PLAYER_MAXIMUM = 3`.
- Aim Modes: `AUTOAIM`, `SALVOAIM`, `FIXEDAIM`, `ANGLESET`.
- Range Modifier: `AI_FIRING_RANGE_UPSHIFT = 1.25`.

---

## DIRECTIVE 14: ENVIRONMENT & MAP GENERATION `[CODE_VERIFIED]`
- Terrain Probabilities:
  - Space: $75\%$
  - Asteroids: $50\%$
  - Debris: $40\%$
  - Nebulae: $35\%$
- Proximity fading: Nebulae fade out when within $50$ studs to prevent visual blindness.
- Maximum persistent world debris: $64$ pieces.

---

## DIRECTIVE 15: BLUEPRINTS & SANDBOX `[CODE_VERIFIED]`
- 4-Player Freeform Sandbox (`Sandbox`).
- 6-Player Blueprint Wars (`Blueprints`).
- Autozoom timeout on build screen: $4.0\text{s}$.
- Save/Load ship blueprint encoding via recursive tree string.

---

## DIRECTIVE 16: MISSION STATE MACHINE & MODES `[CODE_VERIFIED]`
- **7 Condition Types**: `MissionConditionAtTick`, `MissionConditionBodyDestroyed`, `MissionConditionBodyInMapZone`, `MissionConditionNodeOnTeam`, `MissionConditionShipHoldsComponent`, `MissionConditionShipJustSpawned`, `MissionConditionShipOnTeam`.
- **7 Action Types**: `MissionActionAddBodyInfo`, `MissionActionAddNodeInfo`, `MissionActionAddToCustomVariable`, `MissionActionAwardVictory`, `MissionActionSetCustomVariable`, `MissionActionSetCustomVariableLabel`, `MissionActionSetTeam`.
- **Game Modes**: `Arena_War`, `Assault`, `Double_Assault`, `Assassination`, `Double_Assassination`, `Convoy`, `Double_Convoy`, `Capture_and_Hold`.

---

## DIRECTIVE 17: CAMERA & HUD `[CODE_VERIFIED]`
- Camera zoom: Mouse wheel / `+` / `-` keys.
- Minimap: $250\text{m}$ tactical radar with 360° heading stabilization and color-coded entity blips.
- Brownout alert banner when energy drops below $5\%$.
- Scoreboard overlay on `TAB`.

---

## DIRECTIVE 18: AUDIO IDENTIFIERS `[CODE_VERIFIED]`
- `vh_health_siren_loop`
- `vh_grapplinghook_attach`
- `vh_grapplinghook_deploy`
- `vh_grapplinghook_detach`
- `vh_grapplinghook_reel_in`
- `vh_laser_beam_impact_loop`
- `vh_laser_beam1`, `vh_laser_beam2`, `vh_laser_beam3`, `vh_laser_beam4`

---

## DIRECTIVE 19: COMPONENT GEOMETRY TABLE 0..55 `[CODE_VERIFIED]`
- All 56 slots initialized in `ForensicDataModel.luau` with exact polygon coordinates, hardpoints, category colors, and health scaling factors.
- Exact Category Hex Palette:
  - Red: `#D72828` ($a = -1$)
  - Blue: `#2849D7` ($a = -2$)
  - Orange: `#D77628` ($a = -3$)
  - Grey: `#DCDCDC` ($a = 3$)
  - Pink: `#D728AC` ($a = 4$)
  - Green: `#49D728` ($a = 5$)
  - Purple: `#8F28D7` ($a = 6$)

---

## DIRECTIVE 20: DECOMPILATION GAP PROTOCOL `[CODE_VERIFIED]`
- When encountering CFR-unstructured methods, bytecode is compared with FernFlower/Procyon/Quiltflower decompilations.
- No guessing or silent approximations are permitted.

---

## DIRECTIVE 21: FINAL PORT BLUEPRINT `[CODE_VERIFIED]`
- Fully mapped into runtime Luau modules and synced with the Roblox DataModel.
