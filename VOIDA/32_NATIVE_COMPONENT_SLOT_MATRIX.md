# VOIDA — Native Component Slot Matrix

## Authority
Raw `wlb.java` / `hab.g` evidence is authoritative. This matrix records extraction status only and must not override raw source.

## Native allocation
`hab.g` contains 56 `wfb` definition slots: IDs `0..55`.

## Directly documented static slots
| Native ID | Raw evidence | Status |
|---:|---|---|
| 0 | `{5,0,-5,4,-5,-4}` polygon; multiple hardpoints | EXTRACTED |
| 1 | square ±40; four hardpoints; `z=1024` | EXTRACTED |
| 2 | square ±10; four hardpoints; `z=1024` | EXTRACTED |
| 12 | `{2,0,-2,1,-2,-1}` | EXTRACTED |
| 13 | `{3,0,-4,3,-4,-3}` | EXTRACTED |
| 14 | `{2,-1,2,1,-2,0}`; weapon behavior 11 | EXTRACTED |
| 15 | `{5,-1,5,1,-5,3,-5,-3}`; weapon behavior 0 | EXTRACTED |
| 16 | `{10,-3,10,3,-10,1,-10,-1}`; weapon behavior 3 | EXTRACTED |
| 17 | `{10,-5,10,5,-10,3,-10,-3}`; weapon behavior 1 | EXTRACTED |
| 19 | rectangle ±40 × ±5; hardpoint; generic behavior | EXTRACTED |
| 20 | rectangle ±20 × ±5; hardpoint; generic behavior | EXTRACTED |
| 23 | `{3,-3,3,3,-3,1,-3,-1}`; weapon behavior 4 | EXTRACTED |
| 24 | rectangle ±4 × ±1; weapon behavior 6 | EXTRACTED |
| 25 | elongated ±8; weapon behavior 7 | EXTRACTED |
| 26 | `{6,-4,6,4,-6,3,-6,-3}`; grapple/generic behavior; pink | EXTRACTED |
| 27 | elongated ±8; weapon behavior 8; pink | EXTRACTED |
| 28 | square ±3; three auxiliary outlines | EXTRACTED |
| 29 | square ±5; three hardpoints; orange | EXTRACTED |
| 42 | tall polygon; generic behavior; blue | EXTRACTED |
| 43 | `{3,-1,3,1,-3,1,-3,-1}`; weapon behavior 9; blue | EXTRACTED |
| 44 | `{3,-3,3,3,-3,5,-3,-5}`; weapon behavior 10; blue | EXTRACTED |
| 47 | large 20-unit chassis polygon; symmetry/index map; purple | EXTRACTED |

## Generated / special ranges
- IDs `3–11`: not enumerated by the current qualitative evidence; require direct `wlb.java` extraction.
- IDs `18,21,22,30–41,45,46`: not fully enumerated by the current qualitative evidence; some are generated/chassis-dependent.
- IDs `48–55`: generated terrain/chassis-like definitions through `jba.a(...)`; not all are ordinary ship components.

## Native color mapping
- `a=-1` → `#D72828`
- `a=-2` → `#2849D7`
- `a=-3` → `#D77628`
- `a=3` → `#DCDCDC`
- `a=4` → `#D728AC`
- `a=5` → `#49D728`
- `a=6` → `#8F28D7`

## Roblox mapping policy
- Native IDs are **not** inferred from Roblox declaration order.
- Native IDs are **not** inferred from `Instance.Name`.
- `Components.Types` remains the Roblox runtime authority.
- `Components.Connections` remains the Roblox topology authority.
- A native→Roblox mapping is promoted only when raw evidence identifies the corresponding component behavior/geometry/name.

## Required next extraction
Read the actual `wlb.java` initializer/body from the raw decompiled source or a better decompilation and populate every native ID with:
`geometry`, `auxiliary outlines`, `hardpoints`, `behavior references`, `color/category`, `origin`, `health scale`, `area-derived field`, and `health`.

## STATUS
PARTIAL / RAW-SOURCE EXTRACTION ACTIVE

## FUTURE AGENT NOTE:
This file is a slot ledger, not a replacement for the raw class. Use it to track what is known and what still needs extraction. Do not “complete” blank IDs by guessing. Preserve the distinction between direct static literals, generated chassis expressions, and terrain/special definitions. Once each native ID is recovered, add an explicit Roblox `NativeTypeId` mapping only where source evidence supports it.

## Git-ready commit message
`docs: add native 56-slot component matrix`
