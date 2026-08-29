# Native 56 Full Runtime Field Closure — 2026-08-28

## Source pass
Re-read the current Git catalog, then cross-checked the supplied archive's original `wlb.txt` and `wfb.txt`. The original `wfb(int[],int,int)` constructor establishes the common runtime baseline for every slot:

- `v` = constructor vertex array
- `b` = first constructor integer (native origin X)
- `i` = second constructor integer (native origin Y)
- `f=false`
- `h=256`
- `r=false`
- `s=false`
- `z=256`
- `y=0`
- `B=256`
- `d=0`
- `q=256`
- `k=true`
- `a=6`
- constructor then invokes its geometry/setup routines

This is the missing common variable closure: slots do not need invented per-slot defaults. They inherit these exact native `wfb` defaults unless the static initializer subsequently overrides them.

## Runtime override classes recovered
The original initializer shows these native override mechanisms:

- `wfb.a(int,boolean)` writes `z` and derives `p` from native `u` and `z`.
- `wfb.a(byte,int)` is used by slot definitions to set a native integer/flag property; the call site is preserved rather than renamed without `wfb` semantic proof.
- `wfb.c=qjb(...)` attaches a native behavior object.
- `wfb.t=aqa(...)` attaches the native thruster/operator object.
- `wfb.w=int[][]` attaches native hardpoint/attachment coordinate arrays.
- direct assignments to `a`, `A`, `B`, `q`, `d`, `n`, `y`, `x`, `s`, `f`, and related fields are constructor-level overrides and must remain native-domain data.

## 56-slot implementation status

| Slot range | Runtime closure |
|---|---|
| 0–2 | Native geometry/reference + common `wfb` defaults locked |
| 3–11 | Referenced native objects; common `wfb` defaults locked; reference constructor remains the identity source |
| 12–13 | Native geometry + `aqa`/attachment data recovered; native overrides retained |
| 14–18 | Geometry + weapon behavior + native behavior object/attachment data recovered |
| 19–20 | Geometry + generic `kma` behavior recovered |
| 21–22 | Generated/referenced definitions; common `wfb` defaults plus source expression/reference locked |
| 23–27 | Geometry + weapon/grapple behavior + native behavior data recovered |
| 28–29 | Native geometry and setup mutations recovered |
| 30–41 | Generated/referenced constructors; native source expressions and runtime override classes locked |
| 42–47 | Native geometry/behavior/reference data locked |
| 48–55 | Generated native definitions; source generator expressions locked |

## Critical correction
The remaining 38 slots are **not missing default variables**. Their common `wfb` runtime defaults are now source-verified. Their remaining unresolved information is only the constructor-specific override/reference body. That is a semantic/source-expression problem, not a missing-value problem.

## Implementation rule
A future runtime adapter should instantiate every slot with the exact `wfb` constructor baseline first, then apply only the slot-specific native overrides represented by its source constructor/reference. It must not substitute Roblox defaults such as arbitrary health, density, attachment names, or timing values.

## Native-only boundary
No native→Roblox unit conversion is included here. No Roblox component identity is guessed. This file closes the variable/default side of the 56-slot runtime contract.

## Status
**56/56 common runtime variable closure complete. Slot-specific constructor/reference semantics remain source-defined and are preserved rather than fabricated.**
