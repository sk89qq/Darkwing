# VOIDA Engineering & Implementation Directives

## 🛑 MANDATORY DECISION TRIAGE RULE
**DO NOT SOLVE A PROBLEM TWICE.**

Before implementing any mechanic or system, MUST follow this exact sequence:

1. **ASK:** *"Does the original client already contain the answer?"*
   - If YES: extract it directly from the decompiled/reference code (`ml.java`, `anb.java`, `sg.java`, `nbb.java`, `wlb.java`, `hab.java`, `wfb.java`, behavior classes, client specifications, or recovered formulas).
2. **THEN ASK:** *"Does Roblox already provide a mechanism capable of reproducing it?"*
   - If YES: use the native Roblox engine primitive/API where it preserves the observable behavior.
3. **ONLY IF BOTH ANSWERS ARE NO:**
   - Design custom logic and label it `[INFERRED]` until validated.

Never create a parallel implementation of a recovered mechanic merely because it is easier to write.

---

## 🔬 SOURCE-TRUTH VERIFICATION RULE
Every engineer-facing value, constant, equation, schema mapping, or claim must be tagged with one of:
- `[CODE_VERIFIED]`
- `[ASSET_VERIFIED]`
- `[ORIGINAL_DATA_VERIFIED]`
- `[ALTERORB_BEHAVIOR_VERIFIED]`
- `[DOCUMENTATION_ONLY]`
- `[INFERRED]`
- `[UNKNOWN]`

`[CODE_VERIFIED]` means the original source itself establishes the behavior/value. A compatible Roblox implementation is not automatically code-verified.

Never silently convert `UNKNOWN` into a tunable guess.

---

## ✅ COMPLETION STATES
Use only:
- `EXTRACTED` — reference behavior/data recovered; runtime parity not established.
- `IMPLEMENTED` — Roblox code exists; parity not demonstrated.
- `VERIFIED` — scoped behavior compared with reference and acceptance-tested.
- `BLOCKED` — required evidence/runtime/resource is unavailable.
- `SUPERSEDED` — intentionally replaced by a newer authoritative implementation.

Code existence is not completion. A `VERIFIED` claim requires an acceptance test and source reference.

---

## 🧠 CANONICAL RUNTIME STATE
The original game is component/graph/body based. Roblox Instances are the physical/rendering projection.

Canonical logical state boundaries:

- `ReplicatedStorage.Shared.Combat.ComponentAuthority` owns per-component runtime state: type, HP, max HP, parent/children, connection state, destroyed/critical state, and immutable base visual color.
- `ReplicatedStorage.Shared.Ship.StructuralAuthority` is the mutation boundary for attach, detach, replacement, and structural severance.
- `ReplicatedStorage.Shared.ShipSocketGraph` remains the hardpoint/socket solver and graph index.
- `ReplicatedStorage.Shared.Physics.RigidBody2D` remains the logical 2D body solver where a native Roblox Assembly cannot reproduce the original observable behavior exactly.
- Server systems are authoritative for combat, damage, graph mutation, match state, and persistence.

Do not create subsystem-local authoritative dictionaries for the same state (for example a second `partHealth[part]` map). Subsystems consume/update `ComponentAuthority` instead.

Attributes on Instances are **mirrors/diagnostics**, not the authoritative source of gameplay state.

---

## 🔗 STRUCTURAL MUTATION RULE
All physical assembly mutations must converge on `StructuralAuthority`:

- manual construction
- dragging
- blueprint/autobuild
- replacement
- damage severance
- manual detach

Do not create ad-hoc nearest-neighbor `WeldConstraint` behavior or delete detached components directly.

A non-root disconnected component/subtree remains extant as a physical debris assembly unless original client evidence establishes a different lifecycle.

Do not invent cleanup timers for damaged/debris components when the source does not establish one.

---

## ❤️ HEALTH / DAMAGE RULE
Health is per Component and reaches a terminal zero state.

Damage, repair, critical-state presentation, and destruction must pass through `ComponentAuthority`.

Do not derive HP from Roblox Part size/name heuristics when authoritative component data exists.

The observed ~15% critical flash threshold is not considered original-code-verified until the original render/update method is recovered; keep that presentation rule isolated and labeled appropriately.

---

## 🎨 TEAM VS COMPONENT COLOR RULE
Historical team identity is **Yellow / Blue**.

Component category colors are independent:
- Red
- Blue
- Orange
- Grey
- Pink
- Green
- Purple

Never recolor an entire component category to indicate team ownership. Use team-specific UI/markers/accents.

---

## 🧩 COMPONENT DATA RULE
Use recovered component definitions and hardpoints as authoritative data.

Do not replace component-specific geometry/topology with generic four-way sockets or name-based assumptions once an authoritative definition exists.

Unknown/missing component definitions must fail closed or be explicitly `[UNKNOWN]`; do not invent fallback topology that changes possible builds.

---

## 🛡️ COMMON ROBLOX STRUCTURE
Preferred placement:

`ReplicatedStorage.Shared.*` — shared pure data/services used by server and client.

`ReplicatedStorage.VoidHunterComponents` — component definitions/factory compatibility layer.

`ServerScriptService.*` — authoritative orchestration, mutation and persistence.

`StarterPlayer.StarterPlayerScripts.*` — local input, presentation and client prediction only.

`Workspace.VoidHunterDebris` — live detached/debris physical assemblies.

Use ModuleScripts for reusable logic, RemoteEvents/RemoteFunctions only at explicit network boundaries, and CollectionService/Attributes for discovery/diagnostics rather than hidden global state.

Avoid `_G` for new systems. Existing `_G` compatibility may remain until the corresponding system is migrated to explicit ModuleScript references.

---

## ⚙️ ENGINE-NATIVE LEVERAGE
Use Roblox native facilities where they preserve observable behavior:
- `AssemblyLinearVelocity` / `AssemblyAngularVelocity`
- `ApplyImpulse`
- `VectorForce`
- `AlignOrientation`
- `WeldConstraint`
- `Raycast`
- `RunService`
- `TweenService`
- `CollectionService`
- Models/Assemblies for grouped physical debris

Do not replace the logical component graph with Roblox weld topology; the graph remains authoritative and welds are a projection.

---

## 🔒 SERVER AUTHORITY
Server is authoritative for:
- damage resolution
- component HP
- repair application
- structural detach/severance
- debris conversion
- weapon/projectile hit confirmation
- energy consumption when gameplay-relevant
- match state
- team assignment
- blueprint persistence

Client may predict/animate only where server reconciliation is preserved.

---

## 📦 PORTING PRINCIPLE
The goal is observable behavioral equivalence to the already functioning local Void Hunters reference, not a Java-to-Luau transliteration.

Preserve original semantics first; use Roblox-native equivalents second; add custom logic only where required.
