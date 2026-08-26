# VOIDA — Forensic Provenance Correction

## SOURCE:
`VOIDA/00_RAW_FORENSIC_REFERENCE.md` and supplied `voidhunters_decompiled_raw.zip`.

## OLD:
`ForensicDataModel.luau` broadly labeled the component/body sections and many generated definitions `[CODE_VERIFIED]`, while the raw reference explicitly distinguishes direct literal slots from generated chassis-dependent slots and CFR gaps.

## NEW:
The project now treats raw-source evidence as the authority boundary. Directly extracted fields/constants may be `CODE_VERIFIED`; generated or inferred Roblox values remain `INFERRED`/`RAW-GAP` until traceable evidence exists.

No geometry values are silently rewritten in this pass because the table is large and mixed-provenance. Provenance corrections must not alter gameplay data unless the source value itself is being changed.

## TEST:
- Cross-checked the raw reference: only the explicitly listed literal component slots are directly confirmed as literal polygon assignments.
- Confirmed `anb` body fields and `nbb` debris specialization are raw-supported.
- Confirmed health math depends on `lw`/`eo` and must not be simplified as exact.
- Confirmed this policy is now reflected in the master audit and source index.

## STATUS:
IMPLEMENTED.

## FUTURE AGENT NOTE:
Do not promote generated table entries to `CODE_VERIFIED` merely because their values resemble recovered geometry. Maintain separate source-value and Roblox-mapping provenance. The authoritative raw reference is `VOIDA/00_RAW_FORENSIC_REFERENCE.md`; unresolved native operators remain `RAW-GAP`.
