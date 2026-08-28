# VOIDA — Native `anb` Mapping Recovery — 2026-08-28

## SOURCE:
Original `voidhunters(1).jar` extracted from the supplied archive, inspected with `javap -c -p` and targeted bytecode search across the intact JAR.

Relevant native classes: `anb`, `ara`, `lw`, `wfb`.

## OLD:
The working audit described `lw.a` as an unresolved native-to-Roblox unit conversion and left the mapping blocker broadly scoped.

## NEW:
The original JAR establishes that `lw.a(byte,int)` is **not** the missing world-unit conversion. It is a trigonometric lookup helper used by `wfb` for angle/vector calculations. Targeted JAR-wide call-site search found `lw.a:(BI)I` in `wfb` paths and no evidence that it converts `anb` physical units into Roblox units.

The exact native `anb` update path is now narrowed to these verified operations:

- `anb.KB(...)` first accumulates linear terms directly into `t` and `o`.
- The application-point displacement is shifted by `ge.c = 4` before the torque cross-product term.
- The torque accumulator is shifted by `tua.a = 4` before being added to `p`.
- `anb.EA(..., integrationDivisor)` applies `t / integrationDivisor` and `o / integrationDivisor` directly to linear velocity.
- Angular integration applies `(p >> wf.e) / max(1, m)` with `wf.e = 12`, then adds the result to angular velocity.
- The existing `d(byte)` call in these methods is a guard/side-effect hook and does not perform a physical unit conversion; its body reduces to a remainder calculation with no state mutation.

The bytecode therefore confirms the native fixed-point shifts, but the Roblox-side conversion remains a separate boundary question. No source-backed constant was found that licenses an arbitrary studs-per-native-unit or Newton conversion.

## VERIFIED CONSTANTS:

- `ge.c = 4` — application-point coordinate normalization shift.
- `tua.a = 4` — torque accumulator shift.
- `wf.e = 12` — angular accumulator shift before division by inertia.
- `ou.r = 8` — recovered native vertex/geometry shift used by the associated mass/inertia path.

## TEST:

- Extracted the 2,325,563-byte original JAR from the uploaded fork bundle.
- Confirmed `anb.class`, `lw.class`, and `d.class` exist in the intact JAR.
- Decompiled `anb` and `lw` directly with JDK 21 `javap`.
- Searched the complete preprocessed JAR `javap-all.txt` for every `lw.a` call site.
- Confirmed `lw.a:(BI)I` is used by `wfb` trigonometric/vector logic, not as a physical unit converter.
- Re-read current GitHub `main` audit and `NativeAnbPhysics` before recording this correction.

## STATUS:
PARTIAL — native fixed-point semantics narrowed and the previous `lw.a` attribution corrected. Native-to-Roblox world-unit mapping is still RAW-GAP because no source-backed conversion constant has yet been established.

## FUTURE AGENT NOTE:
Do not treat `lw.a` as the conversion boundary. Continue from the actual `anb` callers and the `ara`/`faa` data-loading path. The next useful target is the call-site that supplies `anb.b(int,int)`'s integration divisor and the path that projects native `anb.d/e/f/h/n/r` state to rendering/network coordinates. Only promote a conversion factor when it is established from raw bytecode/data rather than compatibility with the Roblox implementation.
