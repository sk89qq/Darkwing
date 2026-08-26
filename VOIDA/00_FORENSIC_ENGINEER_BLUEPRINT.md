# VOID HUNTERS — FORENSIC ENGINEER BLUEPRINT

**AUTHORITY:** AUTHORITATIVE FIRST-PASS REFERENCE
**STATUS:** SOURCE-OF-TRUTH / FULLY INTACT USER-PROVIDED REFERENCE
**DATE RECEIVED:** 2026-08-26

This repository uses the user-provided `VOID_HUNTERS_FORENSIC_ENGINEER_BLUEPRINT(2).md` as the authoritative first-pass engineering reference.

## Integrity

- Source lines: **748**
- Source bytes: **25,981**
- SHA-256: `83bac0521dd24c76545648a2489713a4d80a9bb229c89fff5c6a8e4f5b78c11b`

The source reference is preserved **verbatim** in the supplied reference artifact. Do not rewrite, normalize, simplify, or silently correct it.

## Precedence

1. This first-pass forensic blueprint establishes the recovered behavioral/data contract.
2. Original/decompiled source evidence cited by the blueprint outranks inferred Roblox behavior.
3. `AGENTS.md` defines implementation/authority rules but must not override recovered source semantics.
4. `VOIDA/09_AUTHORITY_CENSUS.md` and later audit documents record implementation deltas against this reference; they do not replace it.
5. `VOIDA/10_ROBLOX_LUAU_REFERENCE.md` supplies Roblox/Luau idioms and implementation shortcuts; it does not invent gameplay behavior.

## Engineering rule

Do not redesign mechanics that the reference already defines. Where the repository contains a functional legacy implementation that conflicts with this blueprint, migrate callers to the authoritative replacement and remove the obsolete authority. Where no functional replacement exists, implement the missing boundary from the blueprint and tag unverified behavior appropriately.

## Important source-truth rule

The blueprint explicitly forbids filling missing data with guesses. A value or behavior that the blueprint marks unrecovered/unknown must remain `UNKNOWN` or `INFERRED` until the required source evidence is recovered.

## Superseded duplicate

`VOIDA/05_FORENSIC_PORT_BLUEPRINT.md` was removed because it duplicated this contract while asserting several inferred values as `[CODE_VERIFIED]`. Keeping two competing blueprints would violate the single-source-of-truth rule.

END REFERENCE MANIFEST
