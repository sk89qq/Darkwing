# VOIDA — Native `wfb[56]` Slot Extraction

## SOURCE
Original supplied `voidhunters-original.jar`, `wlb` static initializer bytecode in `VOIDA/ORIGINAL_JAR/PREPROCESSING_01_06/javap-targeted/wlb.txt`.

## VERIFIED
- Native allocation is exactly `new wfb[56]`.
- The initializer writes native slot objects through `hab.g[index]`.
- Static geometry/metadata initialization is therefore indexed by the native slot ID, not Roblox declaration order.
- The recovered bytecode contains explicit writes for slots 0, 1, 2 and subsequent slots; generated slots are constructed through helper expressions rather than a single flattened table.
- `wfb` fields populated by the initializer include polygon arrays, auxiliary arrays, hardpoint/connect data, behavior references, color/category metadata, origin/offset values, and health-related quantities.

## SLOT-IDENTITY RULE
No native slot is mapped to a Roblox `Components.Types` name merely because its shape or declaration position appears similar. A mapping is accepted only when the native constructor/caller evidence establishes identity.

## CURRENT CLOSURE
The raw `wfb[56]` index space is now explicitly anchored to the original initializer. This closes the evidence-location gap for slot reconciliation, but does **not** claim semantic identity for slots whose native constructor/caller remains unresolved.

## NEXT FORENSIC TARGET
Resolve the remaining native slot identities by tracing each `wfb` constructor's behavior reference (`weapon/generic/thruster/grapple`), category/color, hardpoint shape, and downstream callers into the known gameplay component classes. Generated slots `30–41` and terrain/chassis-like `48–55` remain separate from ordinary ship-component mapping.

## STATUS
**RAW SLOT INDEXING VERIFIED — SEMANTIC IDENTITY RECONCILIATION ACTIVE.**
