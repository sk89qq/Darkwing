# TASK 4 — ml FIELD LIFECYCLE CENSUS — 2026-09-02

Source: original JAR targeted javap `ml.txt`. This census is a port-oriented dataflow map. Semantic names remain conservative where bytecode does not prove meaning.

## VERIFIED CONSTRUCTOR
`ml(int)`:
- j := constructor argument
- reads wfb definition from hab.g[j]
- conditionally constructs native subsystems from definition fields c/e/g/t/x
- p := 0
- i := wfb.p
- q := 0
- if wfb.o != null, d := new imb[wfb.o.length]
- invokes c(true), which allocates g to wfb.v.length and initializes child-related runtime state

## VERIFIED FIELD ACCESS SUMMARY
The native `ml` class contains 20 instance fields plus static `l`. The following are the highest-value field access patterns recovered from the targeted disassembly.

### i
Reads occur in health/state queries, damage routing, repair/adjustment, terminal checks, selection predicates, and serialization/state transfer. Writes occur in direct damage subtraction, health adjustment, constructor initialization, state-copy/update paths, and explicit zeroing.

Known transitions:
- constructor: i = wfb.p
- direct damage: i -= amount; if i <= 0 then i = 0 and terminal/handled result is returned
- signed health adjustment: adds delta, clamps positive overflow against wfb.p; residual behavior depends on native flags
- special damage path: reads wfb.B and applies native fixed-point scaling before subtracting/clamping

### p / q
Both are explicitly initialized to 0. They are read by multiple state/timing/resource calculations. `h(byte)` proves a transition `p := q` and `n` is also written in that method. Do not assign semantic names until producer/consumer closure.

### n / r
Frequently read by transform/kinematic calculations, recursive state propagation, and coordinate/state update paths. `a(byte,int[])` consumes both with native wfb.u scaling. Multiple methods write them during state/update operations. Resolve source producers before port renaming.

### f
Child `ml[]` array. Read by recursive traversal, state propagation, selection, and destruction-related paths. Constructor/initialization establishes child-related runtime state. Parent-child mutation and severance remain active closure targets.

### d
`imb[]` runtime hardpoint array. Constructor allocation is exactly `wfb.o.length` when `wfb.o` exists. Runtime reads/writes occur in hardpoint/state/update paths. Exact hardpoint object semantics remain an active geometry/runtime target.

### g
`int[]` runtime derived state. `c(boolean)` allocates it with length `wfb.v.length`. It is subsequently read/written by multiple mapping/update paths. It is not an independent static constant.

### a / c / h / k
Runtime subsystem/object references. Constructor conditionally creates them from native definition data. Their lifecycle and parent ownership are important because they participate in damage, update, physics and special-component behavior.

### b / e / m / o
Integer runtime fields with multiple writes and reads. Current bytecode census shows they participate in state/update, selection, transform, and serialization paths. Semantic labels remain unresolved until their strongest producer/consumer chains are traced.

### j
Constructor-supplied component definition/type index. Multiple native methods use j to retrieve the corresponding `wfb` definition. This is safe to expose as a type/definition index in the target contract.

## HIGH-VALUE METHODS FOR NEXT TRACE
- `ml(int)` — constructor/default state
- `a(int,int,pe,anb)` — direct damage routing
- `a(int,byte)` — special damage/residual path
- `a(boolean,boolean,int)` — signed health/resource-like adjustment
- `h(int)` — terminal/health transition
- `h(byte)` — p/q/n transition
- `c(int,int,int,int)` — multi-field state write site
- `a(byte,int)` — direct `e` write
- `a(ml,int,int,byte,ij)` — child/runtime mapping write to g
- `a(int,int,anb,int,int,pe)` — writes o
- `a(byte,anb)` — writes e/o/p/t through body/state update
- `a(ml,...)` / `a(boolean,ml,...)` — parent/child mutation and subsystem state

## NATIVE DAMAGE BRIDGE
The direct damage method is source-verified in `NATIVE_DAMAGE_ROUTING_2026-09-01.md`. Do not replace its selector-driven recursion with nearest-part/random targeting. External selector generation and target eligibility still require caller tracing.

## PORT INTERPRETATION RULE
This census is not a prescription to create one Luau object field per Java field. The downstream implementation may collapse or reorganize fields if the resulting state machine preserves the native observable contract. Native field identities must remain available for provenance and unresolved-state tracing.

## STATUS
`ACTIVE / HIGH-VALUE TASK 4 SUBCENSUS`
