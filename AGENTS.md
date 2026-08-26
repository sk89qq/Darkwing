# VOIDA Engineering & Implementation Directives

## 🛑 MANDATORY DECISION TRIAGE RULE
**DO NOT SOLVE A PROBLEM TWICE.**

Before implementing any mechanic or system, MUST follow this exact sequence:

1. **ASK:** *"Does the original client already contain the answer?"*
   - **If YES:** Extract it directly from the decompiled/reference code (`ml.java`, `anb.java`, `sg.java`, `nbb.java`, `wlb.java`, `hab.java`, `wfb.java`, `AlterOrb_VoidHunters_Reference.luau`, client specifications, or original formulas).
2. **THEN ASK:** *"Does Roblox already provide a mechanism capable of reproducing it?"*
   - **If YES:** Use native Roblox engine primitives and APIs (e.g., `WeldConstraint`, `VectorForce`, `AlignOrientation`, `Raycast`, `RunService`, `TweenService`, `CollectionService`).
3. **ONLY IF BOTH ANSWERS ARE NO:**
   - Design custom logic from scratch.

---

## 🔬 SOURCE-TRUTH VERIFICATION RULE
Every engineer-facing value, constant, equation, and schema mapping must be tagged with one of:
- `[CODE_VERIFIED]`
- `[ASSET_VERIFIED]`
- `[ORIGINAL_DATA_VERIFIED]`
- `[ALTERORB_BEHAVIOR_VERIFIED]`
- `[DOCUMENTATION_ONLY]`
- `[INFERRED]`
- `[UNKNOWN]`

*Never silently convert UNKNOWN into a tunable guess.*

---

## Definitive Forensic Data Models

### 1. Component Data Model (`ml.java`) `[CODE_VERIFIED]`
- `j` : `component_type_id` (0..55 in `hab.g[56]`)
- `e` : `triggermap`
- `o` : `connectionpointx`
- `m` : `connectionpointy`
- `q` : `connectedangle`
- `p` : `currentconnectedangle`
- `i` : `health` (clamped to 0, initialized to `wfb.p`)
- `r` : `finalx`
- `n` : `finaly`
- `b` : `finalangle`
- `g[]` : `finaloutline`
- `f[]` : `Component[]` recursive subcomponents
- `d[]` : `Hardpoint[]` hardpoints
- `c` : `WeaponBehaviour` (`qjb`)
- `a` : `ThrusterBehaviour` (`aqa`)
- `k` : `GrappleLauncherBehaviour` (`lja`)
- `h` : generic `ComponentBehaviour` (`mua`, `kma`)

### 2. Body / Physical Model (`anb.java`, `sg.java`, `nbb.java`) `[CODE_VERIFIED]`
- `d` : `x`
- `e` : `y`
- `f` : `dx` (linear velocity X)
- `h` : `dy` (linear velocity Y)
- `r` : `angle`
- `n` : `angularvelocity`
- `i` : `centreofmassx`
- `j` : `centreofmassy`
- `s` : `mass`
- `m` : `momentofinertia`
- `q[]` : `boundingbox`
- `l` : `id`
- `k` : `Component` chassis/root
- Specializations: `sg` = Ship, `nbb` = Debris (adds phantom state `v`, graph detachment creates `new nbb(ml2, false)`).

### 3. Exact Category Color Codes (`wfb.a()`) `[CODE_VERIFIED]`
- `a = -1` → `#D72828` (Red)
- `a = -2` → `#2849D7` (Blue)
- `a = -3` → `#D77628` (Orange)
- `a =  3` → `#DCDCDC` (Grey)
- `a =  4` → `#D728AC` (Pink)
- `a =  5` → `#49D728` (Green)
- `a =  6` → `#8F28D7` (Purple)

### 4. Destruction & Debris Preservation `[CODE_VERIFIED]`
- Destroyed/severed components are NOT immediately deleted.
- They transform via `new nbb(ml2, false)` into physical Debris objects in the world simulation.
- Parent removes child via graph surgery (`this.f(...)`) and triggers parent body COM/Inertia recalculation (`anb.e(...)`).

---

## Persistent Architectural Rules
- **Reference-First**: All physics constants, damping equations ($v_{t+1} = v_t \cdot d^{\Delta t}$), hardpoint topologies, socket dimensions (7 studs), weapon rates of fire, projectile velocities, and match timings must strictly mirror the FunOrb / AlterOrb decompile reference.
- **Engine-Native Leverage**: Utilize Roblox's native physics and DataModel infrastructure wherever it matches the math, avoiding unnecessary layer duplication.
- **Server Authoritative**: All match state transitions, projectile hits, structural damage, severance, and kill crediting must be verified on the server.

