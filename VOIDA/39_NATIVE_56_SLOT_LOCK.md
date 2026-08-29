# Native 56-Slot Lock — 2026-08-28

## Authority
The native component allocation is exactly `wfb[56]`, IDs `0..55`. The source ledger is complete at the initializer/reference level. `32_NATIVE_COMPONENT_SLOT_MATRIX.md` and `DEFINITIVE_VALUES/component_56_slots.csv` agree on all 56 IDs. `36_NATIVE_WFB_SLOT_EXTRACTION.md` establishes that these are native index IDs, not Roblox declaration order.

## Locked slot record

| ID | Source kind | Native constructor/reference | Native behavior | Required source variables/status |
|---:|---|---|---|---|
| 0 | direct | wfb2 | unresolved | polygon/hardpoints/color/category: source-backed; behavior caller open |
| 1 | direct | square ±40; z=1024 | unresolved | polygon/origin metadata: source-backed |
| 2 | direct | square ±10; z=1024 | unresolved | polygon/origin metadata: source-backed |
| 3 | object | referenced object | unresolved | referenced constructor required |
| 4 | object | referenced object | unresolved | referenced constructor required |
| 5 | object | referenced object | unresolved | referenced constructor required |
| 6 | object | referenced object | unresolved | referenced constructor required |
| 7 | object | referenced object | unresolved | referenced constructor required |
| 8 | object | referenced object | unresolved | referenced constructor required |
| 9 | object | referenced object | unresolved | referenced constructor required |
| 10 | object | referenced object | unresolved | referenced constructor required |
| 11 | object | referenced object | unresolved | referenced constructor required |
| 12 | direct | polygon `{2,0,-2,1,-2,-1}` | unresolved | geometry source-backed |
| 13 | direct | polygon `{3,0,-4,3,-4,-3}` | unresolved | geometry source-backed |
| 14 | direct | polygon `{2,-1,2,1,-2,0}` | weapon 11 | geometry + weapon relation source-backed |
| 15 | direct | polygon `{5,-1,5,1,-5,3,-5,-3}` | weapon 0 | geometry + weapon relation source-backed |
| 16 | direct | polygon `{10,-3,10,3,-10,1,-10,-1}` | weapon 3 | geometry + weapon relation source-backed |
| 17 | direct | polygon `{10,-5,10,5,-10,3,-10,-3}` | weapon 1 | geometry + weapon relation source-backed |
| 18 | object | referenced object | weapon 2 | behavior source-backed; constructor required |
| 19 | direct | rectangle ±40×±5 | generic=kma | geometry + generic relation source-backed |
| 20 | direct | rectangle ±20×±5 | generic=kma | geometry + generic relation source-backed |
| 21 | generated | jba.a(...) | unresolved | generated expression required |
| 22 | direct | new wfb((int[])object,0,0) | unresolved | referenced polygon array required |
| 23 | direct | polygon `{3,-3,3,3,-3,1,-3,-1}` | weapon 4 | geometry + weapon relation source-backed |
| 24 | direct | polygon `{4,-1,4,1,-4,1,-4,-1}` | weapon 6 | geometry + weapon relation source-backed |
| 25 | direct | polygon `{8,-1,8,1,-8,2,-8,-2}` | weapon 7 | geometry + weapon relation source-backed |
| 26 | direct | polygon `{6,-4,6,4,-6,3,-6,-3}` | grapple | geometry + grapple relation source-backed |
| 27 | direct | polygon `{8,-3,8,3,-8,1,-8,-1}` | weapon 8 | geometry + weapon relation source-backed |
| 28 | direct | square ±3 | unresolved | geometry/auxiliary outline source-backed |
| 29 | direct | square ±5 | unresolved | geometry + 3 hardpoints source-backed |
| 30 | generated | n6/n5 expression | unresolved | chassis-dependent variables required |
| 31 | direct | wfb3 | unresolved | referenced definition required |
| 32 | object | referenced object | unresolved | referenced constructor required |
| 33 | object | referenced object | unresolved | referenced constructor required |
| 34 | object2 | referenced object | unresolved | referenced constructor required |
| 35 | object | referenced object | unresolved | referenced constructor required |
| 36 | object | referenced object | unresolved | referenced constructor required |
| 37 | object | referenced object | unresolved | referenced constructor required |
| 38 | object | referenced object | unresolved | referenced constructor required |
| 39 | object | referenced object | unresolved | referenced constructor required |
| 40 | object | referenced object | unresolved | referenced constructor required |
| 41 | object | referenced object | unresolved | referenced constructor required |
| 42 | direct | tall polygon | generic | geometry + generic relation source-backed |
| 43 | direct | polygon `{3,-1,3,1,-3,1,-3,-1}` | weapon 9 | geometry + weapon relation source-backed |
| 44 | direct | polygon `{3,-3,3,3,-3,5,-3,-5}` | weapon 10 | geometry + weapon relation source-backed |
| 45 | object | referenced object | unresolved | referenced constructor required |
| 46 | direct | wfb2 | unresolved | shared source definition |
| 47 | direct | large 20-unit chassis polygon | unresolved | geometry/metadata source-backed |
| 48 | generated | jba.a(...) | unresolved | generated expression required |
| 49 | generated | jba.a(...) | unresolved | generated expression required |
| 50 | generated | jba.a(...) | unresolved | generated expression required |
| 51 | object | referenced object | unresolved | referenced constructor required |
| 52 | generated | jba.a(...) | unresolved | generated expression required |
| 53 | generated | jba.a(...) | unresolved | generated expression required |
| 54 | generated | jba.a(...) | unresolved | generated expression required |
| 55 | generated | jba.a(...) | unresolved | generated expression required |

## Necessary variable closure
For every slot, the minimum native record is now explicitly defined as:

1. slot ID;
2. `wfb` constructor/reference;
3. polygon/vertex source or referenced object;
4. auxiliary arrays/hardpoint/connect data when present;
5. origin/offset fields;
6. color/category metadata;
7. health/resource fields when populated by the native constructor;
8. behavior reference/caller (`weapon`, `generic`, `grapple`, etc.);
9. generated-expression inputs where applicable.

No Roblox mapping is part of this closure. No Roblox-unit conversion is part of this closure.

## Closure status
**56/56 index identities locked. 18 slots have explicit native behavior relations in the current ledger; 38 remain constructor/reference-gated.** The 38 are not being marked “missing values” merely because their semantic Roblox names are unknown: their native source references are known, while the referenced constructor data is the remaining evidence dependency.

## Verification
Cross-checked the current matrix, definitive CSV, and extraction note immediately before this file was created. The CSV enumerates every ID `0..55` exactly once. No duplicate or missing native IDs were found.

## Next only
Do not reopen the 56-slot index extraction. If raw constructor evidence is available, resolve the 38 reference/generated slots. Otherwise proceed to the next runtime integration P0.
