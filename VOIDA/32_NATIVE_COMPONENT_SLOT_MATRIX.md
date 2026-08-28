# VOIDA — Native Component Slot Matrix

## Authority
Raw `wlb.java` / `hab.g` evidence is authoritative. This matrix records extraction status only and must not override raw source.

## Native allocation
`hab.g` contains exactly 56 `wfb` definition slots: IDs `0..55`.

## Complete slot ledger
The definitive slot artifact has been reconciled into a **56/56 ledger**. Every native slot now has an explicit source initializer/reference classification. This closes the bookkeeping gap without inventing geometry or Roblox identities.

| Native ID | Definition kind | Source-backed reference | Behavior |
|---:|---|---|---|
| 0 | DIRECT | `wfb2` polygon/hardpoints | — |
| 1 | DIRECT | square ±40; `z=1024` | — |
| 2 | DIRECT | square ±10; `z=1024` | — |
| 3 | DIRECT | referenced object | — |
| 4 | DIRECT | referenced object | — |
| 5 | DIRECT | referenced object | — |
| 6 | DIRECT | referenced object | — |
| 7 | DIRECT | referenced object | — |
| 8 | DIRECT | referenced object | — |
| 9 | DIRECT | referenced object | — |
| 10 | DIRECT | referenced object | — |
| 11 | DIRECT | referenced object | — |
| 12 | DIRECT | polygon `{2,0,-2,1,-2,-1}` | — |
| 13 | DIRECT | polygon `{3,0,-4,3,-4,-3}` | — |
| 14 | DIRECT | polygon `{2,-1,2,1,-2,0}` | weapon 11 |
| 15 | DIRECT | polygon `{5,-1,5,1,-5,3,-5,-3}` | weapon 0 |
| 16 | DIRECT | polygon `{10,-3,10,3,-10,1,-10,-1}` | weapon 3 |
| 17 | DIRECT | polygon `{10,-5,10,5,-10,3,-10,-3}` | weapon 1 |
| 18 | DIRECT | referenced object | weapon 2 |
| 19 | DIRECT | rectangle ±40×±5 | generic |
| 20 | DIRECT | rectangle ±20×±5 | generic |
| 21 | GENERATED | `jba.a(...)` | — |
| 22 | DIRECT | `new wfb((int[])object,0,0)` | — |
| 23 | DIRECT | polygon `{3,-3,3,3,-3,1,-3,-1}` | weapon 4 |
| 24 | DIRECT | polygon `{4,-1,4,1,-4,1,-4,-1}` | weapon 6 |
| 25 | DIRECT | polygon `{8,-1,8,1,-8,2,-8,-2}` | weapon 7 |
| 26 | DIRECT | polygon `{6,-4,6,4,-6,3,-6,-3}` | grapple |
| 27 | DIRECT | polygon `{8,-3,8,3,-8,1,-8,-1}` | weapon 8 |
| 28 | DIRECT | square ±3; auxiliary outlines | — |
| 29 | DIRECT | square ±5; three hardpoints | — |
| 30 | GENERATED | chassis-dependent `n6/n5` expression | — |
| 31 | DIRECT | `wfb3` | — |
| 32 | DIRECT | referenced object | — |
| 33 | DIRECT | referenced object | — |
| 34 | DIRECT | referenced object | — |
| 35 | DIRECT | referenced object | — |
| 36 | DIRECT | referenced object | — |
| 37 | DIRECT | referenced object | — |
| 38 | DIRECT | referenced object | — |
| 39 | DIRECT | referenced object | — |
| 40 | DIRECT | referenced object | — |
| 41 | DIRECT | referenced object | — |
| 42 | DIRECT | tall polygon | generic |
| 43 | DIRECT | polygon `{3,-1,3,1,-3,1,-3,-1}` | weapon 9 |
| 44 | DIRECT | polygon `{3,-3,3,3,-3,5,-3,-5}` | weapon 10 |
| 45 | DIRECT | referenced object | — |
| 46 | DIRECT | `wfb2` | — |
| 47 | DIRECT | large 20-unit chassis polygon | — |
| 48 | GENERATED | `jba.a(...)` | — |
| 49 | GENERATED | `jba.a(...)` | — |
| 50 | GENERATED | `jba.a(...)` | — |
| 51 | DIRECT | referenced object | — |
| 52 | GENERATED | `jba.a(...)` | — |
| 53 | GENERATED | `jba.a(...)` | — |
| 54 | GENERATED | `jba.a(...)` | — |
| 55 | GENERATED | `jba.a(...)` | — |

## Native color mapping
- `a=-1` → `#D72828`
- `a=-2` → `#2849D7`
- `a=-3` → `#D77628`
- `a=3` → `#DCDCDC`
- `a=4` → `#D728AC`
- `a=5` → `#49D728`
- `a=6` → `#8F28D7`

## Interpretation boundary
`DIRECT` means the slot's initializer/reference is source-backed. `GENERATED` means the slot is source-backed but depends on another recovered expression. Neither label authorizes a guessed native→Roblox identity.

## TEST
- Re-read `VOIDA/DEFINITIVE_VALUES/component_56_slots.csv` before modification.
- Confirmed the source artifact covers native IDs `0..55` with no missing IDs.
- Confirmed generated/special entries remain marked rather than flattened.
- No Roblox component geometry, health, or topology values were invented.

## STATUS
**SOURCE LEDGER COMPLETE — 56/56. Native→Roblox semantic reconciliation remains open only where the referenced constructor/behavior is not yet fully recovered.**
