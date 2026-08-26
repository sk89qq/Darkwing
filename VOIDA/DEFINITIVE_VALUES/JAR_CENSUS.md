# Void Hunters JAR — Complete Binary Value Census

## Source identity
- File: `voidhunters.jar`
- Bytes: 2325563
- SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- Class entries: 1570
- Non-class entries: 0

## Literal coverage
The census parser walked the constant pool of every class entry in the exact JAR. It recorded every JVM Integer, Float, Double, Long, and UTF-8 constant. This is an archive-wide literal census; it is not a claim that every literal is gameplay data.

- Integer literals: 4,805
- Distinct integers: 3,999
- Float literals: 601
- Distinct floats: 445
- Double literals: 121
- Distinct doubles: 63
- Long literals: 186
- Distinct longs: 111
- UTF-8 constants: 94,161
- Distinct UTF-8 constants: 16,853
- Game/value-relevant strings: 1,370

## Numeric domains observed
- Integer range: `-2147483648 .. 2147483647`
- Float range: `-100.0 .. 2147483648.0`
- Double range: `-3.141592653589793 .. 16777216.0`

## Interpretation rules
1. Literal is not automatically a semantic game value. A bytecode integer can be an opcode argument, array size, protocol field, color channel, coordinate, hash, bitmask, or gameplay setting.
2. Semantic values become authoritative only when class/method context establishes their role.
3. The 235 native configuration defaults have a dedicated table in `VOIDA/DEFINITIVE_VALUES/native_configuration_values.csv`.
4. The 56 native component initializer slots have a dedicated table in `VOIDA/DEFINITIVE_VALUES/component_56_slots.csv`.
5. This census preserves all literal evidence while avoiding false semantic claims.

## Priority categories for semantic mining
- weapon/projectile coefficients
- force/impulse and physics downshifts
- time/tick constants
- component dimensions and hardpoints
- colors/ARGB values
- mission identifiers and symbols
- protocol opcodes and packet fields
- lookup tables (`sqrt`, trig, interpolation, collision)
- AI range/aim/targeting constants

## FUTURE AGENT NOTE:
Treat the exact JAR hash above as the source anchor. Use the numeric census files as an index into the binary, not as semantic overrides. When a literal is needed for Roblox parity, trace it to the containing class/method and preserve original integer scaling and unit semantics before converting to Luau.

## Commit message
`Add complete Void Hunters JAR literal/value census`
