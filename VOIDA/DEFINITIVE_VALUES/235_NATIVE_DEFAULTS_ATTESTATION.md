# Void Hunters — 235 Native Configuration Defaults Attestation

Status: EXTRACTED

SOURCE PRIORITY
1. Original `voidhunters.jar`.
2. Decompiled source derived from that exact JAR.
3. AlterOrb distribution metadata for binary identity.

SOURCE BINARY
- Name: `voidhunters.jar`
- Size: 2,325,563 bytes
- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- AlterOrb internal name: `voidhunters`
- AlterOrb gamepack hash: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`

NATIVE SOURCE INPUTS
- `qb.java` exposes the canonical 235 configuration-key namespace.
- `ik.java` constructs `int[235]` and maps every index to a native holder field.
- `kga.java` applies the 235-value vector back into the native holder fields.
- `tr.java` initializes settings by invoking `kga.a(107, sp.p)` and `ik.a(-21049)`.
- `jk.java` populates `sp.p` from `ik.a(...)`.
- `oq.java` defines the native timer scale `l = 50` used by expression-backed settings.

RESULT
`VOIDA/DEFINITIVE_VALUES/native_configuration_values.csv` now contains all 235 configuration entries with:
- zero-based native key index,
- canonical configuration key,
- native holder/field,
- native default expression,
- resolved numeric default,
- source status.

Coverage: 235/235 entries numerically resolved.
- Direct numeric holder literals/assignments: 217
- Timer expressions resolved through native `oq.l = 50`: 18

REPRODUCTION RULE
The resolved value is the value obtained from the native holder initialization represented by the decompiled source. It is not a value inferred from the key name. Runtime/server mutations may change a live settings instance after initialization; those mutations are separate from this native default chart.

NO-REINVENTION RULE
Do not substitute Roblox tuning values into this chart. Roblox runtime code may consume these values through a dedicated adapter, but this file remains the native source-of-truth record.

FUTURE AGENT NOTE:
- Treat `native_configuration_values.csv` as the canonical 235-row native defaults table.
- Preserve the zero-based indices exactly; callers and `kga`/`ik` use those indices.
- Preserve native integer units until a specific consumer proves a conversion is required.
- Timer-derived values use the native base `l = 50`.
- `source_status=DECL` means the field has a static declaration initializer in the decompiled holder class.
- `source_status=ASSIGN` means the final value is assigned in the holder source before the settings vector is constructed.
- Do not label runtime/server overrides as defaults.
- Roblox remains the target execution environment; these values must be adapted through authoritative component/behavior mappings rather than scattered literals.

COMMIT INTENT
Replace the prior unresolved 235-key inventory with a complete native default-values attestation and reproducible provenance record.
