# Structural Replacement Transaction

STATUS: IMPLEMENTED

Commit: 9e01d22b0e599f7c786a256b0591f7d4f0754d68

## CHANGE
`StructuralAuthority.ReplaceComponent` now validates the replacement component, its definition, parent node, parent hardpoint, compatible child socket, and candidate placement before the old component is removed.

## ORDER
validate replacement
→ solve candidate placement
→ validate snap distance
→ detach old component
→ rebuild graph
→ attach replacement
→ bind component authority
→ set parent relationship
→ recompute body

Rollback remains available when the post-detach attach fails.

## WHY
The forensic audit requires replacement failure to leave the existing component intact whenever possible. The previous implementation removed the old component before knowing the replacement could be committed.

## FUTURE AGENT NOTE:
- Structural replacement remains centralized in `StructuralAuthority`.
- Do not implement replacement independently in UI/build/repair systems.
- The old component is still converted to debris only after replacement prevalidation succeeds.
- `BodyRecomputeService` remains the post-transaction recompute boundary.
- Roblox remains the runtime environment; graph state and structural authority remain authoritative.
