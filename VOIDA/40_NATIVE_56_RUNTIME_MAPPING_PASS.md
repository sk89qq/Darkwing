# Native 56 Runtime Mapping Pass — 2026-08-28

## Scope
Implementation-facing runtime mapping only. Native slot truth remains source-domain; Roblox names/units are deliberately deferred.

## Closed runtime mappings

### Weapon slots
- 14 → native weapon behavior 11
- 15 → native weapon behavior 0
- 16 → native weapon behavior 3
- 17 → native weapon behavior 1
- 18 → native weapon behavior 2
- 23 → native weapon behavior 4
- 24 → native weapon behavior 6
- 25 → native weapon behavior 7
- 27 → native weapon behavior 8
- 43 → native weapon behavior 9
- 44 → native weapon behavior 10

These should resolve through the existing native weapon contract rather than through Roblox component declaration order.

### Utility/interaction slots
- 26 → native grapple behavior.
- 19 → native generic `kma` behavior.
- 20 → native generic `kma` behavior.
- 42 → native generic behavior.

### Geometry-only slots
Slots 1, 2, 12, 13, 28, 29, 47 have complete native polygon/origin data and require no additional runtime variable to reproduce their native geometry.

### Reference/generated slots
Slots 0, 3–11, 21–22, 30–31, 32–41, 45–46, 48–55 are source-reference/generator backed. Their exact native expressions/references are preserved in `NativeComponentCatalog`. No semantic Roblox identity is asserted without the referenced constructor/body.

## Required runtime representation
The implementation boundary for each slot is:

`native slot id → NativeComponentCatalog record → native behavior/constructor → later execution adapter`

It must NOT be:

`native slot id → guessed Components.Types name → Roblox-tuned values`.

## What is safe to wire now
1. Slot lookup by numeric native ID.
2. Native geometry retrieval for direct slots.
3. Native behavior classification for the 15 explicitly identified behavior slots above.
4. Native weapon dispatch for weapon-bearing slots.
5. Native grapple dispatch for slot 26.
6. Generic behavior dispatch for slots 19, 20, 42.

## What is intentionally not wired
- HP values inferred from Roblox definitions.
- Roblox mass/density.
- Roblox attachment names inferred from geometry.
- Native-to-stud or native-to-second conversion.
- Constructor semantics for referenced/generated objects whose bodies are not encoded in the current catalog record.

## Verification
The current `NativeComponentCatalog` contains all IDs `0..55` and exposes `Get`, `All`, `Count`, and `IsComplete`. Its source-domain contract is explicit and does not perform unit conversion.

## Result
**Runtime mapping pass complete for all behavior-bearing slots that have source-backed behavior. Direct geometry slots are implementation-ready. Reference/generated slots are implementation-represented but remain constructor-gated.**
