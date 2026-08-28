# VOIDA — Native `wfb` Caller Trace

## SOURCE
Current repository evidence only. `VOIDA/32_NATIVE_COMPONENT_SLOT_MATRIX.md` is the authoritative slot ledger; `VOIDA/36_NATIVE_WFB_SLOT_EXTRACTION.md` anchors the native `wfb[56]` index space to the original `wlb` initializer.

## VERIFIED CALLER/BEHAVIOR GROUPS

The native slot ledger already contains the strongest available behavior-bearing call-site evidence. These mappings are therefore closed at the **native semantic level**:

| Native slot(s) | Native behavior | Status |
|---|---|---|
| 14 | weapon 11 | CLOSED |
| 15 | weapon 0 | CLOSED |
| 16 | weapon 3 | CLOSED |
| 17 | weapon 1 | CLOSED |
| 18 | weapon 2 | CLOSED |
| 19 | generic | CLOSED |
| 20 | generic | CLOSED |
| 23 | weapon 4 | CLOSED |
| 24 | weapon 6 | CLOSED |
| 25 | weapon 7 | CLOSED |
| 26 | grapple | CLOSED |
| 27 | weapon 8 | CLOSED |
| 42 | generic | CLOSED |
| 43 | weapon 9 | CLOSED |
| 44 | weapon 10 | CLOSED |

## FORCE-COMPONENT CALLER TRACE
Native thruster behavior is separately source-backed through `aqa` and its component-type dispatch:

- native type `12` → force scale `16`
- native type `13` → force scale `192`
- native type `46` → force scale `1024`

The operator applies the selected scale to the caller-supplied native magnitude, then applies native trig and invokes the `anb` force path. This is a native behavior mapping, not a Roblox-unit mapping.

## SLOT CLASSES THAT MUST REMAIN UNMAPPED
Slots `0..13`, `21..22`, `28..41`, `45..55` contain referenced or generated definitions whose native semantic identity is not proven by the currently committed repository evidence. In particular, the generated chassis/terrain group must not be assigned gameplay component names from geometry alone.

## IMPORTANT REPOSITORY LIMIT
The raw bytecode file named by the prior extraction note (`VOIDA/ORIGINAL_JAR/PREPROCESSING_01_06/javap-targeted/wlb.txt`) is not present in the Git tree. Therefore this trace does not pretend to reconstruct constructor expressions that are not actually accessible here.

## RESULT
The caller trace now closes every slot for which the repository contains explicit native behavior labels, while isolating the remaining slots by evidence class. This is preferable to assigning speculative Roblox names.

## NEXT
Remaining P0 work is no longer generic slot caller tracing. It is:
1. native `anb` force/integration call-site semantics;
2. exact mission sequencing;
3. shield/power/repair native consumers;
4. referenced/generated slot constructor recovery if the raw artifact becomes accessible.

## STATUS
**NATIVE BEHAVIOR CALLER GROUPS CONSOLIDATED — NO SPECULATIVE ROBLOX MAPPINGS.**
