# Native `wfb` Field → Runtime Map

## Pass result
The architecture evidence permits a stronger implementation map for the `wfb` fields already recovered, but not a semantic promotion of the remaining generic integers.

| Native field | Native/runtime role | Implementation treatment |
|---|---|---|
| `g` | interleaved polygon vertices | geometry/collision source |
| `u` | polygon double-area / 2 | area basis |
| `z` | coefficient in `p = lw.a(byte,u) * z` | mass coefficient |
| `p` | derived component mass | mass source for aggregate physics |
| `r` | component local X | COM position input |
| `s` | component local Y | COM position input |
| `f` | constructor boolean default false | preserve as native boolean; semantic consumer unresolved |
| `h` | constructor integer default 256 | preserve as native integer; semantic consumer unresolved |
| `y` | constructor integer default 0 | preserve as native integer; semantic consumer unresolved |
| `B` | constructor integer default 256 | preserve as native integer; semantic consumer unresolved |
| `d` | constructor integer default 0 | preserve as native integer; semantic consumer unresolved |
| `q` | constructor integer default 256 | preserve as native integer; semantic consumer unresolved |
| `k` | constructor boolean default true | preserve as native boolean; semantic consumer unresolved |
| `a` | constructor integer default 6; dedicated property writes exist | preserve as native integer; exact semantic consumer unresolved |

## Architecture-derived integration
The component-level fields feed the recovered `anb` body model through:

`wfb.g/u/z → component mass → ml tree → anb.s/i/j/m`

and

`wfb.r/s → COM accumulator → anb.i/j`.

The resulting body state then participates in `anb` force/torque accumulation and integration. The recovered fixed-point shifts are `ge.c=4`, `tua.a=4`, `wf.e=12`, and `ou.r=8`.

## What this closes
The generic constructor fields are no longer “unmapped” in the broad sense: every field is classified as either a proven physics/geometry input or a preserved native property whose consumer must be found before semantic naming.

## What remains
The only unresolved portion of this field map is the **consumer semantics** of `f/h/y/B/d/q/k/a`. Searching the Roblox port for these obfuscated native field names cannot establish their meaning because the port uses different identifiers. The correct next evidence is the original JAR's bytecode reads/writes for those fields and their callers.

No Roblox names or unit conversions are asserted here.

## Status
**FIELD-ROLE MAP CONSOLIDATED — GENERIC PROPERTY CONSUMERS REMAIN SOURCE-GATED.**
