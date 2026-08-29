# Native `wfb` → runtime field hints

This pass uses the already-recovered architecture rather than inventing semantics from field names.

## Strong mappings

- `wfb.u` — polygon double-area / 2. It is the native geometric area basis used by `ml.e(byte)` before `lw.a(...)` mass conversion. **Runtime role: component area basis.**
- `wfb.p` — component mass produced from the area basis through `lw.a(byte,u)` and `wfb.z`. **Runtime role: component mass.**
- `wfb.z` — mass scaling factor participating directly in the native component-mass calculation. **Runtime role: mass coefficient, not MaxHealth.**
- `wfb.r` — local/native component X coordinate used by the COM accumulator. **Runtime role: local position X.**
- `wfb.s` — local/native component Y coordinate used by the COM accumulator. **Runtime role: local position Y.**
- `wfb.g` — interleaved polygon vertex array. **Runtime role: collision/geometry vertices.**
- `wfb.a` — constructor default `6`; source behavior writes this field through a dedicated integer property path. **Runtime role: native integer component property; semantic name still source-gated.**

## Body fields confirmed by `anb` architecture

- `anb.d/e` — body position.
- `anb.f/h` — linear velocity.
- `anb.r` — body rotation/orientation.
- `anb.n` — angular velocity.
- `anb.s` — aggregate mass.
- `anb.i/j` — aggregate center of mass.
- `anb.m` — aggregate moment of inertia.
- `anb.o/t` — transient linear accumulators.
- `anb.p` — transient torque accumulator.

These are not guesses: the native equation recovery documents the copy path and the equations consuming these fields.

## Common `wfb` constructor defaults

The constructor initializes:
`f=false, h=256, r=false, s=false, z=256, y=0, B=256, d=0, q=256, k=true, a=6`.

The current architecture does **not** prove that these boolean/integer properties correspond to Roblox `Anchored`, `CanCollide`, HP, shield, energy, or similar names. Therefore this pass intentionally does not assign those semantic labels.

## Implementation rule

The safe runtime adapter should carry these values as native component properties. It may expose explicit typed accessors only where the native consumer proves the role. It must not translate `h/z/B/q/a` into Roblox gameplay concepts merely because the numbers resemble prototype defaults.

## Result
This closes the strongest field→runtime hints available from the discovered architecture and narrows the remaining unknowns to the exact native consumers of the generic property fields, rather than treating all `wfb` fields as unmapped.
