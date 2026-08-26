# Definitive Native Source — Original Void Hunters JAR

## Source identity

The project-owner-supplied `voidhunters.jar` has been verified locally against the official AlterOrb launcher configuration.

- Version: `3.1.2`
- AlterOrb internal name: `voidhunters`
- Native main class: `VoidHunters`
- JAR size: `2,325,563` bytes
- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- AlterOrb `gamepackHash`: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- AlterOrb `gamecrc`: `-1843231949`

The SHA-256 in the official AlterOrb `config.json` exactly matches the uploaded JAR. This establishes the uploaded binary as the official AlterOrb Void Hunters gamepack for the recorded launcher configuration.

## Authority order

1. This exact original JAR is the definitive binary source for native behavior and data.
2. Decompiled source/disassembly derived from this binary is evidence tied to the hashes above.
3. Roblox code is the target implementation and must not override native values without explicit source-backed translation.
4. Historical/inferred values remain non-authoritative until supported by the native binary or functional AlterOrb behavior.

## Definitive extraction artifacts

- `DEFINITIVE_VALUES/component_56_slots.csv` — native `wlb.f(byte)` 56-slot component-definition ledger.
- `DEFINITIVE_VALUES/native_configuration_values.csv` — native configuration-key namespace from `qb.a[]`.
- `DEFINITIVE_VALUES/README.md` — extraction/provenance rules.
- `00_SOURCE_INDEX.md` — numbered VOIDA forensic navigation index.

## Runtime configuration status

The native binary contains the configuration-key registry, but the complete numeric runtime configuration payload is not stored as one readable static table inside the JAR. Numeric values must therefore be recovered from the original client's configuration-resolution path, AlterOrb runtime/cache data, or another source directly tied to this same gamepack identity.

Do not copy Roblox prototype constants into the definitive native-value chart merely because a key exists.

## FUTURE AGENT NOTE:

Use SHA-256 `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4` as the primary identity anchor for this Void Hunters build. The official AlterOrb `config.json` entry for `internalName=voidhunters` matches it exactly. Any recovered configuration value, component mapping, physics operator, mission sequence, or resource should be recorded against this build identity with source class/method, raw value, units, translation, and confidence. Keep Roblox as the implementation environment; do not replace its architecture with Java-shaped abstractions.