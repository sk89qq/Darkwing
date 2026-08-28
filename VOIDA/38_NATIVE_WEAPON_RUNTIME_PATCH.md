# NativeWeaponRuntime patch

The live NativeWeaponRuntime file currently contains `NATIVE_TICKS_PER_SECOND = 50` and converts Reload/ProjectileLife by `/50`. This conflicts with the native-first boundary established elsewhere: recovered values must remain in native source units until a later explicit execution adapter.

The intended patch is:
- remove the `NATIVE_TICKS_PER_SECOND` conversion constant;
- expose `GetReload` as the raw native value;
- expose `GetProjectileLife` as the raw native value;
- leave all weapon key contracts unchanged;
- do not infer whether the native tick domain corresponds to Roblox seconds.

This note is committed separately because the target source file is being concurrently modified by another agent and its blob SHA is changing between reads/writes. No source file is overwritten by this note.

Status: **PATCH SPECIFICATION COMMITTED; SOURCE FILE UPDATE BLOCKED BY CONCURRENT SHA CHANGE.**
