# VOIDA — Native 56-Slot Component Reconciliation

## SOURCE:
- Raw forensic component-definition evidence from `wlb.java` / `hab.g`.
- `VOIDA/00_RAW_FORENSIC_REFERENCE.md`.
- `VOID_HUNTERS_FORENSIC_ENGINEER_BLUEPRINT.md`.
- `src/roblox/ReplicatedStorage/VoidHunterComponents.luau`.

## RAW FACTS:
- Native client allocates `hab.g = new wfb[56]`.
- `wfb` stores polygon vertices, auxiliary outlines, hardpoints, optional weapon/generic/thruster/grapple behavior, display color/category code, origin/offset, health scale, polygon-area-derived quantity, and health quantity.
- Directly documented native color mapping: `-1=#D72828`, `-2=#2849D7`, `-3=#D77628`, `3=#DCDCDC`, `4=#D728AC`, `5=#49D728`, `6=#8F28D7`.
- Directly documented static geometry includes slots `0,1,2,12,13,14,15,16,17,19,20,23,24,25,26,27,28,29,42,43,44,47`.
- Native slots `30–41` are generated from chassis-dependent `fnb.a/fnb.b` expressions.
- Native slots `48–55` include generated terrain/chassis-like shapes and are not all ordinary ship components.

## ROBLOX STATE:
- Current `VoidHunterComponents` already contains the runtime component vocabulary and connection definitions used by the Roblox implementation.
- Native type IDs are not embedded in the Roblox definitions, so this pass does not guess IDs from declaration order or names.
- Existing connection definitions remain unchanged.

## CURRENT MAPPING STATUS:
- Direct native geometry: extracted for the documented static subset; full per-slot source body still requires raw `wlb.java` extraction.
- Native generated geometry: identified as generated; exact expressions remain a source-recovery task.
- Roblox named component definitions: implemented, but native ID mapping is not yet proven slot-by-slot.
- Health parity: not declared; native health derives through `wfb -> lw -> eo` and cannot be replaced by a simplified area formula without complete lookup reconstruction.

## TEST:
- Source corpus confirms the 56-slot allocation and the explicitly documented static/generated groups.
- Roblox connection table was audited for internal count/array consistency without mutating definitions.
- No geometry or health values were changed in this pass.

## STATUS:
PARTIAL / SOURCE-RECOVERY ACTIVE

## FUTURE AGENT NOTE:
Treat this document as the reconciliation ledger, not as an authority over raw source. For each native slot, record the direct `wfb` initializer, then map it to the Roblox `ComponentType`. Never infer native ID from Roblox declaration order. Native color mappings are source-verified; generated 30–41 and 48–55 require their generating expressions and should not be flattened into generic Roblox shapes. `Components.Types` and `Components.Connections` remain the live Roblox runtime authority.

## Git-ready commit message:
`docs: add native 56-slot component reconciliation ledger`
