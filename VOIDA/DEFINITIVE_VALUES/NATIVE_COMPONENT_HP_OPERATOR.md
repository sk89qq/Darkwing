# Native Component HP / Geometry Operator

## Source identity
- Original JAR SHA-1: `1f10b35f16b5de98ebf67f9b6f3f127aab7b66d3`
- Original JAR SHA-256: `4bb086ef9b0ec1f6f5362df92d634a2b4d997b4b5037f213fd3d5e5ea219bba4`
- Native class: `wfb`
- Native definition builder: `wlb.f(byte)`

## Exact recovered operator

`wfb` stores the component polygon in integer coordinate pairs `v[]`.

Its geometry-area routine `wfb.a(boolean)` computes:

```text
u = 0
for each consecutive vertex pair (x_i, y_i), (x_{i+1}, y_{i+1}):
    u += -(x_{i+1} * y_i) + (y_{i+1} * x_i)
u = u / 2
```

Then:

```text
if u == -1:
    u = 1
if u < -1:
    u = Integer.MAX_VALUE
```

The resulting health initialization path is:

```text
p = lw.a(-73, u) * z
```

The `wfb` constructor establishes these defaults before the definition-specific overrides:

```text
s = false
z = 256
y = 0
B = 256
d = 0
q = 256
k = true
a = 6
```

The constructor's third argument is copied into `i`; the second argument is copied into `b` and therefore acts as the initial X-origin offset. The first polygon is assigned to `v` and processed immediately by `a(true)`.

## Provenance

This is a binary-derived native fact from the project-owner-supplied JAR whose SHA-256 exactly matches the official AlterOrb `voidhunters` gamepack hash. It is not inferred from Roblox behavior.

## Translation rule

Do not replace this operator with an area approximation, bounding-box area, Roblox `Part.Size`, or arbitrary HP scale. Preserve the integer polygon and native calculation chain first; any Roblox unit conversion must occur only after this native operator is represented faithfully.

## FUTURE AGENT NOTE:

Use this document as the authoritative HP/geometry operator anchor for component definitions. `component_56_slots.csv` contains the 56 native definition slots; this document supplies the shared `wfb` constructor/area/HP semantics. Runtime configuration keys in `qb.a[]` remain a separate namespace and must not be conflated with this static component operator.
