# Native Configuration Resolution Trace

## Binary authority

- Official AlterOrb gamepack: `voidhunters`
- JAR SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- JAR SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- Official AlterOrb `config.json` identifies `internalName=voidhunters`, `mainClass=VoidHunters`, and the same SHA-256.

## Native configuration architecture

`qb.a[]` is the canonical configuration-key namespace containing 235 names.

`qb` implements the state-object factory interface and creates `mib` state objects. `mib` accepts an `mfa` keyed-value provider. The `mfa` contract is:

```text
String a(int key, int context)
void a(String value, int key, byte context)
```

This establishes that the configuration/state values are not stored as a simple `qb` numeric-default array.

## Provenance classification

### Embedded / statically recoverable

Values appearing directly in constructors, field initializers, polygon initializers, generated-geometry formulas, and other native class bytecode/source are authoritative from the verified JAR. These belong in the static native-value chart.

### Runtime-resolved

The 235 `qb.a[]` keys identify configuration/state variables, but their actual values are supplied through the client state/configuration pipeline. A key name alone does not establish its numeric value.

### Do not do

- Do not copy current Darkwing prototype constants into this chart.
- Do not infer a numeric default from the key name.
- Do not treat a Roblox value as native merely because gameplay looks plausible.

## Current state

The static native component/geometry/HP values are recoverable directly from `wlb.java` and `wfb.java`.

The runtime configuration-value payload remains a separate extraction target. The current JAR contains the compiled client and no separate readable configuration resource table. The next valid source is the runtime/config/state payload consumed by the original client.

## FUTURE AGENT NOTE:

Use `native_configuration_values.csv` for the canonical 235-key namespace. Use this document to decide whether a value can be filled from static binary evidence. When a runtime capture or original configuration payload is obtained, populate existing rows with: key, raw value, type, unit, producing class/method, transport/source, confidence, and Roblox translation. Never create a second competing configuration table.
