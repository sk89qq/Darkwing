# VOIDA SOURCE INDEX

## Purpose

Machine-searchable index for the numbered VOIDA forensic/source corpus. Use this before repository code search when investigating a subsystem.

## Authority order

1. `VOIDA/00_RAW_FORENSIC_REFERENCE.md` — source-of-truth rules and evidence classes, raw class map.
2. Numbered `VOIDA/*` forensic directives/reconciliations — subsystem evidence and migration history.
3. Raw decompiled package referenced by the first-pass forensic reference.
4. `src/roblox/*` — final Roblox implementation target.
5. `VOIDA/07_SUPER_AUDIT.md` and related audits — status only; never stronger than raw evidence.

## Evidence labels

- `RAW-DIRECT` — directly present in supplied Java/resource text.
- `RAW-STRUCTURED` — recoverable from raw code/data despite CFR formatting.
- `RAW-GAP` — unresolved by the supplied decompilation.
- `ROBLOX-MAPPING` — Roblox implementation choice reproducing recovered behavior.
- `INFERRED` — not established by raw evidence.

## Numbered corpus navigation

- `00_RAW_FORENSIC_REFERENCE.md` — global source authority, evidence classes, raw class map.
- `00_FORENSIC_ENGINEER_BLUEPRINT.md` — first-pass structural map of the native game.
- `01_GAME_STRUCTURE_INVENTORY.md` — game structure inventory.
- `02_BASELINE_GAMEPLAY_LOOP.md` — baseline gameplay lifecycle.
- `03_NETWORK_RPC_MANIFEST.md` — network/RPC reference.
- `06_FOUNDATION_AUDIT.md` — foundation audit.
- `07_SUPER_AUDIT.md` — master implementation audit.
- `08_RUNTIME_AUDIT_ACTIONS.md` — runtime action checklist.
- `09_AUTHORITY_CENSUS.md` — authority ownership map.
- `10_ROBLOX_LUAU_REFERENCE.md` — Roblox/Luau implementation standards.
- `11_RAW_RECONCILIATION.md` — raw-vs-implementation reconciliation.
- `12_NATIVE_SEMANTIC_EXTRACTION_STATUS.md` — native semantic extraction boundary.
- `12_WEAPON_AUTHORITY_MIGRATION.md` — weapon authority migration.
- `13_COMPONENT_AUTHORITY_MIGRATION.md` — component state authority.
- `13_SOCKET_GRAPH_AUTHORITY_MIGRATION.md` — socket/topology authority.
- `14_STRUCTURAL_REPLACEMENT_MIGRATION.md` — structural replacement.
- `15_BLUEPRINT_BUILD_AUTHORITY_MIGRATION.md` — blueprint/build authority.
- `16_COMBAT_RESOURCE_AUTHORITY_MIGRATION.md` — combat resources.
- `17_PHYSICS_DETACH_KINEMATICS_MIGRATION.md` — detached-body kinematics.
- `18_DEBRIS_AUTHORITY_MIGRATION.md` — debris authority.
- `19_RAW_PHYSICS_OPERATOR_RECOVERY.md` — native physics operator recovery.
- `20_NATIVE_DEBRIS_KINEMATICS_MIGRATION.md` — native debris kinematics mapping.
- `21_FORENSIC_PROVENANCE_CORRECTION.md` — evidence provenance correction.
- `21_NATIVE_DEBRIS_LAUNCH_MAPPING.md` — native debris launch mapping.
- `22_MISSION_FRAMEWORK_MIGRATION.md` — mission framework.
- `23_NETWORK_AUTHORITY_MIGRATION.md` — network authority.
- `23_RESOURCE_AUTHORITY_MIGRATION.md` — resource authority.
- `24_PROJECTILE_AUTHORITY_MIGRATION.md` — projectile authority.
- `24_WEAPON_RESOURCE_AUTHORITY_MIGRATION.md` — weapon/resource authority.
- `25_BALLISTICS_HIT_RESOLUTION_MIGRATION.md` — hit resolution.
- `25_BODY_RECOMPUTE_MIGRATION.md` — body recompute boundary.
- `26_BALLISTIC_WEAPON_MIGRATION.md` — ballistic weapon integration.
- `26_COMPONENT_DEFINITION_VALIDATION.md` — component definition validation.
- `27_PROJECTILE_HIT_AUTHORITY_HANDOFF.md` — hit authority handoff.
- `28_HIT_RESOLUTION_HANDOFF.md` — hit resolution handoff.
- `29_NATIVE_THRUSTER_OPERATOR_RECOVERY.md` — native `aqa` thruster force operator.
- `30_NATIVE_THRUSTER_BINDING_RECOVERY.md` — native `ml.VA()` thruster binding classification.
- Later numbered files should be appended here in numeric order.

## Working rule

When a code symbol is not discoverable through GitHub search, first consult this index and open the relevant numbered VOIDA source/audit document. Do not infer absence from a zero-result code search.

## FUTURE AGENT NOTE:

VOIDA filenames are intentionally numbered. The number is the investigation/migration sequence, not an authority score over raw evidence. Always cross-check `00_RAW_FORENSIC_REFERENCE.md` before promoting a claim to source truth. Roblox remains the final runtime environment; VOIDA documents provide behavioral/data provenance for the port.
