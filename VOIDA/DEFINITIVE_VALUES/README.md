# Definitive Native Values

## Source anchor

The project-owner-supplied original `voidhunters.jar` was verified locally:

- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- Size: `2,325,563` bytes

## Current definitive charts

`component_56_slots.csv` records all native component-definition slots `0..55` from `wlb.f(byte)`, including exact source-line locations and generated-definition markers.

`native_configuration_values.csv` records all 235 canonical configuration keys from `qb.a[]`. The chart deliberately marks these values `RUNTIME_RESOLVED_NOT_EMBEDDED` because `qb.java` is a key registry, not a compiled numeric-default table, and the supplied JAR archive contains compiled classes rather than a separate readable configuration payload.

## Important distinction

A configuration key being present in the native client is verified. Its numeric value is **not** verified merely from the key name. Do not copy prototype Roblox constants into the definitive chart.

The next source for numeric defaults is the runtime configuration/resource feed consumed by the original client. That data is outside the static `qb` registry and is not present as an external resource file in the supplied JAR.

## FUTURE AGENT NOTE:

Use the verified JAR hash as the binary identity anchor. Use `component_56_slots.csv` for the complete native component-slot map and `native_configuration_values.csv` for the 235-key canonical configuration namespace. When runtime configuration data is obtained from the original AlterOrb client/cache/network capture, populate the existing rows rather than creating a competing table, and record class/method, raw value, unit, and translation provenance.
