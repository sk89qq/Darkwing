# Task 4 Native State / Resource Continuation — 2026-09-02

Authority: original Void Hunters JAR and javap bytecode only.
Purpose: implementation-ready behavioral port contract for Luau + Box2D + Roblox; not literal Java translation.

## sg native state inventory

Native class `sg extends anb implements ntb,utb` fields:
`x:int[]`, `P:int`, `G:int`, `y:boolean`, `A:int`, `R:boolean`, `L:qua`, `S:boa`, `N:int`, `H:static int`, `u:int`, `E:static int`, `M:int`, `v:int`, `T:boolean`, `Q:int`, `K:boolean`, `F:int`, `D:boolean`, `I:int`, `J:int[]`, `C:int`, `O:boolean`, `w:boolean`, `z:aoa`.

Only mappings established by caller/dataflow evidence are semantic. Unresolved fields must not be renamed by inference.

## Verified state relationships

### Maximum energy
`sg.e(byte)` calls `anb.e(byte)` and then performs:
`C := jo.e + k.a(0)`
where `k:Lml` is the component tree.

Port contract: maximum resource capacity is derived from a fixed/native base contribution plus the component-tree contribution. It must be recomputed when the native body/component state is recomputed; do not hardcode a duplicated target value.

### Current energy and reload state
Active forensic mapping:
- `P` = current energy/resource amount.
- `I` = reload/recharge timer/progress state.
- `C` = maximum energy/resource capacity.

These are forensic port labels, not native semantic names.

### Energy availability predicate
`sg.s(byte)` checks the native energy/reload state and returns the native boolean result. Preserve the exact comparison/order until all callers are closed; do not replace it with a generic cooldown abstraction.

### Capability bitmask
`sg.b(int,byte)` returns `(A & argument) != 0`. This is a verified bitmask predicate. Individual bit meanings remain unresolved until callers establish them.

### Resource/index list mutation
`sg.c(int,int)` checks the native `Q` gate, tests whether the supplied integer is already present in `J`, and when absent adds it through native helper `qi.a(...)`. For a non-sentinel second argument it sets `M := 18`.

This is a native state mutation and must be represented logically in the port even if the target uses a different data structure.

### Derived state accessor
`sg.y(int)` returns `-oq.e + M` after the native obfuscation guard. This is a derived value, not an independent constant.

### Cleanup/reset
`sg.B(int)` clears `J`; on the relevant non-sentinel path it also clears `S`. Treat as lifecycle/reset behavior until caller evidence establishes its exact trigger.

### Accessors/predicates
- `sg.w(int)` returns `G`.
- `sg.q(int)` returns true when `y` is true and `G == oq.I`, subject to the native sentinel guard.
- `sg.q(byte)` returns `N`, with a helper call on the relevant guard path.
- `sg.n(byte)` returns `S` after a helper call on the relevant guard path.
- `sg.r(byte)` returns `K` except on the native guard path.
- `sg.n(int)` returns `R` except on the native guard path.

Do not assign higher-level names without caller evidence.

## UI/state projection
`sg.a(ij,int,boolean,boolean)` emits state-dependent records. Verified dependencies include:
- `y` selects a `2` vs `0` value in one branch.
- `G` is emitted in the alternate branch.
- `O` controls an additional `0` record.
- `K` controls emission of `M`.
- the component tree `k` is passed into `ml.a(ij,sg,0)`.

The target may implement this presentation differently, but the logical source state must remain available.

## Native recharge/resource boundary still open

Do not mark the following resolved until producer/consumer tracing is complete:
- exact producer semantics of `jo.e`;
- complete semantics of `ml.a(0)` across all structural states;
- exact post-spend behavior reached through `sg.d(-126)` and related calls;
- exact recharge increment source involving `vdb.d` / `sja.b`;
- every gameplay consumer of `P`, `C`, and `I`;
- exact meanings of unresolved capability/state fields.

## Port-readiness rule

The target implementation is allowed to reorganize classes, state containers, networking, and rendering. It must preserve verified observable behavior and native input/output relationships. Box2D owns generic rigid-body integration and collision solving; forensic work supplies the gameplay inputs crossing that boundary.
