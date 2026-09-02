# NATIVE ENERGY / RELOAD STATE — 2026-09-02

Source: original JAR targeted disassembly of native class `sg`. Behavioral port contract; native field names retained only where semantics are proven.

## VERIFIED STATE
- `sg.P:int` = current energy quantity; native diagnostic serialization labels it `energy`.
- `sg.I:int` = reload timer/progress quantity; native diagnostic serialization labels it `reloadtimer`.
- `sg.C:int` = maximum energy; native diagnostic serialization labels it `max_energy`.
- `sg.F:int` = update/shot-related counter; do not collapse into reload state.
- `sg.M:int` = additional countdown/state quantity; native writes include decrement while `O` is active and `M := 49` in another path; semantics remain open.

## LOADED RUNTIME STATE
Native `sg.a(faa,int)` loads P, I, C, G and several booleans plus M and F from serialized state. These are runtime state values, not proof of gameplay defaults.

## MAX ENERGY PRODUCER
Native `sg.e(byte)` executes `C := jo.e + k.a(0)`, where `k` is the native component root (`ml`). Thus maximum energy is recomputed from a native base contribution `jo.e` plus a component-tree contribution returned by `ml.a(0)`. The formula is verified; the internals of `ml.a(0)` and `jo.e` remain producer-chain targets.

## ENERGY CONSUMPTION GATE
Native `sg.a(byte,int)` accepts the valid selector byte 11. If `P > 0`, it performs `P := P - amount`, invokes the native post-energy update path, and returns true. Otherwise it returns false without consuming. The target must preserve this logical gate and avoid arbitrary negative-energy semantics.

## EMPTY-ENERGY RELOAD / RECHARGE
Native `sg.a(pe,boolean,byte,boolean)` after base body update:
1. If `P <= 0`, increment `I`.
2. Increment `F`.
3. On the native reload-threshold condition, reset `I := 0` and set `P := f(true)`; `f(true)` returns `C`.
4. While P is below maximum, add native global recharge increment `sja.b` and clamp to `f(true)`.
5. If `O` is active and `M > 0`, decrement M.

Preserve the native branch ordering and threshold comparisons; do not substitute a generic Roblox recharge loop.

## DERIVED PROGRESS
`m(byte)` returns `I * 255 / max(vdb.d,1)`.
`o(int)` returns `255 * P / max(f(true),1)`.
These are derived 0–255 display/progress values, not independent state.

## EMPTY STATE
`sg.s(byte)` tests the native P/I state against the `vdb.d` threshold. Preserve the exact threshold semantics.

## PORT CONTRACT
Target may expose `currentEnergy`, `maxEnergy`, `reloadTimer`, spend-success, and recharge-progress rather than P/I/C. Preserve native arithmetic, ordering, and thresholds.

## NEXT HIGH-VALUE PRODUCERS/CONSUMERS
1. Resolve `ml.a(0)` to close component contribution to maximum energy.
2. Resolve `jo.e` base-energy source.
3. Trace every writer/caller of `sg.P` to distinguish weapon, shield, recharge, shutdown and reset consumers.
4. Resolve `vdb.d` reload threshold and timing relationship.
5. Map weapon energy-use values into the `sg.a(byte,int)` consumer.

## STATUS
`SOURCE-VERIFIED / IMPLEMENTATION-READY for energy gate + reload/recharge structure; producer aggregation and complete consumer map remain active.`
